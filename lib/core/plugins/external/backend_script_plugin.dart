import '../../../core/api_service.dart';
import '../../plugins/i_script_processor.dart';
import '../../models/input_schema.dart';
import '../../models/script_bundle.dart';

/// Plugin que adapta el backend FastAPI existente
/// Convierte ScriptAnalysis del backend a ScriptBundle
class BackendScriptPlugin implements IScriptProcessor {
  @override
  String get pluginId => 'backend_api_v1';

  @override
  Future<ScriptBundle> process(
    InputSchema input,
    Map<String, dynamic> configuration,
  ) async {
    try {
      // Llamar al backend con el formato que espera
      final response = await ApiService.callPrompt(
        category: 'script',
        name: 'analyze',
        payload: {
          'topic': input.rawTopic,
          'context': input.contextData,
          'profile_id': configuration['profile_id'] ?? 'authority_builder',
        },
      );

      // Adaptar ScriptAnalysis del backend a ScriptBundle
      return _adaptBackendResponse(response);
    } catch (e) {
      throw Exception('Backend script processing failed: $e');
    }
  }

  /// Adapta la respuesta del backend (ScriptAnalysis) a ScriptBundle
  ScriptBundle _adaptBackendResponse(Map<String, dynamic> response) {
    // El backend retorna: { meta: {...}, segments: [...] }
    final meta = response['meta'] as Map<String, dynamic>;
    final segments = response['segments'] as List;

    final chunks = segments.map((segment) {
      final segmentMap = segment as Map<String, dynamic>;
      return ScriptChunk(
        order: segmentMap['id'] as int,
        text: segmentMap['text'] as String,
        estimatedDurationSec:
            (segmentMap['edit_metadata']?['duration_seconds'] as num?)
                ?.toDouble(),
        emotionalTone: segmentMap['direction']?['tone'] as String?,
      );
    }).toList();

    return ScriptBundle(
      scriptId: DateTime.now().millisecondsSinceEpoch.toString(),
      totalChunks: meta['total_segments'] as int,
      chunks: chunks,
    );
  }
}
