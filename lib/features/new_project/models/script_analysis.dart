class ScriptAnalysis {
  final Meta meta;
  final Viability? viability;
  final List<ScriptSegment> segments;

  ScriptAnalysis({required this.meta, this.viability, required this.segments});

  factory ScriptAnalysis.fromJson(Map<String, dynamic> json) {
    return ScriptAnalysis(
      meta: Meta.fromJson(json['meta']),
      viability: json['viability'] != null
          ? Viability.fromJson(json['viability'])
          : null,
      segments: (json['segments'] as List)
          .map((i) => ScriptSegment.fromJson(i))
          .toList(),
    );
  }
}

class Meta {
  final String language;
  final int totalSegments;
  final double estimatedDurationSeconds;

  Meta({
    required this.language,
    required this.totalSegments,
    required this.estimatedDurationSeconds,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      language: json['language'],
      totalSegments: json['total_segments'],
      estimatedDurationSeconds: json['estimated_duration_seconds'].toDouble(),
    );
  }
}

class Viability {
  final String verdict;
  final double retentionScore;
  final String summary;

  Viability({
    required this.verdict,
    required this.retentionScore,
    required this.summary,
  });

  factory Viability.fromJson(Map<String, dynamic> json) {
    return Viability(
      verdict: json['verdict'],
      retentionScore: json['retention_score'].toDouble(),
      summary: json['summary'],
    );
  }
}

class ScriptSegment {
  final int id;
  final String type;
  final String text;
  final SegmentDirection direction;
  final String subtitles;
  final EditMetadata editMetadata;

  ScriptSegment({
    required this.id,
    required this.type,
    required this.text,
    required this.direction,
    required this.subtitles,
    required this.editMetadata,
  });

  factory ScriptSegment.fromJson(Map<String, dynamic> json) {
    return ScriptSegment(
      id: json['id'],
      type: json['type'],
      text: json['text'],
      direction: SegmentDirection.fromJson(json['direction']),
      subtitles: json['subtitles'],
      editMetadata: EditMetadata.fromJson(json['edit_metadata']),
    );
  }
}

class SegmentDirection {
  final String tone;
  final String pauses;
  final String emphasis;

  SegmentDirection({
    required this.tone,
    required this.pauses,
    required this.emphasis,
  });

  factory SegmentDirection.fromJson(Map<String, dynamic> json) {
    return SegmentDirection(
      tone: json['tone'],
      pauses: json['pauses'],
      emphasis: json['emphasis'],
    );
  }
}

class EditMetadata {
  final double durationSeconds;
  final double wpm;

  EditMetadata({required this.durationSeconds, required this.wpm});

  factory EditMetadata.fromJson(Map<String, dynamic> json) {
    return EditMetadata(
      durationSeconds: json['duration_seconds'].toDouble(),
      wpm: json['wpm'].toDouble(),
    );
  }
}
