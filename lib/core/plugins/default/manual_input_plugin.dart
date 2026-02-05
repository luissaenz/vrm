import 'package:uuid/uuid.dart';
import '../../plugins/i_idea_source.dart';
import '../../models/input_schema.dart';

/// Plugin Default: Ingesta manual desde campo de texto
/// Este es el plugin más simple para MVP
class ManualInputPlugin implements IIdeaSource {
  static const _uuid = Uuid();

  @override
  String get pluginId => 'manual_input_v1';

  @override
  Future<InputSchema> fetchIdea(Map<String, dynamic> params) async {
    final topic = params['topic'] as String?;
    if (topic == null || topic.isEmpty) {
      throw Exception('Missing required param: topic');
    }

    return InputSchema(
      ideaId: _uuid.v4(),
      rawTopic: topic,
      sourceType: 'manual',
      contextData: params['context'] as String? ?? '',
    );
  }

  @override
  bool validateParams(Map<String, dynamic> params) {
    return params.containsKey('topic') &&
        params['topic'] is String &&
        (params['topic'] as String).isNotEmpty;
  }
}
