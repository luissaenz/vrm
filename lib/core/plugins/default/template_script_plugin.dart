import 'package:uuid/uuid.dart';
import '../../plugins/i_script_processor.dart';
import '../../models/input_schema.dart';
import '../../models/script_bundle.dart';

/// Plugin Default: Usa plantillas predefinidas (educativo, viral, etc.)
/// Fragmenta el texto en chunks de aproximadamente 3 segundos
class TemplateScriptPlugin implements IScriptProcessor {
  static const _uuid = Uuid();

  // Configuración de fragmentación
  static const int _wordsPerChunk = 8; // ~3 segundos a 160 WPM
  static const double _estimatedDurationPerChunk = 3.0;

  @override
  String get pluginId => 'template_script_v1';

  @override
  Future<ScriptBundle> process(
    InputSchema input,
    Map<String, dynamic> configuration,
  ) async {
    // Obtener template del configuration o usar default
    final template = configuration['template'] as String? ?? 'default';

    // Generar chunks basados en el contexto
    final chunks = _generateChunks(input.rawTopic, input.contextData, template);

    return ScriptBundle(
      scriptId: _uuid.v4(),
      totalChunks: chunks.length,
      chunks: chunks,
    );
  }

  /// Genera micro-fragmentos desde el texto
  List<ScriptChunk> _generateChunks(
    String topic,
    String context,
    String template,
  ) {
    // Combinar topic y context
    final fullText = context.isNotEmpty ? '$topic. $context' : topic;

    // Dividir en palabras
    final words = fullText.split(RegExp(r'\s+'));
    final chunksData = <ScriptChunk>[];
    int order = 1;

    // Fragmentar en bloques de _wordsPerChunk palabras
    for (int i = 0; i < words.length; i += _wordsPerChunk) {
      final chunkWords = words.skip(i).take(_wordsPerChunk).toList();
      if (chunkWords.isEmpty) continue;

      final chunkText = chunkWords.join(' ');

      // Determinar tono emocional basado en template
      final tone = _determineTone(template, order, chunksData.length);

      chunksData.add(
        ScriptChunk(
          order: order++,
          text: chunkText,
          estimatedDurationSec: _estimatedDurationPerChunk,
          emotionalTone: tone,
        ),
      );
    }

    return chunksData;
  }

  /// Determina el tono emocional según el template
  String _determineTone(String template, int order, int totalSoFar) {
    switch (template) {
      case 'viral':
        return order == 1 ? 'excited' : 'energetic';
      case 'educational':
        return 'neutral';
      case 'storytelling':
        if (order == 1) return 'intriguing';
        if (totalSoFar > 5) return 'exciting';
        return 'calm';
      default:
        return 'neutral';
    }
  }
}
