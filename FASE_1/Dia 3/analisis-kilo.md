# 🧠 ANÁLISIS TÉCNICO - DÍA 3: Clip Review Screen

**Agente:** kilo  
**Fecha:** 9 de abril de 2026  
**Fase:** FASE 1 - Core de Grabación (Día 3 de 21)  
**Objetivo del Día:** Implementar `ClipReviewScreen` que permita al usuario reproducir, evaluar y decidir sobre cada clip grabado antes de avanzar al siguiente fragmento.

---

## 1. ANATOMÍA DE COMPONENTES

### 1.1 Widget Principal: `ClipReviewPage`

**Archivo destino:** `lib/features/recording/widgets/clip_review_page.dart` (nuevo)

| Atributo | Detalle |
|----------|---------|
| **Inputs/Props** | `clipPath` (String - ruta absoluta del archivo .mp4), `chunkIndex` (int - índice del fragmento 0-based), `totalChunks` (int - total de fragmentos del guion), `takeNumber` (int - número de intento), `onAccept` (VoidCallback - callback al aprobar), `onReject` (VoidCallback - callback al rechazar/repetir) |
| **Outputs/Events** | Dispara `onAccept()` → avanza al siguiente fragmento. Dispara `onReject()` → vuelve a grabar el mismo fragmento. |
| **Estado Interno** | `isPlaying` (bool), `isMuted` (bool - default true), `videoDuration` (Duration), `videoPosition` (Duration), `isLooping` (bool - default true), `isVideoInitialized` (bool), `isLoading` (bool) |
| **Persistencia** | Ninguna. Es una pantalla efímera de revisión. |

**Dependencias externas:**
- `video_player` package (`VideoPlayerController`, `VideoPlayer`)
- `camera_service.dart` (para acceder al clip grabado)
- `session_data.dart` (para contexto de sesión)

---

### 1.2 Sub-widgets necesarios

#### 1.2.1 `VideoReviewArea`

**Archivo:** embebido en `clip_review_page.dart` (widget privado `_VideoReviewArea`)

| Atributo | Detalle |
|----------|---------|
| **Inputs** | `controller` (VideoPlayerController), `onInitialized` (Callback), `onError` (Callback<String>) |
| **Responsabilidad** | Envolver `VideoPlayer` con manejo de errores, placeholder mientras carga, y aspect ratio correcto (16:9 o 9:16) |

#### 1.2.2 `ReviewControlsBar`

**Archivo:** embebido en `clip_review_page.dart` (widget privado `_ReviewControlsBar`)

| Atributo | Detalle |
|----------|---------|
| **Inputs** | `isPlaying` (bool), `onPlayPause` (VoidCallback), `onMuteToggle` (VoidCallback), `isMuted` (bool), `position` (Duration), `duration` (Duration), `onSeek` (ValueChanged<double>) |
| **Responsabilidad** | Barra inferior con: ▶/⏸ (play/pause), 🔇/🔊 (mute/unmute), scrubber/slider de progreso |

#### 1.2.3 `DecisionButtonsRow`

**Archivo:** embebido en `clip_review_page.dart` (widget privado `_DecisionButtonsRow`)

| Atributo | Detalle |
|----------|---------|
| **Inputs** | `onAccept` (VoidCallback), `onReject` (VoidCallback), `chunkIndex` (int), `totalChunks` (int), `takeNumber` (int) |
| **Responsabilidad** | Dos botones flotantes grandes: 🗑️ "Repetir" (rojo, izquierda) y ✅ "Siguiente" (verde, derecha) |

---

### 1.3 Modificación a `RecordingManager`

**Archivo existente:** `lib/features/recording/services/recording_manager.dart`

| Cambio | Detalle |
|--------|---------|
| **Nuevo método** | `String? getCurrentClipPath()` → retorna la ruta del último clip grabado para el fragmento actual |
| **Nuevo método** | `void acceptCurrentClip()` → marca el clip actual como aprobado y avanza al siguiente fragmento |
| **Nuevo método** | `Future<void> rejectCurrentClip()` → elimina el archivo físico del clip rechazado y permite re-grabación |

---

### 1.4 Modificación a `RecordingPage`

**Archivo existente:** `lib/features/recording/recording_page.dart`

| Cambio | Detalle |
|--------|---------|
| **Nuevo estado** | Agregar `reviewing` al enum `RecordingState` |
| **Nueva navegación** | Después de `stopRecording()`, navegar a `ClipReviewPage` en vez de volver a idle |
| **Callback onAccept** | Al aceptar, cerrar `ClipReviewPage`, incrementar `currentChunk`, preparar siguiente fragmento |
| **Callback onReject** | Al rechazar, cerrar `ClipReviewPage`, llamar `rejectCurrentClip()`, reiniciar grabación del mismo fragmento |

---

## 2. MAPA DE CONCURRENCIA Y LIFECYCLE

### 2.1 Flujos Asíncronos

```
┌──────────────────────────────────────────────────────────────────┐
│                    FLUJO DE GRABACIÓN → REVISIÓN                 │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [RecordingPage]                                                 │
│       │                                                          │
│       │ 1. Usuario graba fragmento                               │
│       ▼                                                          │
│  [grabando...]                                                   │
│       │                                                          │
│       │ 2. Usuario detiene grabación                            │
│       ▼                                                          │
│  RecordingManager.stopRecording()                                │
│       │    - CameraController.stopRecording() → XFile            │
│       │    - ClipStorageService.saveClip() → archivo .mp4        │
│       │    - SessionData actualizado                             │
│       ▼                                                          │
│  Navigator.push(ClipReviewPage(...))                             │
│       │                                                          │
│       │ 3. ClipReviewPage.initState()                            │
│       │    - VideoPlayerController.file(File(clipPath))          │
│       │    - controller.initialize()  ← ASYNC CRÍTICO           │
│       │    - controller.setLooping(true)                         │
│       │    - controller.play() (muted)                           │
│       ▼                                                          │
│  [Video reproduciéndose en loop]                                 │
│       │                                                          │
│       │ 4a. Usuario toca "✅ Siguiente"                          │
│       ▼                                                          │
│  onAccept() → RecordingManager.acceptCurrentClip()               │
│       │    - SessionData.currentChunk++                          │
│       │    - Navigator.pop() → vuelve a RecordingPage            │
│       ▼                                                          │
│  [RecordingPage - Fragmento N+1 listo]                           │
│                                                                  │
│       │ 4b. Usuario toca "🗑️ Repetir"                            │
│       ▼                                                          │
│  onReject() → RecordingManager.rejectCurrentClip()               │
│       │    - File(clipPath).delete()  ← ASYNC I/O               │
│       │    - Navigator.pop() → vuelve a RecordingPage            │
│       │    - Mismo chunkIndex, reiniciar grabación               │
│       ▼                                                          │
│  [RecordingPage - Mismo fragmento, nuevo take]                   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Zonas Rojas de Condición de Carrera

| Zona | Riesgo | Estrategia |
|------|--------|------------|
| **ZONA 1: `VideoPlayerController.initialize()`** | Si el archivo está corrupto o no existe, `initialize()` lanza excepción. El widget queda en estado de error infinito. | Try/catch en `_initializeVideo()`. Si falla, mostrar pantalla de error con botón "Repetir grabación". |
| **ZONA 2: `File.delete()` en reject** | Si el archivo ya fue borrado o el dispositivo se queda sin espacio, `delete()` falla. | Verificar `file.existsSync()` antes de borrar. Envolver en try/catch. Loggear pero continuar flujo. |
| **ZONA 3: Navegación durante inicialización** | Usuario presiona back mientras video se inicializa, controller puede quedar con leak. | En `dispose()`, llamar `controller.dispose()`. Usar `mounted` checks en setState. |
| **ZONA 4: Seek durante reproducción** | Usuario arrastra scrubber mientras video reproduce, puede causar glitches. | Pausar video durante seek, reanudar después de seek completo. |

### 2.3 Estrategia de Limpieza (`dispose`)

```dart
@override
void dispose() {
  // 1. Detener reproducción si está activa
  if (_controller.value.isPlaying) {
    _controller.pause();
  }
  
  // 2. Cancelar timer de actualización de posición
  _positionTimer?.cancel();
  
  // 3. Dispose del controller (libera buffers de video)
  _controller.dispose();
  
  super.dispose();
}
```

---

## 3. PROTOCOLOS DE ERROR Y RESILIENCIA

### 3.1 Interacciones con FileSystem (I/O de Video)

| Escenario | Qué ve el usuario | Acción del sistema |
|-----------|-------------------|-------------------|
| **Clip se grabó correctamente** | Video reproduce en loop muted. Controles y botones visibles. | Flujo normal. |
| **Archivo de clip no existe** | Pantalla de error: "No se encontró el clip grabado". Botón "🔁 Repetir grabación". | Log del error. Forzar re-grabación del mismo fragmento. |
| **Archivo corrupto (dañado)** | Video muestra frame negro o error. Mensaje: "El clip está dañado". Botón "🔁 Repetir". | Log con detalles. Intentar delete del archivo corrupto. |
| **Sin espacio para inicializar video** | Error genérico: "Error al cargar video". | Verificar espacio disponible antes de mostrar review. |
| **Delete falla en reject** | Silencioso. El flujo continúa (archivo huérfano se limpia después). | Log del error. No bloquear al usuario. |

### 3.2 Casos de "Limbo" (App se cierra durante operación)

| Momento del cierre | Consecuencia | Recuperación |
|--------------------|--------------|--------------|
| **Durante `VideoPlayerController.initialize()`** | Archivo existe en disco. Estado de revisión perdido. | Al reabrir, `RecordingManager` detecta clip sin aprobar. Ofrece "¿Revisar último clip grabado?" |
| **Durante `File.delete()` en reject** | Archivo puede quedar o irse. | Idempotente: si existe, se borra al reintentar. Si no existe, se ignora. |
| **Usuario cierra app en revisión** | Clip queda en estado "pendiente de aprobación". | Al reanudar, mostrar `ClipReviewPage` directamente con el clip pendiente. |

### 3.3 Manejo de Permisos

| Permiso | Estado | Acción |
|---------|--------|--------|
| **Storage (lectura)** | Necesario para leer el archivo .mp4. | Ya solicitado en `RecordingPage`. Si denegado, no se puede mostrar review. |
| **Storage (escritura)** | Necesario para delete en reject. | Mismo manejo. |

---

## 4. DISEÑO TÉCNICO NOMINATIVO

### 4.1 Archivos y Clases

| Archivo | Clase/Tipo | Responsabilidad |
|---------|-----------|-----------------|
| `lib/features/recording/widgets/clip_review_page.dart` | `ClipReviewPage` (StatelessWidget) | Wrapper que recibe props y crea state |
| `lib/features/recording/widgets/clip_review_page.dart` | `_ClipReviewPageState` (State) | Manejo completo del estado, controller y UI |
| `lib/features/recording/widgets/clip_review_page.dart` | `_VideoReviewArea` (StatelessWidget) | Área de video con aspect ratio y placeholder |
| `lib/features/recording/widgets/clip_review_page.dart` | `_ReviewControlsBar` (StatelessWidget) | Controles de reproducción y scrubber |
| `lib/features/recording/widgets/clip_review_page.dart` | `_DecisionButtonsRow` (StatelessWidget) | Botones de decisión flotantes |
| `lib/features/recording/widgets/clip_review_page.dart` | `_ErrorScreen` (StatelessWidget) | Pantalla de error cuando video no carga |
| `lib/features/recording/services/recording_manager.dart` | `RecordingManager` (existente) | Agregar métodos `getCurrentClipPath()`, `acceptCurrentClip()`, `rejectCurrentClip()` |
| `lib/features/recording/models/session_data.dart` | `SessionData` (existente) | Agregar tracking de clips aprobados/rechazados |

### 4.2 Métodos de `RecordingManager`

```dart
// recording_manager.dart - métodos nuevos

/// Retorna la ruta del último clip grabado para el fragmento actual.
String? getCurrentClipPath() {
  final currentChunk = sessionData.currentChunk;
  final takeInfo = sessionData.takesPerChunk[currentChunk];
  if (takeInfo == null) return null;
  
  return '${_storage.getClipDirectory(currentChunk)}/chunk_${currentChunk}_take_${takeInfo.selectedTake}.mp4';
}

/// Marca el clip actual como aprobado y avanza al siguiente fragmento.
void acceptCurrentClip() {
  final chunkIndex = sessionData.currentChunk;
  sessionData = sessionData.copyWith(
    currentChunk: chunkIndex + 1,
    lastUpdatedAt: DateTime.now(),
  );
  _saveSessionData();
}

/// Rechaza el clip actual: mantiene el chunkIndex para re-grabación.
/// El archivo se borra desde ClipReviewPage para mejor UX.
void rejectCurrentClip() {
  // Solo actualiza estado lógico, archivo se borra en UI
  sessionData = sessionData.copyWith(
    lastUpdatedAt: DateTime.now(),
  );
  _saveSessionData();
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
  final VoidCallback onReject;

  const ClipReviewPage({
    super.key,
    required this.clipPath,
    required this.chunkIndex,
    required this.totalChunks,
    required this.takeNumber,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _ClipReviewPageState(
        clipPath: clipPath,
        chunkIndex: chunkIndex,
        totalChunks: totalChunks,
        takeNumber: takeNumber,
        onAccept: onAccept,
        onReject: onReject,
      ),
    );
  }
}

class _ClipReviewPageState extends State<ClipReviewPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = true;
  bool _isMuted = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
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
      _controller.setVolume(0.0); // muted por defecto
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _duration = _controller.value.duration;
        });
        _controller.play();
        _startPositionTracking();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  // ... resto de implementación
}
```

---

## 5. PLAN DE IMPLEMENTACIÓN ATÓMICO

Cada tarea está diseñada para no exceder ~50 líneas de código real.

| # | Tarea | Archivo | Líneas estimadas | Dependencias |
|---|-------|---------|-----------------|--------------|
| **1** | Actualizar `RecordingState` enum con `reviewing` | `lib/features/recording/models/recording_state.dart` | ~5 | Ninguna |
| **2** | Agregar métodos `getCurrentClipPath()`, `acceptCurrentClip()`, `rejectCurrentClip()` a `RecordingManager` | `lib/features/recording/services/recording_manager.dart` | ~40 | Tarea 1 |
| **3** | Crear `ClipReviewPage` skeleton con props y estructura básica | `lib/features/recording/widgets/clip_review_page.dart` | ~50 | Tarea 2 |
| **4** | Implementar `_initializeVideo()` y manejo de `VideoPlayerController` | `clip_review_page.dart` | ~45 | Tarea 3 |
| **5** | Crear `_VideoReviewArea` widget con placeholder y error handling | `clip_review_page.dart` | ~35 | Tarea 4 |
| **6** | Crear `_ReviewControlsBar` con play/pause, mute, scrubber | `clip_review_page.dart` | ~50 | Tarea 4 |
| **7** | Crear `_DecisionButtonsRow` con botones flotantes | `clip_review_page.dart` | ~40 | Tarea 4 |
| **8** | Crear `_ErrorScreen` para casos de error | `clip_review_page.dart` | ~30 | Tarea 4 |
| **9** | Implementar navegación en `RecordingPage`: push `ClipReviewPage` después de grabar | `lib/features/recording/recording_page.dart` | ~35 | Tarea 3 |
| **10** | Implementar callbacks `onAccept` y `onReject` en `RecordingPage` | `lib/features/recording/recording_page.dart` | ~30 | Tarea 9 |
| **11** | Implementar `dispose()` y limpieza de recursos en `ClipReviewPage` | `clip_review_page.dart` | ~25 | Tarea 4 |
| **12** | Agregar verificación de existencia de archivo antes de mostrar review | `lib/features/recording/services/recording_manager.dart` | ~15 | Tarea 2 |
| **13** | Test manual: grabar → revisar → aceptar → siguiente fragmento | - | - | Tareas 1-12 |
| **14** | Test manual: grabar → revisar → rechazar → re-grabar mismo fragmento | - | - | Tareas 1-12 |
| **15** | Test de error: simular archivo inexistente y verificar error screen | - | - | Tarea 8 |

**Total estimado:** ~440 líneas de código nuevo + ~80 de modificación.

---

## DECISIONES TÉCNICAS

### D1: ¿Por qué `VideoPlayerController.file()` en vez de `asset()` o `network()`?
El clip es un archivo local persistente en el filesystem del dispositivo. `file()` permite acceso directo al `File` para operaciones como verificación de existencia y eliminación. Es la única opción viable para archivos locales offline.

### D2: ¿Por qué muted por defecto?
El usuario está evaluando el clip visualmente para decidir si acepta o repite. El audio puede distraer durante esta evaluación rápida. El usuario puede activar audio si necesita revisar dicción específica.

### D3: ¿Por qué looping automático?
Permite evaluación continua sin acciones manuales. El usuario puede pausar o hacer scrub si necesita revisar secciones específicas, pero por defecto reproduce continuamente.

### D4: ¿Por qué borrar archivo en reject desde la UI?
Mejor UX: el usuario ve feedback inmediato al tocar "Repetir". Borrar desde `RecordingManager.rejectCurrentClip()` sería asíncrono y podría causar delay en la navegación.

### D5: ¿Por qué `acceptCurrentClip()` no borra archivos?
Los clips aprobados se conservan para el proceso de stitching en fases posteriores. Solo los rechazados se eliminan inmediatamente para ahorrar espacio.

---

## RIESGOS IDENTIFICADOS

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| **`VideoPlayerController.initialize()` tarda > 3 segundos en clips largos** | Media | 🟡 Medio | Mostrar spinner durante inicialización. Si > 5s, mostrar error y opción de retry. |
| **Archivo corrupto por grabación interrumpida** | Baja | 🔴 Alto | Verificar existencia y intentar inicializar. Si falla, mostrar error screen con opción de repetir. |
| **Memory leak si dispose no se ejecuta correctamente** | Baja | 🔴 Alto | Try/catch en dispose. Verificar con DevTools. Usar `mounted` checks. |
| **Seek del scrubber interfiere con reproducción** | Alta | 🟡 Medio | Pausar video durante drag del slider, reanudar al soltar. |
| **Aspect ratio del video no coincide con pantalla** | Alta | 🟡 Medio | Usar `AspectRatio` widget con ratio calculado del video. |
| **Usuario presiona back durante inicialización** | Media | 🟡 Medio | Manejar `WillPopScope` para prevenir navegación hasta que video esté listo. |

---

## TRAMPAS ASÍNCRONAS A EVITAR

### Trampa 1: setState después de dispose
```dart
// ❌ MAL
await _controller.initialize();
setState(() { _isInitialized = true; }); // Crash si usuario cerró página

// ✅ BIEN
await _controller.initialize();
if (mounted) {
  setState(() { _isInitialized = true; });
}
```

### Trampa 2: No esperar dispose del controller
```dart
// ❌ MAL
dispose() {
  _controller.dispose(); // No await
  super.dispose();
}

// ✅ BIEN
@override
void dispose() {
  _controller.dispose(); // VideoPlayerController.dispose() es síncrono
  _positionTimer?.cancel();
  super.dispose();
}
```

### Trampa 3: Timer sin cancel en dispose
```dart
// ❌ MAL
_positionTimer = Timer.periodic(..., (_) {
  setState(...);
});

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
│     FRAGMENTO 3 / 8                 │  ← Header con progreso
├─────────────────────────────────────┤
│                                     │
│         ┌───────────────┐           │
│         │               │           │
│         │   VIDEO EN    │           │  ← Área de video (70% altura)
│         │   LOOP        │           │
│         │   (muted)     │           │
│         └───────────────┘           │
│                                     │
│    ◀❚❚▶    🔇     ▬▬▬●▬▬▬▬         │  ← Control bar
│                                     │
│  TAKE 2                             │  ← Info del take
├─────────────────────────────────────┤
│                                     │
│   🗑️ REPETIR      ✅ SIGUIENTE      │  ← Decision buttons
│   (rojo)          (verde)           │
│                                     │
└─────────────────────────────────────┘
```

### Estados visuales

| Estado | Visual |
|--------|--------|
| Loading (inicializando) | Spinner centrado + "Cargando clip..." |
| Error (archivo no existe) | ⚠️ "No se encontró el clip" + botón "🔁 Repetir grabación" |
| Reproduciendo | Video en loop, controles activos |
| Pausado | ▶ grande semi-transparente sobre video |
| Muted | 🔇 en control bar |
| Unmuted | 🔊 en control bar |

---

## BACKLOG ORDENADO PARA IMPLEMENTADOR

1. **[T1]** Actualizar `RecordingState` con `reviewing`
2. **[T2]** Agregar métodos de gestión de clips a `RecordingManager`
3. **[T3]** Crear skeleton de `ClipReviewPage`
4. **[T4]** Implementar inicialización del video player
5. **[T5]** Crear área de video con error handling
6. **[T6]** Crear barra de controles (play/pause, mute, scrubber)
7. **[T7]** Crear botones de decisión
8. **[T8]** Crear pantalla de error
9. **[T9]** Integrar navegación en `RecordingPage`
10. **[T10]** Implementar callbacks de aceptación/rechazo
11. **[T11]** Implementar dispose y limpieza
12. **[T12]** Agregar verificación de archivos
13. **[T13-T15]** Tests manuales

---

**FIN DEL ANÁLISIS DÍA 3**