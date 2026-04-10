# 📋 ANÁLISIS TÉCNICO - DÍA 7-8: PERSISTENCIA LOCAL OFFLINE
**Agente:** mm | **Fecha:** 2026-04-10
**Estado del paso según `estado-fase.md`:** ✅ COMPLETADO

---

## 1. Diseño Funcional

### 1.1 Happy Path Completo

El flujo de persistencia opera en tres capas:

**Capa 1 — Sesión en memoria (`SessionData`):**
- Se mantiene en memoria dentro de `RecordingManager` durante toda la sesión activa.
- Se actualiza tras cada `acceptCurrentClip`, `stopRecording` y `startStitching`.

**Capa 2 — Persistencia "Hot" (automática tras cada operación):**
- `_saveSessionDataToDisk()` se invoca imperativamente tras cada modificación de estado (no hay debounce, no hay timer).
- Destino: `{appDocDir}/vrm_data/projects/{projectId}/session_data.json`.
- El JSON se sobrescribe completamente cada vez (`writeAsString`).

**Capa 3 — Recuperación al reanudar:**
- `SessionData.fromJson()` permite reconstruir el estado completo desde disco.
- `RecordingManager` recibe `SessionData` pre-cargado en su constructor.
- El proyecto se identifica por `projectId` (UUID), que es el mismo usado en `ClipStorageService` y `ProjectRepository`.

### 1.2 Edge Cases Cubiertos

| Edge Case | Estrategia |
|-----------|-----------|
| App matada durante grabación | `stopAndSavePartial()` guarda el clip en curso antes de dispose |
| App matada entre clips | `session_data.json` ya fue persisted tras el último `acceptCurrentClip` |
| Stitching interrumpido | `stitchingCompleted=false` en disco; se puede re-intentar desde UI de revisión |
| Corrupción de JSON de sesión | `try/catch` en `_saveSessionDataToDisk` — no lanza, solo loguea; el flujo de grabación continúa |
| Espacios de almacenamiento agotados | `ClipStorageService.hasFreeSpace()` verificado antes de grabar |
| Directorio de proyecto no existe | `projectDir.create(recursive: true)` en `_saveSessionDataToDisk` |

### 1.3 Manejo de Errores

- **Fallo al guardar sesión:** Silencioso (`debugPrint`), no bloquea la grabación. Justificado porque perder el último guardado es mejor que perder el clip en curso.
- **Fallo de lectura de sesión:** Propaga `PersistenceException` vía `ProjectRepository`.
- **Fallo de clip en disco:** `ClipStorageService.saveClip` tiene fallback `readAsBytes/writeAsBytes` antes de re-lanzar.

---

## 2. Diseño Técnico

### 2.1 Componentes Involucrados

| Componente | Rol | ¿Modificado en Día 7-8? |
|------------|-----|------------------------|
| `RecordingManager` | Orquestador + persistencia de sesión | ✅ Sí — `_saveSessionDataToDisk`, `acceptCurrentClip`, `stopRecording`, `startStitching` |
| `SessionData` | Modelo de estado de sesión | ✅ Sí — `toJson`, `fromJson`, `copyWith` |
| `ChunkTakeInfo` | Sub-modelo de takes por chunk | ✅ Sí — `toJson`, `fromJson` |
| `ClipStorageService` | Persistencia de archivos de clip | ⚠️ Pre-existente — estructura `vrm_data/projects/{id}/clips/` |
| `ProjectRepository` | Persistencia de `ProjectState` | ⚠️ Pre-existente — esquema `{projectId}.json` |
| `FFmpegStitcherService` | Escritura de `final.mp4` | ⚠️ Pre-existente |

### 2.2 Estructura en Disco (Implementada)

```
{appDocDir}/
  vrm_data/
    projects/
      {projectId}/
        session_data.json    ← Sesión de grabación actual
        clips/
          chunk_0_take_1.mp4 ← Clip aprobado
          chunk_0_take_2.mp4 ← Segundo take (rechazado tras ver)
          chunk_1_take_1.mp4
        final.mp4           ← Video generado por stitching
```

### 2.3 Modelo de Datos: `SessionData`

**JSON Schema (implementado):**
```json
{
  "projectId": "uuid",
  "chunksRecorded": [0, 1, 2],
  "currentChunkIndex": 3,
  "takesPerChunk": {
    "0": { "total": 2, "selectedTake": 2 },
    "1": { "total": 1, "selectedTake": 1 }
  },
  "approvedClips": {
    "0": "/path/to/chunk_0_take_2.mp4",
    "1": "/path/to/chunk_1_take_1.mp4"
  },
  "startedAt": "2026-04-10T...",
  "lastUpdatedAt": "2026-04-10T...",
  "stitchingCompleted": false,
  "finalVideoPath": null,
  "stitchedAt": null
}
```

### 2.4 Punto de Recuperación

Para recuperar una sesión tras cerrar la app:

```dart
// Carga desde disco
final sessionFile = File('.../vrm_data/projects/{id}/session_data.json');
final sessionData = SessionData.fromJson(jsonDecode(await sessionFile.readAsString()));

// Re-instanciar RecordingManager con sesión precargada
final manager = RecordingManager(
  camera: cameraService,
  storage: ClipStorageService(projectId: sessionData.projectId),
  sessionData: sessionData,
);
```

### 2.5 Coherencia con `estado-fase.md`

✅ **CONTRATO VIGENTE:** La implementación cumple exactamente con la estructura de carpetas documentada (`vrm_data/projects/{id}/`).

✅ **`session_data.json`** es el archivo de persistencia de sesión. El `mvp-Definition.md` lo menciona como parte de la estructura de datos.

⚠️ **NOTA:** Existe un esquema dual de persistencia:
- `session_data.json` (este paso) — datos de la sesión de grabación activa.
- `{projectId}.json` vía `ProjectRepository` — `ProjectState` con `input`, `script`, `assets`.

Esto es **coherente**: `ProjectState` es el nivel superior (proyecto completo), `SessionData` es el nivel de la sesión de grabación dentro del proyecto.

---

## 3. Decisiones

### DECISIÓN 1: Sobreescritura completa vs. diffing (NUEVA)

**Decisión:** Se usa sobreescritura completa del archivo `session_data.json` en cada guardado.

**Justificación:** La sesión es un objeto pequeño (< 10 KB). El costo de leer-modificar-escribir supera el beneficio. La atomicidad se delega al OS (Android/iOS proveen atomicidad de `writeAsString` a nivel directorio).

**Alternativa descartada:** Diffing/patching incremental —overengineering para el volumen de datos.

### DECISIÓN 2: Guardado síncrono tras cada operación (NUEVA)

**Decisión:** `_saveSessionDataToDisk()` es `async` pero se awaited inmediatamente (no hay debounce).

**Justificación:** La sesión es el estado más crítico del flujo. Un crash a los 2 segundos de aprobar un clip no puede perder ese clip. El overhead de I/O (~5-20ms en móvil) es aceptable comparado con el riesgo.

**Alternativa descartada:** Debounce de 1-2s — introduce ventana de pérdida de datos.

### DECISIÓN 3: Fallo de persistencia es silencioso (NUEVA)

**Decisión:** Si `_saveSessionDataToDisk()` falla, solo se loguea; el flujo continúa.

**Justificación:** No hay acción correctiva que el usuario pueda tomar en ese momento. Bloquear la UI o mostrar error interrumpe la grabación sin beneficio. El clip ya está guardado en disco por `ClipStorageService`, así que la pérdida es parcial (solo metadatos de sesión).

---

## 4. Criterios de Aceptación

| # | Criterio | Método de Verificación |
|---|----------|------------------------|
| 1 | `session_data.json` existe en `{appDocDir}/vrm_data/projects/{id}/` tras aprobar el primer clip | Inspección de文件系统 |
| 2 | `session_data.json` se actualiza (mtime cambia) tras cada `acceptCurrentClip` | `File.statSync().modified` |
| 3 | La sesión se reconstruye correctamente desde JSON tras kill+restart de app | Re-instanciar `RecordingManager` con `SessionData.fromJson` |
| 4 | `currentChunkIndex` refleja el chunk siguiente al último aprobado | Comparar con valor en memoria previo al reload |
| 5 | `approvedClips` mapea correctamente chunk → ruta absoluta del clip | Verificar que el path existe en filesystem |
| 6 | Si la app muere durante grabación, `stopAndSavePartial` deja el clip en disco | Simular señal de muerte durante `startRecording` |
| 7 | `stitchingCompleted=true` y `finalVideoPath` se persisten tras stitching | Verificar JSON post-stitching |
| 8 | Si `session_data.json` está corrupto, se lanza `PersistenceException` (no crash) | Test con JSON malformado |
| 9 | El espacio mínimo de 500MB se verifica antes de iniciar grabación | Test con mock de `DiskSpace` |
| 10 | Los clips aprobados sobreviven a un ciclo completo de kill+restart | Verificar existencia de archivos `.mp4` post-recovery |

---

## 5. Riesgos

| # | Riesgo | Probabilidad | Impacto | Estrategia de Mitigación |
|---|--------|-------------|---------|------------------------|
| R1 | `session_data.json` corrupto (escritura truncada por crash) | Baja | Alto | `try/catch` en `fromJson` —lanza excepción en vez de crash. El `ProjectRepository.loadProject` detecta `PersistenceException` y puede ofrecer "Nueva sesión". |
| R2 | Colisión de `projectId` entre sesiones (GUID mal generado) | Muy Baja | Alto | `projectId` viene de `uuid` v4. La probabilidad de colisión es negligible. |
| R3 | El directorio `vrm_data` está en almacenamiento limitado (no expandible) | Baja | Medio | Verificación de espacio vía `ClipStorageService.hasFreeSpace()` antes de grabar. Si no hay espacio, se muestra error antes de iniciar. |
| R4 | Concurrencia: dos procesos escriben `session_data.json` simultáneamente | Muy Baja | Medio | La app es single-threaded en Dart. No hay multihilo en el flujo de grabación. |
| R5 | Migración de formato `session_data.json` entre versiones de app | Baja | Medio | No hay versionado de schema aún. En v2 se debe agregar campo `version` al JSON. |

---

## 6. Plan

### Tareas Implementadas (Retroanálisis de lo hecho)

| # | Tarea | Complejidad | Estado |
|---|-------|-------------|--------|
| P1 | Implementar `_saveSessionDataToDisk()` en `RecordingManager` | Baja | ✅ Hecha |
| P2 | Agregar `toJson()`/`fromJson()` a `SessionData` y `ChunkTakeInfo` | Baja | ✅ Hecha |
| P3 | Invocar `_saveSessionDataToDisk()` tras `acceptCurrentClip` | Baja | ✅ Hecha |
| P4 | Invocar `_saveSessionDataToDisk()` tras `startStitching` | Baja | ✅ Hecha |
| P5 | Implementar `stopAndSavePartial()` para ciclo de vida de app | Media | ✅ Hecha |
| P6 | Integrar `ProjectRepository` para gestión de proyectos | Media | ✅ Hecha |
| P7 | Verificar espacio en disco antes de grabar (`hasFreeSpace`) | Baja | ✅ Hecha |

### Validaciones Pendientes de Testing Real

| # | Tarea | Complejidad | Dependencia |
|---|-------|-------------|-------------|
| V1 | Prueba de ciclo kill+restart completo en dispositivo físico | Media | P1-P6 |
| V2 | Prueba de espacio en disco insuficiente (mock DiskSpace) | Baja | P7 |
| V3 | Prueba de corrupción de JSON (archivo truncado) | Baja | P2 |
| V4 | Prueba de stitching re-emprendido tras crash | Media | P4 |

---

## 🔮 Roadmap (NO implementar ahora)

1. **Versionado de schema de sesión:** Agregar campo `schemaVersion: int` a `session_data.json` para migraciones futuras entre versiones de la app.

2. **Persistencia transaccional (atomicidad):** Reemplazar `writeAsString` por rename atómico: escribir a `.tmp`, luego `renameSync` a destino final. Esto previene corrupción por crash durante la escritura.

3. **GC de sesiones huérfanas:** Un servicio que escanee `vrm_data/projects/` y detecte `{projectId}` sin `session_data.json` (sesión incompleta), ofreciendo al usuario recuperarla o eliminarla.

4. **Persistencia de `ProjectState` integrada a sesión:** Actualmente hay dos archivos separados (`session_data.json` y `{projectId}.json`). En v2可以考虑 merge o link explícito.

5. **Respaldo en la nube (iCloud/Google Drive):** Sincronización de `vrm_data/` hacia storage externo para recuperación cross-device. Depende de autenticación y elección de proveedor.

6. **Compresión de `session_data.json`:** Si el número de clips por sesión crece (100+ takes), gzip del JSON reduce I/O. Premature optimization por ahora.

---

## Referencias Cruzadas

- **Implementación analizada:** `lib/features/recording/services/recording_manager.dart` (líneas 209, 215-230, 284)
- **Modelo de sesión:** `lib/features/recording/models/session_data.dart`
- **Repositorio de proyectos:** `lib/core/data/project_repository.dart`
- **Servicio de almacenamiento:** `lib/features/recording/services/clip_storage_service.dart`
- **Estado fase:** `D:\Develop\Personal\vrm\docs\estado-fase.md` — Día 7-8 marcado ✅ completo
- **Plan MVP:** `D:\Develop\Personal\vrm\docs\mvp-Definition.md` — Estructura `vrm_data/` definida en sección 3
