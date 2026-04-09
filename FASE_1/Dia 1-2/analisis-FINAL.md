# Análisis Final Unificado: FASE 1 — Día 1-2 (Grabación Crítica)

> **Consolidado por**: Qwen (Principal Engineer)
> **Fecha**: 2026-04-08
> **Fuentes**: `analisis-antigravity.md`, `analisis-kilo.md`, `analisis-qwen.md`
> **Destino**: `FASE1/Dia1-2/analisis-FINAL.md`

---

## 0. Evaluación Comparativa de los Análisis

### 0.1 Similitudes

Los tres análisis coinciden en los puntos estructurales fundamentales:

| Punto | Coincidencia |
|---|---|
| **Problema central** | `recording_page.dart` tiene UI completa pero cero escritura de video. Los métodos `_startActualRecording()` y `_stopRecording()` son TODOs. |
| **Naming de archivos** | Todos proponen `chunk_{idx}_take_{n}.mp4` en `/vrm_data/projects/{projectId}/clips/`. |
| **Necesidad de `permission_handler`** | Los tres lo identifican como dependencia faltante obligatoria. |
| **Debounce en botón REC** | Los tres detectan el riesgo de llamadas concurrentes a `startVideoRecording()`. |
| **App lifecycle (background)** | Los tres exigen capturar `paused` → stop + save clip parcial. |
| **File.copy() sobre rename()** | Antigravity y Qwen lo explicitan; Kilo lo implica. Todos contra `rename()` por EXDEV. |
| **Testing en dispositivo físico** | Los tres enfatizan: emulador no es suficiente. |

### 0.2 Contradicciones y Resolución

| Contradicción | Antigravity | Kilo | Qwen | Decisión Final | Justificación |
|---|---|---|---|---|---|
| **Versión `permission_handler`** | `^11.0.0` | `^6.0.0` | `^11.3.0` | **`^11.3.0`** | La v6 es obsoleta (2021). La API cambió significativamente entre v6 y v11. Usar v6 rompería compatibilidad con Android 13+/iOS 16+. |
| **Versión `camera`** | `^0.10.x` | `^0.11.0+4` | `^0.11.0+4` | **`^0.11.0+4`** (la que ya está en pubspec) | La v0.11 incluye mejoras de estabilidad y soporte de Android 14. No hay razón para bajar a 0.10.x. |
| **Persistencia de `session_data.json`** | No menciona persistencia, solo memoria | Lo incluye como output del paso con JSON completo | En memoria para Día 1-2, persistencia en Día 7-8 | **Solo en memoria para Día 1-2** | El MVP planifica Día 7-8 para persistencia. Escribir JSON ahora duplica esfuerzo y no aporta al objetivo de Día 1-2 (tener clips en disco). |
| **Auto-checkpoint cada 10s** | No menciona | Propone checkpoint cada 10s para recovery | No propone checkpoint periódico | **NO implementar checkpoint periódico** | El plugin `camera` del plugin escribe frames continuamente al archivo temporal en background. Un "checkpoint" manual no es posible con la API actual — no hay `snapshot()` ni `flush()`. Lo único viable es interceptar `paused` (que ya se hace). El checkpoint de Kilo es conceptualmente correcto pero técnicamente inviable con el plugin `camera` actual. |
| **`pauseRecording()` / `resumeRecording()`** | No menciona | Los incluye como APIs del RecordingController | No los incluye | **NO implementar pause/resume en Día 1-2** | El plugin `camera` de Flutter **no soporta pausa nativa**. `pauseVideoRecording()` existe pero es inestable en Android. Implementarlo ahora genera un falso sentido de seguridad. Se pospone. |
| **Niveles de granularidad de servicios** | 3 componentes: CameraManager, ProjectFileSystem, RecordingViewModel | 3 servicios: CameraService, FileStorageService, PermissionService + RecordingController | 4 servicios: CameraService, ClipStorageService, PermissionService + RecordingManager | **4 servicios (Qwen) con el naming de Kilo** | La separación en 4 servicios es la más limpia. CameraService (hardware), ClipStorageService (filesystem), PermissionService (permisos), RecordingManager (orquestador). El naming de Kilo es más descriptivo para `FileStorageService`, pero `ClipStorageService` es más específico. Se usa ClipStorageService. |
| **Storage check threshold** | No especifica número | No especifica | 500MB | **500MB mínimo** | Un clip de 30s a 1080p ocupa ~5-8MB. 500MB da margen de 60+ clips. Es un threshold razonable y conservador. |

### 0.3 Enfoques Únicos Valiosos (por análisis)

| Análisis | Aporte exclusivo | Decisión |
|---|---|---|
| **Antigravity** | Énfasis en `AppConfig` inmutable de cámara para garantizar consistencia con ffmpeg posterior. | **Adoptado**: se fija la configuración en un objeto centralizado, no dispersa en el código. |
| **Antigravity** | Warning sobre A/V sync: teleprompter heavy + recording pueden causar stuttering. | **Adoptado**: se documenta como riesgo a monitorear; el plugin camera corre en thread nativo separado, pero el Dart UI thread no debe bloquear el stop. |
| **Kilo** | Tabla de 8 preguntas críticas con responsable asignado (PO vs Tech Lead). | **Adoptado parcialmente**: las preguntas se consolidan en la sección de ambigüedades. Los responsables no aplican en este contexto. |
| **Kilo** | Error levels: CATASTRÓFICO / PARCIAL / WARNING con comportamiento diferenciado. | **Adoptado**: se integra en el manejo de errores. |
| **Kilo** | Monkey-test específico: 15 ciclos start/stop en 1 segundo consecutivos. | **Adoptado**: se incluye en la estrategia de testing. |
| **Qwen** | Schema explícito de metadata por clip con campos para ffmpeg futuro. | **Adoptado**: se estandariza el schema. |
| **Qwen** | Pipeline numerado de 4 fases (Init → Countdown → Recording → Exit) con detalle de cada rama. | **Adoptado**: es el flujo más ejecutable. |
| **Qwen** | Ambigüedad A1 (`projectId` no llega a RecordingPage) con propuesta concreta de solución. | **Adoptado**: es el bloqueo #1 para implementar. |
| **Qwen** | Fallback de File.copy() → `writeAsBytes(readAsBytes())` si copy falla. | **Adoptado**: defensa en profundidad contra edge cases de filesystem. |

### 0.4 Errores Técnicos Detectados

| Análisis | Error | Corrección |
|---|---|---|
| **Kilo** | Sugiere `permission_handler: ^6.0.0` | Obsoleto. API cambió. Se usa `^11.3.0`. |
| **Kilo** | Propone `pauseRecording()`/`resumeRecording()` como APIs | El plugin `camera` no soporta pausa de forma estable. La API `pauseVideoRecording()` existe pero es experimental y crash-prone en Android. Eliminar del scope. |
| **Kilo** | Propone auto-checkpoint cada 10s | Técnicamente inviable con el plugin `camera`. El archivo temporal se escribe en native thread; no hay API para flush manual. El único recovery point es `didChangeAppLifecycleState`. |
| **Kilo** | Sugiere async I/O con `isolate` o `compute` para archivos >10MB | Over-engineering para clips de 30s. `File.copy()` es I/O nativo y corre en thread pool del OS. No necesita isolate. |
| **Todos** | Ninguno menciona que `camera: ^0.11.0+4` tiene un **bug conocido** en Android donde `stopVideoRecording()` puede lanz `CameraException` si se llama <100ms tras `startVideoRecording()`. | **Agregado en riesgos**: el debounce debe ser >= 500ms para cubrir este bug del plugin. |

---

## 1. Resumen Ejecutivo

### Qué se va a construir

La capacidad de **grabar video real con audio y escribir archivos `.mp4` a disco** desde `RecordingPage`, reemplazando los TODOs actuales. El usuario presiona REC → countdown 3-2-1 → graba un fragmento del guion mientras el teleprompter avanza → presiona STOP → el clip se guarda como `chunk_{idx}_take_{n}.mp4` en el filesystem del proyecto.

Este es el **bloque de domino #1** del MVP: sin clips en disco, las fases de revisión (Día 3), stitching con ffmpeg (Día 4-5), exportación (Día 6) y persistencia (Día 7-8) no tienen input.

### Enfoque elegido

**Service layer desacoplado** con 4 componentes nuevos que separan responsabilidades:

1. **`PermissionService`** — chequeo y solicitud proactiva de permisos de cámara y micrófono.
2. **`CameraService`** — wrapper del plugin `camera` (init, start, stop, switch, dispose).
3. **`ClipStorageService`** — gestión de filesystem: directorios, naming, copia desde cache temporal, limpieza.
4. **`RecordingManager`** — orquestador que une los 3 anteriores y maneja debounce.

La UI (`RecordingPage`) **no toca `CameraController` directamente** ni escribe en filesystem. Solo llama al `RecordingManager` y reacciona a los resultados.

**No se implementa en este paso**: persistencia de `session_data.json` (Día 7-8), pause/resume (bloqueado por el plugin), camera swap (se implementa pero es secondary), revisión de clip con video_player (Día 3), stitching (Día 4-5).

---

## 2. Diseño Funcional Consolidado

### 2.1 Flujo Completo (Pipeline)

```
═══════════════════════════════════════════════════════════
FASE 1: INIT (al montar RecordingPage)
═══════════════════════════════════════════════════════════

1. PermissionService.requestPermissions()
   ├─ Granted (camera + mic) → proceed
   ├─ Denied → request → granted → proceed
   └─ Permanently denied → AlertDialog → "Ir a configuración" o "Cancelar"
       ├─ Settings → usuario activa permisos → volver a init
       └─ Cancelar → Navigator.pop() (regresa)

2. CameraService.initialize(direction: front)
   ├─ Success → _isCameraInitialized = true → muestra CameraPreview
   └─ Failure → AlertDialog "No se pudo acceder a la cámara"
       ├─ "Reintentar" → re-inicializa
       └─ "Ir a configuración" → openAppSettings()

3. ClipStorageService.ensureClipsDirectory()
   └─ Crea /vrm_data/projects/{projectId}/clips/ si no existe

4. _sessionData = SessionData(projectId, startedAt: now)


═══════════════════════════════════════════════════════════
FASE 2: COUNTDOWN (usuario presiona REC)
═══════════════════════════════════════════════════════════

5. _startCountdown() → 3, 2, 1 (rings animados)
   └─ Voice service paused durante countdown

6. _startActualRecording() → RecordingManager.startRecording()
   ├─ _isProcessing = true (debounce ON)
   ├─ CameraService.startRecording()
   │   └─ _cameraController.startVideoRecording()
   └─ setState(() => _recordingState = RecordingState.recording)


═══════════════════════════════════════════════════════════
FASE 3: RECORDING (usuario graba el fragmento)
═══════════════════════════════════════════════════════════

7. [Usuario lee el fragmento — teleprompter avanza]
   - Indicador REC visible (badge rojo con pulso)
   - Botón REC cambia a icono STOP
   - Voice commands limitados: solo "stop"/"detener" funcional


═══════════════════════════════════════════════════════════
FASE 4: STOP + SAVE (usuario presiona STOP)
═══════════════════════════════════════════════════════════

8. _stopRecording() → RecordingManager.stopRecording()
   ├─ CameraService.stopRecording() → XFile
   ├─ ClipStorageService.getNextTakeNumber(chunkIndex) → take N
   ├─ ClipStorageService.saveClip(XFile, chunkIndex, take N, metadata)
   │   ├─ File.copy(tempPath, clipPath)
   │   │   └─ Si copy falla → File(dest).writeAsBytes(File(source).readAsBytesSync())
   │   ├─ File(tempPath).delete()  // limpia cache de cámara
   │   └─ Retorna absolutePath del clip guardado
   ├─ _sessionData updated (incrementa take count para este chunk)
   ├─ _isProcessing = false (debounce OFF)
   └─ setState(() => _recordingState = RecordingState.idle)

9. Feedback al usuario: SnackBar "Clip guardado — 4.2s"


═══════════════════════════════════════════════════════════
FASE 5: EXIT (usuario navega fuera de la página)
═══════════════════════════════════════════════════════════

10. Si estaba grabando → stopRecording() bloqueante
11. CameraService.dispose()  ← CRÍTICO
12. ClipStorageService.cleanupTemp()
13. VoiceCommandService.stopService()
```

### 2.2 Casos Normales

| Escenario | Comportamiento |
|---|---|
| **Primera grabación exitosa** | REC → countdown → grabar 5-15s → STOP → `chunk_0_take_1.mp4` creado y reproducible |
| **Re-grabación del mismo fragmento** | REC → grabar → STOP → `chunk_0_take_2.mp4` creado (take 1 se conserva) |
| **Grabación del siguiente fragmento** | Usuario avanza a fragmento 1 → REC → STOP → `chunk_1_take_1.mp4` |
| **Voice command "stop"** | Equivalente a presionar botón STOP — mismo flujo de save |
| **Cambio de cámara** | Botón switch → preview cambia de frontal a trasera (solo en estado idle) |

### 2.3 Edge Cases y Manejo de Errores

| Escenario | Severidad | Comportamiento |
|---|---|---|
| **App pasa a background durante grabación** | 🔴 Crítico | `WidgetsBindingObserver.didChangeAppLifecycleState` → `AppLifecycleState.paused` → `CameraService.stopRecording()` → guarda clip parcial (puede ser más corto pero válido) → `session_data` actualizado |
| **Llamada entrante** | 🔴 Crítico | Igual que background. El OS interrumpe la cámara; se intercepta y se salva. |
| **Storage lleno (< 500MB)** | 🔴 Crítico | Check ANTES de iniciar grabación. SnackBar: "Almacenamiento insuficiente. Libera espacio y reintenta." No se inicia grabación. |
| **Camera init falla** | 🟡 Alto | AlertDialog: "No se pudo acceder a la cámara. Verifica permisos." Botones: "Reintentar" (re-inicializa) + "Configuración" (openAppSettings). |
| **startVideoRecording lanza excepción** | 🔴 Crítico | Catch → `_isProcessing = false` → SnackBar: "Error al iniciar grabación." No cambia estado a `recording`. |
| **stopVideoRecording lanza excepción** | 🔴 Crítico | Catch → reintentar una segunda vez (delay 200ms) → si falla de nuevo: `_isProcessing = false` → SnackBar: "Error al guardar el clip. Intenta de nuevo." |
| **File.copy() falla (cross-device)** | 🟡 Alto | Fallback: `dest.writeAsBytes(await source.readAsBytes())` → si también falla: SnackBar "Error al guardar." |
| **Usuario navega atrás durante grabación** | 🔴 Crítico | `dispose()` del StatefulWidget → stopRecording() síncrono (await en bloque) → salva clip → dispose camera. |
| **Doble tap rápido en REC** | 🟡 Alto | `_isProcessing` flag bloquea la segunda llamada silenciosamente. El botón también se deshabilita visualmente (opacity 0.4). |
| **stop llamado < 500ms tras start** | 🟡 Alto | El bug del plugin camera en Android lanza `CameraException`. El debounce de 500ms previene esto. Si ocurre por voice command, se maneja con retry. |
| **Video corrupto (archivo 0 bytes o no playable)** | 🟡 Medio | Detectar post-save: si `File.lengthSync() == 0`, mostrar "Clip corrupto. Intenta de nuevo." y borrar el archivo corrupto. |

### 2.4 Niveles de Error

| Nivel | Ejemplo | UX |
|---|---|---|
| **CATASTRÓFICO** (sin grabación) | Camera init falla, storage lleno | AlertDialog blocking con retry/settings |
| **ERROR PARCIAL** (grabación interrumpida) | App backgrounded, stopVideoRecording falla | SnackBar informativo + clip parcial se conserva |
| **WARNING** (storage bajo < 500MB) | Espacio insuficiente | SnackBar no-blocking, grabación no inicia |

---

## 3. Diseño Técnico Definitivo

### 3.1 Arquitectura Final

```
┌─────────────────────────────────────────────────────────┐
│              PRESENTATION (sin cambios mayores)          │
│  RecordingPage                                           │
│  - Countdown, Teleprompter, Voice, Menu, Grid           │
│  - Delega toda grabación a RecordingManager             │
│  - NO toca CameraController directamente                │
│  - NO escribe en FileSystem                             │
└──────────┬──────────────────────────┬───────────────────┘
           │ llama                    │ escucha estado
           ▼                          ▼
┌─────────────────────┐   ┌──────────────────────────────┐
│  RecordingManager   │   │  WidgetsBindingObserver       │
│  (orquestador)      │   │  (lifecycle handler)          │
│  - startRecording() │   │  - paused → stop + save       │
│  - stopRecording()  │   │  - resumed → re-init camera   │
│  - switchCamera()   │   └──────────────────────────────┘
│  - isRecording      │
│  - isProcessing     │
└──────────┬──────────┘
           │ delega
     ┌─────┴─────┐
     ▼           ▼
┌────────────┐  ┌────────────────────┐
│ Camera-    │  │ ClipStorageService │
│ Service    │  │ (filesystem)        │
│ (hardware) │  │ - ensureClipsDir()  │
│ - init()   │  │ - clipPath()        │
│ - start()  │  │ - getNextTake()     │
│ - stop()   │  │ - saveClip()        │
│ - switch() │  │ - cleanupTemp()     │
│ - dispose()│  │ - checkFreeSpace()  │
└────────────┘  └────────────────────┘
     ▲
     │ usa
┌────────────────────┐
│ PermissionService   │
│ - checkPermissions()│
│ - requestAll()      │
│ - handleDenied()    │
└────────────────────┘
```

### 3.2 Componentes — Interfaces Definidas

#### 3.2.1 `lib/features/recording/services/permission_service.dart`

```dart
abstract class PermissionService {
  /// Returns true if both camera and microphone are granted.
  Future<bool> checkPermissions();

  /// Requests both permissions. Returns final status.
  Future<bool> requestPermissions();

  /// Shows explanation dialog and opens app settings.
  Future<void> handleDenied(BuildContext context);
}
```

**Dependencia**: `permission_handler: ^11.3.0`

#### 3.2.2 `lib/features/recording/services/camera_service.dart`

```dart
abstract class CameraService {
  CameraController? get controller;
  bool get isInitialized;
  bool get isRecording;
  CameraLensDirection get currentDirection;

  Future<void> initialize({CameraLensDirection direction});
  Future<void> startRecording();
  Future<XFile> stopRecording();
  Future<void> switchCamera();
  Future<void> dispose();
}
```

**Dependencia**: `camera: ^0.11.0+4`

**Contratos críticos**:
- `startRecording()` lanza `StateError` si no está inicializado.
- `stopRecording()` lanza `StateError` si no está grabando.
- `switchCamera()` solo funciona si no está grabando (caller debe verificar).
- `dispose()` es idempotente (seguro llamar múltiples veces).

#### 3.2.3 `lib/features/recording/services/clip_storage_service.dart`

```dart
abstract class ClipStorageService {
  String get projectId;

  Future<Directory> ensureClipsDirectory();
  String clipPath({required int chunkIndex, required int takeNumber});
  Future<int> getNextTakeNumber(int chunkIndex);

  /// Copies XFile from camera cache to clips directory.
  /// Returns the absolute path of the saved clip.
  Future<String> saveClip({
    required XFile sourceFile,
    required int chunkIndex,
    required int takeNumber,
    required ClipMetadata metadata,
  });

  Future<void> deleteClip({required int chunkIndex, required int takeNumber});
  Future<bool> hasFreeSpace({required int requiredMB});
  Future<void> cleanupTemp();
}
```

**Dependencias**: `path_provider: ^2.1.3`, `path: ^1.9.0`, `dart:io`

#### 3.2.4 `lib/features/recording/services/recording_manager.dart`

```dart
abstract class RecordingManager {
  bool get isRecording;
  bool get isProcessing;  // debounce flag

  /// Starts recording for the given chunk. Returns immediately.
  /// The caller is responsible for calling stopRecording().
  Future<void> startRecording(int chunkIndex);

  /// Stops recording, saves the clip, and returns its path.
  Future<String> stopRecording();

  Future<void> switchCamera();
}
```

**Nota de diseño**: A diferencia de la propuesta original de Qwen (que tenía `recordClip()` como bloque atómico start→stop), se separan `startRecording()` y `stopRecording()` porque la UI necesita control granular: el usuario decide cuándo parar, no es automático. El `RecordingManager` mantiene estado interno (`_isRecording`, `_currentChunkIndex`) para validar las transiciones.

### 3.3 Modelos de Datos

#### 3.3.1 `ClipMetadata` (nuevo)

```dart
class ClipMetadata {
  final int chunkIndex;
  final int takeNumber;
  final int durationMs;
  final String resolution;    // "1080x1920"
  final int fps;              // 30
  final bool hasAudio;
  final int fileSizeBytes;
  final DateTime createdAt;

  ClipMetadata({
    required this.chunkIndex,
    required this.takeNumber,
    required this.durationMs,
    required this.resolution,
    required this.fps,
    required this.hasAudio,
    required this.fileSizeBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'chunkIndex': chunkIndex,
    'takeNumber': takeNumber,
    'durationMs': durationMs,
    'resolution': resolution,
    'fps': fps,
    'hasAudio': hasAudio,
    'fileSizeBytes': fileSizeBytes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ClipMetadata.fromJson(Map<String, dynamic> json) => ClipMetadata(
    chunkIndex: json['chunkIndex'] as int,
    takeNumber: json['takeNumber'] as int,
    durationMs: json['durationMs'] as int,
    resolution: json['resolution'] as String,
    fps: json['fps'] as int,
    hasAudio: json['hasAudio'] as bool,
    fileSizeBytes: json['fileSizeBytes'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
```

#### 3.3.2 `SessionData` (en memoria, persiste en Día 7-8)

```dart
class ChunkTakeInfo {
  final int total;
  final int selectedTake;

  ChunkTakeInfo({required this.total, required this.selectedTake});

  Map<String, dynamic> toJson() => {'total': total, 'selectedTake': selectedTake};
  factory ChunkTakeInfo.fromJson(Map<String, dynamic> json) =>
      ChunkTakeInfo(total: json['total'], selectedTake: json['selectedTake']);

  ChunkTakeInfo copyWith({int? total, int? selectedTake}) =>
      ChunkTakeInfo(total: total ?? this.total, selectedTake: selectedTake ?? this.selectedTake);
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

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'chunksRecorded': chunksRecorded,
    'currentChunk': currentChunk,
    'takesPerChunk': takesPerChunk.map((k, v) => MapEntry(k.toString(), v.toJson())),
    'startedAt': startedAt.toIso8601String(),
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
  };

  factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(
    projectId: json['projectId'] as String,
    chunksRecorded: (json['chunksRecorded'] as List?)?.map((e) => e as int).toList() ?? [],
    currentChunk: json['currentChunk'] as int? ?? 0,
    takesPerChunk: (json['takesPerChunk'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(int.parse(k), ChunkTakeInfo.fromJson(v as Map<String, dynamic>)),
    ) ?? {},
    startedAt: DateTime.parse(json['startedAt'] as String),
    lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
  );

  SessionData copyWith({
    List<int>? chunksRecorded,
    int? currentChunk,
    Map<int, ChunkTakeInfo>? takesPerChunk,
    DateTime? lastUpdatedAt,
  }) => SessionData(
    projectId: projectId,
    chunksRecorded: chunksRecorded ?? this.chunksRecorded,
    currentChunk: currentChunk ?? this.currentChunk,
    takesPerChunk: takesPerChunk ?? this.takesPerChunk,
    startedAt: startedAt,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );
}
```

### 3.4 Naming Convention de Archivos

```
/vrm_data/
  projects/
    {projectId}/
      clips/
        chunk_0_take_1.mp4
        chunk_0_take_2.mp4    ← re-grabación del mismo chunk
        chunk_1_take_1.mp4
        chunk_2_take_1.mp4
```

- `chunk_N`: índice del fragmento del guion (0-based).
- `take_M`: número de intento para ese chunk (1-based, incremental, no reutiliza).
- Extensión `.mp4` forzada (el plugin camera produce MP4 en Android y MOV en iOS — se normaliza a `.mp4` renombrando en iOS si es necesario).

### 3.5 Configuración de Cámara (Inmutable)

```dart
/// Centralized camera config to ensure consistency across
/// the app and compatibility with ffmpeg stitching (Día 4-5).
class CameraConfig {
  static const resolution = ResolutionPreset.high;  // 1080p target
  static const enableAudio = true;
  static const imageFormat = ImageFormatGroup.jpeg;
  static const defaultDirection = CameraLensDirection.front;

  /// Target resolution string for metadata. Actual may vary by device.
  static const targetResolution = '1080x1920';

  /// Expected FPS. Actual may vary (device-dependent).
  static const expectedFps = 30;
}
```

**Por qué centralizar**: Si ffmpeg necesita saber resolución/FPS para el stitch, todos los clips deben tener metadata consistente. Si en el futuro se necesita bajar la calidad (dispositivos con storage limitado), se cambia en un solo lugar.

---

## 4. Decisiones Tecnológicas

### 4.1 Stack Definitivo

| Dependencia | Versión | Estado | Justificación |
|---|---|---|---|
| `camera` | `^0.11.0+4` | ✅ Ya en pubspec | Oficial Flutter team. Soporta iOS + Android. La v0.11 incluye fixes para Android 14. Alternativas (`camerawesome`) tienen APIs inestables y menos mantenimiento. |
| `permission_handler` | `^11.3.0` | ❌ Agregar | Estándar de facto. Distingue `denied` vs `permanentlyDenied` y abre settings. La v6 (sugerida por Kilo) es obsoleta — la API cambió entre v6 y v11. |
| `path` | `^1.9.0` | ❌ Agregar | Necesario para `join()`, `extension()`, construcción de paths cross-platform. `path_provider` solo da directorios base. |
| `path_provider` | `^2.1.3` | ✅ Ya en pubspec | Abstrae diferencias Android/iOS para documentos y cache. |
| `video_player` | `^2.9.1` | ✅ Ya en pubspec | No se usa en Día 1-2. Será crítico para Día 3 (review). |

### 4.2 Decisiones de Diseño Resueltas

| Decisión | Elección | Justificación |
|---|---|---|
| **`projectId` en RecordingPage** | Agregar como parámetro requerido del constructor | Sin `projectId` no hay ruta de clips. El caller (`NewProjectPage` o equivalente) debe generar el UUID con el paquete `uuid` (ya en pubspec) antes de navegar. |
| **Política de takes** | Conservar todos, no sobrescribir | `chunk_0_take_1`, `chunk_0_take_2`, ... Permite recovery, debugging y A/B visual. Costo: ~5-8MB por take de 10s. Limpieza se pospone para optimización futura. |
| **Debounce** | Flag `bool _isProcessing` (no timer) | Más limpio que un Timer de 500ms. El flag se setea en start y se limpia en stop/error. Cubre el bug del plugin Android que crash si stop se llama <100ms tras start. |
| **File copy** | `File.copy()` → fallback `writeAsBytes(readAsBytes())` | `rename()` falla con EXDEV cross-device. `copy()` es seguro. El fallback con bytes cubre el raro caso de que `copy()` también falle (filesystems exoticos). |
| **State management** | `setState` (existente) | Over-engineering agregar Riverpod/Bloc ahora. La página ya maneja 15+ estados con `setState`. Se refactorizará si la complejidad lo exige. |
| **Persistencia de session_data** | Solo en memoria para Día 1-2 | El MVP planifica Día 7-8 para persistencia JSON. Escribir ahora duplica trabajo. El objeto vive en `_sessionData` del `RecordingManager`. |
| **Pause/Resume** | NO implementar | El plugin `camera` no soporta pausa de forma estable. `pauseVideoRecording()` es experimental y crash-prone en Android. Se pospone. |
| **Resolución** | `ResolutionPreset.high` | Balance calidad/tamaño. `veryHigh` (4K) genera archivos enormes. `medium` (720p) se ve mal. Se centraliza en `CameraConfig` para cambio futuro en un solo lugar. |
| **Cámara default** | Frontal | App de teleprompter — el creador se graba a sí mismo mirando la pantalla. |
| **Scope de plataforma** | Mobile only (iOS + Android) | Desktop no es target del MVP. Si `Platform.isWindows || Platform.isMacOS`, mostrar "Mobile only". |

### 4.3 Ambigüedades Resueltas (Decisiones del Arquitecto)

| # | Ambigüedad | Decisión |
|---|---|---|
| A1 | `projectId` no llega a RecordingPage | **Resolver**: agregar `required String projectId` al constructor. El caller genera UUID. |
| A2 | SessionData persistence timing | **Resolver**: memoria ahora, JSON en Día 7-8. |
| A3 | Política de takes | **Resolver**: conservar todos, numbering incremental. |
| A5 | Camera swap scope | **Resolver**: implementar en Día 1-2 pero solo en estado idle. |
| A6 | FPS consistency | **Resolver**: documentar como variable por dispositivo. Metadata registra el real. |
| A7 | Desktop support | **Resolver**: NO soportado. Mensaje "Mobile only". |
| A9 | Storage threshold | **Resolver**: 500MB mínimo. |
| A10 | Metadata schema | **Resolver**: schema estandarizado (ver `ClipMetadata` arriba). |

---

## 5. Plan de Implementación

### 5.1 Backlog de Tareas

```
PRIORIDAD 1 — Foundation (paralelizable)
══════════════════════════════════════════════════════════

T1. Agregar dependencias a pubspec.yaml               [5 min]
    ├─ permission_handler: ^11.3.0
    ├─ path: ^1.9.0
    └─ flutter pub get
    Dependencias: ninguna

T2. Crear ClipMetadata model                           [15 min]
    ├─ Archivo: lib/features/recording/models/clip_metadata.dart
    └─ Test: round-trip fromJson/toJson
    Dependencias: ninguna

T3. Crear SessionData + ChunkTakeInfo models           [20 min]
    ├─ Archivo: lib/features/recording/models/session_data.dart
    └─ Test: round-trip fromJson/toJson, copyWith
    Dependencias: ninguna

T4. Crear CameraConfig                                 [5 min]
    ├─ Archivo: lib/features/recording/config/camera_config.dart
    └─ Constants estáticas
    Dependencias: ninguna


PRIORIDAD 2 — Services (paralelizable entre T5, T6, T7)
══════════════════════════════════════════════════════════

T5. PermissionService                                  [30 min]
    ├─ Archivo: lib/features/recording/services/permission_service.dart
    ├─ checkPermissions() → bool
    ├─ requestPermissions() → bool
    └─ handleDenied(context) → dialog + settings
    Dependencias: T1

T6. ClipStorageService                                 [45 min]
    ├─ Archivo: lib/features/recording/services/clip_storage_service.dart
    ├─ ensureClipsDirectory()
    ├─ clipPath(chunkIndex, takeNumber)
    ├─ getNextTakeNumber(chunkIndex)
    ├─ saveClip(XFile, chunkIndex, takeNumber, metadata)
    ├─ hasFreeSpace(requiredMB)
    ├─ cleanupTemp()
    └─ Test: con temp directory real
    Dependencias: T1, T2

T7. CameraService                                      [45 min]
    ├─ Archivo: lib/features/recording/services/camera_service.dart
    ├─ initialize({direction})
    ├─ startRecording()
    ├─ stopRecording() → XFile
    ├─ switchCamera()
    ├─ dispose()
    └─ getter: controller (para CameraPreview)
    Dependencias: T1, T4

T8. RecordingManager                                   [30 min]
    ├─ Archivo: lib/features/recording/services/recording_manager.dart
    ├─ startRecording(chunkIndex)
    ├─ stopRecording() → path
    ├─ switchCamera()
    ├─ isRecording, isProcessing
    └─ Test: mock de CameraService + ClipStorageService
    Dependencias: T5, T6, T7


PRIORIDAD 3 — Integración (secuencial)
══════════════════════════════════════════════════════════

T9. Integrar servicios en RecordingPage                [90 min]
    ├─ Archivo: lib/features/recording/recording_page.dart
    ├─ Agregar `required String projectId` al constructor
    ├─ Instanciar los 4 servicios en initState
    ├─ Reemplazar _initializeCamera() → CameraService.initialize()
    ├─ Reemplazar _startActualRecording() → RecordingManager.startRecording()
    ├─ Reemplazar _stopRecording() → RecordingManager.stopRecording()
    ├─ Camera switch en botón existente
    ├─ dispose() → CameraService.dispose()
    ├─ WidgetsBindingObserver para didChangeAppLifecycleState
    │   └─ paused → stopRecording() + save
    └─ Debounce visual en botón REC (opacity 0.4 si isProcessing)
    Dependencias: T5, T6, T7, T8

T10. Storage check pre-grabación                        [15 min]
    ├─ ClipStorageService.hasFreeSpace(500)
    ├─ SnackBar si < 500MB
    └─ Prevenir inicio de grabación
    Dependencias: T6, T9

T11. UX feedback post-grabación                         [15 min]
    ├─ SnackBar "Clip guardado — 4.2s"
    ├─ SnackBar de error si algo falla
    └─ Indicador visual de estado (ya existe badge REC)
    Dependencias: T9


PRIORIDAD 4 — Validación
══════════════════════════════════════════════════════════

T12. Test en dispositivo físico Android                 [60 min]
    ├─ Happy path: grabar 3 fragmentos → verificar archivos
    ├─ Re-grabación: 2 takes del mismo chunk → verificar naming
    ├─ Background: grabar → home → volver → verificar clip parcial
    ├─ Monkey: 15 start/stop rápidos → verificar no crash
    ├─ Permisos: denegar → dialog → settings → permitir → retry
    └─ Verificar archivos reproducibles en VLC
    Dependencias: T9, T10, T11

T13. Test en dispositivo físico iOS (si disponible)     [60 min]
    ├─ Mismos tests que T12
    └─ Verificar que extensión es .mp4 (renombrar si .mov)
    Dependencias: T9, T10, T11
```

### 5.2 Dependencias y Orden

```
         T1 ──┬── T5 ──┐
              ├── T6 ──┼── T8 ──┐
              ├── T7 ──┘        │
              └── T2 ──┐        ├── T9 ──┬── T10 ──┐
              └── T3    └── T8 ──┘        │         ├── T12
              └── T4 ─────────────────────┘         └── T11 ──┘
                                                          └── T13

Ruta crítica: T1 → T7 → T8 → T9 → T12  = mínimo viable
Paralelizable: T2, T3, T4, T5, T6 entre sí
```

### 5.3 Definition of Done

- [ ] Usuario presiona REC → countdown 3-2-1 → graba fragmento → presiona STOP
- [ ] Archivo `.mp4` existe en `/vrm_data/projects/{projectId}/clips/chunk_{idx}_take_{n}.mp4`
- [ ] El archivo se reproduce en VLC con video + audio sincronizados
- [ ] Segundo take del mismo chunk genera `chunk_0_take_2.mp4` (no sobrescribe take 1)
- [ ] App a background durante grabación → clip parcial existe, app no crashea
- [ ] 15 start/stop rápidos → 0 crashes, 0 memory leaks
- [ ] Permisos denegados → dialog explicativo + deep link a settings
- [ ] Tests pasan en al menos 1 dispositivo físico Android
- [ ] `CameraController` disposed limpiamente al navegar fuera de la página

---

## 6. Riesgos y Mitigaciones

### 6.1 Riesgos Técnicos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| **`CameraController` no disposed → memory leak → lock de hardware** | Media | 🔴 Crítico | `dispose()` obligatorio en `State.dispose()` + `WidgetsBindingObserver` para `paused`. Test: navegar adelante/atrás 10 veces, verificar memoria estable. |
| **`startVideoRecording` + `stopVideoRecording` < 100ms → crash en Android** | Alta sin debounce | 🔴 Crítico | Flag `_isProcessing` que bloquea stop durante 500ms mínimos tras start. El botón REC se deshabilita visualmente. |
| **XFile borrado por GC antes de copiar** | Baja | 🔴 Crítico | Copiar inmediatamente tras `stopRecording()`. No almacenar referencia al XFile fuera del scope de la función. |
| **`stopVideoRecording` lanza CameraException** | Media | 🔴 Crítico | Try/catch + 1 retry con delay 200ms. Si falla de nuevo: error UI + clip se descarta. |
| **Android 13+ scoped storage** | Media | 🟡 Medio | `path_provider` abstrae esto. Nunca usar paths hardcoded. |
| **iOS background → recording terminated por sistema** | Baja | 🟡 Medio | `didChangeAppLifecycleState` → stop + save. El clip parcial puede ser más corto pero es válido. |
| **Thermal throttling** | Baja (clips de ~10-30s) | 🟢 Bajo | No aplica para clips cortos del MVP. Monitorear en Día 16-17. |
| **A/V desync por UI thread blocking** | Baja | 🟡 Medio | El plugin camera usa thread nativo separado. El teleprompter y voice services corren en Dart thread. No deberían interferir. Verificar que `stopRecording()` no espere operaciones UI. |

### 6.2 Riesgos Operativos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| **Testing solo en emulador** | Crashes en producción garantizados — el plugin camera no funciona bien en emuladores Android. | **Obligatorio**: test en dispositivo físico desde el Día 1. Mínimo 1 Android real. |
| **Usuario niega permisos y no sabe re-activar** | App no graba. UX destruida. | Dialog proactivo con explicación clara + botón "Ir a configuración". |
| **Disco lleno sin warning** | Clip corrupto o crash. | Check `hasFreeSpace(500)` antes de cada grabación. |

### 6.3 Riesgos de Escalabilidad

| Problema | Cuándo | Prep ahora |
|---|---|---|
| **Miles de clips en /clips/** | 50+ proyectos con múltiples takes | Estructura plana funciona hasta ~500 archivos. Más allá: `/clips/{date}/`. No urgente. |
| **Clips >2 minutos** | Guiones con segmentos largos | `ResolutionPreset.high` genera ~150MB/min. Si feedback indica storage issues, bajar a `medium`. |
| **ffmpeg stitch lento** | Día 4-5 con clips de 1080p | Metadata con resolución/FPS ya incluido. ffmpeg sabrá exactamente qué esperar. |

### 6.4 Costos

| Item | Costo |
|---|---|
| Dependencias nuevas | Gratis (open source) |
| Storage por clip | ~5-8MB por 10s a 1080p (usuario pone el hardware) |
| Testing físico | Requiere 1 Android real + 1 iOS real (ideal) |
| Costo cloud | $0 — todo es local |

---

## 7. Métricas de Éxito

### 7.1 KPIs Técnicos

| Métrica | Target | Cómo medir |
|---|---|---|
| **Clip válido** | 100% de grabaciones producen `.mp4` reproducible | Reproducir en VLC o `video_player` |
| **Latencia stop→save** | < 1.5 segundos | Stopwatch entre `stopRecording()` call y `saveClip()` complete |
| **Memory leak** | 0 crashes por OOM en 20 ciclos start/stop | `adb shell dumpsys meminfo` (Android), Xcode Instruments (iOS) |
| **Permiso recovery** | Usuario que deniega puede re-activar desde settings | Test manual: deny → settings → allow → retry |
| **Lifecycle handling** | 0 crashes al ir a background durante grabación | Test manual con botón home durante grabación |
| **Debounce efectivo** | 0 crashes por doble tap | Monkey test: 15 taps rápidos |

### 7.2 KPIs de Producto

| Métrica | Target |
|---|---|
| **Primera grabación exitosa** | > 90% de usuarios que inician grabación producen un clip válido |
| **Tamaño de clip de 10s** | < 10MB a 1080p |
| **Tasa de retake** | < 3 takes promedio por fragmento (si es mayor, hay problema de UX o calidad) |

---

## 8. Estrategia de Testing

### 8.1 Unit Tests

| Archivo | Qué prueba |
|---|---|
| `test/.../models/clip_metadata_test.dart` | `fromJson`/`toJson` round-trip, todos los campos serializados correctamente |
| `test/.../models/session_data_test.dart` | Round-trip, `copyWith`, manejo de `takesPerChunk` con keys int |
| `test/.../services/clip_storage_service_test.dart` | `ensureClipsDirectory` crea dir, `clipPath` formato correcto, `getNextTakeNumber` incrementa (crear archivos fake y verificar), `saveClip` copia y limpia source |
| `test/.../services/recording_manager_test.dart` | `startRecording` delega a CameraService, `stopRecording` llama stop + save en orden, `isProcessing` bloquea llamadas concurrentes |

**Test concreto — Take numbering**:
```dart
test('getNextTakeNumber returns 3 when take_1 and take_2 exist', () async {
  final service = ClipStorageService(projectId: 'test-1');
  await service.ensureClipsDirectory();
  // Crear archivos fake
  File(service.clipPath(chunkIndex: 0, takeNumber: 1)).createSync();
  File(service.clipPath(chunkIndex: 0, takeNumber: 2)).createSync();

  final next = await service.getNextTakeNumber(0);
  expect(next, 3);
});

test('getNextTakeNumber returns 1 when no takes exist', () async {
  final service = ClipStorageService(projectId: 'test-2');
  await service.ensureClipsDirectory();

  final next = await service.getNextTakeNumber(0);
  expect(next, 1);
});
```

### 8.2 Integration Tests (obligatorio en hardware físico)

| Test | Procedimiento | Resultado esperado |
|---|---|---|
| **Happy path** | REC → countdown → grabar 5s → STOP | `chunk_0_take_1.mp4` existe y es reproducible |
| **Multi-fragment** | Grabar fragmento 0 → siguiente → grabar fragmento 1 → STOP | `chunk_0_take_1.mp4` + `chunk_1_take_1.mp4` |
| **Multi-take** | Grabar frag 0 → STOP → grabar frag 0 → STOP | `chunk_0_take_1.mp4` + `chunk_0_take_2.mp4` |
| **Debounce** | Tap REC 15 veces rápidas | Solo 1 grabación inicia. 0 crashes. |
| **Background** | Grabar → presionar home → volver | Clip parcial existe. App no crashea. |
| **Permission denied** | Denegar cámara en settings → abrir app | Dialog con "Ir a configuración" |
| **Storage full** | Simular disco lleno | Alerta "Almacenamiento insuficiente" |
| **Switch camera** | Tap switch en idle | Preview cambia a cámara trasera |
| **Dispose clean** | Grabar → navegar atrás → volver a grabar | No memory leak. Camera re-inicializa limpio. |
| **Monkey stress** | 15 ciclos start/stop en 1 segundo | 0 crashes, 0 OOM, todos los clips válidos |
| **Airplane mode** | Grabar con airplane mode ON | Sin efecto — todo es local |
| **Video corrupto (0 bytes)** | Inyectar archivo 0 bytes como fuente | Detectar y borrar, mostrar error |

### 8.3 Casos Críticos

1. **El archivo tiene audio**: Verificar stream de audio en el `.mp4` final. El plugin `camera` con `enableAudio: true` debe incluirlo, pero hay bugs reportados en algunos dispositivos Android donde el audio se pierde.
2. **El archivo es válido tras app kill forzada**: `kill -9` en Android durante grabación. Verificar si el archivo parcial es reproducible o corrupto.
3. **El path no contiene caracteres inválidos**: Verificar que `projectId` (UUID) no contenga `/`, `\`, o caracteres que rompan paths.
4. **Cross-device copy**: Verificar que `File.copy()` funciona correctamente tanto en Android (cache → documents) como en iOS (cache → documents).

---

## 9. Consideraciones de Escalabilidad

### 9.1 Problemas Futuros y Preparación

| Problema | Cuándo aparece | Cómo se prepara ahora |
|---|---|---|
| **Storage explosion con muchos takes** | Usuario re-graba un chunk 10+ veces | Take numbering incremental permite identificar y borrar takes viejos. Implementar "max 5 takes por chunk" como política futura. |
| **Stitching lento con clips 1080p** | Día 4-5 con ffmpeg | `CameraConfig` centralizado + metadata con resolución/FPS. ffmpeg sabrá exactamente qué parámetros usar sin inferencia. |
| **UI lag con muchos archivos en /clips/** | 100+ clips en un proyecto | `getNextTakeNumber()` usa `listSync()` que es O(n). Con 500+ archivos, migrar a índice JSON o paginación. No urgente para MVP. |
| **Memory pressure en grabaciones largas** | Clips > 60s | El plugin camera escribe en native thread. Si se detecta pressure, implementar chunking automático cada 30s. |
| **Thermal throttling** | Sesiones > 10 minutos | Throttle de resolución (bajar a `medium`) o pausa obligatoria entre clips. |
| **Cloud sync de clips** | V2 con backup | `ClipStorageService` es una abstracción. Se puede implementar `CloudClipStorageService` que suba a S3 sin cambiar la UI. |

### 9.2 Decisiones de Diseño que Habilitan Escalabilidad

1. **Interface-based services**: Cada servicio tiene una interfaz abstracta. Se puede swap la implementación (local → cloud, camera → camerawesome) sin tocar la UI.

2. **Metadata estandarizado**: El schema de `ClipMetadata` incluye campos que ffmpeg necesitará (resolución, FPS, duración). Incluirlos ahora evita migración de datos después.

3. **Take numbering incremental**: No sobrescribir permite recovery, debugging y políticas de limpieza selectiva. El costo de storage es manejable (~5-8MB/take de 10s).

4. **Debounce centralizado en RecordingManager**: El patrón `_isProcessing` se reutilizará para operaciones async futuras (stitching, export, upload).

5. **`WidgetsBindingObserver` para lifecycle**: Implementarlo ahora protege contra el crash más común en producción. El mismo patrón sirve para teleprompter y cualquier proceso de fondo.

### 9.3 Qué NO Optimizar Ahora

| Optimización | Por qué posponer |
|---|---|
| Compresión de clips | Se maneja en Día 4-5 con ffmpeg. No duplicar. |
| Cleanup automático de takes viejos | No hay data de uso real. Esperar feedback. |
| Índice JSON de clips | `listSync()` funciona bien hasta 500 archivos. Optimizar cuando sea medible el problema. |
| Isolate para file copy | `File.copy()` es I/O nativo en thread del OS. No necesita isolate para clips de <50MB. |
| Pause/resume de grabación | Plugin inestable. No vale el riesgo en MVP. |
