import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project_state.dart';
import '../exceptions/pipeline_exceptions.dart';

/// Repository for managing project persistence as JSON files
class ProjectRepository {
  static const _projectsFolder = 'projects';

  /// Get the projects directory path
  Future<String> _getProjectsPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectsDir = Directory('${appDir.path}/$_projectsFolder');

    // Create directory if it doesn't exist
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }

    return projectsDir.path;
  }

  /// Get the file path for a specific project
  Future<String> _getProjectFilePath(String projectId) async {
    final projectsPath = await _getProjectsPath();
    return '$projectsPath/$projectId.json';
  }

  /// Save a project to disk as JSON
  Future<void> saveProject(ProjectState project) async {
    try {
      final filePath = await _getProjectFilePath(project.projectId);
      final file = File(filePath);

      final jsonString = jsonEncode(project.toJson());
      await file.writeAsString(jsonString, flush: true);
    } catch (e) {
      throw PersistenceException(
        operation: 'save',
        projectId: project.projectId,
        message: 'Failed to save project',
        cause: e,
      );
    }
  }

  /// Load a project from disk by ID
  Future<ProjectState?> loadProject(String projectId) async {
    try {
      final filePath = await _getProjectFilePath(projectId);
      final file = File(filePath);

      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return ProjectState.fromJson(jsonData);
    } catch (e) {
      throw PersistenceException(
        operation: 'load',
        projectId: projectId,
        message: 'Failed to load project',
        cause: e,
      );
    }
  }

  /// List all projects
  Future<List<ProjectState>> listProjects() async {
    try {
      final projectsPath = await _getProjectsPath();
      final projectsDir = Directory(projectsPath);

      if (!await projectsDir.exists()) {
        return [];
      }

      final files = projectsDir.listSync().whereType<File>().where(
        (file) => file.path.endsWith('.json'),
      );

      final projects = <ProjectState>[];

      for (final file in files) {
        try {
          final jsonString = await file.readAsString();
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          projects.add(ProjectState.fromJson(jsonData));
        } catch (e) {
          // Log error but continue with other files
          debugPrint('Warning: Failed to load project from ${file.path}: $e');
          continue;
        }
      }

      // Sort by updated date, most recent first
      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return projects;
    } catch (e) {
      throw PersistenceException(
        operation: 'list',
        message: 'Failed to list projects',
        cause: e,
      );
    }
  }

  /// Delete a project by ID
  Future<bool> deleteProject(String projectId) async {
    try {
      final filePath = await _getProjectFilePath(projectId);
      final file = File(filePath);

      if (!await file.exists()) {
        return false;
      }

      await file.delete();
      return true;
    } catch (e) {
      throw PersistenceException(
        operation: 'delete',
        projectId: projectId,
        message: 'Failed to delete project',
        cause: e,
      );
    }
  }

  /// Check if a project exists
  Future<bool> projectExists(String projectId) async {
    try {
      final filePath = await _getProjectFilePath(projectId);
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Get the total number of projects
  Future<int> getProjectCount() async {
    final projects = await listProjects();
    return projects.length;
  }

  /// Search projects by topic (case-insensitive)
  Future<List<ProjectState>> searchProjects(String query) async {
    final allProjects = await listProjects();
    final lowercaseQuery = query.toLowerCase();

    return allProjects.where((project) {
      final topic = project.input?.rawTopic.toLowerCase() ?? '';
      return topic.contains(lowercaseQuery);
    }).toList();
  }
}
