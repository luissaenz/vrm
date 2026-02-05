import '../models/asset_manifest.dart';

/// Fase 3: Interfaz de Post-Procesamiento de Video
/// Mejora el asset de video (stitching, audio cleanup, effects, etc.)
abstract class IPostProcessor {
  /// Identificador único del plugin
  String get pluginId;

  /// Mejora el asset de video
  /// @param rawAsset - AssetManifest con status 'raw'
  /// @returns AssetManifest mejorado con status 'processed'
  Future<AssetManifest> enhance(AssetManifest rawAsset);
}
