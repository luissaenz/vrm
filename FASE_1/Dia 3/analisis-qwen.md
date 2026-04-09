# Análisis Técnico: FASE 1 — Día 3 (Revisión Visual de Clips)

> **Autor**: Qwen
> **Fecha**: 2026-04-08
> **Documento fuente**: `docs/mvp-Definition.md`
> **Alcance**: Widget `ClipReviewScreen` usando `VideoPlayerController.file()` permitiendo repetir el "Take" o continuar al siguiente bloque del Script.

---

## 1. Diseño Funcional

### 1.1 Qué problema resuelve

Después de grabar un fragmento (implementado en Día 1-2), el usuario **no tiene forma de ver lo que grabó** ni de decidir si el take es válido o necesita repetirse. Situación actual del código:

- `_stopRecording()` muestra solo un SnackBar "Clip guardado — 4.2s" y regresa a `RecordingState.idle`.
- `RecordingEndPage` es un stub completo: imagen hardcodeada, botón play sin acción, "42m saved" fake, todos los callbacks son `() {}`.
- El estado `RecordingState.finished` existe en el enum pero **nunca se asigna** en ningún lugar — transición muerta.
- `video_player: ^2.9.1` está en `pubspec.yaml` pero **cero archivos en `lib/` lo importan**.
- No existe ningún archivo con "review" en el nombre.

**Este paso conecta los clips `.mp4` en disco (Día 1-2) con una UI de revisión** que permite: (a) reproducir el clip, (b) decidir "este take sirve → siguiente fragmento" o "no sirve → regrabar".

### 1.2 Pipeline del sistema

```
[Grabar chunk_X] → stop → save clip → [ClipReviewScreen ← ESTE PASO]
                                              │
                        ┌─────────────────────┼──────────────────────┐
                        ▼                     ▼                      ▼
                  "Regrabar"            "Siguiente"             "Terminar"
                  (retake)              (next chunk)            (finish session)
                        │                     │                      │
                        ▼                     ▼                      ▼
                  [Grabar             [Grabar               [RecordingEndPage
                   chunk_X              chunk_X+1]            → Stitch Día 4-5]
                   de nuevo]
```

### 1.3 Inputs

| Input | Origen | Formato |
|---|---|---|
| `projectId` | `RecordingPage` (constructor) | `String` UUID |
| `clipPath` | Ruta del clip recién guardado | `String` absoluto |
| `chunkIndex` | `_activeFragmentIndex` | `int` 0-based |
| `takeNumber` | Take que se acaba de grabar | `int` 1-based |
| `totalChunks` | `widget.analysis.segments.length` | `int` |
| `availableTakes` | Takes existentes para este chunk | `List<int>` |

### 1.4 Outputs

| Output | Destino | Formato |
|---|---|---|
| `ReviewAction.retake` | `RecordingPage` → reinicia countdown del mismo chunk | Enum |
| `ReviewAction.next` | `RecordingPage` → incrementa `_activeFragmentIndex` | Enum |
| `ReviewAction.finish` | `RecordingPage` → `RecordingState.finished` → `RecordingEndPage` | Enum |
| `selectedTake` actualizado | `SessionData.takesPerChunk[chunkIndex]` | En memoria |

---

## 2. Supuestos y Ambigüedades

### 2.1 Detectadas

| # | Ambigüedad | Impacto | Resolución propuesta |
|---|---|---|---|
| A1 | **¿Cuándo aparece la review?** Después de CADA fragmento o solo al FINAL. | Determina el flujo de navegación. | Después de CADA fragmento. El MVP dice "repetir el Take o continuar al siguiente bloque" — implica revisión por-fragmento. |
| A2 | **¿Se muestran TODOS los takes o solo el último?** | Si hay 3 takes del mismo chunk, ¿el usuario puede verlos todos? | Sí, puede ver y comparar todos los takes del chunk. `SessionData.takesPerChunk` ya tiene `selectedTake`. |
| A3 | **¿El usuario puede avanzar sin grabar?** | Si un chunk no tiene takes, ¿se permite saltar? | **No en MVP.** Cada chunk debe tener al menos 1 take antes de avanzar. |
| A4 | **¿Pantalla separada o modal overlay?** | Afecta UX y complejidad de implementación. | **Pantalla separada** (`Navigator.push`). Mayor foco en el video. |
| A5 | **¿`RecordingEndPage` se reemplaza o complementa?** | Es un stub completo. | Se deja para cuando `RecordingState.finished` sea alcanzable. Día 3 no lo modifica. |
| A6 | **¿`VideoPlayerController.file()` funciona con todos los codecs?** | En Android de gama baja, el codec de la cámara puede ser incompatible. | Se asume compatibilidad. Si falla, catch → error UI con "Regrabar". |
| A7 | **¿Cómo vuelve el usuario a RecordingPage?** | Necesita contexto de qué chunk grabar. | `Navigator.pop(ReviewAction)` con resultado. `RecordingPage` reacciona según la acción. |
| A8 | **¿Qué pasa si el usuario presiona back durante review?** | Navegación sin acción explícita. | Equivalente a `retake` — vuelve a grabar el mismo chunk. |

---

## 3. Diseño Técnico

### 3.1 Arquitectura

```
┌─────────────────────────────────────────────────────┐
│              RecordingPage (existente)               │
│  - Después de stopRecording() exitoso               │
│  - Navega a ClipReviewScreen con clipPath           │
└──────────────────────┬──────────────────────────────┘
                       │ push<ReviewAction>
                       ▼
┌─────────────────────────────────────────────────────┐
│              ClipReviewScreen (NUEVO)                │
│  - VideoPlayerController.file(clipPath)             │
│  - Controles: play/pause, seek, time                │
│  - Acciones: "Regrabar", "Siguiente", "Terminar"    │
│  - Selector de takes (si hay >1)                    │
│  - Pop con resultado: ReviewAction                   │
└─────────────────────────────────────────────────────┘
                       │ pop(action)
                       ▼
┌─────────────────────────────────────────────────────┐
│              RecordingPage (resultado)               │
│  - retake  → _startCountdown() mismo chunk          │
│  - next    → _activeFragmentIndex++                 │
│  - finish  → RecordingState.finished                │
│  - null    → idle (equivale a retake)               │
└─────────────────────────────────────────────────────┘
```

### 3.2 Componentes nuevos

#### 3.2.1 `lib/features/recording/models/review_action.dart`

```dart
enum ReviewAction {
  retake,   // El take no sirve, regrabar el mismo chunk
  next,     // El take sirve, avanzar al siguiente chunk
  finish,   // Terminar la sesión completa
}
```

#### 3.2.2 `lib/features/recording/clip_review_screen.dart`

**Constructor:**

```dart
class ClipReviewScreen extends StatefulWidget {
  final String projectId;
  final String clipPath;
  final int chunkIndex;
  final int takeNumber;
  final int totalChunks;
  final List<int> availableTakes;

  const ClipReviewScreen({
    required this.projectId,
    required this.clipPath,
    required this.chunkIndex,
    required this.takeNumber,
    required this.totalChunks,
    this.availableTakes = const [1],
    super.key,
  });
}
```

**Layout:**

```
┌──────────────────────────────────────┐
│  ← Back                    🔄 Takes  │
├──────────────────────────────────────┤
│                                      │
│        ┌──────────────────┐          │
│        │                  │          │
│        │  Video Player    │          │
│        │  (auto-play)     │          │
│        │   ▶ overlay      │          │
│        │                  │          │
│        └──────────────────┘          │
│                                      │
│    [◀◀] ━━━━━━━━━━●━━━━━ [0:04/0:12] │
│                                      │
├──────────────────────────────────────┤
│  Fragmento 2/5  •  Take 3 de 3      │
├──────────────────────────────────────┤
│  [🔄 Regrabar]    [▶ Siguiente]     │
└──────────────────────────────────────┘
```

**Estado interno:**

```dart
class _ClipReviewScreenState extends State<ClipReviewScreen> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  bool _hasError = false;
  int _currentTakeView = -1; // Se settea en initState

  @override
  void initState() {
    super.initState();
    _currentTakeView = widget.takeNumber;
    _initVideo(widget.clipPath);
  }

  Future<void> _initVideo(String path) async {
    _videoController = VideoPlayerController.file(
      File(path),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await _videoController.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _videoController.play(); // Auto-play
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onRetake() => Navigator.of(context).pop(ReviewAction.retake);

  void _onNext() => Navigator.of(context).pop(ReviewAction.next);

  void _onFinish() => Navigator.of(context).pop(ReviewAction.finish);

  /// Carga un take diferente del mismo chunk.
  Future<void> _loadTake(int takeNumber) async {
    await _videoController.dispose();

    final appDir = await getApplicationDocumentsDirectory();
    final newPath = p.join(
      appDir.path,
      'vrm_data',
      'projects',
      widget.projectId,
      'clips',
      'chunk_${widget.chunkIndex}_take_$takeNumber.mp4',
    );

    setState(() {
      _currentTakeView = takeNumber;
      _isInitialized = false;
      _hasError = false;
    });

    await _initVideo(newPath);
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }
}
```

**Selector de takes** (bottom sheet, solo si `availableTakes.length > 1`):

```dart
void _showTakeSelector() {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.availableTakes.map((take) {
          final isSelected = take == _currentTakeView;
          return ListTile(
            leading: Icon(isSelected ? Icons.check_circle : Icons.videocam),
            title: Text('Take $take'),
            trailing: isSelected
                ? Text('${_durationForTake(take)}')
                : null,
            onTap: () {
              Navigator.pop(ctx);
              if (take != _currentTakeView) _loadTake(take);
            },
          );
        }).toList(),
      ),
    ),
  );
}
```

### 3.3 Integración en RecordingPage

Modificar `_stopRecording()` para navegar a la review:

```dart
void _stopRecording() async {
  // ... validación existente ...

  try {
    final clipPath = await _recordingManager!.stopRecording();

    // Validar clip antes de navegar
    final clipFile = File(clipPath);
    if (!await clipFile.exists() || await clipFile.length() == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clip corrupto. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _recordingState = RecordingState.idle;
          _isProcessingRecording = false;
        });
      }
      return;
    }

    // Obtener takes disponibles
    final takes = await _clipStorageService.getTakesForChunk(
      _activeFragmentIndex,
    );
    final currentTake = _recordingManager!.sessionData
        .takesPerChunk[_activeFragmentIndex]?.total ?? 1;

    // Navegar a review
    final action = await Navigator.of(context).push<ReviewAction>(
      MaterialPageRoute(
        builder: (context) => ClipReviewScreen(
          projectId: widget.projectId,
          clipPath: clipPath,
          chunkIndex: _activeFragmentIndex,
          takeNumber: currentTake,
          totalChunks: widget.analysis.segments.length,
          availableTakes: takes,
        ),
      ),
    );

    if (!mounted) return;

    switch (action) {
      case ReviewAction.retake:
      case null:
        // Volver a grabar el mismo chunk
        setState(() {
          _recordingState = RecordingState.idle;
          _isProcessingRecording = false;
        });
        _startCountdown();
        break;

      case ReviewAction.next:
        if (_activeFragmentIndex < widget.analysis.segments.length - 1) {
          setState(() {
            _activeFragmentIndex++;
            _recordingState = RecordingState.idle;
            _isProcessingRecording = false;
          });
        } else {
          // Último chunk completado
          setState(() {
            _recordingState = RecordingState.finished;
            _isProcessingRecording = false;
          });
        }
        break;

      case ReviewAction.finish:
        setState(() {
          _recordingState = RecordingState.finished;
          _isProcessingRecording = false;
        });
        break;
    }
  } catch (e) {
    // ... manejo de error existente ...
  }
}
```

### 3.4 Método nuevo en ClipStorageService

Agregar `getTakesForChunk` a `clip_storage_service.dart`:

```dart
/// Retorna la lista ordenada de take numbers para un chunk.
/// Ej: [1, 2, 3] si existen chunk_0_take_1.mp4, chunk_0_take_2.mp4, etc.
Future<List<int>> getTakesForChunk(int chunkIndex) async {
  final clipsDir = await ensureClipsDirectory();
  if (!await clipsDir.exists()) return [];

  final takes = <int>[];
  final pattern = 'chunk_${chunkIndex}_take_';

  await for (final entity in clipsDir.list()) {
    if (entity is File) {
      final filename = p.basename(entity.path);
      if (filename.startsWith(pattern) && filename.endsWith('.mp4')) {
        final takePart = filename.substring(pattern.length).replaceAll('.mp4', '');
        final takeNum = int.tryParse(takePart);
        if (takeNum != null) takes.add(takeNum);
      }
    }
  }

  takes.sort();
  return takes;
}
```

### 3.5 Edge Cases y Manejo de Errores

| Escenario | Comportamiento |
|---|---|
| **VideoPlayer no puede inicializar el archivo** | Catch en `initialize()` → `_hasError = true` → pantalla de error con "No se pudo reproducir el clip" + botón "Regrabar" |
| **Clip es 0 bytes** | Detectar ANTES de navegar a review → SnackBar "Clip corrupto" + mantener en idle |
| **Usuario presiona back durante review** | `Navigator.pop(null)` → interpretar como `retake` |
| **App va a background durante review** | `VideoPlayerController` pausa automáticamente. Al volver, reanuda. |
| **Archivo se borra entre grabación y review** | `initialize()` lanza excepción → catch → error UI + "Regrabar" |
| **Take selector con 1 solo take** | No mostrar el botón de selector. Solo visible si `availableTakes.length > 1` |
| **Video muy corto (<1s)** | Seek bar funciona pero es poco útil. Sin tratamiento especial. |
| **Usuario toca play/pause mientras video carga** | Ignorar taps hasta `_isInitialized == true`. Mostrar loading spinner. |

---

## 4. Decisiones Tecnológicas

### 4.1 Stack

| Dependencia | Versión | Estado | Justificación |
|---|---|---|---|
| `video_player` | `^2.9.1` | ✅ Ya en pubspec | Oficial Flutter team. Soporta `VideoPlayerController.file()` para archivos locales. Alternativas (`chewie`) son wrappers de UI, no reemplazos. Para el MVP, el player nativo es suficiente. |
| `path` | `^1.9.0` | ✅ Ya en pubspec (Día 1-2) | Necesario para `p.join()` en construcción de paths. |
| `path_provider` | `^2.1.3` | ✅ Ya en pubspec | Para `getApplicationDocumentsDirectory()`. |

### 4.2 Decisiones de Diseño

| Decisión | Valor | Justificación |
|---|---|---|
| **Pantalla separada vs overlay** | Pantalla separada (`Navigator.push`) | Mayor foco en el video. Overlay complica interacción con reproductor + botones en espacio reducido. |
| **Auto-play al entrar** | Sí | El usuario acaba de grabar — quiere ver inmediatamente. Reducir fricción. |
| **Seek bar** | `Slider` custom con `VideoPlayerController.value.position` | `video_player` no trae widget de seek. Se construye con bindings a `Duration`. |
| **Selector de takes** | Modal bottom sheet | No ocupar espacio permanente. Solo mostrar si hay >1 take. |
| **Conservar todos los takes** | Sí, no borrar anteriores | Usuario puede comparar. Storage: ~5-8MB por take de 10s. |
| **Back = retake** | Sí | Si el usuario sale sin decidir, asume que el take no fue satisfactorio. |
| **Avanzar sin grabar** | No permitido | Cada chunk necesita al menos 1 take confirmado. |

### 4.3 Lo que NO se implementa en Día 3

| Item | Por qué posponer |
|---|---|
| RecordingEndPage con datos reales | Requiere iterar sobre todos los chunks grabados. Se activa cuando `RecordingState.finished` sea alcanzable. |
| Trimming / recorte del clip | Día 4-5 con ffmpeg. Review solo reproduce el clip completo. |
| Comparación side-by-side de takes | UI compleja. Para MVP, el usuario ve un take a la vez. |
| Persistencia de `session_data.json` | Día 7-8. Ahora vive en memoria. |

---

## 5. Riesgos

### 5.1 Técnicos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| **VideoPlayer no reproduce el codec de la cámara** | Media | 🔴 Alto | Catch en `initialize()` → error UI con "Regrabar". Si ocurre en dispositivo específico, documentar como known issue. |
| **Memory leak por VideoPlayerController no disposed** | Media | 🔴 Alto | `dispose()` obligatorio. Al cambiar de take, disposed el viejo antes de crear el nuevo. |
| **Video no carga (archivo corrupto)** | Baja | 🟡 Medio | Detección de 0 bytes antes de navegar. Si corrupto, `initialize()` lanza excepción → catch → error UI. |
| **Auto-play no funciona en algún dispositivo** | Baja | 🟢 Bajo | Fallback: botón play grande visible. Usuario toca manualmente. |

### 5.2 Operativos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| **Usuario no entiende la review** | Puede confundir con producto final. | Copy claro: "Fragmento 2/5 — Take 3". Contexto siempre visible. |
| **Navegación confusa retake/next** | Usuario no sabe cuál elegir. | Labels: "🔄 Regrabar" vs "▶ Siguiente". Colores diferenciados. |

### 5.3 Escalabilidad

| Problema futuro | Cuándo | Prep ahora |
|---|---|---|
| **Múltiples takes × muchos chunks = storage** | 10 chunks × 5 takes ≈ 400MB | Estructura ya diseñada para selección. Cleanup automático después. |
| **VideoPlayer con clips largos (>2min)** | Si chunk tiene mucho texto | `video_player` maneja cualquier duración sin problema. |

---

## 6. Plan de Implementación

### 6.1 Backlog de Tareas

#### T1: Crear modelo `ReviewAction`
- **Archivo**: `lib/features/recording/models/review_action.dart`
- [ ] Enum `ReviewAction { retake, next, finish }`
- **Estimación**: 5 min
- **Dependencia**: Ninguna

#### T2: Agregar `getTakesForChunk` a `ClipStorageService`
- **Archivo**: `lib/features/recording/services/clip_storage_service.dart`
- [ ] Escanear directorio clips/, retornar `List<int>` ordenado
- [ ] Unit test: crear 3 archivos fake → verificar `[1, 2, 3]`
- **Estimación**: 15 min
- **Dependencia**: Ninguna

#### T3: Crear `ClipReviewScreen`
- **Archivo**: `lib/features/recording/clip_review_screen.dart`
- [ ] Constructor con todos los parámetros
- [ ] `VideoPlayerController.file()` con auto-play
- [ ] Loading state mientras inicializa
- [ ] Error state si no puede reproducir
- [ ] Video player:
  - [ ] Play/pause al tocar el video
  - [ ] Seek bar con `Slider` + position/duration
  - [ ] Time display (elapsed / total)
- [ ] Context info: "Fragmento X/Y — Take Z de N"
- [ ] Botón "🔄 Regrabar" → `pop(retake)`
- [ ] Botón "▶ Siguiente" → `pop(next)` (si último chunk → "Terminar" → `pop(finish)`)
- [ ] Selector de takes (bottom sheet) si `availableTakes.length > 1`
  - [ ] Al seleccionar → dispose → nuevo controller → initialize → play
- [ ] Back → `pop(null)` (interpreta como retake)
- [ ] `dispose()` → `_videoController.dispose()`
- **Estimación**: 2 horas
- **Dependencia**: T1

#### T4: Integrar navegación en `RecordingPage._stopRecording()`
- **Archivo**: `lib/features/recording/recording_page.dart`
- [ ] Después de `stopRecording()` exitoso → `push<ReviewAction>` a `ClipReviewScreen`
- [ ] Validar clip (existe y length > 0) antes de navegar
- [ ] Handle resultado:
  - [ ] `retake` / `null` → `_startCountdown()` mismo chunk
  - [ ] `next` → `_activeFragmentIndex++` o `RecordingState.finished`
  - [ ] `finish` → `RecordingState.finished`
- **Estimación**: 30 min
- **Dependencia**: T1, T2, T3

#### T5: Test en dispositivo físico
- [ ] Grabar 1 fragmento → review aparece → video se reproduce
- [ ] Touch play/pause funciona
- [ ] Seek bar funciona
- [ ] "Regrabar" → vuelve a grabar mismo chunk → review muestra nuevo take
- [ ] "Siguiente" → avanza al siguiente fragmento
- [ ] Si hay 2+ takes → selector muestra todos → puede ver cada uno
- [ ] Back button → vuelve a grabar
- [ ] Error de video → muestra error con opción de regrabar
- **Estimación**: 45 min
- **Dependencia**: T4

### 6.2 Dependencias y Orden

```
T1 ──┐
     ├── T3 ──────┬── T4 ──┬── T5
T2 ──┘            │        │
                  └────────┘

Ruta crítica: T1 → T3 → T4 → T5
Paralelizable: T2 con T1/T3
```

### 6.3 Definition of Done

- [ ] Después de cada grabación, aparece la pantalla de review con el clip reproduciéndose
- [ ] Play/pause al tocar el video funciona
- [ ] Seek bar permite mover el video a cualquier punto
- [ ] "Regrabar" lleva de vuelta a la cámara para grabar el mismo chunk
- [ ] "Siguiente" avanza al próximo fragmento
- [ ] Si hay múltiples takes, el selector permite ver cada uno
- [ ] Si el video no se puede reproducir, muestra error con opción de regrabar
- [ ] 0 crashes en 10 ciclos de: grabar → review → regrabar → review
- [ ] `RecordingState.finished` se alcanza al completar el último chunk
