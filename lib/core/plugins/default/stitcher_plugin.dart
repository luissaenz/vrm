import 'package:vrm_app/core/services/logger_service.dart';
import '../../plugins/i_post_processor.dart';
import '../../models/asset_manifest.dart';
import '../../services/native_stitcher_service.dart';

/// Plugin Default: FFmpeg Stitcher
/// Usa FFmpeg para concatenar clips de video en un archivo final
///
/// Nota: En la implementación actual del MVP, RecordingManager llama
/// directamente a FFmpegStitcherService para simplificar el flujo.
/// Este plugin se mantiene para futura integración con el pipeline VRM
/// si se requiere extensibilidad por parte de otros plugins.
class StitcherPlugin implements IPostProcessor {
  final NativeStitcherService _stitcherService = NativeStitcherService();

  @override
  String get pluginId => 'ffmpeg_stitcher_v1';

  @override
  Future<AssetManifest> enhance(AssetManifest rawAsset) async {
    // Asumir que rawAsset contiene la lista de clips en metadata['clips']
    final clips = rawAsset.metadata?['clips'] as List<String>? ?? [];

    if (clips.isEmpty) {
      throw ArgumentError('No clips provided for stitching');
    }

    // Asumir projectId está en metadata
    final projectId = rawAsset.metadata?['projectId'] as String? ?? 'unknown';

    try {
      final finalVideoPath = await _stitcherService.stitchVideos(
        projectId: projectId,
        clipPaths: clips,
        onProgress: (progress) {
          // Progress callback - could be exposed to UI if needed
          LoggerService.log(
            'StitcherPlugin',
            'Stitching progress: ${progress.progress} - ${progress.status}',
          );
        },
        onError: (error) {
          throw Exception('Stitching failed: $error');
        },
      );

      return rawAsset.copyWith(
        status: 'stitched',
        metadata: {
          ...?rawAsset.metadata,
          'finalVideoPath': finalVideoPath,
          'stitched_at': DateTime.now().toIso8601String(),
          'processor': pluginId,
        },
      );
    } catch (e) {
      return rawAsset.copyWith(
        status: 'stitching_failed',
        metadata: {
          ...?rawAsset.metadata,
          'error': e.toString(),
          'processor': pluginId,
        },
      );
    }
  }
}
