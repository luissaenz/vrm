/// Paquete de video con metadatos de calidad
class AssetManifest {
  final String videoId;
  final String filePath;
  final String status; // raw, processing, processed
  final Map<String, dynamic>? metadata;

  AssetManifest({
    required this.videoId,
    required this.filePath,
    required this.status,
    this.metadata,
  });

  factory AssetManifest.fromJson(Map<String, dynamic> json) {
    return AssetManifest(
      videoId: json['video_id'] as String,
      filePath: json['file_path'] as String,
      status: json['status'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video_id': videoId,
      'file_path': filePath,
      'status': status,
      if (metadata != null) 'metadata': metadata,
    };
  }

  AssetManifest copyWith({
    String? videoId,
    String? filePath,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return AssetManifest(
      videoId: videoId ?? this.videoId,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }
}
