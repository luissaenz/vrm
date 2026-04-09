# 🧠 ANÁLISIS TÉCNICO - DÍA 3: Clip Review Screen

**Agente:** qwen  
**Fecha:** 9 de abril de 2026  
**Fase:** FASE 1 - Core de Grabación (Día 3 de 21)  
**Objetivo del Día:** Implementar `ClipReviewScreen` que permita al usuario reproducir, evaluar y decidir sobre cada clip grabado antes de avanzar al siguiente fragmento.

---

## 1. ANATOMÍA DE COMPONENTES

### 1.1 Widget Principal: `ClipReviewPage`

**Archivo destino:** `lib/features/recording/widgets/clip_review_page.dart` (nuevo)

| Atributo | Detalle |
|----------|---------|
| **Inputs/Props** | `clipPath` (String - ruta absoluta del archivo .mp4), `chunkIndex` (int - índice del fragmento 0-based), `totalChunks` (int - total de fragmentos del guion), `takeNumber` (int - número de intento), `onAccept` (VoidCallback - callback al aprobar), `onRepeat` (VoidCallback - callback al rechazar/repetir) |
| **Outputs/Events** | Dispara `onAccept()` → avanza al siguiente fragmento o finaliza sesión. Dispara `onRepeat()` → vuelve a grabar el mismo fragmento. |
| **Estado Interno** | `isPlaying` (bool), `isMuted` (bool - default true), `videoDuration` (Duration), `videoPosition` (Duration), `isLooping` (bool - default true), `isVideoInitialized` (bool) |
| **Persistencia** | Ninguna. Es una pantalla efímera de revisión. |

**Dependencias externas:**
- `video_player` package (`VideoPlayerController`, `VideoPlayer`)
- `camera_service.dart` (para acceder al clip grabado)
- `session_data.dart` (para contexto de sesión)

---

### 1.2 Sub-widgets necesarios

#### 1.2.1 `ReviewVideoPlayer`

**Archivo:** embebido en `clip_review_page.dart` (widget privado `_ReviewVideoPlayer`)

| Atributo | Detalle |
|----------|---------|
| **Inputs** | `controller` (VideoPlayerController), `onInitialized` (Callback), `onError` (Callback<String>) |
| **Responsabilidad** | Envolver `VideoPlayer` con manejo de errores, placeholder mientras carga, y aspect ratio correcto |

#### 1.2.2 `ReviewControls`

**Archivo:** embebido en `clip_review_page.dart` (widget privado `_ReviewControls`)

| Atributo | Detalle |
|----------|---------|
| **Inputs** | `isPlaying` (bool), `onPlayPause` (VoidCallback), `onMuteToggle` (VoidCallback), `isMuted` (bool) |
| **Responsabilidad** | Barra inferior con botones: ▶/⏸ (play/pause), 🔇/🔊 (mute/unmute), slider de progreso scrub |

#### 1.2.3 `ReviewDecisionButtons`

**Archivo:** embebido en `clip_review_page.dart` (widget privado `_ReviewDecisionButtons`)

| Atributo | Detalle |
|----------|---------|
| **Inputs** | `onAccept` (VoidCallback), `onRepeat` (VoidCallback), `chunkIndex` (int), `totalChunks` (int) |
| **Responsabilidad** | Dos botones flotantes grandes sobre el video: 🗑️ "Repetir" (rojo, izquierda) y ✅ "Siguiente" (verde, derecha) |

---

### 1.3 Modificación a `RecordingManager`

**Archivo existente:** `lib/features/recording/services/recording_manager.dart`

| Cambio | Detalle |
|--------|---------|
| **Nuevo método** | `Future<String?> getCurrentClipPath()` → retorna la ruta del último clip grabado para el fragmento actual |
| **Nuevo método** | `int getCurrentTakeNumber()` → retorna el número de intento del fragmento actual |
| **Modificación** | `acceptCurrentClip()` → marca el clip actual como "aprobado" en `SessionData` y lo persiste |
| **Modificación** | `rejectCurrentClip()` → elimina el archivo físico del clip rechazado del filesystem, decrementa `takeNumber` en `SessionData` |

---

### 1.4 Modificación a `RecordingPage`

**Archivo existente:** `lib/features/recording/recording_page.dart`

| Cambio | Detalle |
|--------|---------|
| **Nuevo estado** | Agregar `reviewing` al enum `_RecordingState` (actualmente tiene: `idle`, `countdown`, `recording`) |
| **Nueva navegación** | Cuando `RecordingManager` termina de grabar, en vez de auto-avanzar, navega a `ClipReviewPage` con los parámetros del clip |
| **Callback onAccept** | Al aceptar, cierra `ClipReviewPage`, incrementa `chunkIndex` en `SessionData`, y prepara siguiente fragmento |
| **Callback onRepeat** | Al repetir, cierra `ClipReviewPage`, llama a `rejectCurrentClip()`, y reinicia grabación del mismo fragmento |

---

## 2. MAPA DE CONCURENCIA Y LIFECYCLE

### 2.1 Flujos Asíncronos

```
┌──────────────────────────────────────────────────────────────────┐
│                    FLUJO DE GRABACIÓN → REVISIÓN                 │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [RecordingPage]                                                 │
│       │                                                          │
│       │ 1. Usuario dice "grabar"                                 │
│       ▼                                                          │
│  [countdown 3-2-1]                                               │
│       │                                                          │
│       │ 2. RecordingManager.startRecording()                     │
│       │    - CameraController.startVideoRecording()              │
│       │    - Archivo se escribe en disco (async I/O)             │
│       ▼                                                          │
│  [grabando...]                                                   │
│       │                                                          │
│       │ 3. VAD detecta silencio / timeout / manual stop          │
│       ▼                                                          │
│  RecordingManager.stopRecording()                                │
│       │  - XFile.saveTo() → chunk_X_take_Y.mp4                  │
│       │  - SessionData.update()                                  │
│       ▼                                                          │
│  Navigator.push(ClipReviewPage(clipPath: ...))                   │
│       │                                                          │
│       │ 4. ClipReviewPage.initState()                            │
│       │    - VideoPlayerController.file(File(clipPath))          │
│       │    - controller.initialize()  ← ASYNC CRÍTICO           │
│       │    - controller.setLooping(true)                         │
│       │    - controller.play()                                   │
│       ▼                                                          │
│  [Video en loop - usuario revisa]                                │
│       │                                                          │
│       │ 5a. Usuario toca "✅ Siguiente"                          │
│       ▼                                                          │
│  onAccept() → RecordingManager.acceptCurrentClip()               │
│       │    - Marca clip como aprobado en SessionData             │
│       │    - Navigator.pop() → vuelve a RecordingPage            │
│       │    - RecordingPage: chunkIndex++                         │
│       │    - Prepara siguiente fragmento                         │
│       ▼                                                          │
│  [RecordingPage - Fragmento N+1 listo]                           │
│                                                                  │
│       │ 5b. Usuario toca "🗑️ Repetir"                            │
│       ▼                                                          │
│  onRepeat() → RecordingManager.rejectCurrentClip()               │
│       │    - File(clipPath).delete()  ← ASYNC I/O               │
│       │    - SessionData.takeNumber--                            │
│       │    - Navigator.pop() → vuelve a RecordingPage            │
│       │    - RecordingPage: mismo chunkIndex, reinicia grabación │
│       ▼                                                          │
│  [RecordingPage - Mismo fragmento, nuevo take]                   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Zonas Rojas de Condición de Carrera

| Zona | Riesgo | Estrategia |
|------|--------|------------|
| **ZONA 1: `VideoPlayerController.initialize()`** | Si el archivo no existe o está corrupto, `initialize()` lanza excepción. El widget se quedaría en estado loading infinito. | Try/catch alrededor de `initialize()`. Si falla, mostrar pantalla de error con botón "Repetir" (no hay clip válido para revisar). |
| **ZONA 2: `File(clipPath).delete()` en onRepeat** | Si el archivo ya fue borrado o la app se cerró entre medio, `delete()` lanza `FileSystemException`. | Verificar `file.existsSync()` antes de borrar. Envolver en try/catch. Loggear error pero no bloquear flujo. |
| **ZONA 3: Navegación durante inicialización** | Si usuario presiona "Atrás" del OS mientras el video se inicializa, el controller puede quedar leak. | En `dispose()`, llamar `controller.dispose()` siempre. Cancelar timers pendientes. |
| **ZONA 4: Auto-accept pasivo (F7.3 MVP+)** | Si se implementa auto-accept después de 3 segundos, puede haber race entre el timer y la acción del usuario. | Usar `Timer` con flag `_isDisposed`. Si el usuario actuó primero, cancelar timer con `timer?.cancel()`. |

### 2.3 Estrategia de Limpieza (`dispose`)

```dart
@override
void dispose() {
  // 1. Detener reproducción
  if (_controller.value.isPlaying) {
    _controller.pause();
  }
  
  // 2. Disposable del controller (libera buffers de video)
  _controller.dispose();
  
  // 3. Cancelar timer de auto-accept si existe (MVP+)
  _autoAcceptTimer?.cancel();
  
  // 4. Cancelar timer de actualización de posición (para scrubber)
  _positionTimer?.cancel();
  
  super.dispose();
}
```

---

## 3. PROTOCOLOS DE ERROR Y RESILIENCIA

### 3.1 Interacciones con FileSystem (I/O de Video)

| Escenario | Qué ve el usuario | Acción del sistema |
|-----------|-------------------|-------------------|
| **Clip se grabó correctamente** | Video se reproduce en loop. Botones Repetir/Siguiente visibles. | Flujo normal. |
| **Archivo de clip no existe al abrir review** | Pantalla de error: "No se encontró la grabación". Botón grande "🔁 Intentar de nuevo". | Log del error. No avanzar de fragmento. Forzar re-grabación. |
| **Archivo corrupto (parcial)** | Video muestra error o frame negro. Mensaje: "La grabación no se completó correctamente". Botón "🔁 Repetir". | Log con ruta y tamaño del archivo. Intentar delete del archivo corrupto. |
| **Sin espacio en disco al grabar** | Toast/Toast-like: "No hay espacio suficiente. Libera memoria e intenta de nuevo." Grabación se detiene. | `disk_space` package para verificar antes de grabar. Si < 50MB libre, mostrar advertencia preemptiva. |
| **Delete falla en onRepeat** | Silencioso. El flujo continúa normal (el archivo huérfano se limpiará en cleanup posterior). | Log del error. No bloquear al usuario. |

### 3.2 Casos de "Limbo" (App se cierra durante operación)

| Momento del cierre | Consecuencia | Recuperación |
|--------------------|--------------|--------------|
| **Durante `VideoPlayerController.initialize()`** | Ninguna. El archivo en disco está intacto. | Al reabrir, `RecordingManager` lee `SessionData` del disco. Detecta que hay un clip sin aprobar para el fragmento actual. Ofrece: "¿Quieres revisar el último clip grabado?" |
| **Durante `File.delete()` en onRepeat** | El archivo puede quedar (delete parcial) o irse. | Idempotente: si el archivo existe, se borra al reintentar. Si no existe, se salta. |
| **Usuario cierra app en medio de la revisión** | Clip queda en estado "pendiente de revisión" en `SessionData`. | Al reanudar proyecto, `RecordingPage` lee `SessionData`. Si hay clip sin aprobar, muestra pantalla de revisión directamente. Si clip fue aceptado, avanza al siguiente. |

### 3.3 Manejo de Permisos

| Permiso | Estado | Acción |
|---------|--------|--------|
| **Storage (lectura)** | Necesario para leer el clip del filesystem. | Ya solicitado en `RecordingPage`. Si fue denegado, no se puede mostrar review. Mostrar diálogo educativo y redirigir a settings del OS. |
| **Storage (escritura)** | Necesario para delete en onRepeat. | Mismo manejo. |

---

## 4. DISEÑO TÉCNICO NOMINATIVO

### 4.1 Archivos y Clases

| Archivo | Clase/Tipo | Responsabilidad |
|---------|-----------|-----------------|
| `lib/features/recording/widgets/clip_review_page.dart` | `ClipReviewPage` (StatelessWidget) | Wrapper que recibe parámetros y crea el state |
| `lib/features/recording/widgets/clip_review_page.dart` | `_ClipReviewPageState` (State<ClipReviewPage>) | Estado completo: controller, timers, UI |
| `lib/features/recording/widgets/clip_review_page.dart` | `_ReviewVideoArea` (StatelessWidget) | Área de video con aspect ratio 9:16 o 16:9 |
| `lib/features/recording/widgets/clip_review_page.dart` | `_ReviewControlBar` (StatelessWidget) | Play/pause, mute, scrubber |
| `lib/features/recording/widgets/clip_review_page.dart` | `_ReviewDecisionOverlay` (StatelessWidget) | Botones flotantes Repetir/Siguiente |
| `lib/features/recording/widgets/clip_review_page.dart` | `_ReviewErrorScreen` (StatelessWidget) | Pantalla de error cuando el video no carga |
| `lib/features/recording/services/recording_manager.dart` | `RecordingManager` (existente) | Agregar métodos: `getCurrentClipPath()`, `acceptCurrentClip()`, `rejectCurrentClip()` |
| `lib/features/recording/models/session_data.dart` | `SessionData` (existente) | Agregar campo `clipStatuses: Map<int, ClipStatus>` |
| `lib/features/recording/models/clip_status.dart` | `ClipStatus` (enum - nuevo) | `pending`, `recorded`, `approved`, `rejected` |

### 4.2 Método de `RecordingManager`

```dart
// recording_manager.dart - métodos a agregar

/// Retorna la ruta del último clip grabado para el fragmento actual.
String? getCurrentClipPath() {
  final currentChunk = _sessionData.currentChunkIndex;
  final take = _sessionData.getCurrentTakeNumber(currentChunk);
  if (take == null) return null;
  return '${_sessionData.projectClipsDir}/chunk_${currentChunk}_take_$take.mp4';
}

/// Marca el clip actual como aprobado y avanza el índice.
void acceptCurrentClip() {
  final chunkIndex = _sessionData.currentChunkIndex;
  _sessionData.markChunkApproved(chunkIndex);
  _sessionData.currentChunkIndex = chunkIndex + 1;
  _saveSession();
}

/// Rechaza el clip actual: borra archivo y permite re-grabación.
Future<void> rejectCurrentClip() async {
  final chunkIndex = _sessionData.currentChunkIndex;
  final clipPath = getCurrentClipPath();
  if (clipPath != null) {
    final file = File(clipPath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        // Log pero no bloquear
        debugPrint('⚠️ No se pudo eliminar clip rechazado: $e');
      }
    }
  }
  _sessionData.markChunkRejected(chunkIndex);
  _saveSession();
}
```

### 4.3 Estructura de `ClipReviewPage`

```dart
class ClipReviewPage extends StatelessWidget {
  final String clipPath;
  final int chunkIndex;
  final int totalChunks;
  final int takeNumber;
  final VoidCallback onAccept;
  final VoidCallback onRepeat;

  const ClipReviewPage({
    required this.clipPath,
    required this.chunkIndex,
    required this.totalChunks,
    required this.takeNumber,
    required this.onAccept,
    required this.onRepeat,
  });
}

class _ClipReviewPageState extends State<ClipReviewPage> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _hasError = false;
  bool _isMuted = true;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final file = File(widget.clipPath);
      if (!await file.exists()) {
        setState(() => _hasError = true);
        return;
      }
      _controller = VideoPlayerController.file(file);
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.setVolume(0); // mute por defecto (F7.4)
      _controller.play();
      setState(() {
        _isVideoInitialized = true;
        _isPlaying = true;
      });
      _startPositionTracking();
    } catch (e) {
      setState(() => _hasError = true);
    }
  }

  // ... resto de la implementación
}
```

---

## 5. PLAN DE IMPLEMENTACIÓN ATÓMICO

Cada tarea está diseñada para no exceder ~50 líneas de código real.

| # | Tarea | Archivo | Líneas estimadas | Dependencias |
|---|-------|---------|-----------------|--------------|
| **1** | Crear enum `ClipStatus` | `lib/features/recording/models/clip_status.dart` (nuevo) | ~10 | Ninguna |
| **2** | Agregar campo `clipStatuses` a `SessionData` + métodos `markChunkApproved`, `markChunkRejected` | `lib/features/recording/models/session_data.dart` (modificar) | ~30 | Tarea 1 |
| **3** | Agregar método `getCurrentClipPath()` a `RecordingManager` | `lib/features/recording/services/recording_manager.dart` | ~15 | Tarea 2 |
| **4** | Agregar método `acceptCurrentClip()` a `RecordingManager` | `lib/features/recording/services/recording_manager.dart` | ~15 | Tarea 2 |
| **5** | Agregar método `rejectCurrentClip()` a `RecordingManager` | `lib/features/recording/services/recording_manager.dart` | ~25 | Tarea 2 |
| **6** | Crear `ClipReviewPage` con initState y _initializeVideo | `lib/features/recording/widgets/clip_review_page.dart` (nuevo) | ~45 | Tarea 3 |
| **7** | Crear `_ReviewVideoArea` (área de video con aspect ratio) | `clip_review_page.dart` | ~35 | Tarea 6 |
| **8** | Crear `_ReviewErrorScreen` (pantalla de error) | `clip_review_page.dart` | ~30 | Tarea 6 |
| **9** | Crear `_ReviewControlBar` (play/pause, mute, scrubber) | `clip_review_page.dart` | ~40 | Tarea 6 |
| **10** | Crear `_ReviewDecisionOverlay` (botones Repetir/Siguiente) | `clip_review_page.dart` | ~35 | Tarea 6 |
| **11** | Integrar navegación en `RecordingPage`: al terminar grabación, push a `ClipReviewPage` | `lib/features/recording/recording_page.dart` | ~30 | Tarea 6 |
| **12** | Implementar callback `onAccept` en `RecordingPage` | `lib/features/recording/recording_page.dart` | ~15 | Tarea 4, Tarea 11 |
| **13** | Implementar callback `onRepeat` en `RecordingPage` | `lib/features/recording/recording_page.dart` | ~15 | Tarea 5, Tarea 11 |
| **14** | Agregar verificación de espacio en disco preemptiva | `lib/features/recording/services/recording_manager.dart` | ~20 | Ninguna |
| **15** | Test manual: grabar → revisar → aceptar → siguiente fragmento | - | - | Tareas 1-13 |
| **16** | Test manual: grabar → revisar → repetir → re-grabar mismo fragmento | - | - | Tareas 1-13 |
| **17** | Test de error: forzar archivo inexistente y verificar error screen | - | - | Tarea 8 |

**Total estimado:** ~400 líneas de código nuevo + ~80 de modificación.

---

## DECISIONES TÉCNICAS

### D1: ¿Por qué `VideoPlayerController.file()` y no `asset()` o `network()`?
El clip es un archivo local en el filesystem del dispositivo. `file()` es la única opción que funciona offline. Además, permite acceso directo al `File` para verificación de existencia y delete.

### D2: ¿Por qué mute por defecto? (F7.4 del spec)
El usuario está en medio de un flujo de grabación. El audio del clip puede interferir con su concentración para decidir si repite. Mute por defecto permite revisar el aspecto visual rápidamente. El usuario puede activar audio si necesita revisar dicción.

### D3: ¿Por qué looping por defecto?
Permite al usuario observar el clip múltiples veces sin acción adicional mientras decide. Sin looping, el video se detendría y el usuario tendría que dar play manualmente, añadiendo fricción.

### D4: ¿Por qué borrar el archivo en reject?
Los clips rechazados son datos muertos que ocupan espacio. En un pipeline de grabación de múltiples fragmentos, los takes rechazidos pueden acumularse rápidamente (ej: 5 fragmentos x 3 takes rechazados = 15 archivos huérfanos). Borrar inmediatamente mantiene el filesystem limpio.

### D5: ¿Por qué no usar `video_player` nativo de cámara?
El `camera` package de Flutter permite preview en vivo pero no tiene un modo de "reproducir el último video grabado" sin salir del controller. `VideoPlayerController.file()` es la forma estándar de reproducir un archivo .mp4 local en Flutter.

---

## RIESGOS IDENTIFICADOS

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| **`VideoPlayerController.initialize()` tarda > 2 segundos en clips grandes** | Media | 🟡 Medio | Mostrar placeholder de loading con spinner mientras inicializa. Si tarda > 5s, mostrar error. |
| **Clip corrupto por grabación interrumpida** | Baja | 🔴 Alto | Verificar existencia y tratar de inicializar. Si falla, mostrar error screen con opción de repetir. |
| **Memory leak si dispose no se ejecuta** | Baja | 🔴 Alto | Try/catch/finally en dispose. Verificar con DevTools de Flutter. |
| **`speech_to_text` interfiere con `video_player`** | Media | 🟡 Medio | Pausar `speech_to_text` durante la revisión. Reanudar al volver a RecordingPage. |
| **Aspect ratio del video no coincide con pantalla** | Alta | 🟡 Medio | Usar `FittedBox` o `AspectRatio` widget para ajustar. El video de cámara probablemente es 9:16 o 3:4. |
| **El clip se graba pero `SessionData` no se actualiza a tiempo** | Baja | 🔴 Alto | Asegurar que `_saveSession()` se llama después de cada cambio. Usar await en I/O. |

---

## TRAMPAS ASÍNCRONAS A EVITAR

### Trampa 1: setState después de dispose
```dart
// ❌ MAL
await _controller.initialize();
setState(() { _isVideoInitialized = true; }); // Si el usuario cerró la página, crash.

// ✅ BIEN
await _controller.initialize();
if (mounted) {
  setState(() { _isVideoInitialized = true; });
}
```

### Trampa 2: No esperar el delete antes de navegar
```dart
// ❌ MAL
rejectCurrentClip(); // Future<void> sin await
Navigator.pop(context); // Navega antes de que se borre

// ✅ BIEN
await RecordingManager.rejectCurrentClip();
if (mounted) Navigator.pop(context);
```

### Trampa 3: Timer sin cancel en dispose
```dart
// ❌ MAL
Timer.periodic(..., (_) { setState(...); });

// ✅ BIEN
_positionTimer = Timer.periodic(..., (_) {
  if (mounted) setState(...);
});
// Y en dispose: _positionTimer?.cancel();
```

---

## UX VISIBLE (Diseño Funcional)

### Flujo de pantalla

```
┌─────────────────────────────────────┐
│     FRAGMENTO 3 / 8                 │  ← Header
├─────────────────────────────────────┤
│                                     │
│         ┌───────────────┐           │
│         │               │           │
│         │   VIDEO EN    │           │
│         │   LOOP        │           │  ← Área de video (70% altura)
│         │   (mute)      │           │
│         │               │           │
│         └───────────────┘           │
│                                     │
│    ◀❚❚▶    🔇     ▬▬▬●▬▬▬▬         │  ← Control bar (play, mute, scrubber)
│                                     │
│  TAKE 2                             │  ← Info del take
├─────────────────────────────────────┤
│                                     │
│   🗑️ REPETIR      ✅ SIGUIENTE      │  ← Decision buttons (flotantes)
│   (rojo)          (verde)           │
│                                     │
└─────────────────────────────────────┘
```

### Estados visuales

| Estado | Visual |
|--------|--------|
| Loading (inicializando video) | Spinner centrado + texto "Cargando grabación..." |
| Error (archivo no encontrado) | Icono ⚠️ grande + "No se encontró la grabación" + botón "🔁 Intentar de nuevo" |
| Normal (video reproduce) | Video en loop mute, controles visibles |
| Video pausado | Icono ▶ grande semi-transparente sobre el video |
| Video sin mute | Icono 🔊 en control bar |

---

## BACKLOG ORDENADO PARA IMPLEMENTADOR

1. **[T1]** Crear `ClipStatus` enum → `lib/features/recording/models/clip_status.dart`
2. **[T2]** Extender `SessionData` con clipStatuses → `lib/features/recording/models/session_data.dart`
3. **[T3]** `getCurrentClipPath()` en `RecordingManager`
4. **[T4]** `acceptCurrentClip()` en `RecordingManager`
5. **[T5]** `rejectCurrentClip()` en `RecordingManager`
6. **[T6]** Crear `ClipReviewPage` skeleton + `_initializeVideo`
7. **[T7]** `_ReviewVideoArea` widget
8. **[T8]** `_ReviewErrorScreen` widget
9. **[T9]** `_ReviewControlBar` widget
10. **[T10]** `_ReviewDecisionOverlay` widget
11. **[T11]** Integrar navegación en `RecordingPage`
12. **[T12]** Callback `onAccept` en `RecordingPage`
13. **[T13]** Callback `onRepeat` en `RecordingPage`
14. **[T14]** Verificación de espacio en disco preemptiva
15. **[T15-T17]** Tests manuales

---

**FIN DEL ANÁLISIS DÍA 3**