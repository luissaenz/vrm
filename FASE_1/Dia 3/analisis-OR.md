# Análisis Técnico: FASE 1 - Día 3 (Revisión Visual de Clips)

## 1. Comprensión del Paso

### Problema que resuelve
Permitir al usuario validar visualmente el clip grabado antes de proceder al siguiente fragmento del guion. Es el "feedback loop" crítico post-grabación donde el creador decide: aprobar (avanzar) o re-grabar (repetir).

### Inputs
- `clipPath`: Ruta absoluta del archivo `.mp4` generado (ej: `.../clips/chunk_0_take_1.mp4`)
- `chunkIndex`: Índice actual del fragmento (0-based)
- `totalChunks`: Total de fragmentos del proyecto
- `scriptAnalysis`: Objeto con el guion analizado y segmentos
- `projectId`: ID del proyecto actual

### Outputs
- **Aprobado**: Navegación al siguiente chunk (o a Stitcher si es el último) + guardado del path en `script_bundle.json`
- **Re-grabar**: Retorno a `RecordingPage` con el mismo `chunkIndex`, eliminando el clip defectuoso

### Rol en el sistema
Punto de bifurcación después de cada grabación. Conecta:
- **Entrada**: Día 1-2 (RecordingPage) - provee clip grabado
- **Salida**: Día 4-5 (Stitcher) - recibe lista de clips aprobados

---

## 2. Supuestos y Ambigüedades

### Críticas (requieren resolución antes de coding)

1. **Auto-play o manual?**
   - Documento menciona "auto-play en loop" pero no especifica si el video empieza muted
   - Pregunta: ¿el video reproduce automáticamente al entrar a la screen?

2. **¿Navegación o reinstanciación?**
   - ¿Se usa `Navigator.pushReplacement` para evitar stack de pantallas?
   - ¿O se reinstancia completamente `RecordingPage`?

3. **¿Comportamiento del mute en iOS?**
   - El switch Ring/Silent puede silenciar el VideoPlayer
   - ¿Se implementa `audio_session` para forzar audio?

4. **¿Cuántas re-grabaciones permite?**
   - ¿Hay límite o es ilimitado?
   - ¿El contador de "takes" es por chunk o global?

5. **¿El usuario puede hacer scrub (barra de progreso)?**
   - ¿Solo hay loop automático o puede avanzar manualmente?

6. **Mensaje de error si archivo corrupto**
   - ¿Se muestra UI de error específica o se redirige directamente a re-grabación?

### Secundarias

- ¿Se muestra el texto del chunk actual como contexto?
- ¿Hay indicador de progreso "Fragmento X de Y"?
- ¿El usuario puede cerrar y continuar después?

---

## 3. Diseño Funcional

### Flujo Principal (Pipeline)

```
[RecordingPage] → stopRecording() → saveClip()
        ↓
   ClipReviewScreen (auto-instanciada post-stop)
        ↓
   ┌───────┴───────┐
   ↓               ↓
[Repetir]      [Aprobar]
   ↓               ↓
Delete clip    Guardar path en script_bundle
Return to      Advance to next chunk
RecordingPage  (or Stitcher if last)
```

### Casos Normales

1. **Aprobación directa**: Usuario ve el loop 1-2 veces → toca "Aprobar" → siguiente fragmento
2. **Re-grabación**: Usuario toca "Repetir" → clip se elimina → retorna a cámara con mismo índice
3. **Stitch automático**: Al aprobar el último chunk → navegar a Stitcher

### Edge Cases

| Escenario | Comportamiento |
|-----------|-----------------|
| Archivo corrupto (0 bytes) | Mostrar mensaje de error, redirigir a re-grabación |
| VideoPlayer falla al inicializar | Pantalla de error con opción de re-grabar |
| Usuario cierra app durante review | Estado ya persistido en session_data.json |
|Último chunk aprobado | Redirigir automáticamente a pantalla de stitching |
| Dos aprobación rápida (double-tap) | Deshabilitar botón hasta navegación completa |

### Manejo de Errores

```dart
try {
  // 1. Verificar archivo existe
  if (!File(clipPath).existsSync()) {
    throw FileSystemException('Clip no encontrado');
  }
  
  // 2. Verificar tamaño > 0
  final size = await File(clipPath).length();
  if (size == 0) {
    throw FileSystemException('Clip corrupto (0 bytes)');
  }
  
  // 3. Inicializar VideoPlayer
  await controller.initialize();
  
} on VideoPlayerException catch (e) {
  // Mostrar UI de error con "Regrabar" como única opción
} on FileSystemException catch (e) {
  // Mismo tratamiento - re-grabación forzada
}
```

---

## 4. Diseño Técnico

### Arquitectura Sugerida

```
lib/features/recording/
├── clip_review_screen.dart       ← Pantalla principal
├── clip_review_notifier.dart     ← State management (Provider)
└── services/
    └── clip_review_service.dart   ← Lógica de validación y decisión
```

### Componentes Involucrados

1. **ClipReviewScreen** - Widget de UI
   - VideoPlayer con loop automático
   - Botones Approve (✓) y Retake (↻)
   - Indicador de progreso "Fragmento X de Y"
   - Mini teleprompter con texto del chunk actual

2. **ClipReviewNotifier** - State (ChangeNotifier)
   - `clipPath: String`
   - `chunkIndex: int`
   - `isVideoInitialized: bool`
   - `isPlaying: bool`
   - `errorMessage: String?`
   - `decision: ReviewDecision?`

3. **ClipReviewService** - Lógica de negocio
   - `validateClip(String path) -> Future<bool>`
   - `approveClip(String path, int chunkIndex) -> Future<void>`
   - `deleteClip(String path) -> Future<void>`

### Modelos de Datos

```dart
// clip_review_state.dart
enum ReviewDecision { approved, retake }

class ClipReviewState {
  final String clipPath;
  final int chunkIndex;
  final int totalChunks;
  final String? currentSegmentText;
  final bool isVideoInitialized;
  final bool isPlaying;
  final double progress; // 0.0 - 1.0
  final String? errorMessage;
  final ReviewDecision? decision;
}

// script_bundle.json (actualización post-aprobación)
{
  "script_id": "uuid-123",
  "total_chunks": 5,
  "chunks": [
    {
      "order": 0,
      "text": "Hola, hoy voy a hablarte sobre...",
      "valid_take": "/path/to/chunk_0_take_1.mp4",
      "status": "approved"
    },
    {
      "order": 1,
      "text": "Primero, necesitamos entender que...",
      "valid_take": null,
      "status": "pending"
    }
  ]
}

// session_data.json (actualización post-aprobación)
{
  "projectId": "uuid-123",
  "clips": [
    {
      "chunkIndex": 0,
      "takeNumber": 1,
      "status": "approved",
      "filePath": "/path/to/chunk_0_take_1.mp4",
      "approvedAt": "2026-04-08T15:30:00Z"
    }
  ]
}
```

### Integraciones

| Paquete | Propósito |
|---------|-----------|
| `video_player: ^2.9.1` | Reproducción local del clip |
| `dart:io` | Verificación y eliminación de archivos |
| `path_provider` | Rutas de directorios |

---

## 5. Decisiones Tecnológicas

### Librería Base

- **video_player: ^2.9.1** (oficial) - NO usar chewie
- **Justificación**: Botones custom son triviales, chewie añade ~500KB innecesarios y poco control sobre lifecycle

### Decisiones Pendientes

| Decisión | Recomendada | Alternativa |
|----------|-------------|-------------|
| Loop behavior | Auto-loop hasta interacción | One-shot + play button visible |
| Audio inicial | Unmuted (respetar mute switch) | Force unmute con audio_session |
| Delete strategy | Hard delete inmediato | Soft delete (mover a .trash) |
| Navegación | pushReplacement | pop + push nuevo |
| Scrub | Deshabilitado (solo loop) | Habilitado |

---

## 6. Plan de Implementación

### Backlog Técnico

#### Tarea 1: ClipReviewScreen estructura (0.5h)
- Crear archivo `lib/features/recording/clip_review_screen.dart`
- Constructor con params requeridos
- Scaffold básico con fondo negro

#### Tarea 2: VideoPlayer integración (1h)
- Inicializar `VideoPlayerController.file(File(clipPath))` en initState
- Mostrar `FutureBuilder` con indicador de carga
- Widget `VideoPlayer(controller)` con AspectRatio 9:16

#### Tarea 3: UI de controles (1h)
- Overlay con botones Approve y Retake
- Indicador "Fragmento X de Y"
- Texto del chunk (mini teleprompter)
- Auto-play loop

#### Tarea 4: Lógica de decisión (1h)
- `onApprove()`: guardar path, navegar siguiente
- `onRetake()`: eliminar archivo, navegar a RecordingPage
- Validar archivo existente antes de mostrar UI

#### Tarea 5: Cleanup y errores (0.5h)
- Override dispose() - dispose controller explícitamente
- Manejo de errores de inicialización
- Feedback visual durante procesamiento

#### Tarea 6: Integración con RecordingPage (0.5h)
- Modificar `_stopRecording()` para navegar a ClipReviewScreen
- Pasar clipPath como argumento

### Total Estimado: 4.5 horas

### Dependencias entre Tareas
- Tareas 1 → 2 → 3: Secuencial
- Tarea 4 requiere Tareas 1-3 completas
- Tarea 5 es cross-cutting
- Tarea 6 depende de Tareas 1-5

---

## 7. Riesgos y Cuellos de Botella

### Técnicos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Memory leak por VideoPlayer no dispose | ALTA | 🔴 ALTO | Code review obligatorio del dispose() |
| Navegación genera stack overflow | MEDIA | 🟡 MEDIO | Usar siempre pushReplacement |
| Archivo corrupto no detectable | BAJA | 🟡 MEDIO | Verificar size > 0 antes de mostrar |
| Black screen al cargar video | MEDIA | 🟡 MEDIO | Mostrar loader hasta isInitialized true |

### Operativos

- No hay "undo" después de aprobar - flow lineal
- Usuario no puede "ir hacia atrás" una vez aprobado - aceptado para MVP

### Escalabilidad

- Para clips > 30s: tiempo de carga aumenta → considerar pre-carga
- Videos 4K pueden ser problemáticos → opcional: transcodificar a 1080p (postergar a V2)

### Costos

- Ninguno adicional - todo es local

---

## 8. Métricas de Éxito

### KPIs Técnicos

| Métrica | Target | Método |
|---------|--------|--------|
| Time-to-first-frame | < 500ms | Medir desde navigation hasta frame visible |
| Memory leak | < 50MB incremento | Profile después de 20 ciclos |
| Crash rate en initialization | 0% | Test con archivos corruptos |

### KPIs de Negocio

| Métrica | Target | Método |
|---------|--------|--------|
| Conversion (aprueba en 1er intento) | > 70% | Analytics: review entered vs approved |
| Retake rate | < 30% | (retakes / total reviews) |

### Validación

- 10 grabaciones completas de 3-5 chunks cada una
- 20 ciclos recording → review → retake sin memory leak
- Archivos corruptos (0 bytes) muestran error claro

---

## 9. Estrategia de Testing

### Unit Tests

```dart
// Test: approve guarda path correctamente
test('approve guarda clip path en script_bundle', () async {
  final notifier = ClipReviewNotifier(...);
  await notifier.approve();
  expect(scriptBundle.chunks[0].validTake, isNotNull);
});

// Test: retake elimina archivo físico
test('retake elimina archivo', () async {
  final notifier = ClipReviewNotifier(...);
  await notifier.retake();
  expect(File(clipPath).existsSync(), false);
});

// Test: Video initialization failure
test('muestra error cuando video init falla', () async {
  final notifier = ClipReviewNotifier(clipPath: '/invalid/path.mp4');
  await notifier.initializeVideo();
  expect(notifier.errorMessage, isNotNull);
});
```

### Integration Tests

- **Flow completo**: Grabar → Review → Approve → Siguiente chunk → Final
- **Stress test**: 20 ciclos recording → review → retake sin memory leak
- **Error path**: Clip corrupto → error UI → retake disponible

### Casos Críticos

1. Video corrupto (0 bytes) → muestra error y permite re-grabar
2. Usuario presiona Approve dos veces → idempotencia
3. App mata durante review → estado consistente al reopen

---

## 10. Optimización y Escalabilidad Futura

### Problemas al Escalar

1. **Clips 4K**: Reproducción lenta en dispositivos low-end
   - Solución V2: Transcodificar a 1080p en background
2. **Videos largos (>1 min)**: Buffering visible
   - Solución V2: Pre-cargar siguiente chunk
3. **Edición de clip**: Usuario quiere cortar principio/fin
   - Solución V2: Trim UI con range selector

### Preparación desde Ahora

- Arquitectura que permita inyectar diferentes video sources
- script_bundle.json extensible para metadata de trim
- Navigation callback pattern (no strongly coupled)
- No hardcodear paths - usar path_provider siempre