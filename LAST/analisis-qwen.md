# Análisis Día 3: Clip Review Visual

## Diseño Funcional

### Problema que resuelve

Después de grabar un clip individual (`chunk_X_take_Y.mp4`), el usuario necesita:
1. **Validar visualmente** que la toma salió bien (enfocada, audio claro, sin errores)
2. **Decidir** si acepta esa toma o la repite
3. **Avanzar** al siguiente fragmento del guion una vez validado

Sin esta pantalla, el usuario graba a ciegas y solo descubre problemas al exportar el video final, cuando ya es demasiado tarde.

### Inputs

| Input | Origen | Formato |
|-------|--------|---------|
| `projectId` | Route params desde `RecordingPage` | `String` |
| `chunkIndex` | Session state (qué bloque del guion se grabó) | `int` |
| `takeNumber` | Auto-incremental desde `ClipStorageService.getNextTakeNumber()` | `int` |
| `clipFilePath` | Ruta absoluta del archivo `.mp4` recién guardado | `String` |
| `totalChunks` | `ScriptAnalysis.fragments.length` desde el guion | `int` |
| `scriptText` | Texto del fragmento actual para contexto visual | `String` |

### Outputs

| Output | Destino | Formato |
|--------|---------|---------|
| **Aceptar clip** → Avanza al siguiente `chunkIndex` o finaliza sesión | `RecordingManager` / Navegación | Evento booleano |
| **Repetir clip** → Re-graba el mismo `chunkIndex` incrementando `takeNumber` | `RecordingPage` (re-entry) | Evento booleano |
| **Eliminar clip** → Borra el archivo `.mp4` del filesystem | `ClipStorageService.deleteClip()` | Evento opcional |

### Rol en el sistema

Es el **gatekeeper de calidad** entre la grabación cruda (Día 1-2) y el stitching (Día 4-5). Sin validación visual, clips corruptos o vacíos se colarían al producto final.

---

## Supuestos y Ambigüedades

### No definido / Ambiguo

1. **¿El usuario puede ver TODAS las tomas previas de un chunk?** Actualmente solo el último take grabado es candidato. ¿Debe haber un "gallery view" de `take_1`, `take_2`, `take_3` para elegir la mejor?
2. **¿Qué pasa con los takes descartados?** Se mantienen en disco (ocupando espacio) o se eliminan automáticamente al aceptar uno nuevo?
3. **¿El review es obligatorio?** ¿Puede el usuario saltárselo y continuar grabando sin revisar?
4. **¿Se muestra el texto del guion durante el review?** Para que el usuario compare "lo que dijo" vs "lo que debía decir".
5. **¿Qué metadata se muestra al usuario?** Duración, resolución, peso del archivo, fecha/hora?
6. **Navegación post-review:** Al "Aceptar", ¿se regresa automáticamente a la pantalla de grabación del siguiente chunk? ¿O hay un dashboard intermedio?

### Preguntas críticas

1. ¿El `video_player` package soporta playback de archivos locales en **ambas plataformas** (iOS Simulator tiene limitaciones conocidas con codecs H.264)?
2. ¿Qué sucede si el clip grabado tiene **0 bytes** o está corrupto? ¿La pantalla de review debe detectar esto y mostrar error?
3. ¿El usuario puede **pausar/reanudar** el playback del clip o solo play/stop?
4. ¿Se necesita un **thumbnail** del clip antes de cargar el video player (para evitar latencia)?

---

## Diseño Técnico

### Arquitectura Sugerida

```
ClipReviewPage (StatefulWidget)
├── ClipReviewController (lógica de estado)
│   ├── VideoPlayerController (video_player package)
│   ├── ClipStorageService (lectura/borrado de clips)
│   └── SessionManager (tracking de takes)
├── ClipReviewUI (widget tree)
│   ├── VideoPlayerWidget (playback real)
│   ├── ClipMetadataBar (duración, peso, take number)
│   ├── ScriptContextBanner (qué decía el guion aquí)
│   └── ActionButtons (Aceptar / Repetir / Eliminar)
└── ClipReviewNavigator (wrapper de navegación)
```

### Componentes Involucrados

| Componente | Tipo | Responsabilidad |
|------------|------|-----------------|
| `ClipReviewPage` | `StatefulWidget` | Pantalla principal con el video player y botones de acción |
| `ClipReviewController` | Clase de control | Inicializa/disposes el `VideoPlayerController`, maneja estado de playback |
| `ClipStorageService` | Servicio existente | Proveer método `listClipsForChunk(chunkIndex)` para obtener todos los takes |
| `SessionData` | Modelo existente | Actualizar `takesPerChunk` con el take seleccionado |
| `RecordingManager` | Servicio existente | Recibe señal para avanzar al siguiente chunk o repetir |

### APIs / Endpoints

**No requiere APIs externas.** Todo opera localmente en filesystem.

### Métodos nuevos en `ClipStorageService`

```dart
/// Lista todos los clips grabados para un chunk específico.
Future<List<ClipFileInfo>> listClipsForChunk(int chunkIndex) async {
  final clipsDir = await ensureClipsDirectory();
  final pattern = 'chunk_${chunkIndex}_take_';
  final clips = <ClipFileInfo>[];

  if (!await clipsDir.exists()) return clips;

  await for (final entity in clipsDir.list()) {
    if (entity is File) {
      final filename = p.basename(entity.path);
      if (filename.startsWith(pattern) && filename.endsWith('.mp4')) {
        final takePart = filename
            .substring(pattern.length)
            .replaceAll('.mp4', '');
        final takeNum = int.tryParse(takePart);
        if (takeNum != null) {
          final stat = await entity.stat();
          clips.add(ClipFileInfo(
            path: entity.path,
            takeNumber: takeNum,
            sizeBytes: stat.size,
            modifiedAt: stat.modified,
          ));
        }
      }
    }
  }

  return clips..sort((a, b) => a.takeNumber.compareTo(b.takeNumber));
}

/// Elimina todos los takes de un chunk EXCEPTO el seleccionado.
Future<void> cleanupRejectedTakes(int chunkIndex, int acceptedTake) async {
  final clips = await listClipsForChunk(chunkIndex);
  for (final clip in clips) {
    if (clip.takeNumber != acceptedTake) {
      final file = File(clip.path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[ClipStorage] Cleaned rejected take: ${clip.path}');
      }
    }
  }
}
```

### Nuevo modelo: `ClipFileInfo`

```dart
class ClipFileInfo {
  final String path;
  final int takeNumber;
  final int sizeBytes;
  final DateTime modifiedAt;

  ClipFileInfo({
    required this.path,
    required this.takeNumber,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Duration? get durationFromFile {
    // Opcional: usar ffmpeg_kit para extraer duración sin cargar video_player
    // Por ahora, null hasta que video_player inicialice
    return null;
  }
}
```

### Flujo de Navegación

```
RecordingPage
  → Usuario detiene grabación
  → Clip guardado via ClipStorageService
  → Navigator.push(ClipReviewPage(clipPath, chunkIndex, takeNumber, ...))

ClipReviewPage
  → VideoPlayerController.file(File(clipPath)).initialize()
  → Usuario ve preview
  → [Aceptar] → Navigator.pop(true) → RecordingPage avanza a chunkIndex+1
  → [Repetir] → Navigator.pop(false) → RecordingPage re-graba mismo chunk
  → [Eliminar] → ClipStorageService.deleteClip() → Navigator.pop(null)
```

### Manejo de Errores

| Error | Causa Probable | Acción |
|-------|---------------|--------|
| `VideoPlayerController.initialize()` falla | Codec no soportado, archivo corrupto | Mostrar "Clip corrupto. ¿Repetir?" con botón de borrar |
| Archivo no existe en path | Race condition entre grabación y review | Mostrar "Clip no encontrado. Re-grabar." |
| Archivo 0 bytes | Cámara no entregó frames | Igual al anterior |
| VideoPlayer no carga en iOS Simulator | Limitación de codecs del simulador | Fallback a imagen estática + banner "Preview no disponible en simulador" |
| Memoria insuficiente al inicializar | Clip demasiado grande (>500MB) | Mostrar warning, ofrecer borrar y re-grabar en menor calidad |

### Edge Cases

1. **Usuario acepta sin ver el video:** Debería haber un mínimo de feedback (ej. habilitar botón "Aceptar" solo después de 2 segundos de playback o al menos 1 play).
2. **Rotación de pantalla durante review:** El video player debe mantener su posición de playback.
3. **App backgroundeada durante review:** El `VideoPlayerController` debe pausarse automáticamente y reanudarse al volver.
4. **Múltiples takes del mismo chunk:** El usuario debería poder hacer swipe horizontal entre takes para comparar.
5. **Primer take del primer chunk:** No hay contexto previo. El flujo es lineal.
6. **Último chunk del guion:** Al aceptar, en lugar de volver a grabación, navegar a pantalla de export/stitch.

---

## Decisiones

### Lenguajes / Frameworks

| Tecnología | Decisión | Justificación |
|------------|----------|---------------|
| `video_player` package | **Usar** (ya está en pubspec.yaml) | Es el estándar de Flutter para playback local. Soporta `file://` URIs directamente. |
| `chewie` package | **Evaluar si se necesita** | Provee controles de video pre-construidos (play/pause/seek/barra de progreso). Si la UI custom es suficiente, NO agregar dependencia extra. **Recomendación: NO usar en MVP**, construir controles custom para mantener consistencia visual con el diseño VRM. |
| `ffmpeg_kit_flutter` | **NO usar aquí** (es Día 4-5) | Solo se necesita para stitching. Para extraer metadata del clip (duración), se puede leer del `VideoPlayerController.value.duration`. |
| `photo_manager` | **NO usar aquí** (es Día 6) | Solo para exportar a galería al final del pipeline. |

### Patrón de Estado

**`StatefulWidget` con controller dedicado** — NO Riverpod/Bloc para esta pantalla. El estado es efímero (solo vive durante la review) y no necesita ser compartido con otros widgets. Un controller simple maneja la inicialización del video player.

```dart
class ClipReviewController extends ChangeNotifier {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Métodos: initialize(), play(), pause(), seekTo(), dispose()
  // Cada uno llama notifyListeners()
}
```

### UX: ¿Auto-play al entrar?

**Sí.** Al abrir la pantalla de review, el video debe empezar a reproducirse automáticamente con **muted = false** (el usuario necesita escuchar su voz para validar audio). Esto reduce fricción — no requiere un tap extra.

### UX: ¿Swipe entre takes?

**Sí, si hay múltiples takes.** Un `PageView` horizontal donde cada página es un take diferente. Indicador de página con número de take ("Take 1", "Take 2", etc.).

---

## Riesgos

### Técnicos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| `video_player` no inicializa en iOS Simulator | Alta | Medio | Detectar plataforma (`Platform.isIOS` + `kDebugMode`) y mostrar placeholder informativo |
| Memory leak con múltiples VideoPlayerController | Media | Alto | **Dispose obligatorio** en `dispose()` del StatefulWidget. Nunca mantener referencias a controllers previos |
| Latencia al cargar clip grande (>200MB) | Media | Medio | Mostrar skeleton/shimmer mientras `initialize()` completa. Timeout de 10s con fallback a error |
| Codec incompatido en Android OEM | Baja | Alto | Validar con grabación en H.264 baseline profile (el más compatible). Configurar en `CameraService` |

### Operativos

| Riesgo | Mitigación |
|--------|------------|
| Usuario confunde "Repetir" con "Aceptar" | Diferenciar visualmente: Aceptar = botón primario verde, Repetir = outlined secondary |
| Usuario no entiende que puede ver takes anteriores | Indicador visual de swipe + texto "Desliza para ver otras tomas" |

### Escalabilidad

- **A corto plazo (MVP):** No hay problema. El usuario graba 5-10 clips por sesión.
- **A mediano plazo (V2):** Si el usuario acumula 50+ takes rechazados, el disco se llena. **Solución:** `cleanupRejectedTakes()` automático al aceptar un take.

### Costos

- **Sin costos externos.** Todo opera localmente.
- **Costo de almacenamiento:** Cada take de ~30 segundos en 1080p ≈ 50-100MB. Con 10 chunks × 3 takes = ~1.5-3GB temporales. **Mitigación:** Limpiar takes rechazados inmediatamente.

---

## Plan

### Tareas de Implementación (Orden recomendado)

| # | Tarea | Archivo(s) | Dependencias |
|---|-------|-----------|--------------|
| 1 | Agregar método `listClipsForChunk()` a `ClipStorageService` | `clip_storage_service.dart` | — |
| 2 | Agregar método `cleanupRejectedTakes()` a `ClipStorageService` | `clip_storage_service.dart` | Tarea 1 |
| 3 | Crear modelo `ClipFileInfo` | `clip_metadata.dart` (o archivo nuevo) | — |
| 4 | Crear `ClipReviewController` | `clip_review_controller.dart` (nuevo) | `video_player`, `ClipFileInfo` |
| 5 | Crear `ClipReviewPage` scaffold con UI | `clip_review_page.dart` (nuevo) | Controller anterior |
| 6 | Integrar `VideoPlayerController.file()` con playback real | `clip_review_page.dart` | Tarea 4, 5 |
| 7 | Implementar controles custom (play/pause/seek/timeline) | `clip_review_page.dart` widgets | Tarea 6 |
| 8 | Implementar botones de acción (Aceptar/Repetir/Eliminar) | `clip_review_page.dart` | Tarea 5 |
| 9 | Implementar swipe entre takes (PageView si hay múltiples) | `clip_review_page.dart` | Tarea 1 |
| 10 | Conectar navegación con `RecordingPage` (pop con resultado) | `recording_page.dart` | Tarea 8 |
| 11 | Manejo de errores (clip corrupto, archivo vacío, etc.) | `clip_review_page.dart` | Tarea 6 |
| 12 | Agregar banner de contexto del guion (qué fragmento era) | `clip_review_page.dart` | ScriptAnalysis |
| 13 | Test en dispositivo físico (iOS + Android) | — | Todo lo anterior |
| 14 | Fallback para iOS Simulator | `clip_review_page.dart` | Tarea 11 |

### Dependencias entre tareas

```
1, 2, 3  →  independientes entre sí (pueden ser en paralelo)
1, 3     →  4
4, 5     →  6
6        →  7, 8, 11
7, 8, 9  →  10
11, 12   →  13
```

### Estimación de esfuerzo por tarea

| Tarea | Líneas estimadas | Complejidad |
|-------|-----------------|-------------|
| 1. `listClipsForChunk()` | ~30 | Baja |
| 2. `cleanupRejectedTakes()` | ~15 | Baja |
| 3. `ClipFileInfo` | ~25 | Baja |
| 4. `ClipReviewController` | ~80 | Media |
| 5. `ClipReviewPage` scaffold | ~60 | Baja |
| 6. VideoPlayer integration | ~40 | Media |
| 7. Custom controls | ~100 | Media-Alta |
| 8. Action buttons | ~50 | Baja |
| 9. PageView swipe | ~60 | Media |
| 10. Navigation wiring | ~30 | Baja |
| 11. Error handling | ~70 | Media |
| 12. Script context banner | ~40 | Baja |
| 13. Device testing | — | Tiempo de QA |
| 14. Simulator fallback | ~20 | Baja |

**Total estimado:** ~620 líneas de código nuevo.

---

## Estrategia de Testing

### Unit Tests

| Test | Qué valida |
|------|-----------|
| `ClipStorageService.listClipsForChunk()` retorna lista ordenada por takeNumber | Correcto escaneo de filesystem |
| `ClipStorageService.cleanupRejectedTakes()` borra solo los rechazados | Que no borre el take aceptado |
| `ClipFileInfo.sizeFormatted` formatea correctamente bytes → KB → MB | Formato legible |
| `ClipReviewController` inicializa y hace dispose sin leaks | Lifecycle correcto |

### Integration Tests

| Test | Qué valida |
|------|-----------|
| Grabar clip → Abrir review → Video se reproduce | Pipeline completo recording → review |
| Review → Aceptar → Avanza al siguiente chunk | Navegación post-review |
| Review → Repetir → Vuelve a grabar mismo chunk | Re-grabación |
| Review → Eliminar → Clip borrado del filesystem | Limpieza de archivos |
| Clip corrupto → Muestra error → Permite re-grabar | Error handling |
| Múltiples takes → Swipe entre ellos → Cada uno se reproduce | PageView + video switching |

### Casos Críticos a Validar en Dispositivo Físico

1. **Android físico:** Grabar 30s → Ver review → Playback fluido con audio
2. **iOS físico:** Grabar 30s → Ver review → Playback fluido con audio
3. **iOS Simulator:** Abrir review → Muestra placeholder "Preview no disponible en simulador"
4. **Clip de 0 bytes:** Muestra "Clip corrupto. ¿Repetir?"
5. **Memoria baja (<500MB libres):** Warning antes de abrir review
6. **Background durante review:** Pausa video, reanuda al volver
7. **5 takes del mismo chunk:** Swipe funciona, indicador de página correcto

---

## Optimización y Escalabilidad Futura

### Problemas al escalar

| Escenario | Problema | Solución |
|-----------|----------|----------|
| **Sesiones largas (20+ chunks)** | Acumulación de takes rechazados = GB de basura | Auto-cleanup al aceptar cada take |
| **Clips en 4K** | VideoPlayer puede laggear en devices gama baja | Downscale preview a 1080p, mantener original para export |
| **Múltiples proyectos** | Clips de proyectos distintos mezclados en mismo dir | Estructura actual ya aísla por `projectId` ✅ |
| **Usuarios reanudan sesión días después** | No hay thumbnail/preview sin cargar video | Generar thumbnail (primer frame) al guardar clip |

### Preparación desde ahora

1. **Abstracción del video player:** Crear interfaz `VideoPreviewProvider` que pueda swap entre `video_player` (actual) y un futuro sistema de thumbnails + streaming ligero.

2. **ClipFileInfo extensible:** Agregar campos opcionales `thumbnailPath` y `waveformPath` para cuando se implemente audio waveform visual.

3. **Persistencia de selección:** Guardar `selectedTake` en `session_data.json` (ya existe el campo en `ChunkTakeInfo`) para que al reanudar sesión se sepa cuál take fue aceptado.

4. **Lazy loading de takes:** Si hay 10 takes de un chunk, NO inicializar todos los VideoPlayerControllers. Solo el activo. Los demás como thumbnails estáticos.
