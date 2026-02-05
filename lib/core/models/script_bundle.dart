/// Micro-fragmento individual (chunk) de un guion
class ScriptChunk {
  final int order;
  final String text;
  final double? estimatedDurationSec;
  final String? emotionalTone;

  ScriptChunk({
    required this.order,
    required this.text,
    this.estimatedDurationSec,
    this.emotionalTone,
  });

  factory ScriptChunk.fromJson(Map<String, dynamic> json) {
    return ScriptChunk(
      order: json['order'] as int,
      text: json['text'] as String,
      estimatedDurationSec: (json['estimated_duration_sec'] as num?)
          ?.toDouble(),
      emotionalTone: json['emotional_tone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'text': text,
      if (estimatedDurationSec != null)
        'estimated_duration_sec': estimatedDurationSec,
      if (emotionalTone != null) 'emotional_tone': emotionalTone,
    };
  }
}

/// Guion completo micro-fragmentado (lista enlazada de chunks)
class ScriptBundle {
  final String scriptId;
  final int totalChunks;
  final List<ScriptChunk> chunks;

  ScriptBundle({
    required this.scriptId,
    required this.totalChunks,
    required this.chunks,
  });

  factory ScriptBundle.fromJson(Map<String, dynamic> json) {
    return ScriptBundle(
      scriptId: json['script_id'] as String,
      totalChunks: json['total_chunks'] as int,
      chunks: (json['chunks'] as List)
          .map((chunk) => ScriptChunk.fromJson(chunk as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'script_id': scriptId,
      'total_chunks': totalChunks,
      'chunks': chunks.map((chunk) => chunk.toJson()).toList(),
    };
  }

  ScriptBundle copyWith({
    String? scriptId,
    int? totalChunks,
    List<ScriptChunk>? chunks,
  }) {
    return ScriptBundle(
      scriptId: scriptId ?? this.scriptId,
      totalChunks: totalChunks ?? this.totalChunks,
      chunks: chunks ?? this.chunks,
    );
  }
}
