import '../plugins/i_idea_source.dart';
import '../plugins/i_script_processor.dart';
import '../plugins/i_post_processor.dart';
import '../plugins/default/manual_input_plugin.dart';
import '../plugins/default/template_script_plugin.dart';
import '../plugins/default/stitcher_plugin.dart';
import '../plugins/external/backend_script_plugin.dart';
import 'vrm_pipeline.dart';

/// Factory para crear pipelines con diferentes configuraciones de plugins
/// Implementa el patrón Strategy con inyección de dependencias
class PipelineFactory {
  /// Crea un pipeline con plugins default (100% local, MVP)
  static VRMPipeline createDefaultPipeline() {
    return VRMPipeline(
      ideaSource: ManualInputPlugin(),
      scriptProcessor: TemplateScriptPlugin(),
      postProcessor: StitcherPlugin(),
    );
  }

  /// Crea un pipeline usando el backend para el script processor
  static VRMPipeline createBackendPipeline() {
    return VRMPipeline(
      ideaSource: ManualInputPlugin(),
      scriptProcessor: BackendScriptPlugin(),
      postProcessor: StitcherPlugin(),
    );
  }

  /// Crea un pipeline custom con configuración explícita
  static VRMPipeline createCustomPipeline({
    required IIdeaSource ideaSource,
    required IScriptProcessor scriptProcessor,
    required IPostProcessor postProcessor,
  }) {
    return VRMPipeline(
      ideaSource: ideaSource,
      scriptProcessor: scriptProcessor,
      postProcessor: postProcessor,
    );
  }

  /// Crea un pipeline desde configuración JSON
  /// Esto permite cambiar plugins sin recompilar
  static VRMPipeline createFromConfig(Map<String, dynamic> config) {
    // Leer IDs de plugins desde config
    final scriptProcessorId =
        config['script_processor'] as String? ?? 'template_script_v1';

    // Instanciar plugins según ID
    final ideaSource = ManualInputPlugin();
    final scriptProcessor = _createScriptProcessor(scriptProcessorId);
    final postProcessor = StitcherPlugin();

    return VRMPipeline(
      ideaSource: ideaSource,
      scriptProcessor: scriptProcessor,
      postProcessor: postProcessor,
    );
  }

  static IScriptProcessor _createScriptProcessor(String pluginId) {
    switch (pluginId) {
      case 'backend_api_v1':
        return BackendScriptPlugin();
      case 'template_script_v1':
      default:
        return TemplateScriptPlugin();
    }
  }
}
