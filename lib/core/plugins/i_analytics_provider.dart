import '../models/asset_manifest.dart';

/// Fase 4: Interfaz de Análisis y Métricas
/// Analiza el video y retorna métricas de calidad
abstract class IAnalyticsProvider {
  /// Identificador único del plugin
  String get pluginId;

  /// Analiza el video y retorna métricas
  /// @param asset - AssetManifest a analizar
  /// @returns Map con métricas (wpm, gaze_score, etc.)
  Future<Map<String, dynamic>> analyze(AssetManifest asset);
}
