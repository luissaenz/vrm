# Análisis Unificado — Día 7-8: Persistencia Local Offline

**Rol:** Arquitecto de Software Principal
**Fase:** FASE 1 — Core de Grabación
**Paso:** Día 7-8 — Persistencia Local Offline (reanudación de proyectos)

---

## 1. Resumen Ejecutivo

Este paso consiste en hacer que el sistema de grabación de LUMIS sea **resiliente a interrupciones**: cierres accidentales, crashes del SO, llamadas telefónicas o descargas de batería. El usuario debe poder cerrar la app en medio de una grabación y, al volver, encontrar su progreso intacto y listo para reanudar desde el último fragmento aprobado.

Actualmente la base ya existe: `RecordingManager` escribe `session_data.json` en cada "Accept" de clip, `ProjectRepository` tiene CRUD completo para `ProjectState`, y `ClipStorageService` gestiona los archivos `.mp4` en disco. Sin embargo, **la carga de sesión no existe** — `RecordingPage` siempre crea sesión nueva ignorando lo que hay en disco. Además, el Dashboard muestra proyectos mock en lugar de datos reales.

El entregable de este paso es un sistema completo de persistencia y reanudación que cubra: escritura atómica, recuperación validada, Dashboard con proyectos reales y flujo de reanudación transparente.

---

## 2. Diseño Funcional Consolidado

### 2.1 Happy Path

1. **Creación de proyecto:** El usuario pega un guión en `NewProjectPage` → se segmenta → se genera `projectId` (UUID) → se guardan `input_schema.json`, `script_bundle.json` y se navega a `RecordingPage`.
2. **Grabación incremental:** Graba clip → revisa en `ClipReviewPage` → acepta → `RecordingManager` persiste `session_data.json` automáticamente.
3. **Interrupción:** La app se cierra (background kill, crash, batería baja). El `dispose()` del `RecordingManager` intenta guardar el clip parcial en curso.
4. **Reapertura:** El usuario abre la app → `DashboardPage` muestra el proyecto con badge "En progreso — 3/10 fragmentos".
5. **Reanudación:** Toca la card → se carga `session_data.json` → `SessionRecoveryService` valida integridad de clips → si válido, el usuario aparece en `RecordingPage` posicionado en el `currentChunkIndex` correcto, con los clips ya aprobados preservados.
6. **Continuación:** Graba el siguiente fragmento como si nada hubiera pasado.
7. **Finalización:** Completa todos los fragments → stitching → `final.mp4` → Dashboard muestra "Listo para exportar".

### 2.2 Edge Cases (MVP)

| Escenario | Comportamiento |
|---|---|
| **App crashea DURANTE grabación activa** | `dispose()` o `_handleBackgroundTransition` guarda clip parcial. Al reabrir, el clip existe en la carpeta `clips/` pero NO está en `approvedClips` (el usuario no lo aceptó). Se ofrece al usuario: "Hay una toma sin revisar del fragmento X. ¿Quieres verla?" → navega a `ClipReviewPage`. Si rechaza o el clip no existe, el chunk queda como pendiente. |
| **session_data.json corrupto** | Se renombra a `session_data.json.bak` y se crea sesión nueva. Se notifica: "No se pudo recuperar el progreso anterior." |
| **Clip referenciado en `approvedClips` fue borrado del filesystem** | `validateAndSanitize()` detecta que el `File` no existe → lo remueve del mapa → ajusta `currentChunkIndex` si era el actual → notifica: "El clip del fragmento X no se encontró. Se re-grabará." |
| **Todos los chunks aprobados pero `stitchingCompleted = false`** | Dashboard muestra badge "Listo para unir". Al entrar, se ofrece ejecutar stitching directamente. |
| **`stitchingCompleted = true` pero `final.mp4` no existe** | Badge "Error de exportación". Se ofrece re-ejecutar stitching. |
| **Proyecto sin sesión pero con input/script guardados** | Se trata como proyecto nuevo: se crea `session_data.json` limpio y se inicia grabación desde fragmento 0. |
| **Múltiples proyectos incompletos** | Dashboard lista todos ordenados por `lastUpdatedAt`. Cada uno es independiente. |
| **Sin espacio en disco** | Se detecta antes de iniciar grabación (ya implementado en `ClipStorageService.hasFreeSpace`) → SnackBar bloqueante. |

### 2.3 Manejo de Errores

| Fallo | Qué ve el usuario | Qué puede hacer |
|---|---|---|
| JSON corrupto al cargar | "No se pudo recuperar el progreso anterior. Empezando desde cero." | Aceptar y empezar de nuevo. |
| Escritura JSON falla | Sin notificación visible (solo debug log). La sesión queda en memoria. | Si la app no crashea, el clip aceptado persiste en memoria hasta el siguiente accept. |
| Clip no existe al reanudar | "El clip del fragmento 3 no se encontró. Se re-grabará." | Grabar el fragmento de nuevo. |
| Sin espacio en disco | "Almacenamiento insuficiente. Libera espacio e intenta de nuevo." | Liberar espacio y reintentar. |
| Crash durante stitching | Al reabrir, `stitchingCompleted = false` → stitching pendiente de re-ejecutar. | Volver a ejecutar stitching desde Dashboard. |

---

## 3. Diseño Técnico Definitivo

### 3.1 Arquitectura de Componentes

```
DashboardPage
    │
    ├─ SessionRecoveryService (NUEVO)
    │   ├─ listActiveSessions() → List<SessionSummary>
    │   ├─ loadSession(projectId) → SessionData?
    │   ├─ validateAndSanitize(SessionData) → SessionData
    │   └─ deleteSession(projectId) → void
    │
    └─ ProjectLifecycleManager (NUEVO)
        ├─ createProject(InputSchema) → ProjectState
        ├─ updateProjectScript(ProjectState, ScriptBundle) → ProjectState
        ├─ getProjectState(projectId) → ProjectState?
        └─ linkSessionToProject(projectId, SessionData) → void

RecordingPage
    │
    ├─ SessionRecoveryService.loadSession(projectId) en initState
    ├─ Si sesión existe → diálogo "Reanudar desde fragmento X?"
    ├─ RecordingManager inicializado con SessionData recuperada o nueva
    └─ _saveSessionDataToDisk → escritura atómica (tmp + rename)

NewProjectPage
    │
    └─ Tras segmentar:
        ├─ ProjectLifecycleManager.createProject(InputSchema)
        ├─ ProjectLifecycleManager.updateProjectScript(state, ScriptBundle)
        └─ Navega a RecordingPage con projectId
```

### 3.2 Contratos de Servicio

#### `SessionRecoveryService`

```
loadSession(projectId: String) → Future<SessionData?>
  - Lee {appDir}/vrm_data/projects/{projectId}/session_data.json
  - Retorna null si no existe
  - Lanza exception si corrupto (caller debe try/catch)

validateAndSanitize(SessionData session, {ScriptBundle? script}) → Future<SessionData>
  - Verifica File.exists() de cada path en approvedClips
  - Remueve entries con paths inexistentes
  - Si scriptBundle provisto: valida currentChunkIndex < totalChunks
  - Si currentChunkIndex apunta a chunk ya aprobado → avanza al siguiente no aprobado
  - Retorna sesión saneada

listActiveSessions() → Future<List<SessionSummary>>
  - Escanea {appDir}/vrm_data/projects/
  - Para cada subcarpeta: carga session_data.json
  - Filtra: solo retorna si approvedClips.isNotEmpty O stitchingCompleted=true
  - Ordena por lastUpdatedAt descendente

deleteSession(projectId: String) → Future<void>
  - Borra carpeta completa del proyecto (clips + session_data + final.mp4)
```

#### `ProjectLifecycleManager`

```
createProject(inputSchema: InputSchema) → Future<ProjectState>
  - Genera UUID v4 como projectId
  - Crea ProjectState(createdAt=now, updatedAt=now, input=inputSchema)
  - Guarda vía ProjectRepository.saveProject()
  - Escribe input_schema.json separado en carpeta del proyecto

updateProjectScript(ProjectState state, ScriptBundle script) → Future<ProjectState>
  - state.copyWith(script=script, updatedAt=now)
  - Re-guarda vía ProjectRepository
  - Escribe script_bundle.json separado en carpeta del proyecto

getProjectState(projectId: String) → Future<ProjectState?>
  - Wrapper de ProjectRepository.loadProject(projectId)

linkSessionToProject(projectId: String, SessionData session) → Future<void>
  - Asegura que session_data.json esté en la carpeta del proyecto
  - Si la carpeta no existe, la crea
```

### 3.3 Modelo de Datos

#### `SessionSummary` (DTO nuevo)

```
SessionSummary {
  projectId: String
  title: String?                      // De ProjectState.input?.rawTopic
  approvedClipsCount: int             // sessionData.approvedClips.length
  totalChunks: int?                   // De ProjectState.script?.totalChunks (nullable)
  lastUpdatedAt: DateTime
  stitchingCompleted: bool
  finalVideoPath: String?
  status: SessionStatus
}
```

#### `SessionStatus` (enum nuevo)

```
enum SessionStatus {
  in_progress,         // stitchingCompleted=false, approvedClips < totalChunks
  ready_to_stitch,     // stitchingCompleted=false, approvedClips >= totalChunks
  ready_to_export,     // stitchingCompleted=true, finalVideoPath existe
}
```

#### `SessionData` (EXISTENTE — NO modificar estructura)

Se mantiene **exactamente como está** en `lib/features/recording/models/session_data.dart`. No se agregan campos. Toda la información necesaria ya está presente:
- `approvedClips: Map<int, String>` — paths de clips aceptados.
- `currentChunkIndex: int` — próximo fragmento a grabar.
- `takesPerChunk: Map<int, ChunkTakeInfo>` — historial de intentos.
- `stitchingCompleted: bool` — flag de unión completada.
- `finalVideoPath: String?` — ruta del video final.

### 3.4 Esquema de Paths en Disco

```
{appDir}/vrm_data/
  user_profile.json                          ← Ya existe (OnboardingRepository)
  projects/
    {project_id}/
      input_schema.json                      ← NUEVO: guardar al crear proyecto
      script_bundle.json                     ← NUEVO: guardar tras segmentación
      project_state.json                     ← Ya soporta ProjectRepository
      session_data.json                      ← Ya existe (RecordingManager)
      clips/
        chunk_0_take_1.mp4                   ← Ya existe (ClipStorageService)
        chunk_0_take_2.mp4
        chunk_1_take_1.mp4
      final.mp4                              ← Ya existe (FFmpegStitcherService)
```

### 3.5 Escritura Atómica de `session_data.json`

**Patrón:** Write-to-temp + rename atómico.

1. Serializar `sessionData.toJson()` → JSON string.
2. Escribir a `session_data.json.tmp` en la misma carpeta.
3. Si escritura exitosa → `File(tmpPath).rename(session_data.json)`.
4. `File.rename()` es atómico en la mayoría de filesystems móviles (POSIX rename).
5. Al cargar: si `session_data.json` no existe pero `.tmp` sí → cargar `.tmp` y renombrar.

### 3.6 Paths Relativos vs Absolutos

**Decisión crítica:** `approvedClips` almacena **paths relativos**, no absolutos.

- En `ClipStorageService`, el método `clipPath(chunkIndex, takeNumber)` ya retorna la ruta relativa: `vrm_data/projects/{projectId}/clips/chunk_X_take_Y.mp4`.
- Al guardar en `approvedClips`, usar esta ruta relativa.
- Al cargar sesión, reconstruir el path absoluto con: `File('${appDir.path}/$relativePath')`.
- **Justificación:** Los paths absolutos del sandbox cambian entre versiones de iOS/Android y entre reinstalaciones. Los relativos son portables.

### 3.7 Flujo de Integración con Componentes Existentes

Coherencia con `estado-fase.md`:

| Contrato en estado-fase.md | Cómo se respeta |
|---|---|
| `IExportService` con `saveVideoToGallery`, `shareVideo` | Sin cambios. El `ExportService` opera sobre `finalVideoPath` de `SessionData`. |
| Clips: `chunk_{index}_take_{attempt}.mp4` | Sin cambios. `ClipStorageService` ya usa esta convención. |
| Video final: `final.mp4` | Sin cambios. `FFmpegStitcherService` ya lo genera así. |
| Estructura `/vrm_data/projects/{id}/` | Sin cambios. Se consolidan los archivos adicionales (input_schema, script_bundle) en la misma carpeta. |
| `RecordingManager` guarda `session_data.json` en cada accept | Se mantiene, pero se mejora con escritura atómica. |
| `ProjectRepository` con save/load/list/delete | Se reutiliza tal cual para `ProjectState`. |

### 3.8 Modificaciones a Componentes Existentes

#### `RecordingPage` (modificación de flujo)
- `initState`: Antes de crear `SessionData` nuevo → `SessionRecoveryService.loadSession(projectId)`.
- Si sesión existe → `validateAndSanitize()` → diálogo "Reanudar desde fragmento X?".
- Si usuario acepta → `RecordingManager` con sesión recuperada.
- Si rechaza o no hay sesión → comportamiento actual.

#### `RecordingManager` (modificación menor)
- `_saveSessionDataToDisk()`: Cambiar a patrón write-to-temp + rename.
- Constructor: Aceptar `SessionData` existente (ya lo hace, sin cambio).

#### `NewProjectPage` (modificación de flujo)
- En `_optimizeScript()`, tras generar `ScriptAnalysis`:
  1. Convertir a `InputSchema` (con texto del usuario).
  2. Convertir a `ScriptBundle` (mapeando segments → chunks).
  3. `ProjectLifecycleManager.createProject(inputSchema)` → obtiene `projectId`.
  4. `ProjectLifecycleManager.updateProjectScript(state, scriptBundle)`.
  5. Navegar a `FragmentOrganizationPage` → `RecordingPage` pasando `projectId`.

#### `DashboardPage` (modificación de UI)
- `_RecentProjectsSection`: Reemplazar mocks con `FutureBuilder` que consulta `SessionRecoveryService.listActiveSessions()`.
- Cada card con datos reales de `SessionSummary`.
- Tap en card → cargar sesión → navegar según `status`.
- Estado vacío: "No hay proyectos en curso. ¡Crea uno!"

#### `ClipStorageService` (modificación menor)
- `clipPath()`: Asegurar que retorna path relativo consistente (ya lo hace).
- Agregar método `resolveAbsolutePath(relativePath: String)` → reconstruye path absoluto con `appDir`.

---

## 4. Decisiones Tecnológicas

**No hay decisiones tecnológicas nuevas respecto a `estado-fase.md`.** Se mantienen:

- **JSON plano** para persistencia (no SQLite): volumen bajo de datos, estructura jerárquica simple.
- **`path_provider`** para directorios: `getApplicationDocumentsDirectory()` como raíz de `vrm_data/`.
- **UUID** para project IDs (ya instalado como dependencia).
- **FFmpeg** para stitching (ya definido).
- **`gal`** para exportación a galería (ya en migración).

### Decisiones de diseño tomadas en esta unificación:

| Decisión | Justificación |
|---|---|
| **Paths relativos en `approvedClips`** (propuesta de atg, adoptada) | Los paths absolutos del sandbox cambian. Reconstruirlos en runtime es la única forma de asegurar persistencia entre ciclos de vida. |
| **No modificar estructura de `SessionData`** (corrección sobre propuesta de kl) | `SessionData` ya tiene todos los campos necesarios. Agregar `lastClipIndex`, `scriptProgress`, etc. (como propuso kl) es redundante con `currentChunkIndex` y `approvedClips`. |
| **`SessionRecoveryService` separado de `RecordingManager`** (propuesta de qwen, adoptada) | Responsabilidad única. `RecordingManager` orquesta grabación; `SessionRecoveryService` gestiona I/O de sesiones. Más testeable. |
| **Escritura atómica con tmp + rename** (propuesta compartida por los 3 análisis) | Previene corrupción por crash durante escritura. Patrón estándar en sistemas de archivos. |
| **Dashboard como punto de entrada a reanudación** (propuesta compartida) | Pantalla principal del usuario. Lugar natural para "trabajo en progreso". |
| **Filtrar proyectos con `approvedClips.isNotEmpty` en `listActiveSessions()`** (propuesta de qwen) | Evita listar proyectos creados pero nunca grabados (huérfanos). |
| **Diálogo de reanudación obligatorio** (propuesta de qwen) | El usuario debe confirmar explícitamente si quiere reanudar o empezar de nuevo. Evita confusión. |

### Propuestas descartadas:

| Propuesta | Origen | Razón de descarte |
|---|---|---|
| Agregar campos `lastClipIndex`, `scriptProgress`, `timestampLastSave` a `SessionData` | kl | Redundantes. `currentChunkIndex` = `lastClipIndex`, `approvedClips` = progreso, `lastUpdatedAt` = timestamp. |
| Interfaz abstracta `IProjectStorage` | atg | Over-engineering para MVP. Solo hay una implementación de storage (filesystem local). |
| Checksum/hash para detectar corrupción de JSON | kl | Overkill. `try/catch` en `jsonDecode` detecta corrupción suficiente. |
| Expiración automática de sesiones (>7 días) | kl | Comportamiento no solicitado en MVP. El usuario decide cuándo borrar. |
| Sincronización en "Accept" solamente (no durante grabación) | atg | Ya está implementado el guardado en cada accept. Se mantiene. |

---

## 5. Criterios de Aceptación MVP

### Funcionales
- [ ] Al crear un proyecto desde `NewProjectPage`, se genera un `projectId` (UUID) y se guardan `input_schema.json` y `script_bundle.json` en la carpeta del proyecto.
- [ ] `RecordingPage` intenta cargar `session_data.json` existente antes de crear una sesión nueva.
- [ ] Si existe sesión previa válida, el usuario ve un diálogo "Reanudar grabación desde fragmento X" y puede aceptar o empezar de nuevo.
- [ ] Al reanudar, `RecordingPage` posiciona el teleprompter en el `currentChunkIndex` guardado y preserva los clips ya aprobados.
- [ ] Dashboard muestra proyectos reales desde `SessionRecoveryService.listActiveSessions()` con título, progreso (X/Y fragmentos), badge de estado y última actualización.
- [ ] Tocar un proyecto "En progreso" en Dashboard navega a `RecordingPage` con la sesión recuperada.
- [ ] Tocar un proyecto "Listo para exportar" navega a `RecordingEndPage` con acceso a exportar/compartir.

### Técnicos
- [ ] `session_data.json` se escribe con patrón atómico (write-to-temp + rename).
- [ ] Los paths en `approvedClips` son relativos (`vrm_data/projects/{id}/clips/chunk_X_take_Y.mp4`), no absolutos.
- [ ] Al cargar sesión, los paths relativos se resuelven correctamente a paths absolutos con `getApplicationDocumentsDirectory()`.
- [ ] `SessionRecoveryService.validateAndSanitize()` elimina entries de `approvedClips` cuyos archivos no existen.
- [ ] `SessionStatus` se calcula correctamente: `in_progress`, `ready_to_stitch`, o `ready_to_export`.
- [ ] No hay errores en consola al listar/cargar sesiones múltiples.

### Robustez
- [ ] Si `session_data.json` está corrupto, se renombra a `.bak` y se crea sesión nueva sin crash visible.
- [ ] Si un clip referenciado fue borrado del filesystem, el sistema lo detecta, lo remueve de la sesión y notifica al usuario.
- [ ] Si la app se cierra durante grabación activa, el clip parcial se guarda (vía `dispose()` o `_handleBackgroundTransition`) y está disponible para revisión al reabrir.
- [ ] Si no hay espacio en disco, se bloquea el inicio de grabación con mensaje claro.
- [ ] La app no crashea bajo ninguna circunstancia al cargar sesiones inválidas, missing o con paths rotos.

---

## 6. Plan de Implementación

| # | Tarea | Complejidad | Dependencias |
|---|---|---|---|
| 1 | **Crear `SessionRecoveryService`** con `loadSession`, `validateAndSanitize`, `listActiveSessions`, `deleteSession` | Media | Ninguna |
| 2 | **Crear `ProjectLifecycleManager`** con `createProject`, `updateProjectScript`, `getProjectState`, `linkSessionToProject` | Media | `ProjectRepository` (existente) |
| 3 | **Modificar `NewProjectPage`** para persistir proyecto tras segmentación (crear InputSchema, ScriptBundle, UUID, navegar con projectId) | Baja | Tarea 2 |
| 4 | **Modificar `RecordingPage`** para intentar cargar sesión previa en `initState` + diálogo de reanudación | Media | Tarea 1 |
| 5 | **Implementar escritura atómica** en `_saveSessionDataToDisk` del `RecordingManager` (tmp + rename) | Baja | Ninguna |
| 6 | **Modificar `ClipStorageService`** para asegurar paths relativos + agregar `resolveAbsolutePath()` | Baja | Ninguna |
| 7 | **Modificar `DashboardPage`** para mostrar proyectos reales con `FutureBuilder` + navegación según estado | Alta | Tareas 1, 2, 3, 4 |

### Orden de ejecución recomendado:
```
1 → 2 → 3 → 4 → 5 → 6 → 7
```

La tarea 7 va última porque depende de que existan proyectos reales para mostrar y de que el flujo de creación → grabación → recuperación funcione end-to-end.

---

## 7. Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **Corrupción de `session_data.json` por crash durante escritura** | Baja | 🔴 ALTO | Escritura atómica: escribir a `.tmp` primero, luego `File.rename()`. Si `.json` no existe pero `.tmp` sí, cargar `.tmp` y renombrar. |
| **Race condition: Dashboard lista mientras RecordingManager escribe** | Baja | 🟡 MEDIO | `listActiveSessions()` lee archivos inmutables (no modifica). La escritura es solo desde `RecordingManager` que serializa con `_isProcessing`. Lectura concurrente de JSON es safe. |
| **Paths relativos inconsistentes entre `ClipStorageService` y `SessionData`** | Media | 🔴 ALTO | Centralizar: `ClipStorageService.clipPath()` es la ÚNICA fuente de paths relativos. `SessionData` los recibe ya formateados. Al cargar, `resolveAbsolutePath()` usa la misma convención. |
| **Dashboard lento al listar muchos proyectos** | Media | 🟡 MEDIO | `listActiveSessions()` escanea filesystem secuencialmente. Para MVP (<50 proyectos) es aceptable (<200ms). Si crece, implementar `projects_master.json` index (roadmap). |
| **`ProjectState` y `session_data.json` se desincronizan** | Baja | 🟡 MEDIO | `ProjectLifecycleManager.linkSessionToProject()` asegura coherencia. En MVP, ambos viven en la misma carpeta y se referencian por `projectId`. |
| **Usuario borra clips manualmente del filesystem** | Baja | 🟡 MEDIO | `validateAndSanitize()` detecta archivos faltantes al cargar sesión y los remueve de `approvedClips`. Se notifica al usuario. |

---

## 8. Testing Mínimo Viable

Cada caso de prueba se alinea 1:1 con un criterio de aceptación.

| # | Caso de Prueba | Criterio Validado |
|---|---|---|
| T1 | Crear proyecto desde NewProjectPage → verificar que existen `input_schema.json`, `script_bundle.json` y carpeta en disco | Funcional #1, Técnico #2 |
| T2 | Grabar 3 clips, aceptar los 3 → cerrar app (kill process) → reabrir → cargar desde Dashboard → verificar que session_data.json se recupera con los 3 clips | Funcional #2, #3, #4; Robustez #4 |
| T3 | Corromper manualmente `session_data.json` (editar con texto basura) → cargar desde Dashboard → verificar que no crashea, muestra diálogo de error, crea sesión nueva | Robustez #1, #6 |
| T4 | Grabar 3 clips, aceptar → borrar manualmente el `.mp4` del clip 2 → cerrar app → reabrir → verificar que `validateAndSanitize` remueve clip 2 de `approvedClips` y notifica | Robustez #2 |
| T5 | Iniciar grabación → forzar background (home button) → verificar que `dispose()` guarda clip parcial → reabrir → clip existe en carpeta `clips/` | Robustez #3 |
| T6 | Llenar disco hasta <500MB → intentar grabar → verificar que muestra SnackBar de almacenamiento insuficiente y NO inicia grabación | Robustez #5 |
| T7 | Completar todos los clips → stitching → verificar que Dashboard muestra badge "Listo para exportar" → tap → navega a `RecordingEndPage` | Funcional #7 |
| T8 | Dashboard con 0 proyectos → verificar que muestra estado vacío "No hay proyectos en curso" | Funcional #5 |
| T9 | Crear 2 proyectos → grabar 2 clips en cada uno → cerrar app → verificar que Dashboard lista ambos con progreso correcto ordenado por `lastUpdatedAt` | Funcional #5 |
| T10 | Verificar que los paths en `session_data.json` son relativos (no contienen `/var/`, `/data/`, `/Users/`) | Técnico #2 |

---

## 9. 🔮 Roadmap (NO implementar ahora)

### Cloud Sync / Multi-dispositivo
Sincronizar `vrm_data/` con cloud (iCloud Drive, Google Drive) para reanudar en otro dispositivo. La separación `ProjectState`/`SessionData` y los paths relativos facilitan la portabilidad.

### Versionado de Sesiones
Mantener histórico de `session_data` (tipo "save states") para rollback. La escritura atómica (tmp + rename) es la base: bastaría con preservar los `.tmp` como versiones (`session_data.v1.json`, `v2`, etc.).

### Proyecto Index / Master List
Un archivo `projects_master.json` en la raíz de `vrm_data/` con metadata resumida de todos los proyectos para evitar escanear carpetas en el Dashboard. Optimización para cuando haya >50 proyectos.

### Proyecto "Template" / Duplicar
Permitir clonar un proyecto existente como punto de partida. La separación `ProjectState`/`SessionData` lo permite: clonar state, crear sesión nueva limpia.

### Estadísticas de Producción
Mostrar métricas: "tiempo total grabado", "takes promedio por fragmento", "proyectos completados esta semana". Los datos brutos ya están capturados en `SessionData`.

### Auto-Backup / Exportación
Comprimir la carpeta del proyecto en `.zip` para exportación manual o backup automático periódico.

### Integración con IA Backend
Guardar respuestas crudas del modelo en archivos separados para auditoría y re-uso. `InputSchema.contextData` ya tiene campo extensible para esto.

---

**Documento unificado. Sin contradicciones pendientes. Coherente con `estado-fase.md`. Listo para implementación.**
