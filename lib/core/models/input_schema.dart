/// Contrato de Ingesta - Datos normalizados de cualquier fuente de idea
class InputSchema {
  final String ideaId;
  final String rawTopic;
  final String sourceType;
  final String contextData;

  InputSchema({
    required this.ideaId,
    required this.rawTopic,
    required this.sourceType,
    this.contextData = '',
  });

  factory InputSchema.fromJson(Map<String, dynamic> json) {
    return InputSchema(
      ideaId: json['idea_id'] as String,
      rawTopic: json['raw_topic'] as String,
      sourceType: json['source_type'] as String,
      contextData: json['context_data'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idea_id': ideaId,
      'raw_topic': rawTopic,
      'source_type': sourceType,
      'context_data': contextData,
    };
  }
}
