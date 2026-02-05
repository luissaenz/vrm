import 'input_schema.dart';
import 'script_bundle.dart';
import 'asset_manifest.dart';

/// Estado completo de un proyecto (persistencia local JSON)
class ProjectState {
  final String projectId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final InputSchema? input;
  final ScriptBundle? script;
  final List<AssetManifest> assets;

  ProjectState({
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
    this.input,
    this.script,
    this.assets = const [],
  });

  factory ProjectState.fromJson(Map<String, dynamic> json) {
    return ProjectState(
      projectId: json['project_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      input: json['input'] != null
          ? InputSchema.fromJson(json['input'] as Map<String, dynamic>)
          : null,
      script: json['script'] != null
          ? ScriptBundle.fromJson(json['script'] as Map<String, dynamic>)
          : null,
      assets:
          (json['assets'] as List?)
              ?.map(
                (asset) =>
                    AssetManifest.fromJson(asset as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (input != null) 'input': input!.toJson(),
      if (script != null) 'script': script!.toJson(),
      'assets': assets.map((asset) => asset.toJson()).toList(),
    };
  }

  ProjectState copyWith({
    String? projectId,
    DateTime? createdAt,
    DateTime? updatedAt,
    InputSchema? input,
    ScriptBundle? script,
    List<AssetManifest>? assets,
  }) {
    return ProjectState(
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      input: input ?? this.input,
      script: script ?? this.script,
      assets: assets ?? this.assets,
    );
  }
}
