/// Metadata asociada a cada clip grabado.
/// Se usará como input para ffmpeg stitching (Día 4-5).
class ClipMetadata {
  final int chunkIndex;
  final int takeNumber;
  final int durationMs;
  final String resolution; // "1080x1920"
  final int fps;
  final bool hasAudio;
  final int fileSizeBytes;
  final DateTime createdAt;

  ClipMetadata({
    required this.chunkIndex,
    required this.takeNumber,
    required this.durationMs,
    required this.resolution,
    required this.fps,
    required this.hasAudio,
    required this.fileSizeBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'chunkIndex': chunkIndex,
    'takeNumber': takeNumber,
    'durationMs': durationMs,
    'resolution': resolution,
    'fps': fps,
    'hasAudio': hasAudio,
    'fileSizeBytes': fileSizeBytes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ClipMetadata.fromJson(Map<String, dynamic> json) => ClipMetadata(
    chunkIndex: json['chunkIndex'] as int,
    takeNumber: json['takeNumber'] as int,
    durationMs: json['durationMs'] as int,
    resolution: json['resolution'] as String,
    fps: json['fps'] as int,
    hasAudio: json['hasAudio'] as bool,
    fileSizeBytes: json['fileSizeBytes'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  ClipMetadata copyWith({
    int? chunkIndex,
    int? takeNumber,
    int? durationMs,
    String? resolution,
    int? fps,
    bool? hasAudio,
    int? fileSizeBytes,
    DateTime? createdAt,
  }) {
    return ClipMetadata(
      chunkIndex: chunkIndex ?? this.chunkIndex,
      takeNumber: takeNumber ?? this.takeNumber,
      durationMs: durationMs ?? this.durationMs,
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      hasAudio: hasAudio ?? this.hasAudio,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
