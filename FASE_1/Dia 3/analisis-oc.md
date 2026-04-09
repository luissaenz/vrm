# 🧠 ANÁLISIS TÉCNICO: REVISIÓN DE CLIPS (Día 3 - Agente OC)

## 📋 Perfil del Rol
**Agente:** OC (Principal Systems Architect)  
**Objetivo:** Análisis técnico de la pantalla de revisión visual post-grabación para validar la calidad de cada fragmento antes de proceder.  
**Alcance:** Funcionalidades F7.1 - F7.6 (Revisión y Aprobación de Fragmentos)

---

## 🏗️ 1. Anatomía de Componentes

### 1.1 ClipReviewPage (Widget Principal)

#### Inputs/Props
| Prop | Tipo | Requerido | Descripción |
|------|------|-----------|-------------|
| `videoFile` | File | Sí | Archivo `.mp4` recién grabado |
| `segmentIndex` | int | Sí | Índice del fragmento actual (0-based) |
| `totalSegments` | int | Sí | Total de fragmentos en el guion |
| `segmentText` | String | Sí | Texto del guion correspondiente al fragmento |
| `projectId` | String | Sí | ID del proyecto para persistencia |
| `takeNumber` | int | Sí | Número de intento actual |
| `onKeep` | VoidCallback | Sí | Callback cuando usuario acepta el clip |
| `onRetry` | VoidCallback | Sí | Callback cuando usuario rechaza el clip |

#### Outputs/Events
- **`onKeep()`**: Navega al siguiente fragmento o a `RecordingEndPage` si es el último
- **`onRetry()`**: Elimina archivo actual y vuelve a `RecordingPage` para re-grabar

#### Estado Interno
```dart
VideoPlayerController? _controller;  // Control del stream de video
bool _isInitialized = false;          // UI: spinner vs video
bool _isPlaying = true;              // Estado del botón play/pause
bool _isMuted = true;                 // F7.4: Silenciado por defecto
int _autoAcceptCountdown = 3;         // F7.3: Contador de aprobación pasiva
Timer? _autoAcceptTimer;              // Timer para aprobación pasiva
double _currentPosition = 0.0;       // Posición actual del video
```

### 1.2 Componentes Hijos

#### ClipVideoPlayer
- Widget que envuelve `VideoPlayer` 
- Maneja loop automático (F7.1)
- Responde a mute/unmute (F7.4)
- Aspect ratio: 9:16 (vertical) o detectado del video

#### ReviewOverlay
- Muestra texto del guion sobre el video (opcional, toggle)
- Indicador de progreso: "FRAGMENTO 3/8"
- Contador de takes: "Take 2/3"

#### DecisionButtons
- **Botón Repetir** (rojo, 🗑️): Descarta y vuelve a grabar
- **Botón Siguiente** (verde, ✅): Acepta y avanza
- Posición: flotantes sobre el video, esquinas inferiores

#### AutoAcceptProgressBar (F7.3 - MVP+)
- Barra de progreso horizontal
- Visible solo cuando el video está en loop
- 3 segundos para decisión pasiva
- Texto: "Aceptando en..."

---

## 🔄 2. Mapa de Concurrencia y Lifecycle

### 2.1 Estados del Widget

```
[initState]
     │
     ▼
[Loading Video] ──(error)──> [Error State]
     │                        │
     ▼                        ▼
[Video Ready] ──(user action)──> [User Decision]
     │                        │
     ▼                        ▼
[Auto-Loop Playback]          [Navigate Out]
     │
     ├──(onKeep)──────────────> [RecordingPage/Siguiente]
     │
     └──(onRetry)─────────────> [RecordingPage/Regrabar]
```

### 2.2 Zonas Rojas (Condiciones de Carrera)

| Zona | Problema | Estrategia |
|------|----------|------------|
| **Inicialización** | `_controller.initialize()` es async. Si usuario sale antes, puede quedar "Zombie Controller" | Verificar `mounted` en callbacks async; llamar `dispose()` inmediatamente en `didChangeAppLifecycleState` |
| **Archivo en Disco** | El video puede estar escribiéndose cuando intentamos cargarlo | Implementar retry con delay de 500ms si falla `initialize()` |
| **Aprobación Pasiva** | Timer puede ejecutarse después de que usuario actúa | Cancelar timer en `onKeep()` y `onRetry()` antes de navegar |
| **Navigación During Loop** | Al navegar, el video puede seguir reproduciéndose | Detener controller en `dispose()` y limpiar timer |

### 2.3 Ciclo de Vida (Lifecycle)

```dart
@override
void initState() {
  super.initState();
  _initializeVideo();      // Cargar video async
  _startAutoAcceptTimer(); // F7.3: Iniciar cuenta regresiva
}

@override
void dispose() {
  _autoAcceptTimer?.cancel();  // Limpiar timer
  _controller?.dispose();      // Liberar recursos video
  super.dispose();
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    _controller?.pause();       // Pausar video si app va a background
  } else if (state == AppLifecycleState.resumed) {
    if (_isPlaying) _controller?.play();
  }
}
```

---

## 🛡️ 3. Protocolos de Error y Resiliencia

### 3.1 Caso: Video Corrupto o No Encontrado

```
SI VideoPlayerController.initialize() LANZA error:
  ├── Mostrar tarjeta de error con ícono de alerta
  ├── Mensaje: "No se pudo cargar la previsualización"
  ├── Botón "Grabar de nuevo" → onRetry()
  └── Botón "Volver al menú" → Navigator.pop()
```

### 3.2 Caso: Cierre de App Durante Revisión

```
El clip ya está persistido en disco por RecordingManager.
Al reabrir proyecto:
  ├── RecordingManager.detectarClipsHuérfanos()
  ├── Mostrar modal: "Se encontró un clip sin revisar"
  └── Opciones: "Revisar" | "Descartar"
```

### 3.3 Caso: Fallo de Persistencia en Aprobación

```
SI onKeep() FALLA al actualizar SessionData:
  ├── Reintentar hasta 3 veces con exponential backoff
  ├── Si falla: guardar en cola de "pendingSync"
  ├── Mostrar SnackBar: "Guardando..."
  └── Permitir navegación de todas formas (datos no críticos)
```

### 3.4 Persistencia de Decisiones

| Decisión | Donde se guarda | Cuándo |
|----------|-----------------|--------|
| Clip aceptado | `SessionData.takesPerChunk[chunkIndex].selectedTake` | Inmediato en `onKeep()` |
| Clip rechazado | No se guarda (archivo se elimina) | En `onRetry()` |
| Contador takes | `SessionData.takesPerChunk[chunkIndex].total` | En `RecordingManager.stopRecording()` |

---

## 📝 4. Diseño Técnico Nominativo

### 4.1 Archivos y Clases

| Archivo | Clase | Responsabilidad |
|---------|-------|-----------------|
| `lib/features/recording/clip_review_page.dart` | `ClipReviewPage` | Pantalla principal de revisión |
| `lib/features/recording/widgets/clip_video_player.dart` | `ClipVideoPlayer` | Widget de reproducción con loop |
| `lib/features/recording/widgets/decision_buttons.dart` | `DecisionButtons` | Botones Repetir/Siguiente |
| `lib/features/recording/widgets/review_overlay.dart` | `ReviewOverlay` | Overlay con texto y progreso |
| `lib/features/recording/widgets/auto_accept_bar.dart` | `AutoAcceptProgressBar` | Barra de aprobación pasiva |

### 4.2 Métodos Principales

```dart
// ClipReviewPage
Future<void> _initializeVideo() async;
void _togglePlayPause();
void _toggleMute();
void _handleKeep() async;  // F7.2: Aceptar clip
void _handleRetry() async; // F7.2: Repetir clip
void _startAutoAcceptTimer(); // F7.3: Aprobación pasiva
void _cancelAutoAcceptTimer();

// ClipVideoPlayer  
void setLooping(bool looping); // F7.1
void setMuted(bool muted);      // F7.4

// DecisionButtons
void onKeepPressed();
void onRetryPressed();
```

### 4.3 Modelo de Datos

```dart
// Extensión de SessionData existente
class ReviewDecision {
  final int chunkIndex;
  final bool accepted;
  final int takeNumber;
  final DateTime reviewedAt;
  
  Map<String, dynamic> toJson() => {...};
}
```

---

## 🎯 5. Diseño para la Salida (Pilares)

### 5.1 Diseño Funcional

| Feature | Implementación |
|---------|-----------------|
| **F7.1 Loop Automático** | VideoPlayer con `setLooping(true)`. Se reproduce automáticamente al cargar |
| **F7.2 Botones de Decisión** | Dos botones flotantes: 🗑️ Repetir (rojo) y ✅ Siguiente (verde) |
| **F7.3 Aprobación Pasiva** | Timer de 3 segundos. Barra de progreso decreciente. Cancelar al interactuar |
| **F7.4 Silenciado por Defecto** | `_isMuted = true` inicial. Icono de speaker para toggle |
| **F7.5 Contador de Takes** | Mostrar "Take X/Y" en overlay, donde Y viene de SessionData |
| **F7.6 Transición Suave** | Usar `PageRouteBuilder` con `SlideTransition` al navegar |

### 5.2 Diseño Técnico

- **Video Player**: Usar `video_player` nativo (no Chewie) para control total del loop y mute
- **Navigación**: `Navigator.pushReplacement` para evitar ciclos Grabar→Revisar→Grabar
- **Persistencia**: Integración con `RecordingManager` existente para actualizar `SessionData`

### 5.3 Decisiones de Diseño

| Decisión | Justificación |
|----------|---------------|
| **VideoPlayer nativo vs Chewie** | Control total sobre estética "Atomic" y menor dependencia inicial |
| **Mute por defecto (F7.4)** | Evita interrumpir flujo mental con audio al revisar |
| **Aprobación pasiva como MVP+** | Requiere timer y UI adicional; MVP usa solo botones explícitos |
| **Loop automático (F7.1)** | Permite revisión continua sin interacción para verificar calidad |

### 5.4 Riesgos Identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|-------------|
| Memory leak por VideoPlayer | Media | Alto | dispose() obligatorio en cleanup |
| Race condition en aprobación | Baja | Medio | Cancelar timer antes de navegación |
| Video corrupto no detectable | Baja | Alto | Retry con timeout, fallback a error UI |
| Timer ejecutándose en background | Baja | Bajo | Pausar timer en `AppLifecycleState.paused` |

---

## 📋 6. Plan de Implementación Atómico

### Tarea 1: ClipReviewPage Esqueleto (25 líneas)
- Crear StatefulWidget con props requeridas
- Scaffold con Stack (video + overlay)
- Botones de decisión con layout básico

### Tarea 2: ClipVideoPlayer con Loop (40 líneas)
- Integrar VideoPlayerController
- Implementar `setLooping(true)` en inicialización
- Manejo de estados: loading, ready, error

### Tarea 3: DecisionButtons y Navegación (30 líneas)
- Botones flotantes con colores correcto (rojo/verde)
- Conectar onKeep/onRetry a Navigation
- Animación de transición

### Tarea 4: Silenciado y Contador Takes (20 líneas)
- Toggle mute con icono
- Mostrar "Take X" desde props

### Tarea 5: Aprobación Pasiva MVP+ (25 líneas)
- Timer de 3 segundos
- ProgressBar visual
- Cancelación al interactuar

### Tarea 6: Integración con RecordingPage (15 líneas)
- Modificar _stopRecording() para navegar a ClipReviewPage
- Pasar todos los parámetros requeridos
- Manejar caso último fragmento → RecordingEndPage

---

## 🚀 Estado: READY FOR IMPLEMENTATION

**Archivo de salida:** `D:\Develop\Personal\vrm\LAST\analisis-oc.md`  
**Dependencias:** `video_player` (existente), `RecordingManager` (existente), `SessionData` (existente)  
**Compatibilidad:** MVP core (F7.1-F7.2-F7.4-F7.5-F7.6), MVP+ incluye F7.3
