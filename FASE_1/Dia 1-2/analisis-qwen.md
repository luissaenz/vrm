# Análisis Técnico: FASE 1 — Día 1-2 (Grabación Crítica)

> **Autor**: Qwen
> **Fecha**: 2026-04-08
> **Documento fuente**: `docs/mvp-Definition.md`
> **Alcance**: Día 1-2 — Archivos `recording_page.dart`. Instalar invocaciones reales en el `_cameraController` para escribir clips temporales (`chunk_0_take_1.mp4`). Prestar máxima atención a permisos de FileSystem (`path_provider`).

---

## 1. Diseño Funcional

### 1.1 Qué problema resuelve

El problema central es que `recording_page.dart` tiene **UI completa y funcional** (preview de cámara, countdown, teleprompter, voz, menú) pero **cero lógica de escritura de video a disco**. Sin este paso, no existen los archivos `.mp4` que las fases Día 3 (revisión), Día 4-5 (stitch con ffmpeg), Día 6 (export) y Día 7-8 (persistencia) necesitan como insumo. Es el **bloque de domino #1**: si falla, toda la cadena MVP colapsa.

### 1.2 Inputs

| Input | Origen | Formato |
|---|---|---|
| `ScriptAnalysis` | Navegación desde `NewProjectPage` | Objeto con `segments: List<ScriptSegment>` |
| `currentFragmentIndex` | Navegación desde `NewProjectPage` | `int`, default `0` |
| Trigger Start (botón REC) | Usuario en `_buildRecordButton()` | VoidCallback → `_startCountdown()` |
| Trigger Stop (botón REC durante grabación) | Usuario | VoidCallback → `_stopRecording()` |
| `projectId` | **NO DEFINIDO actualmente** — debe venir del flujo de creación de proyecto | `String` |

### 1.3 Outputs

| Output | Destino | Formato |
|---|---|---|
| Archivo `.mp4` por fragmento grabado | `/vrm_data/projects/{projectId}/clips/chunk_{idx}_take_{n}.mp4` | Video H.264 + audio AAC |
| `AssetManifest` actualizado | `ProjectState.assets` (en memoria, persiste Día 7-8) | `{videoId, filePath, status: "raw", metadata: {durationMs, chunkIndex, takeNumber}}` |
| Estado de grabación | `_recordingState` en `RecordingPage` | Transición `idle → countdown → recording → idle` |

### 1.4 Rol dentro del sistema

```
[Onboarding] → [Laboratorio Ideas] → [Generación Guion] → [Recording Page ← ESTE PASO]
                                                                          ↓
                                                                   chunk_X_take_Y.mp4
                                                                          ↓
                                              [Review Día 3] → [Stitch Día 4-5] → [Export Día 6]
```

Este paso es el **productor primario** de materia prima (clips crudos). Sin él, el pipeline no tiene input.

---

## 2. Supuestos y Ambigüedades

### 2.1 Detectados en el código actual

| # | Ambigüedad | Impacto | Pregunta crítica |
|---|---|---|---|
| A1 | **`projectId` no llega a `RecordingPage`** | El constructor actual solo recibe `ScriptAnalysis` y `currentFragmentIndex`. Sin `projectId` no se puede construir la ruta `/projects/{projectId}/clips/`. | ¿De dónde se obtiene el `projectId`? ¿Se crea un proyecto al iniciar la grabación o ya viene del flujo de `NewProjectPage`? |
| A2 | **No hay modelo de `SessionData`** | El MVP define `session_data.json` en la arquitectura de disco, pero no existe la clase Dart correspondiente. | ¿Se necesita persistir sesión en Día 1-2 o se pospone para Día 7-8? |
| A3 | **Política de takes descartados** | Si un usuario graba `chunk_0_take_1.mp4` y luego re-graba el mismo chunk, ¿se borra el take 1 o se conserva como `chunk_0_take_2.mp4`? | ¿Se mantiene historial completo de takes (consume storage) o se sobrescribe el último take válido? |
| A4 | **No hay debounce en botón REC** | `_startCountdown()` y `_stopRecording()` pueden ser llamados múltiples veces en rápida sucesión, causando `CameraController.startVideoRecording()` concurrentes que crashan el native camera stack. | ¿Se acepta un debounce de 500ms硬编码 o se maneja con un flag `isProcessing`? |
| A5 | **Camera swap no implementado** | Existe un botón `_buildGlassButton(icon: Icons.cameraswitch)` con `// TODO: Implement camera switch`. | ¿Se implementa en Día 1-2 o se pospone? |
| A6 | **Resolución y FPS no están explicitados** | Se usa `ResolutionPreset.high` pero no hay garantía de framerate. En iOS esto puede resultar en 60fps, en Android en 30fps, creando inconsistencia para el stitch posterior. | ¿Se fija un preset unificado (`ResolutionPreset.medium` a 30fps) o se acepta la variación del dispositivo? |
| A7 | **Fallback de cámara frontal en PC/web** | El código actual busca cámara frontal y fallback a la primera disponible. En desktop (Windows/Mac) esto puede comportarse distinto. | ¿El MVP soporta desktop o solo mobile (iOS/Android)? |
| A8 | **No existe `permission_handler` en `pubspec.yaml`** | El `camera` plugin maneja permisos internamente en init, pero si el usuario denegó permisos previamente, `_initializeCamera()` falla con excepción nativa sin UX de re-solicitud. | ¿Se agrega `permission_handler` para chequeo proactivo antes de init? |
| A9 | **Storage full no manejado** | No hay verificación de espacio disponible antes de grabar. Un disco lleno causa `FileSystemException` silencioso o corrompe el archivo. | ¿Se implementa chequeo de espacio mínimo (ej. 500MB) antes de iniciar grabación? |
| A10 | **No se define el formato de `metadata` en `AssetManifest`** | El campo `metadata: Map<String, dynamic>?` existe pero no hay schema. Día 4-5 (ffmpeg) necesitará duración, resolución y codec. | ¿Se estandariza ahora el schema de metadata? |

### 2.2 Decisiones que deben tomarse ANTES de implementar

1. **A1 — `projectId`**: Propongo agregar `projectId` como parámetro requerido del constructor de `RecordingPage`. Si el flujo actual no lo tiene, el caller debe crearlo (vía `uuid`) antes de navegar.
2. **A3 — Política de takes**: Conservar todos los takes (`chunk_0_take_1.mp4`, `chunk_0_take_2.mp4`, ...). El último take válido se marca en metadata. Limpieza se pospone para optimización futura.
3. **A4 — Debounce**: Flag `bool _isRecordingProcessing` que bloquea start/stop mientras una operación está en curso.
4. **A6 — Resolución**: Fijar `ResolutionPreset.high` pero agregar `videoBitrate` y `fps` explícitos al inicializar. Target: 1080p @ 30fps.
5. **A7 — Desktop scope**: **NO soportado en MVP**. La página debe mostrar un mensaje "Mobile only" si `Platform.isWindows || Platform.isMacOS`.
6. **A8 — Permisos**: Sí, agregar `permission_handler: ^11.3.0` para chequeo proactivo con UX amigable.
7. **A10 — Metadata schema**:
   ```json
   {
     "chunkIndex": 0,
     "takeNumber": 1,
     "durationMs": 4520,
     "resolution": "1080x1920",
     "fps": 30,
     "hasAudio": true,
     "createdAt": "2026-04-08T10:30:00.000Z"
   }
   ```

---

## 3. Diseño Técnico

### 3.1 Arquitectura Sugerida

Se desacopla la UI del hardware mediante **3 servicios nuevos**, siguiendo el patrón Repository/Service ya existente en el proyecto (`ProjectRepository`).

```
┌─────────────────────────────────────────────────────┐
│                 RecordingPage (UI)                  │
│   - Countdown, Teleprompter, Voice, Menu, etc.     │
│   - NO toca CameraController directamente          │
│   - NO escribe en FileSystem                        │
└─────────┬───────────────────────────┬───────────────┘
          │ llama                     │ escucha
          ▼                           ▼
┌──────────────────┐       ┌──────────────────────┐
│ RecordingManager │       │ PermissionService     │
│ (nuevo archivo)  │       │ (nuevo archivo)       │
│ - startRecording │       │ - checkCameraPerm     │
│ - stopRecording  │       │ - checkMicPerm        │
│ - switchCamera   │       │ - requestAll          │
│ - isRecording    │       └──────────────────────┘
└────────┬─────────┘
         │ coordina
         ▼
┌──────────────────┐       ┌──────────────────────┐
│ CameraService     │       │ ClipStorageService   │
│ (nuevo archivo)   │       │ (nuevo archivo)       │
│ - initController  │       │ - ensureClipDir       │
│ - startRecording  │       │ - saveClip            │
│ - stopRecording   │◄──────│ - getNextTakeNumber   │
│ - switchCamera    │  XFile│ - getClipPath         │
│ - dispose         │       │ - cleanupTemp         │
└──────────────────┘       └──────────────────────┘
```

### 3.2 Componentes — Detalle de cada archivo nuevo

#### 3.2.1 `lib/features/recording/services/permission_service.dart`

```dart
class PermissionService {
  /// Checks camera and microphone permissions.
  /// Returns true if both are granted.
  Future<bool> checkPermissions();

  /// Requests camera and microphone permissions.
  /// Returns true if both are granted after request.
  Future<bool> requestPermissions();

  /// Shows a dialog explaining why permissions are needed
  /// and navigates to app settings if user denies again.
  Future<void> handleDeniedPermission(BuildContext context);
}
```

**Dependencias**: `permission_handler: ^11.3.0`

#### 3.2.2 `lib/features/recording/services/camera_service.dart`

```dart
class CameraService {
  CameraController? _controller;
  CameraLensDirection _currentDirection = CameraLensDirection.front;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isRecording => _controller?.value.isRecordingVideo ?? false;

  /// Initializes the camera with fixed settings:
  /// - ResolutionPreset.high (1080p target)
  /// - enableAudio: true
  /// - imageFormatGroup: jpeg
  Future<void> initialize({CameraLensDirection direction});

  /// Starts video recording. Returns immediately; the recording
  /// runs in the native background thread.
  Future<void> startRecording();

  /// Stops recording and returns the XFile with the recorded video.
  /// Throws if not recording.
  Future<XFile> stopRecording();

  /// Switches between front and back camera.
  Future<void> switchCamera();

  /// Disposes the controller. Must be called to prevent memory leaks.
  Future<void> dispose();

  /// Gets the underlying CameraController for CameraPreview widget.
  CameraController? get controller => _controller;
}
```

**Dependencias**: `camera: ^0.11.0+4` (ya en pubspec)

**Notas técnicas críticas**:
- `startVideoRecording()` del plugin `camera` devuelve `Future<void>`, no el archivo. El archivo se obtiene al llamar `stopVideoRecording()` que devuelve `XFile`.
- En Android, el archivo se escribe en el cache directory nativo. **NO es persistente** — debe copiarse inmediatamente.
- En iOS, el comportamiento es similar pero con diferencias en el path temporal. Usar `XFile.path` y `File.copy()`.

#### 3.2.3 `lib/features/recording/services/clip_storage_service.dart`

```dart
class ClipStorageService {
  final String projectId;

  ClipStorageService({required this.projectId});

  /// Creates /vrm_data/projects/{projectId}/clips/ if it doesn't exist.
  Future<Directory> ensureClipsDirectory();

  /// Generates the canonical path for a clip:
  /// .../clips/chunk_{chunkIndex}_take_{takeNumber}.mp4
  String clipPath({required int chunkIndex, required int takeNumber});

  /// Returns the next take number for a given chunk by scanning
  /// existing files in the clips directory.
  Future<int> getNextTakeNumber(int chunkIndex);

  /// Copies a recorded XFile from camera cache to the clips directory.
  /// Returns the absolute path of the saved clip.
  Future<String> saveClip({
    required XFile sourceFile,
    required int chunkIndex,
    required int takeNumber,
    required Map<String, dynamic> metadata,
  });

  /// Deletes a specific clip file.
  Future<void> deleteClip({required int chunkIndex, required int takeNumber});

  /// Cleans up all temporary files left by the camera plugin.
  Future<void> cleanupTemp();
}
```

**Dependencias**: `path_provider: ^2.1.3`, `path: ^1.9.0` (agregar a pubspec), `dart:io`

### 3.2.4 `lib/features/recording/services/recording_manager.dart`

```dart
class RecordingManager {
  final CameraService _camera;
  final ClipStorageService _storage;

  bool _isProcessing = false; // Debounce flag

  /// Full recording cycle: start → (user records) → stop → save.
  /// Returns the path to the saved clip.
  Future<String> recordClip({
    required int chunkIndex,
  });

  /// Switches the active camera.
  Future<void> switchCamera();

  bool get isProcessing => _isProcessing;
}
```

Este service orquesta `CameraService` + `ClipStorageService` y maneja el debounce.

### 3.3 Modelo de datos — Session Recording State

Se necesita una estructura para trackear el estado de grabación por chunk. Se agrega a `ProjectState` o se maneja como archivo separado.

**Propuesta: archivo `session_data.json`** (como define la arquitectura del MVP):

```
/vrm_data/projects/{projectId}/session_data.json
```

```json
{
  "projectId": "abc-123",
  "chunksRecorded": [0, 1],
  "currentChunk": 2,
  "takesPerChunk": {
    "0": {"total": 3, "selectedTake": 2},
    "1": {"total": 1, "selectedTake": 1}
  },
  "startedAt": "2026-04-08T10:00:00.000Z",
  "lastUpdatedAt": "2026-04-08T10:30:00.000Z"
}
```

**Clase Dart** — `lib/features/recording/models/session_data.dart`:

```dart
class ChunkTakeInfo {
  final int total;
  final int selectedTake;

  ChunkTakeInfo({required this.total, required this.selectedTake});

  factory ChunkTakeInfo.fromJson(Map<String, dynamic> json) => ChunkTakeInfo(
    total: json['total'] as int,
    selectedTake: json['selectedTake'] as int,
  );

  Map<String, dynamic> toJson() => {'total': total, 'selectedTake': selectedTake};
}

class SessionData {
  final String projectId;
  final List<int> chunksRecorded;
  final int currentChunk;
  final Map<int, ChunkTakeInfo> takesPerChunk;
  final DateTime startedAt;
  final DateTime lastUpdatedAt;

  SessionData({
    required this.projectId,
    this.chunksRecorded = const [],
    this.currentChunk = 0,
    this.takesPerChunk = const {},
    required this.startedAt,
    required this.lastUpdatedAt,
  });

  factory SessionData.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }

  SessionData copyWith({ ... });
}
```

**IMPORTANTE**: La persistencia real de `session_data.json` se implementa en Día 7-8. Para Día 1-2, este objeto vive **solo en memoria** (`_sessionData` en `RecordingPage` o `RecordingManager`). No se escribe a disco todavía.

### 3.4 Flujo completo paso a paso (Pipeline de Grabación)

```
1. INIT PHASE
   ├─ PermissionService.checkPermissions()
   │   ├─ Granted → proceed
   │   └─ Denied → PermissionService.requestPermissions()
   │       ├─ Granted → proceed
   │       └─ Permanently denied → Show dialog → Navigate to settings
   ├─ CameraService.initialize(direction: front)
   ├─ ClipStorageService.ensureClipsDirectory()
   └─ _sessionData = SessionData(projectId: widget.projectId, ...)

2. COUNTDOWN PHASE (user presses REC)
   ├─ _startCountdown() → 3, 2, 1 rings
   └─ _startActualRecording()

3. RECORDING PHASE
   ├─ RecordingManager.recordClip(chunkIndex: _activeFragmentIndex)
   │   ├─ _isProcessing = true  (debounce ON)
   │   ├─ CameraService.startRecording()
   │   │   └─ _cameraController.startVideoRecording()
   │   ├─ setState(() => _recordingState = RecordingState.recording)
   │   ├─ [User speaks the fragment — UI muestra teleprompter]
   │   └─ User presses STOP
   │       ├─ CameraService.stopRecording() → returns XFile
   │       ├─ ClipStorageService.getNextTakeNumber(chunkIndex) → take N
   │       ├─ ClipStorageService.saveClip(XFile, chunkIndex, take N, metadata)
   │       │   ├─ File.copy(XFile.path, clipPath)
   │       │   ├─ File(XFile.path).delete()  // Cleanup camera cache
   │       │   └─ Returns absolutePath
   │       ├─ _sessionData updated (increment take count)
   │       ├─ _isProcessing = false  (debounce OFF)
   │       └─ setState(() => _recordingState = RecordingState.idle)
   └─ [User sees confirmation: "Clip saved — 4.2s"]

4. EXIT PHASE (user leaves page)
   ├─ CameraService.dispose()  ← CRÍTICO: prevenir memory leak
   ├─ ClipStorageService.cleanupTemp()
   └─ VoiceCommandService.stopService()
```

### 3.5 Edge Cases y Manejo de Errores

| Escenario | Comportamiento esperado |
|---|---|
| **App goes to background during recording** | `WidgetsBindingObserver.didChangeAppLifecycleState` → `AppLifecycleState.paused` → `CameraService.stopRecording()` → save whatever was recorded as `chunk_X_take_N.mp4` (parcial pero válido) → update session |
| **Incoming call during recording** | Igual que background — el OS pausa la actividad, se captura y se guarda |
| **Storage full** | Antes de grabar, verificar `Directory.freeSpace()` (vía `statfs` en Android o `NSURLVolumeAvailableCapacityKey` en iOS). Si < 500MB, mostrar snackbar: "Almacenamiento insuficiente. Libera espacio." |
| **Camera init fails** | Catch en `_initializeCamera()` → mostrar `AlertDialog`: "No se pudo acceder a la cámara. Verifica permisos." con botón "Reintentar" y "Ir a configuración" |
| **startVideoRecording throws** | Catch → `_isProcessing = false` → mostrar error UI → no cambiar estado a `recording` |
| **stopVideoRecording throws** | Catch → `_isProcessing = false` → intentar `stopVideoRecording()` una segunda vez → si falla de nuevo, mostrar "Error al guardar el clip. Intenta de nuevo." |
| **File.copy fails (cross-device)** | Usar `File.copy()` (no `rename()`). Si falla, leer bytes del source y escribir en destination manualmente: `await dest.writeAsBytes(await source.readAsBytes())` |
| **User navigates away mid-recording** | `dispose()` del StatefulWidget → `CameraService.stopRecording()` en bloque → dispose → salvar clip |
| **Duplicate start calls (rapid tap)** | `_isProcessing` flag previene ejecución doble. El segundo tap es ignorado silenciosamente. |

### 3.6 Integraciones externas

| Integración | Tipo | Estado |
|---|---|---|
| `camera` plugin | Hardware | ✅ Ya en pubspec (`^0.11.0+4`) |
| `path_provider` | FileSystem | ✅ Ya en pubspec (`^2.1.3`) |
| `permission_handler` | Permisos | ❌ **Agregar** (`^11.3.0`) |
| `path` | Path manipulation | ❌ **Agregar** (`^1.9.0`) |
| `video_player` | Playback (review Día 3) | ✅ Ya en pubspec (`^2.9.1`) — NO usar en Día 1-2 |

---

## 4. Decisiones

### 4.1 Decisiones Tecnológicas

| Decisión | Opción elegida | Justificación |
|---|---|---|
| **Camera plugin** | `camera: ^0.11.0+4` (oficial) | Mantenido por Flutter team, soporta iOS + Android + desktop. Alternativas como `camerawesome` o `awesome_camera` tienen menos soporte desktop y APIs inestables en 2024-2025. |
| **Permission handling** | `permission_handler: ^11.3.0` | Estándar de facto en Flutter. El plugin `camera` pide permisos en init pero no ofrece feedback granular. `permission_handler` permite distinguir `denied` vs `permanentlyDenied` y abrir settings directamente. |
| **Path manipulation** | `path: ^1.9.0` | Necesario para construir paths cross-platform sin errores de slashes. `path_provider` solo da el directorio base; `path` da `join()`, `extension()`, etc. |
| **File copy strategy** | `File.copy()` → fallback `writeAsBytes(readAsBytes())` | `File.rename()` falla con `EXDEV` (cross-device link) cuando el source está en cache temporal y el destination en documents. `copy()` es seguro. El fallback con bytes es el último recurso si `copy()` también falla. |
| **State management** | `setState` (existing) | Para Día 1-2, no se necesita Riverpod/Bloc. La página ya usa `setState` para todos sus estados. Agregar un state manager ahora es over-engineering. |
| **Architecture pattern** | Service layer (no Repository yet) | Los servicios (`CameraService`, `ClipStorageService`, `PermissionService`) son stateless/singleton. `ProjectRepository` ya existe para datos JSON. No crear un `ClipRepository` hasta Día 7-8 cuando se necesita query/list. |

### 4.2 Decisiones de Diseño

| Decisión | Valor | Razonamiento |
|---|---|---|
| **Resolución** | `ResolutionPreset.high` (1080p target) | Balance entre calidad y tamaño de archivo. `veryHigh` (4K) genera archivos enormes que afectan stitching. `medium` (720p) se ve mal en pantallas modernas. |
| **Frame rate** | 30fps (depende del device, no se fuerza) | El plugin `camera` no expone FPS directamente en esta versión. 30fps es el default en la mayoría de dispositivos con `high`. Se documenta como variable. |
| **Audio** | `enableAudio: true` | Obligatorio para el producto. Los clips sin audio no son útiles. |
| **Cámara default** | Frontal (`CameraLensDirection.front`) | Es una app de teleprompter para creadores de contenido — graban mirando la cámara frontal. |
| **Take numbering** | Incremental, no reutiliza números | `chunk_0_take_1`, `chunk_0_take_2`, ... No se sobrescribe. Facilita debugging y recovery. |
| **Metadata per clip** | Inline en `session_data.json` (memoria) | No se crea un archivo JSON separado por clip. Se centraliza en `session_data.json` que se persiste en Día 7-8. |

---

## 5. Riesgos

### 5.1 Técnicos

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **Memory leak por `CameraController` no dispuesto** | Media | 🔴 Crítico | `dispose()` obligatorio en el `dispose()` del StatefulWidget. Agregar `WidgetsBindingObserver` para manejar `paused`/`resumed`. |
| **`startVideoRecording` concurrente crash** | Alta si no hay debounce | 🔴 Crítico | Flag `_isProcessing` + try/catch en toda llamada al controller. |
| **`XFile` se borra antes de copiar** | Baja (GC nativo) | 🔴 Crítico | Copiar inmediatamente tras `stopRecording()`. No almacenar referencias al XFile más del scope de la función. |
| **Android 13+ scoped storage** | Media | 🟡 Medio | Usar `path_provider` que ya abstrae esto. No escribir en paths hardcoded como `/sdcard/`. |
| **iOS background recording termination** | Baja | 🟡 Medio | `didChangeAppLifecycleState` → stop + save. El clip parcial es válido. |
| **Thermal throttling en grabaciones largas** | Baja en MVP (clips de ~10-30s) | 🟢 Bajo | No aplica para clips cortos. Monitorear en Día 16-17 (performance). |

### 5.2 Operativos

| Riesgo | Impacto | Mitigación |
|---|---|---|---|
| **Testing solo en emulador** | Los emuladores Android no soportan `camera` plugin correctamente. Crashes en producción garantizados. | **Testear en dispositivo físico desde Día 1.** Mínimo 1 Android real y 1 iOS real. |
| **Permisos denegados por usuario** | App no graba,用户体验 destruido. | Dialog proactivo con explicación + deep link a settings. |
| **Disco lleno** | Clip corrupto o crash. | Check free space antes de grabar. Mostrar alerta si < 500MB. |

### 5.3 Escalabilidad

| Problema futuro | Cuándo aparece | Preparación ahora |
|---|---|---|
| **Miles de clips acumulados** | Cuando un usuario tiene 50+ proyectos | La estructura `/clips/` plana por proyecto funciona hasta ~500 archivos. Más allá, necesitar `/clips/{date}/`. No urgente para MVP. |
| **Clips de >2 minutos** | Si el guion tiene segmentos largos | `ResolutionPreset.high` genera ~150MB/minuto. Considerar `medium` si el feedback indica storage issues. |
| **Concurrent recording + UI rendering** | Teleprompter pesado + recording | El plugin `camera` usa threads nativos separados. No debería afectar. Monitorear en Día 16-17. |

### 5.4 Costos

| Item | Costo | Nota |
|---|---|---|
| `camera` plugin | Gratis (oficial Flutter) | — |
| `permission_handler` | Gratis (open source) | — |
| `path` | Gratis (oficial Dart) | — |
| Storage en dispositivo | N/A (local) | El usuario pone el hardware. Sin costos cloud. |
| Testing en dispositivos físicos | Costo de hardware | Se necesitan al menos 1 Android + 1 iOS reales. |

---

## 6. Plan de Implementación

### 6.1 Backlog de Tareas (orden recomendado)

#### Tarea 1: Agregar dependencias a `pubspec.yaml`
- [ ] Agregar `permission_handler: ^11.3.0`
- [ ] Agregar `path: ^1.9.0`
- [ ] Ejecutar `flutter pub get`
- **Estimación**: 5 min
- **Dependencia**: Ninguna

#### Tarea 2: Crear `PermissionService`
- **Archivo**: `lib/features/recording/services/permission_service.dart`
- [ ] Implementar `checkPermissions()` → `PermissionStatus` para camera + mic
- [ ] Implementar `requestPermissions()` → request si están denied
- [ ] Implementar `handleDeniedPermission(context)` → dialog + open settings
- [ ] Unit test: mock de `Permission` (usar `permission_handler` con test doubles)
- **Estimación**: 30 min
- **Dependencia**: Tarea 1

#### Tarea 3: Crear `ClipStorageService`
- **Archivo**: `lib/features/recording/services/clip_storage_service.dart`
- [ ] Constructor que recibe `projectId`
- [ ] `ensureClipsDirectory()` → crea `/vrm_data/projects/{projectId}/clips/`
- [ ] `clipPath(chunkIndex, takeNumber)` → retorna path canonical
- [ ] `getNextTakeNumber(chunkIndex)` → escanea directorio, retorna max(take) + 1
- [ ] `saveClip(sourceFile, chunkIndex, takeNumber, metadata)` → copia + cleanup
- [ ] `cleanupTemp()` → borra archivos huérfanos del camera cache
- [ ] Unit test: mock de `Directory` y `File` (usar `FileSystem` interface de `file` package o test con temp directory)
- **Estimación**: 45 min
- **Dependencia**: Tarea 1

#### Tarea 4: Crear `CameraService`
- **Archivo**: `lib/features/recording/services/camera_service.dart`
- [ ] `initialize({direction})` → crea `CameraController` con settings fijos
- [ ] `startRecording()` → envuelve `startVideoRecording()` con try/catch
- [ ] `stopRecording()` → envuelve `stopVideoRecording()` → retorna `XFile`
- [ ] `switchCamera()` → disposes actual, re-inicializa con otra dirección
- [ ] `dispose()` → null-safe dispose
- [ ] Getter `controller` → expone para `CameraPreview` widget
- [ ] **No** unit test (el plugin camera no es mockeable fácilmente sin `camera_platform_interface`). Se valida con integration test.
- **Estimación**: 45 min
- **Dependencia**: Tarea 1

#### Tarea 5: Crear `RecordingManager`
- **Archivo**: `lib/features/recording/services/recording_manager.dart`
- [ ] Constructor que recibe `CameraService` + `ClipStorageService`
- [ ] `recordClip(chunkIndex)` → orquesta start → stop → save → retorna path
- [ ] `_isProcessing` debounce flag
- [ ] `switchCamera()` → delega a CameraService
- [ ] Unit test: mock de CameraService y ClipStorageService
- **Estimación**: 30 min
- **Dependencia**: Tareas 2, 3, 4

#### Tarea 6: Crear `SessionData` model
- **Archivo**: `lib/features/recording/models/session_data.dart`
- [ ] Clase `ChunkTakeInfo`
- [ ] Clase `SessionData` con `fromJson`/`toJson`/`copyWith`
- [ ] Unit test: serialización round-trip
- **Estimación**: 20 min
- **Dependencia**: Ninguna

#### Tarea 7: Integrar en `RecordingPage`
- **Archivo**: `lib/features/recording/recording_page.dart`
- [ ] Agregar `projectId` como parámetro del constructor
- [ ] Agregar imports de los 4 servicios nuevos
- [ ] En `initState`:
  - [ ] Llamar `PermissionService.requestPermissions()` antes de `_initializeCamera()`
  - [ ] Instanciar `CameraService`, `ClipStorageService`, `RecordingManager`
  - [ ] Instanciar `_sessionData` en memoria
  - [ ] **Eliminar** `_initializeCamera()` actual (reemplazar con `CameraService.initialize()`)
- [ ] En `_startActualRecording()`:
  - [ ] Reemplazar TODO con `RecordingManager.recordClip(chunkIndex: _activeFragmentIndex)`
  - [ ] Actualizar `_sessionData` con el resultado
  - [ ] Manejar errores con try/catch
- [ ] En `_stopRecording()`:
  - [ ] El stop es manejado internamente por `recordClip()` (que es un bloque start→stop)
  - [ ] O alternativamente: separar en `startRecording()` y `stopRecording()` llamados independientes desde UI
  - [ ] **Decisión**: separar para mantener el control de cuándo el usuario para
- [ ] En `_buildRecordButton()`:
  - [ ] Cambiar behavior: si idle → start; si recording → stop
  - [ ] Agregar debounce visual (button disabled mientras `_isProcessing`)
- [ ] En `dispose()`:
  - [ ] Reemplazar `_cameraController?.dispose()` con `CameraService.dispose()`
- [ ] Agregar `WidgetsBindingObserver` para `didChangeAppLifecycleState`:
  - [ ] `AppLifecycleState.paused` → stop recording + save partial clip
- [ ] Agregar camera switch en el botón existente
- **Estimación**: 2 horas
- **Dependencia**: Tareas 2, 3, 4, 5, 6

#### Tarea 8: Agregar manejo de storage full
- **Archivo**: `lib/features/recording/services/clip_storage_service.dart`
- [ ] Método `checkFreeSpace()` → retorna MB disponibles
- [ ] En `RecordingPage`, antes de iniciar grabación, verificar > 500MB
- [ ] Mostrar snackbar/alerta si no hay espacio
- **Estimación**: 20 min
- **Dependencia**: Tarea 3

#### Tarea 9: Agregar UX de feedback de grabación
- **Archivo**: `lib/features/recording/recording_page.dart`
- [ ] Mostrar duración del clip guardado ("Clip guardado — 4.2s")
- [ ] Indicador visual de "Grabando..." (ya existe el estado `recording` con el badge rojo)
- [ ] SnackBar de error si algo falla
- **Estimación**: 20 min
- **Dependencia**: Tarea 7

#### Tarea 10: Test en dispositivo físico
- [ ] Deploy a Android físico
- [ ] Test: permisos → grabar 3 fragmentos → verificar archivos en disco
- [ ] Test: app a background mid-recording → verificar clip parcial
- [ ] Test: switch de cámara
- [ ] Test: 10 start/stop rápidos (debounce)
- [ ] Deploy a iOS físico (si disponible)
- [ ] Repetir tests
- **Estimación**: 1 hora
- **Dependencia**: Tareas 7, 8, 9

### 6.2 Orden de Desarrollo y Dependencias

```
T1 (deps)
  └─► T2 (PermissionService)
  └─► T3 (ClipStorageService)
  └─► T4 (CameraService)
        └─► T5 (RecordingManager)
  └─► T6 (SessionData model)
        └─► T7 (Integración RecordingPage) ──► T8 (Storage check)
                                                    └─► T9 (UX feedback)
                                                          └─► T10 (Device test)
```

**Ruta crítica**: T1 → T4 → T7 → T10 = mínimo viable
**Paralelizable**: T2, T3, T6 pueden desarrollarse en paralelo a T4

### 6.3 Definition of Done para Día 1-2

- [ ] Usuario puede presionar REC → countdown → grabar un fragmento → presionar STOP → archivo `.mp4` existe en `/vrm_data/projects/{id}/clips/chunk_0_take_1.mp4`
- [ ] El archivo se reproduce correctamente en un reproductor externo (VLC)
- [ ] Un segundo take del mismo chunk genera `chunk_0_take_2.mp4` (no sobrescribe)
- [ ] Permisos se piden correctamente y se maneja denegación con UX
- [ ] App a background durante grabación salva el clip parcial sin crash
- [ ] `dispose()` limpia todos los recursos de cámara
- [ ] Tests pasan en al menos 1 dispositivo físico Android

---

## 7. Métricas de Éxito

### 7.1 KPIs Técnicos

| Métrica | Target | Cómo medir |
|---|---|---|
| **Clip válido** | 100% de grabaciones producen `.mp4` reproducible | Verificar con `video_player` en Día 3 o VLC externo |
| **Latencia stop→save** | < 1.5 segundos | Stopwatch entre `stopRecording()` call y `saveClip()` complete |
| **Memory leak** | 0 crashes por OOM en 20 ciclos start/stop | Android: `adb shell dumpsys meminfo`. iOS: Xcode Instruments |
| **Permiso recovery** | Usuario que deniega puede re-activar desde settings | Test manual: denegar → abrir settings → permitir → reintentar |
| **App lifecycle handling** | 0 crashes al ir a background durante grabación | Test manual con llamada entrante o botón home |

### 7.2 KPIs de Producto

| Métrica | Target | Cómo medir |
|---|---|---|
| **Flujo end-to-end** | Usuario puede grabar 3 fragmentos consecutivos sin error | Test de usabilidad con 3 usuarios |
| **Tasa de éxito de grabación** | > 95% de intentos producen clip válido | Log de cada start/stop con resultado (éxito/fallo) |
| **Storage efficiency** | Clips de 10 segundos < 20MB cada uno | Medir tamaño de archivos generados |

---

## 8. Estrategia de Testing

### 8.1 Unit Tests

| Archivo de Test | Qué prueba |
|---|---|
| `test/features/recording/services/permission_service_test.dart` | `checkPermissions` retorna bool correcto con mocks de Permission |
| `test/features/recording/services/clip_storage_service_test.dart` | `ensureClipsDirectory` crea directorio, `clipPath` genera formato correcto, `getNextTakeNumber` incrementa, `saveClip` copia archivo y limpia source |
| `test/features/recording/models/session_data_test.dart` | `fromJson`/`toJson` round-trip, `copyWith` funciona |
| `test/features/recording/services/recording_manager_test.dart` | `recordClip` llama start→stop→save en orden, debounce bloquea llamadas concurrentes |

**Test crítico — Clip path naming**:
```dart
test('getNextTakeNumber returns incrementing values', () async {
  // Setup: create chunk_0_take_1.mp4 and chunk_0_take_2.mp4
  final service = ClipStorageService(projectId: 'test-1');
  await service.ensureClipsDirectory();
  // Create fake clip files
  File(service.clipPath(chunkIndex: 0, takeNumber: 1)).createSync();
  File(service.clipPath(chunkIndex: 0, takeNumber: 2)).createSync();

  final next = await service.getNextTakeNumber(0);
  expect(next, 3);
});
```

### 8.2 Integration Tests (obligatorio en hardware físico)

| Test | Procedimiento | Resultado esperado |
|---|---|---|
| **Happy path** | Abrir app → crear proyecto → navegar a recording → REC → esperar 5s → STOP | Archivo `.mp4` existe y es reproducible |
| **Multiple fragments** | Grabar fragmento 0 → siguiente → grabar fragmento 1 → STOP | `chunk_0_take_1.mp4` y `chunk_1_take_1.mp4` existen |
| **Multiple takes** | Grabar fragmento 0 → STOP → grabar fragmento 0 de nuevo → STOP | `chunk_0_take_1.mp4` y `chunk_0_take_2.mp4` existen |
| **Debounce** | Tap REC 5 veces rápidas | Solo 1 grabación inicia |
| **Background** | Grabar → presionar home → volver a app | Clip parcial existe, app no crashea |
| **Permission denied** | Denegar cámara en settings → abrir app | Dialog con "Ir a configuración" |
| **Storage full** | Simular disco lleno (difícil en físico) | Alerta "Almacenamiento insuficiente" |
| **Switch camera** | Tap switch durante idle | Preview cambia a cámara trasera |
| **Dispose clean** | Grabar → navegar atrás → volver a grabar | No hay memory leak, camera re-inicializa limpio |

### 8.3 Casos Críticos a Validar

1. **El archivo `.mp4` tiene audio**: Verificar que el stream de audio existe en el archivo final (el plugin `camera` con `enableAudio: true` debería incluirlo).
2. **El archivo es válido tras app kill**: Forzar cierre de app durante grabación (`kill -9` en Android). Verificar si el archivo parcial es reproducible o está corrupto.
3. **El path no contiene caracteres inválidos**: Verificar que `projectId` no contenga `/`, `\`, o caracteres que rompan paths de filesystem.

---

## 9. Optimización y Escalabilidad Futura

### 9.1 Problemas que aparecerán al escalar

| Problema | Cuándo | Solución futura |
|---|---|---|
| **Storage explosion con muchos takes** | Usuario re-graba un chunk 10+ veces | Implementar política de "max 5 takes por chunk" + auto-delete takes antiguos |
| **Stitching lento con clips grandes** | Día 4-5 con ffmpeg, clips de 1080p | Pre-procesar: bajar resolución a 720p antes de stitch si el dispositivo es de gama baja |
| **UI lag con muchos archivos en /clips/** | 100+ clips en un proyecto | Paginar la lectura del directorio o usar un índice JSON en lugar de `listSync()` |
| **Memory pressure en recording** | Grabaciones de >60 segundos | Implementar chunking automático del video cada 30s durante recording |
| **Thermal throttling** | Sesiones de grabación de >10 minutos | Throttle de framerate (bajar a 24fps) o pausa obligatoria entre clips |

### 9.2 Cómo preparar el diseño ahora

1. **Interface-based design**: `CameraService`, `ClipStorageService` y `RecordingManager` ya están diseñados como clases con interfaces claras. Esto permite:
   - Reemplazar `CameraService` por una implementación con `camerawesome` si el plugin oficial presenta problemas.
   - Swap `ClipStorageService` por una versión cloud (subir clips a S3) sin cambiar la UI.

2. **Metadata extensible**: El schema de metadata en `session_data.json` tiene campos que serán útiles para Día 4-5 (ffmpeg necesita duración y resolución). Incluirlos ahora evita migración después.

3. **Take numbering incremental**: No sobrescribir takes permite:
   - Recovery: si el usuario quiere el take 1 después de grabar el take 3, el archivo sigue ahí.
   - A/B testing: comparar takes sin perder el original.
   - Costo: storage adicional es manejable (un take de 10s a 1080p = ~15MB).

4. **Debounce centralizado**: El flag `_isProcessing` en `RecordingManager` es el patrón que se extenderá a otras operaciones async (stitching, export) para prevenir race conditions.

5. **`WidgetsBindingObserver` para lifecycle**: Implementarlo ahora para recording protege contra el edge case más común de crash en producción. El mismo patrón se reutilizará para el teleprompter y cualquier proceso de fondo.

6. **No over-optimize ahora**:
   - NO implementar compresión de clips (se hace en Día 4-5 con ffmpeg).
   - NO implementar cleanup automático de takes antiguos (se hace cuando haya data de uso real).
   - NO implementar índice JSON de clips (se hace cuando `listSync()` sea lento).

---

## 10. Resumen Ejecutivo para CTO

| Dimensión | Estado |
|---|---|
| **Alcance** | Día 1-2: Grabación real de video + escritura a disco. NO incluye review (Día 3), stitch (Día 4-5), ni persistencia JSON (Día 7-8). |
| **Archivos nuevos** | 4 servicios + 1 model + modificaciones a `recording_page.dart` + 2 deps en pubspec |
| **Líneas estimadas** | ~400-500 líneas nuevas |
| **Riesgo principal** | Camera plugin crashes en producción sin testing en hardware físico |
| **Bloqueante** | Definir de dónde viene `projectId` al `RecordingPage` (A1) |
| **No negotiable** | Test en dispositivo físico Android antes de considerar "done" |
| **Posponible** | Camera swap, storage check avanzado, persistencia de session_data.json |

**Decisión requerida del equipo**: Resolver ambigüedad A1 (`projectId` origin) antes de iniciar Tarea 7. Todo lo demás es ejecutable.
