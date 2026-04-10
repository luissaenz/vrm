# Análisis Técnico — Día 7-8: Persistencia Local Offline

**Agente:** qwen
**Fecha:** 10 de abril de 2026
**Alcance:** Sistema de persistencia JSON para reanudación de proyectos/sesiones interrumpidas

---

## 1. Diseño Funcional

### Happy Path
1. El usuario inicia un proyecto → graba clips → acepta/rechaza tomas.
2. En cada "Accept" de clip, `RecordingManager` persiste `session_data.json` en disco automáticamente.
3. El usuario **cierra la app accidentalmente** (crash, background kill, batería baja).
4. Al reabrir la app, el **Dashboard** muestra el proyecto con un badge "Borrador en curso" indicando el progreso guardado (ej: "3/10 fragmentos grabados").
5. El usuario toca el proyecto → se le ofrece **"Reanudar grabación"** o **"Descartar progreso"**.
6. Si reanuda, `RecordingPage` carga la sesión desde `session_data.json`, restaura:
   - `currentChunkIndex` → el teleprompter muestra el fragmento correcto.
   - `approvedClips` → los clips ya aceptados no se re-graban.
   - `takesPerChunk` → se mantiene el historial de intentos.
7. El usuario continúa grabando desde donde quedó como si nada hubiera pasado.

### Edge Cases (MVP)
| Escenario | Comportamiento esperado |
|---|---|
| **App crashea DURANTE grabación activa** (sin stopRecording) | Al reabrir, el clip parcial guardado por `_handleBackgroundTransition` o `dispose()` aparece como "última toma no revisada". El usuario la ve en ClipReview y decide Accept/Reject. |
| **session_data.json existe pero clips fueron borrados manualmente** | Al reanudar, se detectan paths inválidos → se limpian del session_data y se notifica al usuario: "Algunos clips se perdieron. Re-grabando desde fragmento X." |
| **Múltiples sesiones huérfanas** (usuario creó proyecto pero nunca terminó) | Dashboard lista todas las sesiones con estado "Incompleto". El usuario puede reanudar cualquiera o borrarlas. |
| **stitchingCompleted = true pero final.mp4 no existe** | Se marca la sesión como "Error de exportación". Se ofrece re-ejecutar stitching o descartar. |
| **Proyecto completo (final.mp4 existe)** | Dashboard muestra "Listo para exportar" con acceso directo a `RecordingEndPage` para exportar/compartir. |

### Manejo de Errores
- **Fallo de lectura JSON:** Si `session_data.json` está corrupto, se crea uno nuevo vacío y se notifica: "No se pudo recuperar el progreso anterior. Empezando desde cero."
- **Fallo de escritura JSON:** Se loguea en debug pero NO se bloquea el flujo de grabación (comportamiento actual, se mantiene).
- **Sin espacio en disco:** Se detecta antes de iniciar grabación (ya implementado en `ClipStorageService.hasFreeSpace`) y se muestra SnackBar bloqueante.

---

## 2. Diseño Técnico

### 2.1 Componentes Nuevos

#### `SessionRecoveryService` (nuevo)
**Responsabilidad:** Centralizar la carga, validación y sanitización de sesiones desde disco.

**Interfaces:**
```
SessionRecoveryService
  ├─ loadSession(projectId: String) → Future<SessionData?>
  ├─ listActiveSessions() → Future<List<SessionSummary>>
  ├─ validateAndSanitize(SessionData) → Future<SessionData>
  └─ deleteSession(projectId: String) → Future<void>
```

**Inputs:**
- `projectId: String` — identificador único del proyecto.
- Path base: `{appDir}/vrm_data/projects/{projectId}/session_data.json`

**Outputs:**
- `SessionData?` — null si no existe sesión.
- `SessionSummary` — DTO para Dashboard con: projectId, progress (clips aprobados / total chunks), lastUpdatedAt, stitchingCompleted, finalVideoPath.

**Lógica de `validateAndSanitize`:**
1. Verificar que cada path en `approvedClips` exista como `File`.
2. Si un clip no existe → removerlo del mapa y loguear warning.
3. Si `currentChunkIndex` apunta a un chunk ya aprobado → avanzar al siguiente no aprobado.
4. Si todos los chunks están aprobados pero `stitchingCompleted = false` → marcar como "listo para stitching".
5. Retornar sesión saneada.

#### `ProjectLifecycleManager` (nuevo)
**Responsabilidad:** Orquestar la creación, actualización y consulta de `ProjectState` en el flujo completo.

**Interfaces:**
```
ProjectLifecycleManager
  ├─ createProject(inputSchema: InputSchema) → Future<ProjectState>
  ├─ updateProjectScript(ProjectState, ScriptBundle) → Future<ProjectState>
  ├─ getProjectState(projectId: String) → Future<ProjectState?>
  └─ linkSessionToProject(projectId: String, sessionData: SessionData) → Future<void>
```

**Inputs/Outputs:**
- Usa `ProjectRepository` existente (ya tiene save/load/list/delete).
- `InputSchema` viene del `NewProjectPage` cuando el usuario pega su guión.
- `ScriptBundle` viene del mock/IA fallback tras la segmentación.

### 2.2 Modificaciones a Componentes Existentes

#### `RecordingManager` (modificación menor)
- **Actual:** SessionData se inicializa "eagerly" en `initState` de `RecordingPage` con valores frescos (ignora sesión previa).
- **Cambio:** Antes de crear SessionData nuevo, consultar `SessionRecoveryService.loadSession(projectId)`.
  - Si existe → recuperar sesión.
  - Si no existe → crear nueva (comportamiento actual).

#### `RecordingPage` (modificación de flujo)
- ** initState:** Intentar cargar sesión previa antes de crear nueva.
- **Si hay sesión recuperada:** Mostrar diálogo opcional "¿Reanudar grabación desde fragmento X?" o "Empezar de nuevo".
- **Si no hay sesión:** Comportamiento actual (iniciar desde fragmento 0).

#### `DashboardPage` (modificación de UI)
- Reemplazar los project cards hardcodeados (`VRMProjectCard` mock) con datos reales de `SessionRecoveryService.listActiveSessions()`.
- Cada card muestra:
  - Título: del `ProjectState.input.rawTopic` o "Proyecto sin título".
  - Progreso: "X/Y fragmentos" (de `SessionData.approvedClips.length` vs `ScriptBundle.totalChunks`).
  - Badge de estado:
    - `stitchingCompleted=false` → "En progreso" (naranja)
    - `stitchingCompleted=true` → "Listo para exportar" (verde)
  - `lastUpdatedAt`: "Hace X horas" (con `intl`).
- Tap en card → navegar a lógica de reanudación.

#### `NewProjectPage` (modificación de flujo)
- Tras segmentar el guión (mock o IA), **guardar `ProjectState`** con `input` y `script` antes de navegar a `RecordingPage`.
- Generar `projectId` con `uuid` (ya instalado).
- Pasar `projectId` a `FragmentOrganizationPage` → `RecordingPage`.

### 2.3 Modelo de Datos (Extensión)

#### `SessionSummary` (nuevo DTO)
```
SessionSummary {
  projectId: String
  title: String?             // De ProjectState.input.rawTopic
  approvedClipsCount: int
  totalChunks: int           // De ProjectState.script.totalChunks (si existe)
  lastUpdatedAt: DateTime
  stitchingCompleted: bool
  finalVideoPath: String?
  status: SessionStatus      // in_progress | ready_to_stitch | ready_to_export
}
```

**Enum `SessionStatus`:**
- `in_progress`: Hay clips aprobados pero stitching no completado.
- `ready_to_stitch`: Todos los chunks tienen clips aprobados, stitching pendiente.
- `ready_to_export`: Stitching completado, final.mp4 existe.

### 2.4 Esquema de Paths en Disco (Consolidado)

```
{appDir}/vrm_data/
  user_profile.json                     ← Ya existe (OnboardingRepository)
  projects/
    {project_id}/
      input_schema.json                 ← Pendiente: guardar al crear proyecto
      script_bundle.json                ← Pendiente: guardar tras segmentación
      session_data.json                 ← Ya existe (RecordingManager._saveSessionDataToDisk)
      clips/
        chunk_0_take_1.mp4              ← Ya existe (ClipStorageService)
        chunk_0_take_2.mp4
        chunk_1_take_1.mp4
        ...
      final.mp4                         ← Ya existe (FFmpegStitcherService)
```

### 2.5 Flujo de Reanudación (Secuencia)

```
1. Usuario abre Dashboard
2. Dashboard consulta SessionRecoveryService.listActiveSessions()
3. Muestra cards con proyectos en curso
4. Usuario toca card → SessionRecoveryService.loadSession(projectId)
5. validateAndSanitize() verifica integridad de clips
6. Si válido → Navigator.push(RecordingPage) con sessionData recuperada
7. RecordingPage inicializa RecordingManager con sessionData existente
8. Teleprompter salta a currentChunkIndex
9. Usuario continúa grabando
```

---

## 3. Decisiones

### D1: Mantener `session_data.json` separado de `project_state.json`
**Justificación:** `SessionData` es volátil (cambia con cada clip). `ProjectState` es estable (input, script, assets). Separarlos evita re-escribir el JSON completo del proyecto en cada operación de grabación, reduciendo I/O y riesgo de corrupción.

### D2: Usar `ProjectRepository` existente como capa de persistencia de ProjectState
**Justificación:** Ya implementa save/load/list/delete con manejo de errores robusto (`PersistenceException`). No reinventarlo.

### D3: No migrar `session_data.json` al esquema de `ProjectRepository`
**Justificación:** `SessionData` tiene una estructura diferente (mapas con keys numéricas, fechas) y su ciclo de vida está atado al flujo de grabación, no al CRUD de proyectos. Mantener `_saveSessionDataToDisk` en `RecordingManager` es correcto.

### D4: Validación de integridad de clips al reanudar
**Justificación:** El usuario puede borrar clips manualmente del filesystem o el OS puede limpiar caché. Sin validación, el stitching fallaría silenciosamente o crasharía. La sanitización proactiva previene esto.

### D5: Dashboard como punto de entrada a sesiones recuperables
**Justificación:** Es la pantalla principal del usuario. Es el lugar natural para mostrar "trabajo en progreso" y permitir reanudación sin navegación oculta.

---

## 4. Criterios de Aceptación

- [ ] Al crear un proyecto desde NewProjectPage, se genera un `projectId` (UUID) y se guarda `input_schema.json` en disco.
- [ ] Tras segmentar el guión, se guarda `script_bundle.json` en la carpeta del proyecto.
- [ ] `RecordingPage` intenta cargar `session_data.json` existente antes de crear una sesión nueva.
- [ ] Si existe sesión previa válida, el usuario puede reanudar desde el `currentChunkIndex` guardado.
- [ ] Si `session_data.json` está corrupto o no existe, se crea una sesión nueva sin error visible al usuario.
- [ ] `SessionRecoveryService.validateAndSanitize()` elimina paths de `approvedClips` que no existen como archivos.
- [ ] Dashboard muestra proyectos reales desde `SessionRecoveryService.listActiveSessions()`, no mocks.
- [ ] Cada card de proyecto en Dashboard muestra progreso (X/Y fragmentos), estado y última actualización.
- [ ] Tocar un proyecto "En progreso" en Dashboard navega a `RecordingPage` con la sesión recuperada.
- [ ] Tocar un proyecto "Listo para exportar" navega a `RecordingEndPage` con acceso a exportar/compartir.
- [ ] `ProjectLifecycleManager.linkSessionToProject()` asegura coherencia entre `SessionData` y `ProjectState`.
- [ ] No hay fugas de memoria al listar/cargar sesiones múltiples (controllers disposed correctamente).

---

## 5. Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **`session_data.json` se corrompe por write parcial (crash durante escritura)** | Baja | 🔴 ALTO | Usar patrón "write to temp + rename atómico": escribir `session_data.json.tmp`, luego `File.rename()` que es atómico en la mayoría de los filesystems. Si el `.json` no existe pero el `.tmp` sí, cargar el tmp. |
| **Dashboard lista proyectos huérfanos (sin sesión ni clips)** | Media | 🟡 MEDIO | `listActiveSessions()` filtra: solo retorna proyectos con `approvedClips.count > 0` O `stitchingCompleted = true`. |
| **Race condition: usuario toca Dashboard mientras se está guardando sesión** | Baja | 🟡 MEDIO | `SessionRecoveryService` lee archivos inmutables (no modifica). La escritura es solo desde `RecordingManager` que ya tiene su propio locking vía `_isProcessing`. |
| **Path de clip referenciado en `approvedClips` usa ruta relativa inconsistente** | Media | 🔴 ALTO | Estandarizar: `ClipStorageService.absoluteClipPath()` siempre retorna ruta absoluta. Al cargar sesión, verificar con `File(path).exists()`. Si es relativo, reconstruir con la convención `{appDir}/vrm_data/projects/{projectId}/clips/chunk_X_take_Y.mp4`. |
| **Proyecto con script_bundle.json ausente pero session_data.json presente** | Baja | 🟡 MEDIO | Si no hay `totalChunks` disponible, Dashboard muestra "Proyecto con X clips grabados" sin ratio de progreso. La reanudación funciona igual (usa `approvedClips` keys para determinar siguiente chunk). |

---

## 6. Plan

### Tarea 6.1: Crear `SessionRecoveryService`
- **Complejidad:** Media
- **Dependencias:** Ninguna (solo `path_provider`, `dart:io`)
- **Sub-tareas:**
  1. Implementar `loadSession(projectId)` → lee y parsea `session_data.json`.
  2. Implementar `validateAndSanitize(session)` → verifica existencia de clips, ajusta `currentChunkIndex`.
  3. Implementar `listActiveSessions()` → escanea carpeta `projects/`, carga cada `session_data.json`, retorna `List<SessionSummary>`.
  4. Implementar `deleteSession(projectId)` → borra carpeta completa del proyecto.
  5. Tests manuales: crear sesión, corromperla, validar recovery.

### Tarea 6.2: Crear `ProjectLifecycleManager`
- **Complejidad:** Media
- **Dependencias:** `ProjectRepository` (existente), `uuid`
- **Sub-tareas:**
  1. Implementar `createProject(inputSchema)` → genera UUID, crea `ProjectState`, guarda vía `ProjectRepository`.
  2. Implementar `updateProjectScript(state, scriptBundle)` → actualiza campo `script`, re-guarda.
  3. Implementar `getProjectState(projectId)` → wrapper de `ProjectRepository.loadProject`.
  4. Implementar `linkSessionToProject` → asegura que `session_data.json` y `project_state.json` estén en la misma carpeta.

### Tarea 6.3: Modificar `NewProjectPage` para persistir proyecto
- **Complejidad:** Baja
- **Dependencias:** Tarea 6.2
- **Sub-tareas:**
  1. En `_optimizeScript()`, tras generar `ScriptAnalysis`, convertir a `ScriptBundle`.
  2. Crear `InputSchema` con el texto del usuario.
  3. Llamar `ProjectLifecycleManager.createProject(inputSchema)`.
  4. Llamar `ProjectLifecycleManager.updateProjectScript(state, scriptBundle)`.
  5. Pasar `projectId` a `FragmentOrganizationPage` → `RecordingPage`.

### Tarea 6.4: Modificar `RecordingPage` para recuperación de sesión
- **Complejidad:** Media
- **Dependencias:** Tarea 6.1
- **Sub-tareas:**
  1. En `initState`, antes de crear `SessionData` nuevo, llamar `SessionRecoveryService.loadSession(projectId)`.
  2. Si retorna sesión válida → llamar `validateAndSanitize()`.
  3. Si sesión saneada tiene datos → mostrar diálogo "Reanudar grabación desde fragmento X?".
  4. Si usuario acepta → usar sesión recuperada en `RecordingManager`.
  5. Si usuario rechaza o no hay sesión → comportamiento actual (crear nueva).

### Tarea 6.5: Modificar `DashboardPage` para mostrar proyectos reales
- **Complejidad:** Alta
- **Dependencias:** Tareas 6.1, 6.2, 6.3
- **Sub-tareas:**
  1. Reemplazar `_RecentProjectsSection` con `FutureBuilder` que consulta `SessionRecoveryService.listActiveSessions()`.
  2. Para cada `SessionSummary`, construir `VRMProjectCard` con datos reales.
  3. Implementar navegación: tap en card → cargar sesión → navegar a RecordingPage o RecordingEndPage según estado.
  4. Agregar estado vacío: "No hay proyectos en curso. ¡Crea uno!"
  5. Agregar swipe-to-delete opcional para descartar proyectos huérfanos.

### Tarea 6.6: Guardar `input_schema.json` y `script_bundle.json` en flujo
- **Complejidad:** Baja
- **Dependencias:** Tarea 6.2
- **Sub-tareas:**
  1. Extender `ProjectLifecycleManager` con métodos de escritura de `input_schema.json` y `script_bundle.json` como archivos separados (además de `project_state.json` consolidado).
  2. En `NewProjectPage`, tras crear proyecto, escribir ambos archivos.
  3. En `SessionRecoveryService.loadSession`, si falta `totalChunks` en session_data, leer `script_bundle.json` para obtenerlo.

### Tarea 6.7: Escritura atómica de `session_data.json`
- **Complejidad:** Baja
- **Dependencias:** Ninguna
- **Sub-tareas:**
  1. Modificar `_saveSessionDataToDisk` en `RecordingManager`.
  2. Escribir primero a `session_data.json.tmp`.
  3. Si escritura exitosa → `File.rename()` a `session_data.json`.
  4. Al cargar, si `session_data.json` no existe pero `session_data.json.tmp` sí → cargar tmp y renombrar.

### Orden recomendado de ejecución:
```
6.1 → 6.2 → 6.3 → 6.4 → 6.6 → 6.7 → 6.5
```
(6.5 va último porque depende de que existan proyectos reales para mostrar)

---

## 🔮 Roadmap (NO implementar ahora)

### Cloud Sync / Multi-dispositivo
- **Mejora:** Sincronizar `vrm_data/` con cloud (Firebase, iCloud Drive, Google Drive) para permitir reanudar grabación en otro dispositivo.
- **Decisión de diseño tomada:** Separar `SessionData` de `ProjectState` facilita sincronizar solo lo que cambió (deltas). Los paths de clips serán relativos al proyecto para ser portables entre dispositivos.

### Versionado de Sesiones
- **Mejora:** Mantener histórico de `session_data` (tipo "save states") para permitir rollback a un punto anterior.
- **Decisión de diseño tomada:** El patrón de escritura atómica (tmp + rename) es la base para implementar un sistema de versionado sencillo (renombrar a `session_data.v1.json`, `v2`, etc.).

### Búsqueda y Filtrado de Proyectos
- **Mejora:** Filtrar proyectos por fecha, tema, estado, duración.
- **Decisión de diseño tomada:** `SessionSummary` incluye todos los campos necesarios para filtrado futuro sin re-estructuración.

### Estadísticas de Producción
- **Mejora:** Mostrar al usuario métricas como "tiempo total grabado", "takes promedio por fragmento", "proyectos completados esta semana".
- **Decisión de diseño tomada:** `SessionData.takesPerChunk` y `startedAt`/`lastUpdatedAt` ya capturan los datos brutos necesarios.

### Proyecto "Template"
- **Mejora:** Permitir duplicar un proyecto existente como punto de partida (re-usar input/script, resetear sesión).
- **Decisión de diseño tomada:** La separación ProjectState/SessionData permite clonar el state y crear una sesión nueva limpia.

### Integración con IA Backend
- **Mejora:** Cuando el backend de IA esté disponible, guardar las respuestas crudas del modelo en `input_schema.json` o un archivo separado para auditoría y re-uso.
- **Decisión de diseño tomada:** `InputSchema.contextData` ya tiene campo para metadata extensible.
