# Análisis Técnico: FASE 1 — Día 4-5 (Auto-Stitch con ffmpeg)

> **Autor**: Qwen
> **Fecha**: 2026-04-08
> **Documento fuente**: `docs/mvp-Definition.md`
> **Alcance**: Mediante `ffmpeg_kit_flutter`. Consolidar los videos crudos de fragmentos secuenciales en un solo compilado a nivel FileSystem, creando el track `/final.mp4`. Incluye feedback/barra de proceso al usuario.

---

## 1. Diseño Funcional

### 1.1 Qué problema resuelve

El usuario grabó múltiples clips individuales (`chunk_0_take_1.mp4`, `chunk_1_take_1.mp4`, etc.) — uno por fragmento del guion. Pero **no existe un archivo de video unificado** que el usuario pueda exportar o compartir. Sin stitching:

- Cada clip es un video separado de 5-15 segundos — el usuario no tiene un producto final.
- `RecordingEndPage` no tiene nada que mostrar como preview real.
- Día 6 (exportación a galería/share) y Día 19-21 (publicación en stores) **no tienen archivo de salida**.
- `StitcherPlugin` actual es un placeholder que solo cambia `status: 'raw'` → `status: 'processed'` sin tocar un solo byte de video.
- `ffmpeg_kit_flutter` está en el plan del MVP pero **no está en `pubspec.yaml` ni se importa en ningún archivo Dart**.

**Este paso toma los clips seleccionados por el usuario (el take elegido por cada chunk) y los concatena en un solo archivo `final.mp4`** que es el producto exportable del MVP.

### 1.2 Inputs

| Input | Origen | Formato |
|---|---|---|
| `projectId` | Sesión de grabación actual | `String` UUID |
| `chunksRecorded` | `SessionData.chunksRecorded` | `List<int>` — índices de chunks grabados, ej `[0, 1, 2, 4]` |
| `selectedTake` por chunk | `SessionData.takesPerChunk` | `Map<int, ChunkTakeInfo>` — cada entry tiene `selectedTake` |
| `totalChunks` | `widget.analysis.segments.length` | `int` — total de fragmentos del guion |
| Clips en disco | `vrm_data/projects/{projectId}/clips/chunk_X_take_Y.mp4` | Archivos `.mp4` existentes |

**Ejemplo concreto**:
```
SessionData:
  chunksRecorded: [0, 1, 2]
  takesPerChunk: {
    0: { total: 3, selectedTake: 2 },
    1: { total: 1, selectedTake: 1 },
    2: { total: 2, selectedTake: 1 },
  }

Clips a concatenar (en orden):
  1. chunk_0_take_2.mp4
  2. chunk_1_take_1.mp4
  3. chunk_2_take_1.mp4

Output:
  vrm_data/projects/{projectId}/final.mp4
```

### 1.3 Outputs

| Output | Destino | Formato |
|---|---|---|
| `final.mp4` | `vrm_data/projects/{projectId}/final.mp4` | Video MP4 (H.264 + AAC) concatenado |
| Estado de progreso | UI durante el proceso | Porcentaje 0-100% |
| Resultado (éxito/fallo) | Caller (UI de resumen o export) | `StitchResult { success, outputPath, error, durationMs }` |

### 1.4 Rol dentro del sistema

```
[Grabar chunk 0] → review → [Grabar chunk 1] → review → [Grabar chunk N] → review
                                                                        ↓
                                                               "Terminar sesión"
                                                                        ↓
                                                    [Auto-Stitch ← ESTE PASO]
                                                    chunk_0 + chunk_1 + ... + chunk_N
                                                                        ↓
                                                                   final.mp4
                                                                        ↓
                                              [Export Día 6] → [Galería / Share Sheet]
```

Es el **cuello de botella del pipeline**: sin `final.mp4`, no hay exportación, no hay sharing, no hay producto.

---

## 2. Supuestos y Ambigüedades

### 2.1 Detectadas

| # | Ambigüedad | Impacto | Resolución propuesta |
|---|---|---|---|
| A1 | **¿Qué clips se usan?** ¿Todos los grabados o solo los `selectedTake`? | Determina qué archivos pasar a ffmpeg. | Solo los `selectedTake` de cada chunk en `SessionData.takesPerChunk`. |
| A2 | **¿En qué orden se concatenan?** | El orden incorrecto destruye la coherencia del guion. | Orden ascendente por `chunkIndex`: `chunksRecorded` sorted. |
| A3 | **¿Qué pasa si un chunk no tiene takes?** | El archivo no existe y ffmpeg falla. | Validar antes de ejecutar. Si falta un chunk, mostrar error específico: "Fragmento X no tiene grabación." |
| A4 | **¿Los clips tienen resolución/resolución consistente?** | Si chunk_0 es 1080x1920 y chunk_1 es 720x1280, ffmpeg necesita escalar o la concatenación falla. | `CameraConfig` fija `ResolutionPreset.high` para todos los clips. Se asume consistencia. Si hay variación, ffmpeg aplica `scale` filter. |
| A5 | **¿Los clips tienen el mismo codec/formato?** | Concatenación directa (`concat demuxer`) requiere mismo codec. Si difieren, necesita re-encode. | Todos grabados con la misma cámara → mismo codec. Se usa `concat demuxer` (más rápido, sin re-encode). |
| A6 | **¿ffmpeg_kit_flutter compila en iOS y Android?** | El MVP documenta esto como riesgo: "no transpila en C++ nativo". | Se usa `ffmpeg_kit_flutter: ^6.0.3` que es la versión más estable. Si falla el build, fallback a `ffmpeg_kit_flutter_min` (subset reducido). |
| A7 | **¿El usuario ve progreso o es instantáneo?** | Stitching de 5 clips de 10s cada uno puede tardar 5-30 segundos. El usuario necesita feedback. | Barra de progreso con porcentaje. El MVP dice "Incluye feedback/barra de proceso a usuario." |
| A8 | **¿Se puede cancelar el stitching?** | Usuario cierra la app a mitad del proceso. | Permitir cancelación. Si se cancela, borrar `final.mp4` parcial. |
| A9 | **¿Se re-stitcha si el usuario re-graba un chunk después?** | Si el usuario ya tiene `final.mp4` y luego re-graba chunk_2. | Sí. Cada stitching regenera `final.mp4` desde cero con los takes actuales. El archivo anterior se sobrescribe. |
| A10 | **¿`SessionData` está en memoria o persistido?** | Día 7-8 es la persistencia JSON. Día 4-5 necesita los datos. | En memoria. El stitching se ejecuta dentro de la misma sesión de grabación. `SessionData` está disponible. |

---

## 3. Diseño Técnico

### 3.1 Arquitectura

```
┌───────────────────────────────────────────────────────────────┐
│                   UI (StitchProgressDialog)                    │
│  - Muestra progreso 0-100%                                    │
│  - Botón "Cancelar"                                           │
│  - Resultado: éxito → final.mp4 preview / error → retry       │
└──────────────────────────┬────────────────────────────────────┘
                           │
                           ▼
┌───────────────────────────────────────────────────────────────┐
│                    StitchService (NUEVO)                       │
│  - Recopila paths de clips seleccionados                      │
│  - Valida que todos existan                                   │
│  - Genera ffmpeg concat file list                             │
│  - Ejecuta ffmpeg command con callback de progreso            │
│  - Retorna outputPath o error                                 │
└──────────────────────────┬────────────────────────────────────┘
                           │
                           ▼
┌───────────────────────────────────────────────────────────────┐
│                 ffmpeg_kit_flutter (librería)                  │
│  - FFmpegKit.executeWithStatistics()                          │
│  - Callback de progreso vía statistics callbacks              │
│  - Output: /vrm_data/projects/{projectId}/final.mp4           │
└───────────────────────────────────────────────────────────────┘
```

### 3.2 Componentes nuevos

#### 3.2.1 `lib/features/recording/services/stitch_service.dart`

Servicio principal que envuelve ffmpeg.

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';

/// Resultado del stitching.
class StitchResult {
  final bool success;
  final String? outputPath;
  final String? error;
  final int durationMs;
  final int clipsStitched;

  StitchResult({
    required this.success,
    this.outputPath,
    this.error,
    required this.durationMs,
    required this.clipsStitched,
  });

  factory StitchResult.success({
    required String outputPath,
    required int durationMs,
    required int clipsStitched,
  }) => StitchResult(
    success: true,
    outputPath: outputPath,
    durationMs: durationMs,
    clipsStitched: clipsStitched,
  );

  factory StitchResult.failure({
    required String error,
    required int durationMs,
  }) => StitchResult(
    success: false,
    error: error,
    durationMs: durationMs,
  );
}

/// Callback de progreso del stitching.
typedef StitchProgressCallback = void Function(int progress, String message);

/// Servicio de stitching de clips usando ffmpeg.
class StitchService {
  final String projectId;

  StitchService({required this.projectId});

  /// Obtiene la ruta absoluta del archivo final.
  Future<String> get finalOutputPath async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(
      appDir.path,
      'vrm_data',
      'projects',
      projectId,
      'final.mp4',
    );
  }

  /// Recopila los paths de los clips seleccionados en orden.
  /// Retorna lista de paths absolutos.
  Future<List<String>> getSelectedClipPaths(
    List<int> chunksRecorded,
    Map<int, int> selectedTakes,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final clipsDir = p.join(
      appDir.path,
      'vrm_data',
      'projects',
      projectId,
      'clips',
    );

    final paths = <String>[];

    // Ordenar chunks para mantener secuencia del guion
    final sortedChunks = List<int>.from(chunksRecorded)..sort();

    for (final chunkIndex in sortedChunks) {
      final takeNumber = selectedTakes[chunkIndex];
      if (takeNumber == null) {
        throw StitchValidationException(
          'Fragmento $chunkIndex no tiene take seleccionado',
        );
      }

      final clipPath = p.join(
        clipsDir,
        'chunk_${chunkIndex}_take_$takeNumber.mp4',
      );

      final file = File(clipPath);
      if (!await file.exists()) {
        throw StitchValidationException(
          'Archivo no encontrado: chunk_${chunkIndex}_take_$takeNumber.mp4',
        );
      }

      paths.add(clipPath);
    }

    if (paths.isEmpty) {
      throw StitchValidationException('No hay clips para concatenar');
    }

    return paths;
  }

  /// Ejecuta el stitching de los clips en un solo archivo final.mp4.
  /// Reporta progreso vía [onProgress].
  /// Retorna StitchResult con el path del archivo o el error.
  Future<StitchResult> stitch({
    required List<int> chunksRecorded,
    required Map<int, int> selectedTakes,
    StitchProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Validar y recopilar paths
      final clipPaths = await getSelectedClipPaths(
        chunksRecorded,
        selectedTakes,
      );

      debugPrint(
        '[Stitch] Stitching ${clipPaths.length} clips for project $projectId',
      );

      // 2. Generar archivo de lista para ffmpeg concat demuxer
      final concatFile = await _generateConcatFile(clipPaths);

      // 3. Output path
      final outputPath = await finalOutputPath;

      // 4. FFmpeg command: concat demuxer (fast, no re-encode)
      //    Si falla, fallback a filter_complex concat (re-encode)
      final command =
          '-f concat -safe 0 -i "$concatFile" -c copy "$outputPath"';

      debugPrint('[Stitch] Executing: $command');

      final session = await FFmpegKit.executeWithStatistics(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            debugPrint('[Stitch] Completed successfully');
          } else if (ReturnCode.isCancel(returnCode)) {
            debugPrint('[Stitch] Cancelled');
          } else {
            final failReason = await session.getFailReason();
            debugPrint('[Stitch] Failed: $failReason');
          }
        },
        null, // logs callback — not needed
        (Statistics statistics) {
          // Progress callback
          // statistics.time es en microsegundos del video procesado
          // Usamos una estimación basada en el tiempo transcurred
          final elapsed = stopwatch.elapsedMilliseconds;
          // Estimación: stitching de N clips tarda ~N * 2 segundos
          // Progreso real se basa en el time del statistics
          final videoTimeMs = statistics.time ~/ 1000;
          // Calcular duración total estimada de todos los clips
          // Para progreso visual, usar porcentaje basado en clips procesados
          final totalClips = clipPaths.length;
          // El statistics.time acumula el tiempo de video procesado
          // No tenemos duración total previo, así que usamos un approccio
          // conservador: progreso = min(95, clipsProcesados / totalClips * 100)
          // Una mejor aproximación: usar el tiempo de video del statistics
          // vs una estimación del total.
          if (onProgress != null) {
            // Estimación simple: cada clip aporta progreso igual
            // Usamos statistics.videoFrameCount como proxy de progreso
            final frameProgress = statistics.videoFrameCount > 0
                ? (statistics.videoFrameCount /
                        (totalClips * 300)) // ~300 frames por clip (10s @ 30fps)
                    .clamp(0.0, 0.95)
                : 0.0;
            final progress = (frameProgress * 100).round();
            onProgress(progress, 'Procesando clip...');
          }
        },
      );

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Verify output
        final outputFile = File(outputPath);
        if (!await outputFile.exists()) {
          return StitchResult.failure(
            error: 'Archivo de salida no fue creado',
            durationMs: stopwatch.elapsedMilliseconds,
          );
        }

        final fileSize = await outputFile.length();
        if (fileSize == 0) {
          return StitchResult.failure(
            error: 'Archivo de salida está vacío',
            durationMs: stopwatch.elapsedMilliseconds,
          );
        }

        // Clean up concat file
        try {
          await File(concatFile).delete();
        } catch (_) {}

        stopwatch.stop();
        debugPrint('[Stitch] final.mp4: $outputPath ($fileSize bytes)');

        return StitchResult.success(
          outputPath: outputPath,
          durationMs: stopwatch.elapsedMilliseconds,
          clipsStitched: clipPaths.length,
        );
      } else {
        // Fallback: try filter_complex concat (re-encode)
        debugPrint('[Stitch] Demuxer failed, trying filter_complex');
        return await _stitchWithFilterComplex(
          clipPaths: clipPaths,
          outputPath: outputPath,
          concatFile: concatFile,
          onProgress: onProgress,
          stopwatch: stopwatch,
        );
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('[Stitch] Error: $e');
      return StitchResult.failure(
        error: e.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Genera el archivo de lista para el concat demuxer de ffmpeg.
  /// Formato: file '/absolute/path/to/chunk_0_take_1.mp4'
  Future<String> _generateConcatFile(List<String> clipPaths) async {
    final tempDir = await getTemporaryDirectory();
    final concatPath = p.join(tempDir.path, 'ffmpeg_concat_${projectId}.txt');
    final concatFile = File(concatPath);

    final content = clipPaths
        .map((path) => "file '$path'")
        .join('\n');

    await concatFile.writeAsString(content);
    debugPrint('[Stitch] Concat file: $concatPath');
    debugPrint('[Stitch] Content:\n$content');

    return concatPath;
  }

  /// Fallback: re-encode con filter_complex concat.
  /// Más lento pero más compatible.
  Future<StitchResult> _stitchWithFilterComplex({
    required List<String> clipPaths,
    required String outputPath,
    required String concatFile,
    StitchProgressCallback? onProgress,
    required Stopwatch stopwatch,
  }) async {
    // Construir inputs y filter para filter_complex
    final inputs = clipPaths.map((p) => '-i "$p"').join(' ');
    final filterParts = clipPaths
        .asMap()
        .entries
        .map((e) => '[${e.key}:v][${e.key}:a]')
        .join('');
    final filter =
        '${filterParts}concat=n=${clipPaths.length}:v=1:a=1[outv][outa]';

    final command =
        '$inputs -filter_complex "$filter" -map "[outv]" -map "[outa]" '
        '-c:v libx264 -preset ultrafast -crf 23 -c:a aac -b:a 128k '
        '-movflags +faststart "$outputPath"';

    debugPrint('[Stitch] Filter complex: $command');

    final session = await FFmpegKit.executeWithStatistics(
      command,
      null,
      null,
      (Statistics statistics) {
        if (onProgress != null) {
          final progress = statistics.videoFrameCount > 0
              ? (statistics.videoFrameCount / (clipPaths.length * 300))
                  .clamp(0.0, 0.95)
              : 0.0;
          onProgress((progress * 100).round(), 'Re-encodando video...');
        }
      },
    );

    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final outputFile = File(outputPath);
      if (await outputFile.exists() && await outputFile.length() > 0) {
        try {
          await File(concatFile).delete();
        } catch (_) {}
        stopwatch.stop();
        return StitchResult.success(
          outputPath: outputPath,
          durationMs: stopwatch.elapsedMilliseconds,
          clipsStitched: clipPaths.length,
        );
      }
    }

    final failReason = await session.getFailReason();
    stopwatch.stop();
    return StitchResult.failure(
      error: 'Stitch falló: ${failReason ?? "desconocido"}',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Cancela una sesión de stitching en progreso.
  Future<void> cancel() async {
    await FFmpegKit.cancel();
    debugPrint('[Stitch] Cancel requested');
  }
}

/// Excepción de validación previa al stitching.
class StitchValidationException implements Exception {
  final String message;
  StitchValidationException(this.message);

  @override
  String toString() => 'StitchValidationException: $message';
}
```

### 3.3 UI: Pantalla de Progreso

#### `lib/features/recording/stitch_progress_screen.dart`

```
┌──────────────────────────────────────┐
│                                      │
│         🔗 Uniendo videos...         │
│                                      │
│    ━━━━━━━━━━━━━━━━━━━━━━━━          │
│    ████████████░░░░░░░░░░  58%      │
│    ━━━━━━━━━━━━━━━━━━━━━━━━          │
│                                      │
│       Procesando clip 3 de 5         │
│                                      │
│                                      │
│         [ Cancelar ]                 │
│                                      │
└──────────────────────────────────────┘
```

**Constructor**:

```dart
class StitchProgressScreen extends StatefulWidget {
  final String projectId;
  final List<int> chunksRecorded;
  final Map<int, int> selectedTakes;

  const StitchProgressScreen({
    required this.projectId,
    required this.chunksRecorded,
    required this.selectedTakes,
    super.key,
  });
}
```

**Comportamiento**:
1. Al montar, inicia `StitchService.stitch()` automáticamente.
2. Reporta progreso en barra linear + texto.
3. Botón "Cancelar" llama a `StitchService.cancel()`.
4. Al completar:
   - Éxito → `Navigator.pop(true)` (outputPath disponible)
   - Fallo → pantalla de error con "Reintentar" y "Cancelar"
5. Si el usuario cancela → limpia `final.mp4` parcial → `Navigator.pop(false)`.

### 3.4 Flujo completo (Pipeline)

```
═══════════════════════════════════════════════════════════
FASE 1: VALIDACIÓN (antes de ejecutar)
═══════════════════════════════════════════════════════════

1. StitchService.getSelectedClipPaths(chunksRecorded, selectedTakes)
   ├─ chunksRecorded sorted: [0, 1, 2]
   ├─ Para cada chunk:
   │   ├─ selectedTakes[chunk] existe? → sí → take N
   │   └─ archivo chunk_X_take_N.mp4 existe? → sí
   └─ Retorna [path0, path1, path2]

2. Si algún chunk no tiene take o archivo no existe:
   └─ StitchValidationException → UI: "Fragmento X no está grabado"


═══════════════════════════════════════════════════════════
FASE 2: STITCHING (ffmpeg)
═══════════════════════════════════════════════════════════

3. _generateConcatFile([path0, path1, path2])
   └─ Crea archivo temporal:
       file '/data/.../chunk_0_take_2.mp4'
       file '/data/.../chunk_1_take_1.mp4'
       file '/data/.../chunk_2_take_1.mp4'

4. FFmpegKit.executeWithStatistics()
   └─ Command: -f concat -safe 0 -i "concat.txt" -c copy "final.mp4"
   ├─ Callback de progreso → actualiza UI (0-100%)
   ├─ Si éxito → verifica archivo > 0 bytes → retorna StitchResult.success
   └─ Si fallo → fallback a filter_complex (re-encode)
       └─ Command: -i clip0 -i clip1 -i clip2
                    -filter_complex "[0:v][0:a][1:v][1:a][2:v][2:a]
                                     concat=n=3:v=1:a=1[outv][outa]"
                    -map "[outv]" -map "[outa]"
                    -c:v libx264 -preset ultrafast -crf 23
                    -c:a aac -b:a 128k
                    -movflags +faststart "final.mp4"


═══════════════════════════════════════════════════════════
FASE 3: POST-STITCH
═══════════════════════════════════════════════════════════

5. Verificar final.mp4:
   ├─ Existe → sí
   ├─ Tamaño > 0 → sí (ej: 45MB)
   └─ Borrar concat file temporal

6. Navigator.pop(true) → caller puede mostrar preview o exportar
```

### 3.5 Edge Cases y Manejo de Errores

| Escenario | Comportamiento |
|---|---|
| **Un chunk no tiene take seleccionado** | `StitchValidationException` antes de ejecutar ffmpeg. UI: "Fragmento 3 no tiene grabación. Graba este fragmento primero." |
| **Archivo de clip borrado o corrupto** | Validación en `getSelectedClipPaths` detecta `!file.exists()`. Error específico con nombre del archivo faltante. |
| **ffmpeg_kit no está disponible (crash al importar)** | Catch en import → mostrar error "Motor de video no disponible." con opción de reintentar. |
| **Concat demuxer falla (codecs incompatibles)** | Automáticamente fallback a `filter_complex` con re-encode (libx264 + aac). Más lento (~3x) pero compatible. |
| **Storage lleno durante stitching** | ffmpeg escribe parcialmente → archivo 0 bytes → detectar post-stitch → error "Espacio insuficiente." |
| **Usuario cancela stitching** | `FFmpegKit.cancel()` → borrar `final.mp4` parcial → volver a la pantalla anterior. |
| **App va a background durante stitching** | ffmpeg corre en thread nativo — continúa. Pero la UI pierde conexión. Al volver, verificar si `final.mp4` existe. Si existe y > 0 bytes → stitching completado. Si no → re-stitch. |
| **Solo 1 clip grabado** | No necesita stitching real. Copiar el clip como `final.mp4` directamente (sin ffmpeg). Optimización: evitar overhead innecesario. |
| **Clips con resolución diferente** | Concat demuxer falla → fallback a filter_complex con `scale` filter implícito de libx264. |
| **Clips con diferente frame rate** | Mismo caso: concat demuxer falla → filter_complex con re-encode. |

---

## 4. Decisiones Tecnológicas

### 4.1 Stack

| Dependencia | Versión | Estado | Justificación |
|---|---|---|---|
| `ffmpeg_kit_flutter` | `^6.0.3` | ❌ Agregar a pubspec | Única librería Flutter que empaqueta ffmpeg pre-compilado para iOS + Android. Alternativas: (a) `ffmpeg_kit_flutter_min_gpl` (menor tamaño, menos codecs), (b) platform channels nativos (AVFoundation/MediaCodec) — pero eso duplica el trabajo. `^6.0.3` es la versión estable más reciente. |
| `path` | `^1.9.0` | ✅ Ya en pubspec (Día 1-2) | Construcción de paths cross-platform. |
| `path_provider` | `^2.1.3` | ✅ Ya en pubspec | Directorios de documentos y temp. |

### 4.2 Decisiones de Diseño

| Decisión | Valor | Justificación |
|---|---|---|
| **Método de concatenación** | Concat demuxer (`-f concat`) primero, filter_complex como fallback | Concat demuxer es **stream copy** (sin re-encode) → 5-10x más rápido. Requiere mismos codecs en todos los clips (que es el caso al grabar con la misma cámara). Filter_complex es el fallback seguro. |
| **Codec de fallback** | libx264 (`-c:v libx264 -preset ultrafast -crf 23`) | `ultrafast` minimiza tiempo de CPU. `crf 23` es el default de buena calidad. Para clips de teleprompter, la diferencia visual es imperceptible. |
| **Audio en fallback** | AAC (`-c:a aac -b:a 128k`) | Codec estándar para MP4. 128kbps es suficiente para voz. |
| **faststart** | `-movflags +faststart` | Permite playback progresivo (el video empieza a reproducirse antes de descargar todo). Crítico para que `video_player` lo reproduzca sin buffering. |
| **Progreso basado en frames** | `statistics.videoFrameCount` | ffmpeg_kit no reporta progreso directo. `videoFrameCount` es el proxy más confiable. Estimación: ~300 frames por clip de 10s a 30fps. |
| **Single clip = no stitching** | Copiar archivo directamente | Si solo hay 1 chunk, no hay nada que concatenar. `File.copy()` es instantáneo vs 5-10s de ffmpeg overhead. |
| **Sobrescribir final.mp4** | Sí, siempre | El usuario puede re-grabar un chunk y necesitar re-stitch. No mantener versiones anteriores (storage). |
| **Cancelar stitching** | `FFmpegKit.cancel()` + borrar output parcial | El usuario puede arrepentirse. Limpiar archivos parciales evita storage leak. |
| **Pantalla de progreso** | Modal dedicada, no background task | El stitching tarda 5-30s — lo suficiente como para necesitar UI pero no tanto como para requerir background processing. |

### 4.3 ffmpeg command — Explicación técnica

**Concat demuxer (primary)**:
```bash
-f concat -safe 0 -i "concat.txt" -c copy "final.mp4"
```
- `-f concat`: usa el demuxer de concatenación
- `-safe 0`: permite paths absolutos en el archivo de lista
- `-i "concat.txt"`: archivo con lista de clips (`file '/path/...'`)
- `-c copy`: stream copy (sin re-encode) → **instantáneo**
- **Requisito**: todos los clips deben tener mismo codec, resolución, frame rate

**Filter complex (fallback)**:
```bash
-i clip0 -i clip1 -i clip2 \
-filter_complex "[0:v][0:a][1:v][1:a][2:v][2:a]concat=n=3:v=1:a=1[outv][outa]" \
-map "[outv]" -map "[outa]" \
-c:v libx264 -preset ultrafast -crf 23 \
-c:a aac -b:a 128k \
-movflags +faststart "final.mp4"
```
- Re-encode completo → más lento (5-30s)
- Funciona con clips de diferente resolución/codec
- `n=3`: número de inputs (dinámico según clips)

### 4.4 Lo que NO se implementa en Día 4-5

| Item | Por qué posponer |
|---|---|
| Persistencia de `session_data.json` | Día 7-8. El stitching se ejecuta en la misma sesión activa. |
| Stitching en background (sin UI blocking) | El stitching dura 5-30s — el usuario espera. No justifica complejidad de background task. |
| Transcodificación de calidad configurable | Para MVP, un solo perfil (high/copy) es suficiente. |
| Previsualización de segmentos antes del stitch | El usuario ya vio cada clip en la review (Día 3). |

---

## 5. Riesgos

### 5.1 Técnicos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| **`ffmpeg_kit_flutter` no compila en iOS/Android** | Media | 🔴 Alto | Este es el riesgo #1 documentado en el MVP. Mitigación: (a) usar `ffmpeg_kit_flutter` ^6.0.3 (versión estable), (b) si falla, probar `ffmpeg_kit_flutter_min` (subset más pequeño), (c) fallback a filter_complex si demuxer falla. Si nada compila, implementar copia directa de archivos como fallback extremo (el usuario tendría un video multi-segmento reproducible en secuencia). |
| **Concat demuxer falla por codec mismatch** | Baja (mismo camera config) | 🟡 Medio | Fallback automático a filter_complex con re-encode. |
| **FFmpeg consume mucha memoria (OOM)** | Media en dispositivos de gama baja | 🔴 Alto | `preset ultrafast` minimiza buffer. Monitorear en dispositivos de 2GB RAM. Si ocurre OOM, reducir a `ResolutionPreset.medium` en grabación. |
| **Stitching lento (>30s)** | Media con filter_complex en gama baja | 🟡 Medio | Barra de progreso con texto "Esto puede tomar unos minutos..." para gestionar expectativas. |
| **Output corrupto (0 bytes)** | Baja | 🟡 Medio | Verificación post-stitch: si `final.mp4` existe pero `length == 0`, tratar como fallo. |

### 5.2 Operativos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| **Usuario no entiende el waiting** | Puede pensar que la app se colgó. | Barra de progreso + texto "Uniendo 3 clips..." + porcentaje visible. |
| **Usuario cancela accidentalmente** | Pierde el progreso del stitch. | Confirmación antes de cancelar: "¿Cancelar? El video no estará listo." |

### 5.3 Escalabilidad

| Problema futuro | Cuándo | Prep ahora |
|---|---|---|
| **Muchos clips (>20)** | Guiones largos con muchos fragmentos | Concat demuxer escala linealmente. Filter_complex puede ser lento con >10 inputs. Si es problema, implementar stitching en lotes (batch de 5 clips → intermedios → final). |
| **Clips de alta resolución (4K)** | Si se cambia `CameraConfig` | Re-encode de 4K es muy lento. Forzar downscale a 1080p en el comando ffmpeg. |
| **Audio desincronizado** | Si los clips tienen drift de timestamp | El concat demuxer preserva timestamps originales. Si hay drift, el filter_complex con re-encode lo corrige. |

### 5.4 Costos

| Item | Costo |
|---|---|
| `ffmpeg_kit_flutter` | Gratis (LGPL) — requiere attribution en credits de la app |
| Tamaño de app | +15-30MB por las librerías nativas de ffmpeg |
| Storage temporal | ~50MB para `final.mp4` (5 clips de 10s a 1080p) |
| CPU durante stitching | Alto pero breve (5-30s). Impacto térmico mínimo para clips cortos. |

---

## 6. Plan de Implementación

### 6.1 Backlog de Tareas

#### T1: Agregar `ffmpeg_kit_flutter` a pubspec.yaml
- [ ] Agregar `ffmpeg_kit_flutter: ^6.0.3`
- [ ] Ejecutar `flutter pub get`
- [ ] Verificar que compila en Android (al menos build, no necesita runtime)
- **Estimación**: 10 min
- **Dependencia**: Ninguna

#### T2: Crear `StitchService`
- **Archivo**: `lib/features/recording/services/stitch_service.dart`
- [ ] Clase `StitchResult` (success/failure factory constructors)
- [ ] Clase `StitchValidationException`
- [ ] `StitchService(projectId)` con:
  - [ ] `finalOutputPath` → ruta de `final.mp4`
  - [ ] `getSelectedClipPaths(chunksRecorded, selectedTakes)` → valida y retorna paths
  - [ ] `_generateConcatFile(clipPaths)` → crea archivo temporal de lista
  - [ ] `stitch()` → ejecuta ffmpeg con concat demuxer
  - [ ] Fallback a filter_complex si demuxer falla
  - [ ] `cancel()` → `FFmpegKit.cancel()`
- [ ] Unit test: `getSelectedClipPaths` con paths válidos e inválidos
- **Estimación**: 1.5 horas
- **Dependencia**: T1

#### T3: Crear `StitchProgressScreen`
- **Archivo**: `lib/features/recording/stitch_progress_screen.dart`
- [ ] Constructor con `projectId`, `chunksRecorded`, `selectedTakes`
- [ ] Al `initState`: auto-iniciar stitching
- [ ] UI de progreso:
  - [ ] Barra linear animada (0-100%)
  - [ ] Texto: "Uniendo X clips..." + porcentaje
  - [ ] Botón "Cancelar" con confirmación
- [ ] Estado de carga → éxito → `Navigator.pop(true)`
- [ ] Estado de carga → error → mostrar error + botón "Reintentar"
- [ ] Cancelación → limpiar `final.mp4` parcial → `Navigator.pop(false)`
- [ ] Manejar `WidgetsBindingObserver` para app lifecycle (background)
- **Estimación**: 1.5 horas
- **Dependencia**: T2

#### T4: Integrar stitching en el flujo de "Terminar sesión"
- **Archivo**: `lib/features/recording/recording_page.dart`
- [ ] Cuando `RecordingState.finished` se activa (último chunk completado o usuario elige "Terminar"):
  - [ ] En vez de ir directo a `RecordingEndPage`, navegar a `StitchProgressScreen`
  - [ ] Si stitching exitoso → ir a `RecordingEndPage` (que ahora puede mostrar `final.mp4`)
  - [ ] Si stitching falla → mostrar error + opción de reintentar
- [ ] Modificar la transición `_stopRecording()` → cuando `finish`:
  ```dart
  case ReviewAction.finish:
    setState(() => _recordingState = RecordingState.finished);
    // Después del build, navegar a stitching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToStitching();
    });
  ```
- [ ] Método `_navigateToStitching()`:
  - [ ] Construir `Map<int, int> selectedTakes` de `_sessionData.takesPerChunk`
  - [ ] Push `StitchProgressScreen`
  - [ ] Al return: si éxito → `RecordingEndPage`, si fallo → volver a idle
- **Estimación**: 45 min
- **Dependencia**: T2, T3

#### T5: Optimización — single clip bypass
- **Archivo**: `lib/features/recording/services/stitch_service.dart`
- [ ] En `stitch()`: si `clipPaths.length == 1` → `File.copy(clipPath, outputPath)` directamente
- [ ] Evitar overhead de ffmpeg para un solo clip
- **Estimación**: 10 min
- **Dependencia**: T2

#### T6: Test en dispositivo físico
- [ ] Grabar 3 fragmentos → "Terminar" → stitching inicia
- [ ] Barra de progreso muestra avance
- [ ] `final.mp4` se crea y es reproducible en VLC
- [ ] Cancelar stitching → `final.mp4` no existe
- [ ] Reintentar stitching cancelado → funciona
- [ ] Probar con 1 solo fragmento → bypass ffmpeg, copy directo
- [ ] Probar con 5+ fragmentos → stitching funciona
- [ ] App a background durante stitching → al volver, verificar resultado
- **Estimación**: 1 hora
- **Dependencia**: T4, T5

### 6.2 Dependencias y Orden

```
T1 ── T2 ──┬── T3 ──┬── T4 ──┬── T6
           │        │        │
           └── T5 ──┘        │
                             └── (T5 ya incluida en T2)

Ruta crítica: T1 → T2 → T3 → T4 → T6
Paralelizable: Ninguna (secuencial por naturaleza)
```

### 6.3 Definition of Done

- [ ] `ffmpeg_kit_flutter` compila en Android (build exitoso)
- [ ] Usuario completa sesión de 3+ fragmentos → stitching automático
- [ ] Barra de progreso visible con porcentaje actualizado
- [ ] `final.mp4` se crea en `vrm_data/projects/{projectId}/final.mp4`
- [ ] `final.mp4` es reproducible en VLC con video + audio
- [ ] Cancelar stitching funciona y limpia archivos parciales
- [ ] Con 1 solo clip, stitching es instantáneo (copy directo)
- [ ] Si un clip falta, muestra error específico (no crash genérico)
- [ ] 0 crashes en 5 ejecuciones de stitching en dispositivo físico

---

## 7. Métricas de Éxito

### 7.1 KPIs Técnicos

| Métrica | Target | Cómo medir |
|---|---|---|
| **Stitching exitoso** | > 95% de intentos producen `final.mp4` válido | Log de cada intento con resultado |
| **Tiempo de stitching** | < 15s para 5 clips de 10s (concat demuxer) | Stopwatch en `StitchService.stitch()` |
| **Fallback rate** | < 20% de stitchings necesitan filter_complex | Contar cuántas veces se ejecuta fallback |
| **Tamaño de `final.mp4`** | < 100MB para 5 clips de 10s a 1080p | `File.length()` post-stitch |
| **Memory peak** | < 200MB durante stitching | `adb shell dumpsys meminfo` durante stitch |
| **Cancelación limpia** | 100% de cancelaciones limpian `final.mp4` parcial | Verificar filesystem tras cancelar |

### 7.2 KPIs de Producto

| Métrica | Target |
|---|---|
| **Usuario percibe stitching como "rápido"** | < 20s percibidos (con UI de progreso) |
| **Tasa de abandono durante stitching** | < 10% de usuarios cancelan |
| **`final.mp4` reproducible** | 100% en dispositivos de prueba |

---

## 8. Estrategia de Testing

### 8.1 Unit Tests

| Archivo | Qué prueba |
|---|---|
| `test/.../services/stitch_service_test.dart` | `getSelectedClipPaths` con paths válidos → retorna lista ordenada |
| | `getSelectedClipPaths` con chunk sin take → lanza `StitchValidationException` |
| | `getSelectedClipPaths` con archivo inexistente → lanza `StitchValidationException` |
| | `getSelectedClipPaths` con lista vacía → lanza `StitchValidationException` |
| | `_generateConcatFile` → archivo creado con formato correcto |
| | Single clip bypass → `File.copy()` en vez de ffmpeg |

**Tests concretos**:
```dart
test('getSelectedClipPaths returns sorted paths', () async {
  // Setup: crear archivos fake
  final service = StitchService(projectId: 'test-1');
  await service.ensureClipsDirectory();
  // ... crear chunk_0_take_1.mp4, chunk_2_take_1.mp4, chunk_1_take_1.mp4
  final paths = await service.getSelectedClipPaths(
    [0, 2, 1], // desordenado
    {0: 1, 1: 1, 2: 1},
  );
  expect(paths.length, 3);
  expect(paths[0], contains('chunk_0_take_1'));
  expect(paths[1], contains('chunk_1_take_1'));
  expect(paths[2], contains('chunk_2_take_1'));
});

test('getSelectedClipPaths throws when chunk has no take', () async {
  final service = StitchService(projectId: 'test-2');
  expect(
    () => service.getSelectedClipPaths([0, 1], {0: 1}), // chunk 1 sin take
    throwsA(isA<StitchValidationException>()),
  );
});
```

### 8.2 Integration Tests (obligatorio en hardware físico)

| Test | Procedimiento | Resultado esperado |
|---|---|---|
| **Happy path** | Grabar 3 fragmentos → "Terminar" | `final.mp4` existe, reproducible, > 0 bytes |
| **Single clip** | Grabar 1 fragmento → "Terminar" | `final.mp4` existe (copia directa), idéntico al original |
| **Multi-take** | Grabar chunk 0 con 3 takes → "Terminar" | Usa solo `selectedTake`, ignora los otros |
| **Missing chunk** | Grabar chunks 0, 1, 3 (saltar 2) → "Terminar" | Error: "Fragmento 2 no tiene grabación" |
| **Cancel stitching** | Iniciar stitching → cancelar a los 5s | `final.mp4` no existe o está vacío |
| **Retry después de cancel** | Cancelar → reintentar | Stitching funciona correctamente |
| **Background** | Iniciar stitching → home → volver | Si stitching completó, `final.mp4` existe. Si no, re-stitch. |
| **5+ clips** | Grabar 5 fragmentos → "Terminar" | Stitching funciona, `final.mp4` reproducible |
| **Corrupt input** | Inyectar archivo 0 bytes como clip | Error detectado, stitching no inicia |

### 8.3 Casos Críticos a Validar

1. **`final.mp4` tiene video + audio de TODOS los clips**: Verificar que cada segmento del video final corresponde al clip original. Si hay silencio o pantalla negra entre clips, el stitching falló.
2. **`final.mp4` es reproducible por `video_player`**: El mismo widget que se usará en Día 6 para preview debe poder reproducirlo.
3. **`final.mp4` tiene `-movflags +faststart`**: Verificar con `ffprobe` que los metadata están al inicio del archivo (permite playback progresivo).
4. **ffmpeg no deja archivos temporales**: Verificar que el concat file temporal se borra tras stitching exitoso o cancelado.

---

## 9. Optimización y Escalabilidad Futura

### 9.1 Problemas que aparecerán al escalar

| Problema | Cuándo | Solución |
|---|---|---|
| **Stitching lento con >10 clips** | Guiones largos con muchos fragmentos | Filter_complex con >10 inputs es O(n²). Implementar stitching en árbol: stitch clips en pares → intermedios → final. Reduce de O(n²) a O(n log n). |
| **Storage por `final.mp4`** | Cada re-stitch genera un archivo nuevo si no se limpia | Ya se sobrescribe. Pero si el usuario re-graba y re-stitcha 10 veces, el filesystem nunca ve el archivo anterior. No hay problema de acumulación. |
| **Calidad degradada con re-encode múltiple** | Si filter_complex se usa repetidamente | Cada re-encode con libx264 a CRF 23 pierde calidad marginalmente. Si el usuario re-stitcha 5 veces con filter_complex, la pérdida es notable. Solución: siempre intentar concat demuxer primero (lossless). |
| **Audio drift entre clips** | Clips de diferente duración con timestamps ligeramente distintos | El concat demuxer preserva timestamps originales — no hay drift. Si hay, el filter_complex con re-encode lo corrige al re-timestamp. |
| **ffmpeg_kit tamaño de app** | +15-30MB puede ser problema para stores | Usar `ffmpeg_kit_flutter_min` en vez de la versión full si solo se necesita concatenación (no codecs especiales). Reduce a ~8MB. |

### 9.2 Cómo preparar el diseño desde ahora

1. **`StitchService` como abstracción**: La clase es independiente y testable. Si en el futuro se reemplaza ffmpeg por AVFoundation/MediaCodec nativo, solo se cambia la implementación interna sin tocar la UI.

2. **`StitchResult` estandarizado**: Incluye `durationMs`, `clipsStitched`, `outputPath` — métricas útiles para analytics y debugging.

3. **Fallback chain**: demuxer → filter_complex. Esta cadena de fallbacks es extensible. Si en el futuro se agrega un tercer método (ej: native platform), se añade como otro fallback.

4. **Validación previa**: `getSelectedClipPaths` valida todo antes de ejecutar ffmpeg. Esto es un patrón reutilizable para cualquier operación costosa: validar primero, ejecutar después.

5. **Single clip bypass**: Esta optimización demuestra que el servicio es consciente del costo. Se pueden agregar más bypasses en el futuro (ej: 2 clips con mismo codec → demuxer directo sin file list).

6. **No over-optimize ahora**:
   - NO implementar stitching en árbol para >10 clips — el MVP no tiene guiones tan largos.
   - NO implementar background stitching — 5-30s de espera es aceptable.
   - NO implementar quality presets — un solo perfil es suficiente para el MVP.
