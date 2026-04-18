import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:battery_plus/battery_plus.dart';
import '../exceptions/vrm_exceptions.dart';

class StitchingProgress {
  final double progress; // 0.0 to 1.0
  final String status;
  final Duration? estimatedTimeRemaining;

  StitchingProgress({
    required this.progress,
    required this.status,
    this.estimatedTimeRemaining,
  });
}

class FFmpegStitcherService {
  static const String _inputsFileName = 'inputs.txt';

  /// Stitches multiple video clips into a single final video.
  /// Returns the path to the final video file.
  Future<String> stitchVideos({
    required String projectId,
    required List<String> clipPaths,
    required void Function(StitchingProgress) onProgress,
    required void Function(String) onError,
  }) async {
    if (clipPaths.isEmpty) {
      throw ArgumentError('At least one clip path is required');
    }

    // Día 14: Blindaje de batería antes de iniciar stitching (D3)
    final battery = Battery();
    final batteryLevel = await battery.batteryLevel;
    final batteryState = await battery.batteryState;
    
    // Si la batería es baja (< 15%) y no está cargando, bloqueamos la operación
    if (batteryLevel < 15 && batteryState != BatteryState.charging) {
      throw VideoProcessingException(
        'Batería muy baja para procesar video ($batteryLevel%). Conecta el cargador para continuar.',
        code: 'low_battery_stitching',
      );
    }

    if (clipPaths.length == 1) {
      // Single clip: copy directly
      final outputPath = await _getOutputPath(projectId);
      await _copyFile(clipPaths.first, outputPath);
      onProgress(StitchingProgress(progress: 1.0, status: 'Completed'));
      return outputPath;
    }

    // Multiple clips: use FFmpeg concat
    final outputPath = await _getOutputPath(projectId);
    final inputsFilePath = await _createInputsFile(clipPaths, projectId);

    // Calculate total duration for progress tracking
    final totalDurationMs = await _calculateTotalDuration(clipPaths);

    try {
      await _executeStitchCommand(
        inputsFilePath: inputsFilePath,
        outputPath: outputPath,
        totalDurationMs: totalDurationMs,
        onProgress: onProgress,
        onError: onError,
      );
      return outputPath;
    } finally {
      // Clean up inputs file
      await _deleteFileIfExists(inputsFilePath);
    }
  }

  Future<String> _getOutputPath(String projectId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectDir = Directory(path.join(appDir.path, 'vrm_data', 'projects', projectId));
    await projectDir.create(recursive: true);
    return path.join(projectDir.path, 'final.mp4');
  }

  Future<String> _createInputsFile(List<String> clipPaths, String projectId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final inputsFilePath = path.join(appDir.path, _inputsFileName);

    final inputsContent = clipPaths.map((clipPath) => "file '$clipPath'").join('\n');
    await File(inputsFilePath).writeAsString(inputsContent);

    return inputsFilePath;
  }

  Future<int> _calculateTotalDuration(List<String> clipPaths) async {
    int totalDuration = 0;
    for (final clipPath in clipPaths) {
      try {
        final session = await FFprobeKit.execute('-v quiet -print_format json -show_format "$clipPath"');
        final output = await session.getOutput();
        if (output != null) {
          // Parse duration from ffprobe output
          final durationMatch = RegExp(r'"duration":"(\d+\.\d+)"').firstMatch(output);
          if (durationMatch != null) {
            final durationSeconds = double.parse(durationMatch.group(1)!);
            totalDuration += (durationSeconds * 1000).toInt(); // Convert to milliseconds
          }
        }
      } catch (e) {
        debugPrint('Failed to get duration for $clipPath: $e');
        // Continue with other clips, this clip will contribute 0 to total
      }
    }
    return totalDuration;
  }

  Future<void> _executeStitchCommand({
    required String inputsFilePath,
    required String outputPath,
    required int totalDurationMs,
    required void Function(StitchingProgress) onProgress,
    required void Function(String) onError,
  }) async {
    // Try stream copy first (fast)
    final copyCommand = '-f concat -safe 0 -i "$inputsFilePath" -c copy -y "$outputPath"';

    onProgress(StitchingProgress(progress: 0.0, status: 'Starting stitch...'));

    var session = await FFmpegKit.executeAsync(
      copyCommand,
      (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          onProgress(StitchingProgress(progress: 1.0, status: 'Completed'));
        } else {
          // Try fallback re-encoding
          await _tryFallbackReEncoding(
            inputsFilePath: inputsFilePath,
            outputPath: outputPath,
            totalDurationMs: totalDurationMs,
            onProgress: onProgress,
            onError: onError,
          );
        }
      },
      (log) {
        // Handle logs if needed
      },
      (statistics) {
        // Update progress based on statistics
        final progress = _calculateProgress(statistics, totalDurationMs);
        onProgress(StitchingProgress(
          progress: progress,
          status: 'Processing...',
        ));
      },
    );

    // Wait for completion
    await session.getReturnCode();
  }

  Future<void> _tryFallbackReEncoding({
    required String inputsFilePath,
    required String outputPath,
    required int totalDurationMs,
    required void Function(StitchingProgress) onProgress,
    required void Function(String) onError,
  }) async {
    onProgress(StitchingProgress(progress: 0.0, status: 'Re-encoding...'));

    final reEncodeCommand = '-f concat -safe 0 -i "$inputsFilePath" -c:v libx264 -preset ultrafast -crf 23 -c:a aac -y "$outputPath"';

    final session = await FFmpegKit.executeAsync(
      reEncodeCommand,
      (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          onProgress(StitchingProgress(progress: 1.0, status: 'Completed'));
        } else {
          final failStackTrace = await session.getFailStackTrace();
          throw VideoProcessingException(
            'FFmpeg re-encoding failed: $failStackTrace',
            code: 'ffmpeg_fallback_failure',
          );
        }
      },
      (log) {
        // Handle logs if needed
      },
      (statistics) {
        // Update progress based on statistics - for re-encoding, progress might be less accurate
        final progress = (statistics.getTime() / totalDurationMs).clamp(0.0, 1.0);
        onProgress(StitchingProgress(
          progress: progress,
          status: 'Re-encoding...',
        ));
      },
    );

    await session.getReturnCode();
  }

  double _calculateProgress(Statistics statistics, int totalDurationMs) {
    if (totalDurationMs <= 0) return 0.0;

    // Use Statistics.getTime() which returns time in milliseconds
    final currentTimeMs = statistics.getTime();
    if (currentTimeMs < 0) return 0.0;

    final progress = currentTimeMs / totalDurationMs;
    return progress.clamp(0.0, 1.0);
  }

  Future<void> _copyFile(String sourcePath, String destPath) async {
    await File(sourcePath).copy(destPath);
  }

  Future<void> _deleteFileIfExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}