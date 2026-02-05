import '../../plugins/i_post_processor.dart';
import '../../models/asset_manifest.dart';

/// Plugin Default: Stitcher Nativo (Placeholder para MVP)
/// En producción usará AVFoundation (iOS) / MediaCodec (Android)
/// Por ahora solo marca el asset como procesado
class StitcherPlugin implements IPostProcessor {
  @override
  String get pluginId => 'native_stitcher_v1';

  @override
  Future<AssetManifest> enhance(AssetManifest rawAsset) async {
    // TODO: Implementar stitching real con APIs nativas
    // iOS: AVFoundation AVMutableComposition
    // Android: MediaCodec + MediaMuxer
    //
    // Por ahora retorna el asset marcado como procesado
    // para no bloquear el flujo del MVP

    return rawAsset.copyWith(
      status: 'processed',
      metadata: {
        ...?rawAsset.metadata,
        'processed_at': DateTime.now().toIso8601String(),
        'processor': pluginId,
      },
    );
  }

  // TODO: Implementar método real de stitching
  // Future<String> _stitchVideos(List<String> videoPaths) async {
  //   // Platform-specific implementation
  //   if (Platform.isIOS) {
  //     return await _stitchWithAVFoundation(videoPaths);
  //   } else if (Platform.isAndroid) {
  //     return await _stitchWithMediaCodec(videoPaths);
  //   }
  //   throw UnsupportedError('Platform not supported');
  // }
}
