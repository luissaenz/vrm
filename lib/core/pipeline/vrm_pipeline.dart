import 'package:flutter/foundation.dart';
import '../plugins/i_idea_source.dart';
import '../plugins/i_script_processor.dart';
import '../plugins/i_post_processor.dart';
import '../plugins/i_analytics_provider.dart';
import '../models/input_schema.dart';
import '../models/script_bundle.dart';
import '../models/asset_manifest.dart';
import '../exceptions/pipeline_exceptions.dart';
import '../services/schema_validator.dart';

/// Pipeline Lineal Modular (NO Orquestador IA)
/// Actúa como invocador determinista de plugins intercambiables
class VRMPipeline {
  final IIdeaSource ideaSource;
  final IScriptProcessor scriptProcessor;
  final IPostProcessor postProcessor;
  final IAnalyticsProvider analyticsProvider;

  VRMPipeline({
    required this.ideaSource,
    required this.scriptProcessor,
    required this.postProcessor,
    required this.analyticsProvider,
  });

  /// Ejecuta el pipeline completo: Ingesta → Script → Video → Analytics
  /// Es un flujo DETERMINISTA y LINEAL (no hay agentes autónomos)
  Future<PipelineResult> execute(Map<String, dynamic> initialParams) async {
    try {
      // Fase 1: Ingesta
      debugPrint(
        '[Pipeline] Stage 1: Fetching idea with plugin ${ideaSource.pluginId}',
      );
      final input = await _executeStage(
        'idea_ingestion',
        ideaSource.pluginId,
        () => ideaSource.fetchIdea(initialParams),
      );

      // AUTOMATIZACIÓN: Validar contrato de ingesta
      await SchemaValidator.validate('input_schema', input.toJson());

      // Fase 2: Procesar guion
      debugPrint(
        '[Pipeline] Stage 2: Processing script with plugin ${scriptProcessor.pluginId}',
      );
      final scriptConfig =
          initialParams['script_config'] as Map<String, dynamic>? ?? {};
      final script = await _executeStage(
        'script_processing',
        scriptProcessor.pluginId,
        () => scriptProcessor.process(input, scriptConfig),
      );

      // AUTOMATIZACIÓN: Validar contrato de guion
      await SchemaValidator.validate('script_bundle', script.toJson());

      // Fase 3: Post-procesar video
      debugPrint(
        '[Pipeline] Stage 3: Post-processing with plugin ${postProcessor.pluginId}',
      );
      // NOTA: En implementación real, aquí se graba el video primero
      // Por ahora creamos un placeholder asset para el flujo MVP
      final rawAsset = AssetManifest(
        videoId: script.scriptId,
        filePath: '/placeholder/video_${script.scriptId}.mp4',
        status: 'raw',
        metadata: {'created_at': DateTime.now().toIso8601String()},
      );
      final processedAsset = await _executeStage(
        'post_processing',
        postProcessor.pluginId,
        () => postProcessor.enhance(rawAsset),
      );

      // AUTOMATIZACIÓN: Validar contrato de asset
      await SchemaValidator.validate('asset_manifest', processedAsset.toJson());

      // Fase 4: Métricas
      debugPrint(
        '[Pipeline] Stage 4: Analyzing with plugin ${analyticsProvider.pluginId}',
      );
      final analytics = await _executeStage(
        'analytics',
        analyticsProvider.pluginId,
        () => analyticsProvider.analyze(processedAsset),
      );

      debugPrint('[Pipeline] Execution completed successfully');
      return PipelineResult(
        input: input,
        script: script,
        asset: processedAsset,
        analytics: analytics,
      );
    } catch (e, stackTrace) {
      debugPrint('[Pipeline] Execution failed: $e');
      if (e is PluginException) {
        rethrow;
      }
      throw PipelineException(
        'Pipeline execution failed',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Execute a pipeline stage with error handling
  Future<T> _executeStage<T>(
    String stage,
    String pluginId,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      throw PluginException(
        pluginId: pluginId,
        stage: stage,
        message: e.toString(),
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Ejecuta solo las fases de ingesta y script (útil para preview)
  Future<ScriptBundle> executeScriptOnly(
    Map<String, dynamic> initialParams,
  ) async {
    try {
      debugPrint('[Pipeline] Script-only mode: Fetching idea');
      final input = await _executeStage(
        'idea_ingestion',
        ideaSource.pluginId,
        () => ideaSource.fetchIdea(initialParams),
      );

      debugPrint('[Pipeline] Script-only mode: Processing script');
      final scriptConfig =
          initialParams['script_config'] as Map<String, dynamic>? ?? {};
      final script = await _executeStage(
        'script_processing',
        scriptProcessor.pluginId,
        () => scriptProcessor.process(input, scriptConfig),
      );

      debugPrint('[Pipeline] Script-only mode completed successfully');
      return script;
    } catch (e, stackTrace) {
      debugPrint('[Pipeline] Script-only mode failed: $e');
      if (e is PluginException) {
        rethrow;
      }
      throw PipelineException(
        'Script-only execution failed',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Resultado completo del pipeline
class PipelineResult {
  final InputSchema input;
  final ScriptBundle script;
  final AssetManifest asset;
  final Map<String, dynamic> analytics;

  PipelineResult({
    required this.input,
    required this.script,
    required this.asset,
    required this.analytics,
  });

  Map<String, dynamic> toJson() {
    return {
      'input': input.toJson(),
      'script': script.toJson(),
      'asset': asset.toJson(),
      'analytics': analytics,
    };
  }
}
