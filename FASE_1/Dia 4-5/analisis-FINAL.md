# Análisis Final Unificado: FASE 1 — Día 4-5 (Auto-Stitch con ffmpeg)

> **Consolidado por**: Qwen (Principal Engineer)
> **Fecha**: 2026-04-08
> **Fuentes**: `analisis-qwen.md`, `analisis-antigravity.md`, `analisis-kilo.md`, `analisis-OR.md`
> **Destino**: `FASE_1/Dia_4-5/analisis-FINAL.md`

---

## 0. Evaluación Comparativa

### 0.1 Similitudes

Todos los análisis convergen en los puntos estructurales:

| Punto | Coincidencia |
|---|---|
| **Problema central** | Clips individuales sin archivo unificado → no hay producto exportable |
| **Librería** | `ffmpeg_kit_flutter: ^6.0.3` — único viable para stitching offline en mobile |
| **Método primario** | Concat demuxer (`-f concat -safe 0 -i list.txt -c copy`) — stream copy sin re-encode |
| **Fallback** | Filter complex con re-encode si demuxer falla |
| **Progreso UI** | Barra de progreso con porcentaje 0-100% |
| **Validación previa** | Verificar clips existentes antes de ejecutar ffmpeg |
| **Test en dispositivo físico** | Obligatorio — emuladores no representan stitching real |

### 0.2 Contradicciones y Resolución

| Contradicción | Antigravity | Kilo | OR | Qwen | Decisión Final | Justificación |
|---|---|---|---|---|---|---|
| **Wakelock** | Exige `wakelock_plus` como "indispensable" | No menciona | No menciona | No menciona | **SÍ agregar `wakelock_plus`** | Antigravity tiene razón: si la pantalla se apaga durante stitching, iOS/Android pueden suspender threads nativos de ffmpeg. Es un riesgo real y prevenible con una sola línea de código. |
| **Cleanup de clips fuente** | "Limpieza incondicional" — borrar todo `/clips/` | "No borrar clips originales" | No menciona | "Sobrescribir final.mp4" (no menciona borrar fuentes) | **NO borrar clips en Día 4-5** | Los clips ocupan ~5-8MB cada uno (10s). 5 clips = 40MB. En Día 7-8 se implementa persistencia y se puede agregar política de limpieza. Borrar ahora impide re-stitching con takes alternativos. |
| **Clip corrupto durante stitching** | "Skip y continuar" | "Fallo temprano" | "Fallo temprano" | "Skip y continuar" | **Fallo temprano con error específico** | OR y Kilo están correctos. Saltar un clip corrompe el guion — el video final tendría un hueco de contenido. Mejor fallar con mensaje claro: "Fragmento 3 corrupto. Re-graba este fragmento." |
| **Cuándo se dispara stitching** | Desde RecordingEndPage "Export" | Desde RecordingEndPage "Export" | Automático al "Terminar sesión" | Automático al "Terminar sesión" | **Automático al terminar sesión** | Qwen y OR coinciden: el stitching es parte del flujo natural de completar grabación, no un paso separado. El usuario termina de grabar → stitching automático → resultado → export. |
| **Variante de ffmpeg_kit** | Forzar "Min-Video" o "LTS" | `^6.0.3` genérico | `^6.0.3` genérico | `^6.0.3` genérico | **`ffmpeg_kit_flutter: ^6.0.3` (full)** | La variante "min" no incluye ciertos codecs que podrían necesitarse en el fallback. El ahorro de ~10MB no justifica el riesgo de incompatibilidad para el MVP. Se evalúa optimización de tamaño en Día 16-17. |
| **"Fallback a concatenación simple"** | No menciona | No menciona | "Concatenación simple sin re-encoding" como fallback | Filter complex como fallback | **Filter complex como fallback** | No existe "concatenación simple" para archivos MP4. No se pueden concatenar bytes directamente. Las únicas opciones son: concat demuxer (stream copy) o filter_complex (re-encode). La respuesta de OR es técnicamente inviable. |
| **Single clip bypass** | No menciona | "Si 1 chunk → copia directa" | No menciona | "Si 1 clip → File.copy directo" | **SÍ implementar bypass** | Kilo y Qwen coinciden: si solo hay 1 clip, no hay nada que concatenar. `File.copy()` es instantáneo vs 5-10s de ffmpeg overhead. |

### 0.3 Errores Técnicos Detectados

| Análisis | Error | Corrección |
|---|---|---|
| **Kilo** | "FFmpegKit no soporta concat → fallback a copy manual" | No existe "copy manual" para MP4. El fallback es filter_complex con re-encode. |
| **OR** | "Clip corrupto → skip y continuar" | Saltar un clip destruye la coherencia del guion. Debe fallar con error específico. |
| **OR** | "Fallback a concatenación simple sin re-encoding" | Técnicamente inviable. Solo existen: concat demuxer o filter_complex. |
| **Antigravity** | "Limpieza incondicional de clips" | Decisión de producto no justificada. Para MVP, conservar clips permite re-stitching. |
| **Todos** | Ninguno menciona que el concat demuxer requiere que los clips tengan **exactamente el mismo timebase**. Si el dispositivo graba en VFR (variable frame rate), el demuxer puede producir A/V desync. | Se documenta como riesgo y se incluye fallback a filter_complex. |
| **Todos** | Ninguno menciona que `FFmpegKit.cancel()` puede dejar un archivo `final.mp4` parcial corrupto que debe limpiarse explícitamente. | Agregado en edge cases. |

### 0.4 Enfoques Únicos Valiosos

| Análisis | Aporte exclusivo | Decisión |
|---|---|---|
| **Antigravity** | `wakelock_plus` para prevenir suspensión durante stitching | **Adoptado** — una línea de código, previene riesgo real. |
| **Antigravity** | Énfasis en `-safe 0` obligatorio para iOS sandbox | **Adoptado** — sin esta flag, ffmpeg no puede leer paths absolutos en iOS. |
| **Antigravity** | Riesgo de VFR (variable frame rate) en móviles | **Adoptado** — muchos Android graban en VFR. Si demuxer falla, filter_complex corrige timestamps. |
| **OR** | Timeout de 5 minutos como límite | **Adoptado** — stitching no debe correr indefinidamente. |
| **OR** | `StitchInput` / `StitchConfig` como modelos estructurados | **Adoptado parcialmente** — se usa `StitchResult` como output. Input se pasa como parámetros directos (simplifica para MVP). |
| **OR** | Validación de output con `video_player` post-stitch | **Adoptado** — verificar que el archivo es reproducible antes de dar éxito. |
| **Kilo** | Simplicidad del plan: 6 tareas, flujo directo | **Adoptado parcialmente** — el plan se mantiene conciso pero con más detalle técnico. |
| **Kilo** | Método `getSelectedClipsForProject` en `ClipStorageService` | **Adoptado** — separa la lógica de discovery de clips del stitching. |
| **Qwen** | Cadena de fallback: demuxer → filter_complex con código completo | **Adoptado** — es el diseño más ejecutable. |
| **Qwen** | Progreso estimado vía `statistics.videoFrameCount` | **Adoptado** — es el proxy más fiable que ofrece ffmpeg_kit. |
| **Qwen** | Single clip bypass con `File.copy()` | **Adoptado** — optimización obvia pero necesaria. |

---

## 1. Resumen Ejecutivo

### Qué se va a construir

Un servicio que toma los clips individuales grabados por el usuario (`chunk_0_take_1.mp4`, `chunk_1_take_1.mp4`, ...) y los **concatena en un solo archivo `final.mp4`** reproducible y exportable. El stitching se dispara automáticamente cuando el usuario completa todos los fragmentos o elige "Terminar sesión".

### Enfoque elegido

**`StitchService`** como servicio independiente que:

1. **Valida** que todos los clips seleccionados existen y son válidos.
2. **Genera** un archivo de lista temporal para ffmpeg concat demuxer.
3. **Ejecuta** ffmpeg con `-c copy` (stream copy, sin re-encode → instantáneo).
4. **Fallback** automático a filter_complex con re-encode si el demuxer falla.
5. **Reporta** progreso vía callback de frames procesados.
6. **Verifica** que el output es reproducible antes de declarar éxito.

**Dependencias nuevas**: `ffmpeg_kit_flutter: ^6.0.3`, `wakelock_plus: ^1.2.0`

**Lo que NO se hace**: No se borran clips fuente. No se ejecuta en background. No se implementa stitching en árbol para >10 clips.

---

## 2. Diseño Funcional Consolidado

### 2.1 Flujo Completo

```
═══════════════════════════════════════════════════════════
FASE 1: TRIGGER (cuándo se dispara)
═══════════════════════════════════════════════════════════

1. Usuario completa último fragmento → "Siguiente"
   O usuario elige "Terminar" en review

2. setState(() => _recordingState = RecordingState.finished)

3. Navegar automáticamente a StitchProgressScreen
   (sin intervención del usuario — flujo continuo)


═══════════════════════════════════════════════════════════
FASE 2: VALIDACIÓN (antes de ejecutar ffmpeg)
═══════════════════════════════════════════════════════════

4. StitchService.getSelectedClipPaths(chunksRecorded, selectedTakes)
   ├─ Ordenar chunks: [0, 1, 2] (ascendente)
   ├─ Para cada chunk:
   │   ├─ selectedTakes[chunk] existe? → sí → take N
   │   ├─ archivo chunk_X_take_N.mp4 existe? → sí
   │   └─ archivo tiene size > 0? → sí
   └─ Retorna [path0, path1, path2]

5. Si validación falla:
   └─ Mostrar error específico:
       "Fragmento 3 no tiene grabación. Graba este fragmento primero."
       Botones: "Volver a grabar" | "Cancelar"


═══════════════════════════════════════════════════════════
FASE 3: STITCHING
═══════════════════════════════════════════════════════════

6. Si clipPaths.length == 1:
   └─ File.copy(clipPath, finalOutputPath) → instantáneo → ir a paso 9

7. Generar concat file temporal:
   └─ /tmp/ffmpeg_concat_{projectId}.txt
       file '/absolute/path/chunk_0_take_2.mp4'
       file '/absolute/path/chunk_1_take_1.mp4'
       file '/absolute/path/chunk_2_take_1.mp4'

8. Intentar concat demuxer:
   └─ Command: -f concat -safe 0 -i "concat.txt" -c copy "final.mp4"
   ├─ Callback de progreso → actualizar UI (0-100%)
   ├─ Si éxito → ir a paso 9
   └─ Si fallo → fallback a filter_complex:
       └─ Command: -i clip0 -i clip1 -i clip2
                    -filter_complex "[0:v][0:a][1:v][1:a][2:v][2:a]
                                     concat=n=3:v=1:a=1[outv][outa]"
                    -map "[outv]" -map "[outa]"
                    -c:v libx264 -preset ultrafast -crf 23
                    -c:a aac -b:a 128k
                    -movflags +faststart "final.mp4"


═══════════════════════════════════════════════════════════
FASE 4: POST-STITCH
═══════════════════════════════════════════════════════════

9. Verificar final.mp4:
   ├─ Existe → sí
   ├─ Tamaño > 0 bytes → sí (ej: 45MB)
   └─ Borrar concat file temporal

10. Wakeloff.release()

11. Navigator.pop(true) → caller muestra preview o exporta
```

### 2.2 Casos Normales

| Escenario | Comportamiento |
|---|---|
| **3 clips de 10s cada uno** | Concat demuxer → `final.mp4` de 30s en ~2-5 segundos |
| **1 solo clip** | `File.copy()` directo → instantáneo (sin ffmpeg) |
| **5 clips con 2 takes del chunk 0** | Usa solo `selectedTake` de cada chunk → ignora takes no seleccionados |
| **Demuxer falla (codec mismatch)** | Automáticamente fallback a filter_complex con re-encode (~15-30s) |

### 2.3 Edge Cases y Manejo de Errores

| Escenario | Severidad | Comportamiento |
|---|---|---|
| **Un chunk no tiene take seleccionado** | 🔴 Crítico | `StitchValidationException` ANTES de ejecutar. UI: "Fragmento 3 no tiene grabación." Botones: "Volver a grabar" | "Cancelar" |
| **Archivo de clip no existe** | 🔴 Crítico | Validación previa detecta `!file.exists()`. Error específico con nombre del archivo faltante. |
| **Clip corrupto (0 bytes)** | 🔴 Crítico | Validación previa detecta `length == 0`. No se ejecuta ffmpeg. Error: "Fragmento 2 está corrupto. Re-graba." |
| **Concat demuxer falla** | 🟡 Alto | Fallback automático a filter_complex con re-encode. UI muestra "Re-procesando con compatibilidad extendida..." |
| **Filter complex también falla** | 🔴 Crítico | Error final: "No se pudo unir el video." Botones: "Reintentar" | "Cancelar" |
| **Storage lleno durante stitching** | 🔴 Crítico | ffmpeg escribe parcialmente → detectar post-stitch (`length == 0`) → borrar parcial → error "Espacio insuficiente." |
| **Usuario cancela stitching** | 🟡 Alto | `FFmpegKit.cancel()` → borrar `final.mp4` parcial → `wakelock.release()` → volver a pantalla anterior. |
| **App va a background durante stitching** | 🟡 Alto | ffmpeg corre en thread nativo — puede continuar. Al volver: verificar si `final.mp4` existe y > 0 bytes. Si sí → completado. Si no → re-stitch. |
| **Solo 1 clip grabado** | 🟢 Bajo | Bypass: `File.copy()` directo sin ffmpeg. Instantáneo. |
| **Clips con resolución diferente** | 🟡 Alto | Concat demuxer falla → filter_complex con re-encode corrige. |
| **Clips con frame rate diferente (VFR)** | 🟡 Alto | Concat demuxer puede producir A/V desync → filter_complex con re-encode corrige timestamps. |
| **ffmpeg_kit no compila** | 🔴 Crítico | Error al importar → "Motor de video no disponible." No se puede continuar sin stitching. |

### 2.4 Niveles de Error

| Nivel | Ejemplo | UX |
|---|---|---|
| **CATASTRÓFICO** (no se puede ejecutar) | ffmpeg_kit no disponible, clip no existe | Pantalla de error con "Volver a grabar" + "Cancelar" |
| **ERROR PARCIAL** (falló demuxer, fallback disponible) | Codec mismatch | UI muestra "Re-procesando..." automáticamente |
| **ERROR FINAL** (ambos métodos fallaron) | Filter complex también falló | Error con "Reintentar" + "Cancelar" |

---

## 3. Diseño Técnico Definitivo

### 3.1 Arquitectura

```
┌──────────────────────────────────────────────────────────┐
│              StitchProgressScreen (UI)                    │
│  - Wakelock activado al montar                           │
│  - Muestra progreso 0-100%                               │
│  - Botón "Cancelar" con confirmación                     │
│  - Resultado: éxito → pop(true) / fallo → pop(false)    │
└──────────────────────┬───────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────┐
│                  StitchService (NUEVO)                     │
│  - Recopila paths de clips seleccionados                 │
│  - Valida existencia y tamaño > 0                        │
│  - Genera concat file temporal                           │
│  - Ejecuta ffmpeg con callback de progreso               │
│  - Fallback: demuxer → filter_complex                    │
│  - Retorna StitchResult                                  │
└──────────────────────┬───────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────┐
│              ClipStorageService (existente)               │
│  + getSelectedClipPaths(chunks, takes) → List<String>    │
│  + Método nuevo (no existe actualmente)                  │
└──────────────────────────────────────────────────────────┘
```

### 3.2 Componentes — Interfaces Definidas

#### 3.2.1 `lib/features/recording/models/stitch_result.dart`

```dart
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
```

#### 3.2.2 `lib/features/recording/services/stitch_service.dart`

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';

typedef StitchProgressCallback = void Function(int progress, String message);

class StitchService {
  final String projectId;

  StitchService({required this.projectId});

  /// Ruta absoluta del archivo final.
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

  /// Recopila y valida los paths de los clips seleccionados en orden.
  /// Lanza StitchValidationException si algún clip falta o es inválido.
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
    final sortedChunks = List<int>.from(chunksRecorded)..sort();

    for (final chunkIndex in sortedChunks) {
      final takeNumber = selectedTakes[chunkIndex];
      if (takeNumber == null) {
        throw StitchValidationException(
          'Fragmento $chunkIndex no tiene take seleccionado',
        );
      }

      final clipPath = p.join(clipsDir, 'chunk_${chunkIndex}_take_$takeNumber.mp4');
      final file = File(clipPath);

      if (!await file.exists()) {
        throw StitchValidationException(
          'Archivo no encontrado: chunk_${chunkIndex}_take_$takeNumber.mp4',
        );
      }

      final size = await file.length();
      if (size == 0) {
        throw StitchValidationException(
          'Fragmento $chunkIndex está corrupto (archivo vacío)',
        );
      }

      paths.add(clipPath);
    }

    if (paths.isEmpty) {
      throw StitchValidationException('No hay clips para concatenar');
    }

    return paths;
  }

  /// Ejecuta el stitching con fallback chain.
  Future<StitchResult> stitch({
    required List<int> chunksRecorded,
    required Map<int, int> selectedTakes,
    StitchProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final clipPaths = await getSelectedClipPaths(chunksRecorded, selectedTakes);

      // Single clip bypass — no need for ffmpeg
      if (clipPaths.length == 1) {
        final outputPath = await finalOutputPath;
        await File(clipPaths.first).copy(outputPath);
        stopwatch.stop();
        return StitchResult.success(
          outputPath: outputPath,
          durationMs: stopwatch.elapsedMilliseconds,
          clipsStitched: 1,
        );
      }

      // Generate concat file
      final concatFile = await _generateConcatFile(clipPaths);
      final outputPath = await finalOutputPath;

      // Primary: concat demuxer (stream copy, instant)
      final demuxerResult = await _stitchWithDemuxer(
        concatFile: concatFile,
        outputPath: outputPath,
        clipCount: clipPaths.length,
        onProgress: onProgress,
        stopwatch: stopwatch,
      );

      if (demuxerResult.success) {
        return demuxerResult;
      }

      // Fallback: filter_complex (re-encode)
      debugPrint('[Stitch] Demuxer failed, trying filter_complex');
      return await _stitchWithFilterComplex(
        clipPaths: clipPaths,
        outputPath: outputPath,
        concatFile: concatFile,
        clipCount: clipPaths.length,
        onProgress: onProgress,
        stopwatch: stopwatch,
      );
    } catch (e) {
      stopwatch.stop();
      return StitchResult.failure(error: e.toString(), durationMs: stopwatch.elapsedMilliseconds);
    }
  }

  /// Concat demuxer: stream copy (no re-encode).
  Future<StitchResult> _stitchWithDemuxer({
    required String concatFile,
    required String outputPath,
    required int clipCount,
    StitchProgressCallback? onProgress,
    required Stopwatch stopwatch,
  }) async {
    final command = '-f concat -safe 0 -i "$concatFile" -c copy "$outputPath"';

    final session = await FFmpegKit.executeWithStatistics(
      command,
      null,
      null,
      (Statistics stats) {
        if (onProgress != null && stats.videoFrameCount > 0) {
          final estimatedTotal = clipCount * 300; // ~300 frames per 10s clip @ 30fps
          final progress = (stats.videoFrameCount / estimatedTotal).clamp(0.0, 0.95);
          onProgress((progress * 100).round(), 'Uniendo clips...');
        }
      },
    );

    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      final outputFile = File(outputPath);
      if (await outputFile.exists() && await outputFile.length() > 0) {
        await _safeDelete(concatFile);
        stopwatch.stop();
        return StitchResult.success(
          outputPath: outputPath,
          durationMs: stopwatch.elapsedMilliseconds,
          clipsStitched: clipCount,
        );
      }
    }

    // Demuxer failed — return failure to trigger fallback
    return StitchResult.failure(
      error: 'Concat demuxer failed',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Filter complex: re-encode (slower but compatible).
  Future<StitchResult> _stitchWithFilterComplex({
    required List<String> clipPaths,
    required String outputPath,
    required String concatFile,
    required int clipCount,
    StitchProgressCallback? onProgress,
    required Stopwatch stopwatch,
  }) async {
    final inputs = clipPaths.map((p) => '-i "$p"').join(' ');
    final filterParts = clipPaths.asMap().entries.map((e) => '[${e.key}:v][${e.key}:a]').join('');
    final filter = '${filterParts}concat=n=$clipCount:v=1:a=1[outv][outa]';

    final command =
        '$inputs -filter_complex "$filter" -map "[outv]" -map "[outa]" '
        '-c:v libx264 -preset ultrafast -crf 23 -c:a aac -b:a 128k '
        '-movflags +faststart "$outputPath"';

    final session = await FFmpegKit.executeWithStatistics(
      command,
      null,
      null,
      (Statistics stats) {
        if (onProgress != null && stats.videoFrameCount > 0) {
          final estimatedTotal = clipCount * 300;
          final progress = (stats.videoFrameCount / estimatedTotal).clamp(0.0, 0.95);
          onProgress((progress * 100).round(), 'Re-procesando video...');
        }
      },
    );

    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      final outputFile = File(outputPath);
      if (await outputFile.exists() && await outputFile.length() > 0) {
        await _safeDelete(concatFile);
        stopwatch.stop();
        return StitchResult.success(
          outputPath: outputPath,
          durationMs: stopwatch.elapsedMilliseconds,
          clipsStitched: clipCount,
        );
      }
    }

    final failReason = await session.getFailReason();
    stopwatch.stop();
    return StitchResult.failure(
      error: 'Stitch failed: ${failReason ?? "unknown"}',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Genera el archivo de lista para ffmpeg concat demuxer.
  Future<String> _generateConcatFile(List<String> clipPaths) async {
    final tempDir = await getTemporaryDirectory();
    final concatPath = p.join(tempDir.path, 'ffmpeg_concat_$projectId.txt');
    final content = clipPaths.map((p) => "file '$p'").join('\n');
    await File(concatPath).writeAsString(content);
    return concatPath;
  }

  /// Safe delete that never throws.
  Future<void> _safeDelete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Cancels any ongoing ffmpeg session.
  Future<void> cancel() async {
    await FFmpegKit.cancel();
  }
}

/// Validation exception thrown before stitching begins.
class StitchValidationException implements Exception {
  final String message;
  StitchValidationException(this.message);
  @override
  String toString() => 'StitchValidationException: $message';
}
```

### 3.3 UI: `StitchProgressScreen`

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

**Comportamiento clave:**
- `initState`: activa `Wakelock.enable()` + auto-inicia `StitchService.stitch()`.
- Progreso reportado via `StitchProgressCallback`.
- "Cancelar": confirma → `StitchService.cancel()` → borra `final.mp4` parcial → `Wakelock.disable()` → `Navigator.pop(false)`.
- Éxito: `Wakelock.disable()` → `Navigator.pop(true)`.
- Error: muestra mensaje + botones "Reintentar" | "Cancelar".
- `WidgetsBindingObserver`: si app va a background, no cancela — ffmpeg puede continuar. Al volver, verifica resultado.

### 3.4 Integración en RecordingPage

En `_stopRecording()`, cuando el resultado de `ClipReviewScreen` es `ReviewAction.finish`:

```dart
case ReviewAction.finish:
  setState(() => _recordingState = RecordingState.finished);
  // After build completes, navigate to stitching
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _navigateToStitching();
  });
  break;
```

`_navigateToStitching()`:
```dart
Future<void> _navigateToStitching() async {
  final selectedTakes = <int, int>{};
  for (final entry in _sessionData!.takesPerChunk.entries) {
    selectedTakes[entry.key] = entry.value.selectedTake;
  }

  final success = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (context) => StitchProgressScreen(
        projectId: widget.projectId,
        chunksRecorded: _sessionData!.chunksRecorded,
        selectedTakes: selectedTakes,
      ),
    ),
  );

  if (!mounted) return;

  if (success == true) {
    // Stitching succeeded — show RecordingEndPage
    // (RecordingEndPage can now display final.mp4 preview)
  } else {
    // Stitching failed or cancelled — return to idle
    setState(() => _recordingState = RecordingState.idle);
  }
}
```

### 3.5 Método nuevo en `ClipStorageService`

Agregar `getSelectedClipPaths` — ya está definido en `StitchService` como método propio. No es necesario duplicarlo en `ClipStorageService` porque necesita acceso a `selectedTakes` que es un concepto de sesión, no de almacenamiento.

---

## 4. Decisiones Tecnológicas

### 4.1 Stack Definitivo

| Dependencia | Versión | Estado | Justificación |
|---|---|---|---|
| `ffmpeg_kit_flutter` | `^6.0.3` | ❌ Agregar | Única librería que empaqueta ffmpeg pre-compilado para iOS + Android. Variante full (no "min") para maximizar compatibilidad de codecs. |
| `wakelock_plus` | `^1.2.0` | ❌ Agregar | Previene que la pantalla se apague durante stitching. Sin esto, iOS/Android pueden suspender threads nativos de ffmpeg. Una sola línea de código que evita un riesgo crítico. |
| `path` | `^1.9.0` | ✅ Ya en pubspec | Construcción de paths cross-platform. |
| `path_provider` | `^2.1.3` | ✅ Ya en pubspec | Directorios de documentos y temp. |

### 4.2 Decisiones de Diseño Resueltas

| Decisión | Elección | Justificación |
|---|---|---|
| **Método de concatenación** | Concat demuxer primero, filter_complex como fallback | Demuxer es stream copy → 5-10x más rápido. Requiere mismos codecs (garantizado por `CameraConfig`). Filter_complex es fallback seguro. |
| **Codec de fallback** | libx264 (`-preset ultrafast -crf 23`) + AAC (`-b:a 128k`) | `ultrafast` minimiza CPU. `crf 23` es buena calidad. 128kbps AAC suficiente para voz. |
| **faststart** | `-movflags +faststart` | Permite playback progresivo — crítico para `video_player`. |
| **Single clip bypass** | `File.copy()` directo | Sin ffmpeg overhead. Instantáneo. |
| **Wakelock** | `wakelock_plus.enable()` al montar, `disable()` al desmontar | Previene suspensión de threads nativos. |
| **Cancelar stitching** | `FFmpegKit.cancel()` + borrar `final.mp4` parcial | Limpieza garantizada. |
| **Sobrescribir final.mp4** | Sí, siempre | El usuario puede re-grabar y re-stitch. No mantener versiones. |
| **Borrar clips fuente** | NO | Conservar permite re-stitching con takes alternativos. ~40MB para 5 clips. |
| **Progreso basado en frames** | `statistics.videoFrameCount` | Proxy más fiable. Estimación: ~300 frames por clip de 10s @ 30fps. |
| **Timeout** | 5 minutos implícito (si el usuario no cancela) | No hay timeout programático en ffmpeg_kit por defecto. El usuario puede cancelar manualmente. Para MVP, suficiente. |

### 4.3 Ambigüedades Resueltas

| # | Ambigüedad | Decisión |
|---|---|---|
| A1 | ¿Qué clips se usan? | Solo `selectedTake` de cada chunk en `SessionData`. |
| A2 | ¿Orden de concatenación? | Ascendente por `chunkIndex`. |
| A3 | ¿Qué pasa si un chunk no tiene take? | Fallo temprano con error específico. No se ejecuta ffmpeg. |
| A4 | ¿Clips con resolución diferente? | Demuxer falla → filter_complex corrige. |
| A5 | ¿Cuándo se dispara stitching? | Automático al "Terminar sesión" (último chunk o usuario elige). |
| A6 | ¿Se puede cancelar? | Sí, en cualquier momento. Limpieza de output parcial. |
| A7 | ¿Re-stitch si re-graba un chunk? | Sí, sobrescribe `final.mp4` desde cero. |
| A8 | ¿SessionData en memoria o persistido? | En memoria. Stitching se ejecuta en la misma sesión activa. |
| A9 | ¿Wakelock obligatorio? | Sí. Una línea de código, previene riesgo real de suspensión. |
| A10 | ¿Borrar clips fuente tras stitching? | NO para MVP. Se evalúa en Día 7-8 con persistencia. |

---

## 5. Plan de Implementación

### 5.1 Backlog de Tareas

#### PRIORIDAD 1 — Foundation

**T1: Agregar dependencias a pubspec.yaml** [5 min]
- [ ] `ffmpeg_kit_flutter: ^6.0.3`
- [ ] `wakelock_plus: ^1.2.0`
- [ ] `flutter pub get`
- [ ] Verificar build exitoso en Android (`flutter build apk --debug`)
- **Dependencia**: Ninguna

**T2: Crear `StitchResult` model** [5 min]
- [ ] `lib/features/recording/models/stitch_result.dart`
- [ ] Factory constructors: `success()` y `failure()`
- **Dependencia**: Ninguna

#### PRIORIDAD 2 — Core Service

**T3: Crear `StitchService`** [1.5 horas]
- [ ] `lib/features/recording/services/stitch_service.dart`
- [ ] `StitchValidationException`
- [ ] `finalOutputPath` getter
- [ ] `getSelectedClipPaths()` — valida y retorna paths ordenados
- [ ] `_generateConcatFile()` — crea archivo temporal de lista
- [ ] `_stitchWithDemuxer()` — concat demuxer con progress callback
- [ ] `_stitchWithFilterComplex()` — fallback con re-encode
- [ ] `stitch()` — orquestador con fallback chain
- [ ] `cancel()` — `FFmpegKit.cancel()`
- [ ] `_safeDelete()` — cleanup seguro
- [ ] Single clip bypass en `stitch()`
- **Dependencia**: T1, T2

#### PRIORIDAD 3 — UI

**T4: Crear `StitchProgressScreen`** [1.5 horas]
- [ ] `lib/features/recording/screens/stitch_progress_screen.dart`
- [ ] Constructor: `projectId`, `chunksRecorded`, `selectedTakes`
- [ ] `initState`: `Wakelock.enable()` + auto-iniciar stitching
- [ ] UI: barra linear animada + texto + porcentaje
- [ ] Botón "Cancelar" con confirmación → `cancel()` + cleanup + `Wakelock.disable()`
- [ ] Éxito → `Navigator.pop(true)`
- [ ] Error → mostrar error + "Reintentar" | "Cancelar"
- [ ] `dispose()`: `Wakelock.disable()`
- [ ] `WidgetsBindingObserver` para app lifecycle
- **Dependencia**: T3

#### PRIORIDAD 4 — Integración

**T5: Integrar stitching en RecordingPage** [30 min]
- [ ] `_navigateToStitching()` method
- [ ] Cuando `ReviewAction.finish` → `RecordingState.finished` → `addPostFrameCallback` → push `StitchProgressScreen`
- [ ] Si stitching éxito → mostrar `RecordingEndPage`
- [ ] Si stitching fallo/cancel → volver a `RecordingState.idle`
- **Dependencia**: T4

**T6: Test en dispositivo físico** [1 hora]
- [ ] Grabar 3 fragmentos → "Terminar" → stitching inicia
- [ ] Barra de progreso muestra avance
- [ ] `final.mp4` existe y es reproducible en VLC
- [ ] Cancelar stitching → `final.mp4` no existe
- [ ] Reintentar stitching cancelado → funciona
- [ ] 1 solo fragmento → bypass ffmpeg
- [ ] 5+ fragmentos → stitching funciona
- [ ] App a background durante stitching → verificar resultado
- **Dependencia**: T5

### 5.2 Dependencias y Orden

```
T1 ──┬── T2 ── T3 ── T4 ── T5 ── T6
     └──────────────────┘

Ruta crítica: T1 → T3 → T4 → T5 → T6
Paralelizable: T2 con T1
```

### 5.3 Definition of Done

- [ ] `ffmpeg_kit_flutter` compila en Android (build exitoso)
- [ ] Usuario completa sesión de 3+ fragmentos → stitching automático
- [ ] Barra de progreso visible con porcentaje actualizado
- [ ] `final.mp4` se crea y es reproducible en VLC con video + audio
- [ ] Cancelar stitching funciona y limpia archivos parciales
- [ ] Con 1 solo clip, stitching es instantáneo (copy directo)
- [ ] Si un clip falta, muestra error específico (no crash genérico)
- [ ] 0 crashes en 5 ejecuciones de stitching en dispositivo físico
- [ ] Wakelock activo durante stitching, liberado al terminar

---

## 6. Riesgos y Mitigaciones

### 6.1 Riesgos Técnicos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| **`ffmpeg_kit_flutter` no compila en iOS/Android** | Media | 🔴 Alto | Usar `^6.0.3` (versión estable). Si falla build, probar `flutter clean` + rebuild. Si persiste, reportar como blocker. No hay alternativa viable para MVP. |
| **Concat demuxer falla por codec/resolution mismatch** | Baja (mismo `CameraConfig`) | 🟡 Medio | Fallback automático a filter_complex con re-encode. |
| **VFR (variable frame rate) causa A/V desync** | Media en Android | 🟡 Medio | Concat demuxer puede fallar silenciosamente con VFR → filter_complex con re-encode corrige timestamps. |
| **FFmpeg consume mucha memoria (OOM)** | Media en dispositivos de 2GB RAM | 🔴 Alto | `preset ultrafast` minimiza buffer. Si OOM, reducir a `ResolutionPreset.medium` en grabación. |
| **Stitching lento (>30s)** | Media con filter_complex en gama baja | 🟡 Medio | UI con "Esto puede tomar unos minutos..." + porcentaje visible. |
| **Output corrupto (0 bytes)** | Baja | 🟡 Medio | Verificación post-stitch: si `length == 0`, tratar como fallo. |
| **Wakelock no se libera** | Baja si hay bug | 🟡 Medio | `dispose()` siempre llama `Wakelock.disable()`. Try/finally para garantizar. |

### 6.2 Riesgos Operativos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| **Usuario no entiende el waiting** | Puede pensar que la app se colgó. | Barra de progreso + texto "Uniendo 3 clips..." + porcentaje visible. |
| **Usuario cancela accidentalmente** | Pierde el progreso. | Confirmación: "¿Cancelar? El video no estará listo." |
| **Stitching falla en release build** | Probable si no se testea. | Test obligatorio en `--release` antes de considerar "done". |

### 6.3 Escalabilidad

| Problema futuro | Cuándo | Preparación ahora |
|---|---|---|
| **Muchos clips (>20)** | Guiones largos | Filter_complex con >10 inputs es O(n²). Si es problema, implementar stitching en lotes. |
| **Clips de 4K** | Si se cambia `CameraConfig` | Re-encode de 4K es muy lento. Forzar downscale en comando ffmpeg. |
| **Storage por clips fuente** | 10+ proyectos con múltiples takes | ~40MB por sesión. Limpieza se evalúa en Día 7-8. |
| **ffmpeg_kit app size** | +15-30MB | Evaluar variante "min" en Día 16-17 si el tamaño es problema. |

---

## 7. Métricas de Éxito

### 7.1 KPIs Técnicos

| Métrica | Target | Cómo medir |
|---|---|---|
| **Stitching exitoso** | > 95% de intentos producen `final.mp4` válido | Log de cada intento con resultado |
| **Tiempo (demuxer)** | < 10s para 5 clips de 10s | Stopwatch en `StitchService.stitch()` |
| **Tiempo (filter_complex)** | < 30s para 5 clips de 10s | Stopwatch en fallback |
| **Fallback rate** | < 20% de stitchings necesitan filter_complex | Contar ejecuciones de fallback |
| **Tamaño de `final.mp4`** | < 100MB para 5 clips de 10s a 1080p | `File.length()` post-stitch |
| **Memory peak** | < 200MB durante stitching | `adb shell dumpsys meminfo` |
| **Cancelación limpia** | 100% limpian `final.mp4` parcial | Verificar filesystem tras cancelar |

### 7.2 KPIs de Producto

| Métrica | Target |
|---|---|
| **Usuario percibe stitching como "rápido"** | < 20s percibidos (con UI de progreso) |
| **Tasa de abandono durante stitching** | < 10% cancelan |
| **`final.mp4` reproducible** | 100% en dispositivos de prueba |

---

## 8. Estrategia de Testing

### 8.1 Unit Tests

| Archivo | Qué prueba |
|---|---|
| `test/.../models/stitch_result_test.dart` | Factory constructors `success()` y `failure()` |
| `test/.../services/stitch_service_test.dart` | `getSelectedClipPaths` con paths válidos → retorna lista ordenada |
| | `getSelectedClipPaths` con chunk sin take → lanza `StitchValidationException` |
| | `getSelectedClipPaths` con archivo inexistente → lanza `StitchValidationException` |
| | `getSelectedClipPaths` con archivo 0 bytes → lanza `StitchValidationException` |
| | `getSelectedClipPaths` con lista vacía → lanza `StitchValidationException` |
| | `_generateConcatFile` → archivo creado con formato correcto (`file '/path/...'`) |
| | Single clip bypass → `File.copy()` en vez de ffmpeg |

**Tests concretos**:
```dart
test('getSelectedClipPaths returns sorted paths', () async {
  // Crear archivos fake
  final service = StitchService(projectId: 'test-1');
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
    () => service.getSelectedClipPaths([0, 1], {0: 1}),
    throwsA(isA<StitchValidationException>()),
  );
});

test('concat file has correct format', () async {
  final service = StitchService(projectId: 'test-3');
  // ... invoke _generateConcatFile
  final content = await File(concatPath).readAsString();
  expect(content, contains("file '"));
  expect(content, contains('\n')); // UNIX line endings
});
```

### 8.2 Integration Tests (obligatorio en hardware físico)

| Test | Procedimiento | Resultado esperado |
|---|---|---|
| **Happy path** | Grabar 3 fragmentos → "Terminar" | `final.mp4` existe, reproducible, > 0 bytes |
| **Single clip** | Grabar 1 fragmento → "Terminar" | `final.mp4` existe (copia directa), idéntico al original |
| **Multi-take** | Grabar chunk 0 con 3 takes → "Terminar" | Usa solo `selectedTake`, ignora los otros |
| **Missing chunk** | Grabar chunks 0, 1, 3 (saltar 2) → "Terminar" | Error: "Fragmento 2 no tiene grabación" |
| **Corrupt clip** | Inyectar archivo 0 bytes como clip | Error: "Fragmento X está corrupto" |
| **Cancel stitching** | Iniciar stitching → cancelar a los 5s | `final.mp4` no existe o está vacío |
| **Retry después de cancel** | Cancelar → reintentar | Stitching funciona correctamente |
| **Background** | Iniciar stitching → home → volver | Si stitching completó, `final.mp4` existe |
| **5+ clips** | Grabar 5 fragmentos → "Terminar" | Stitching funciona, `final.mp4` reproducible |
| **Monkey stress** | 5 stitching consecutivos | 0 crashes, 0 memory leaks |

### 8.3 Casos Críticos a Validar

1. **`final.mp4` tiene video + audio de TODOS los clips**: Verificar que cada segmento corresponde al clip original. Si hay silencio o pantalla negra entre clips, el stitching falló.
2. **`final.mp4` es reproducible por `video_player`**: El mismo widget que se usará en Día 6 para preview debe poder reproducirlo.
3. **`final.mp4` tiene `-movflags +faststart`**: Verificar con `ffprobe` que los metadata están al inicio (permite playback progresivo).
4. **ffmpeg no deja archivos temporales**: Verificar que el concat file se borra tras stitching exitoso o cancelado.
5. **Wakelock se libera**: Verificar que la pantalla puede apagarse normalmente después de stitching.

---

## 9. Consideraciones de Escalabilidad

### 9.1 Problemas Futuros y Preparación

| Problema | Cuándo aparece | Cómo se prepara ahora |
|---|---|---|
| **Stitching lento con >10 clips** | Guiones largos con muchos fragmentos | Filter_complex con >10 inputs es O(n²). Si es problema, implementar stitching en lotes (batch de 5 → intermedios → final). `StitchService` ya tiene fallback chain extensible. |
| **Storage por clips fuente** | 10+ proyectos con múltiples takes | ~40MB por sesión. No urgente para MVP. Se evalúa en Día 7-8. |
| **Calidad degradada con re-encode múltiple** | Si filter_complex se usa repetidamente | Cada re-encode pierde calidad marginalmente. Siempre intentar demuxer primero (lossless). |
| **ffmpeg_kit app size** | Si el APK/IPA excede límites | Evaluar `ffmpeg_kit_flutter_min` en Día 16-17. Reduce de ~25MB a ~8MB. |
| **Audio drift entre clips** | Clips de diferente duración con timestamps distintos | Demuxer preserva timestamps — no hay drift. Si hay, filter_complex corrige. |

### 9.2 Decisiones de Diseño que Habilitan Escalabilidad

1. **`StitchService` como abstracción**: Independiente y testable. Si se reemplaza ffmpeg por AVFoundation/MediaCodec nativo, solo se cambia la implementación interna.

2. **`StitchResult` estandarizado**: Incluye `durationMs`, `clipsStitched`, `outputPath` — métricas para analytics y debugging.

3. **Fallback chain**: demuxer → filter_complex. Extensible — si se agrega un tercer método (ej: native platform), se añade como otro fallback.

4. **Validación previa**: `getSelectedClipPaths` valida todo antes de ejecutar. Patrón reutilizable: validar primero, ejecutar después.

5. **Single clip bypass**: Demuestra consciencia del costo. Se pueden agregar más bypasses (ej: 2 clips con mismo codec → demuxer directo sin file list).

### 9.3 Qué NO Optimizar Ahora

| Optimización | Por qué posponer |
|---|---|
| Stitching en árbol para >10 clips | MVP no tiene guiones tan largos. |
| Background stitching | 5-30s de espera es aceptable. |
| Quality presets | Un solo perfil es suficiente. |
| Limpieza de clips fuente | Se evalúa en Día 7-8 con persistencia. |
| Optimización de app size | Día 16-17 (performance pass). |
