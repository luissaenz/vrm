/// Estados posibles de un clip en el proceso de revisión.
enum ClipStatus {
  pending,
  recorded,
  approved,
  rejected,
}

/// InformaciÃ³n de takes por chunk dentro de una sesiÃ³n de grabaciÃ³n.
class ChunkTakeInfo {
  final int total;
  final int selectedTake;

  ChunkTakeInfo({required this.total, required this.selectedTake});

  Map<String, dynamic> toJson() => {
    'total': total,
    'selectedTake': selectedTake,
  };

  factory ChunkTakeInfo.fromJson(Map<String, dynamic> json) => ChunkTakeInfo(
    total: json['total'] as int,
    selectedTake: json['selectedTake'] as int,
  );

  ChunkTakeInfo copyWith({int? total, int? selectedTake}) => ChunkTakeInfo(
    total: total ?? this.total,
    selectedTake: selectedTake ?? this.selectedTake,
  );
}

/// Estado de la sesiÃ³n de grabaciÃ³n actual.
/// Persiste en memoria durante DÃ­a 1-2. Se escribe a disco en DÃ­a 7-8.
class SessionData {
  final String projectId;
  final List<int> chunksRecorded;
  final int currentChunkIndex;
  final Map<int, ChunkTakeInfo> takesPerChunk;
  final Map<int, String> approvedClips;
  final DateTime startedAt;
  final DateTime lastUpdatedAt;

  SessionData({
    required this.projectId,
    this.chunksRecorded = const [],
    this.currentChunkIndex = 0,
    this.takesPerChunk = const {},
    this.approvedClips = const {},
    required this.startedAt,
    required this.lastUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'chunksRecorded': chunksRecorded,
    'currentChunkIndex': currentChunkIndex,
    'takesPerChunk': takesPerChunk.map(
      (k, v) => MapEntry(k.toString(), v.toJson()),
    ),
    'approvedClips': approvedClips.map(
      (k, v) => MapEntry(k.toString(), v),
    ),
    'startedAt': startedAt.toIso8601String(),
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
  };

  factory SessionData.fromJson(Map<String, dynamic> json) {
    final rawTakes = json['takesPerChunk'] as Map<String, dynamic>?;
    final rawApproved = json['approvedClips'] as Map<String, dynamic>?;
    return SessionData(
      projectId: json['projectId'] as String,
      chunksRecorded: (json['chunksRecorded'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      currentChunkIndex: json['currentChunkIndex'] as int? ?? 0,
      takesPerChunk: rawTakes?.map(
            (k, v) => MapEntry(
              int.parse(k),
              ChunkTakeInfo.fromJson(v as Map<String, dynamic>),
            ),
          ) ??
          {},
      approvedClips: rawApproved?.map(
            (k, v) => MapEntry(int.parse(k), v as String),
          ) ??
          {},
      startedAt: DateTime.parse(json['startedAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }

  SessionData copyWith({
    List<int>? chunksRecorded,
    int? currentChunkIndex,
    Map<int, ChunkTakeInfo>? takesPerChunk,
    Map<int, String>? approvedClips,
    DateTime? lastUpdatedAt,
  }) {
    return SessionData(
      projectId: projectId,
      chunksRecorded: chunksRecorded ?? this.chunksRecorded,
      currentChunkIndex: currentChunkIndex ?? this.currentChunkIndex,
      takesPerChunk: takesPerChunk ?? this.takesPerChunk,
      approvedClips: approvedClips ?? this.approvedClips,
      startedAt: startedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
