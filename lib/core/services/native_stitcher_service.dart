import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class StitcherProgress {
  final double progress;
  final String status;
  StitcherProgress(this.progress, this.status);
}

class NativeStitcherService {
  static const MethodChannel _channel = MethodChannel('com.vrm.vrm_app/stitcher');

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
      final projectDir = Directory('${directory.path}/vrm_data/projects/$projectId');
      if (!await projectDir.exists()) {
        await projectDir.create(recursive: true);
      }

      final outputPath = '${projectDir.path}/final_stitched_${DateTime.now().millisecondsSinceEpoch}.mp4';

      onProgress(StitcherProgress(0.1, 'Starting native stitch...'));

      // Llamada directa al código nativo (Muxer de Android / AVFoundation de iOS)
      final bool success = await _channel.invokeMethod('stitchVideos', {
        'clips': clipPaths,
        'outputPath': outputPath,
      });

      if (success) {
        onProgress(StitcherProgress(1.0, 'Completed'));
        return outputPath;
      } else {
        throw Exception('Native stitching encountered an error.');
      }
    } catch (e) {
      onError(e.toString());
      rethrow;
    }
  }
}
