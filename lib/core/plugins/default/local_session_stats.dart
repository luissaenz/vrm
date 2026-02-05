import '../../plugins/i_analytics_provider.dart';
import '../../models/asset_manifest.dart';

/// Plugin Default: Estadísticas básicas de sesión local
/// Cuenta intentos y extrae métricas básicas del metadata
class LocalSessionStats implements IAnalyticsProvider {
  @override
  String get pluginId => 'local_stats_v1';

  @override
  Future<Map<String, dynamic>> analyze(AssetManifest asset) async {
    // Extraer métricas del metadata del asset
    final metadata = asset.metadata ?? {};

    final wpm = metadata['wpm'] as num? ?? 0;
    final gazeScore = metadata['gaze_score'] as num? ?? 0;
    final duration = metadata['total_duration_sec'] as num? ?? 0;

    return {
      'status': 'success',
      'video_id': asset.videoId,
      'metrics': {
        'wpm': wpm.toDouble(),
        'gaze_score': gazeScore.toDouble(),
        'total_duration_sec': duration.toDouble(),
        'quality_score': _calculateQualityScore(
          wpm.toDouble(),
          gazeScore.toDouble(),
        ),
      },
      'session': {
        'processing_attempts': 1,
        'analyzed_at': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Calcula un score de calidad general (0-100)
  double _calculateQualityScore(double wpm, double gazeScore) {
    // Score basado en WPM ideal (120-160) y gaze score
    double wpmScore = 0;
    if (wpm >= 120 && wpm <= 160) {
      wpmScore = 100;
    } else if (wpm > 0) {
      // Penalizar si está fuera del rango ideal
      final deviation = (wpm - 140).abs();
      wpmScore = (100 - deviation).clamp(0, 100);
    }

    // Gaze score ya está normalizado 0-1
    final gazeScorePercent = gazeScore * 100;

    // Promedio ponderado: 40% WPM, 60% Gaze
    return (wpmScore * 0.4 + gazeScorePercent * 0.6).clamp(0, 100);
  }
}
