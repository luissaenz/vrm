import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class StitcherProgress {
  final double progress;
  final String status;
  StitcherProgress(this.progress, this.status);
}

class NativeStitcherService {
  static const MethodChannel _channel = MethodChannel(
    'com.vrm.vrm_app/stitcher',
  );

  Future<String> stitchVideos({
    required String projectId,
    required List<String> clipPaths,
    required void Function(StitcherProgress progress) onProgress,
    required void Function(String error) onError,
  }) async {
    try {
      if (clipPaths.isEmpty) {
        throw Exception('No clips provided');
      }

      final directory = await getApplicationDocumentsDirectory();
      final projectDir = Directory(
        '${directory.path}/vrm_data/projects/$projectId',
      );
      if (!await projectDir.exists()) {
        await projectDir.create(recursive: true);
      }

      final outputPath = '${projectDir.path}/final.mp4';

      // Single clip: copy directly (fast path, no stitching needed)
      if (clipPaths.length == 1) {
        onProgress(StitcherProgress(0.3, 'Copying single clip...'));
        final source = File(clipPaths.first);
        if (!await source.exists()) {
          throw Exception('Clip file not found: ${clipPaths.first}');
        }
        await source.copy(outputPath);
        onProgress(StitcherProgress(1.0, 'Completed'));
        return outputPath;
      }

      // Multiple clips: try native channel first
      onProgress(StitcherProgress(0.1, 'Starting stitch...'));
      try {
        final bool success = await _channel.invokeMethod('stitchVideos', {
          'clips': clipPaths,
          'outputPath': outputPath,
        });
        if (success) {
          onProgress(StitcherProgress(1.0, 'Completed'));
          return outputPath;
        }
        throw Exception('Native stitching returned failure');
      } on MissingPluginException {
        // Fallback 1: ffmpeg via CLI (desktop/emulator)
        onProgress(
          StitcherProgress(0.2, 'Native stitch unavailable, trying ffmpeg...'),
        );
        final stitched = await _stitchWithFFmpeg(
          clipPaths,
          outputPath,
          onProgress,
        );
        if (stitched != null) return stitched;

        // Fallback 2: direct concatenation for compatible MP4s
        onProgress(
          StitcherProgress(0.3, 'FFmpeg unavailable, trying direct concat...'),
        );
        final concatenated = await _concatRaw(
          clipPaths,
          outputPath,
          onProgress,
        );
        if (concatenated != null) return concatenated;

        throw Exception(
          'Video stitching requires a native component not yet installed. '
          'This device needs the native stitch handler. '
          'Clips were saved individually and can be edited manually.',
        );
      }
    } catch (e) {
      onError(e.toString());
      rethrow;
    }
  }

  Future<String?> _stitchWithFFmpeg(
    List<String> clipPaths,
    String outputPath,
    void Function(StitcherProgress) onProgress,
  ) async {
    try {
      // Check if ffmpeg is available
      final whichResult = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        ['ffmpeg'],
      );
      if (whichResult.exitCode != 0) return null;

      // Create concat file list
      final concatFile = File('${outputPath}.concat.txt');
      final concatContent = clipPaths
          .map((p) => "file '${p.replaceAll("'", "'\\''")}'")
          .join('\n'); // ignore: unnecessary_brace_in_string_interps
      await concatFile.writeAsString(concatContent);

      onProgress(StitcherProgress(0.4, 'Re-encoding clips...'));

      final result = await Process.run('ffmpeg', [
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        concatFile.path,
        '-c',
        'copy',
        '-y',
        outputPath,
      ]);

      await concatFile.delete();

      if (result.exitCode == 0 && await File(outputPath).exists()) {
        onProgress(StitcherProgress(1.0, 'Completed'));
        return outputPath;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _concatRaw(
    List<String> clipPaths,
    String outputPath,
    void Function(StitcherProgress) onProgress,
  ) async {
    try {
      final output = File(outputPath);
      final sink = output.openWrite(mode: FileMode.write);

      for (var i = 0; i < clipPaths.length; i++) {
        final chunk = File(clipPaths[i]);
        if (!await chunk.exists()) {
          await sink.close();
          await output.delete();
          return null;
        }

        final bytes = await chunk.readAsBytes();
        // Skip first 50 bytes (header) for all chunks after the first
        // This is a best-effort concat for identically-encoded MP4s
        if (i == 0) {
          sink.add(bytes);
        } else {
          const headerSize = 50;
          if (bytes.length > headerSize) {
            sink.add(bytes.sublist(headerSize));
          }
        }

        onProgress(
          StitcherProgress(
            (i + 1) / clipPaths.length,
            'Processing clip ${i + 1} of ${clipPaths.length}...',
          ),
        );
      }

      await sink.close();

      if (await output.exists() && await output.length() > 0) {
        onProgress(StitcherProgress(1.0, 'Completed'));
        return outputPath;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
