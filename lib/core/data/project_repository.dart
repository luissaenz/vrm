import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project_state.dart';
import '../exceptions/pipeline_exceptions.dart';

/// Repository for managing project persistence as JSON files
class ProjectRepository {
  static const _projectsFolder = 'vrm_data/projects';

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
    // Adjusted: Each project gets its own folder to store session_data, project.json and clips
    final projectFolder = Directory('$projectsPath/$projectId');
    if (!await projectFolder.exists()) {
      await projectFolder.create(recursive: true);
    }
    return '${projectFolder.path}/project.json';
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

      final projects = <ProjectState>[];

      // List subdirectories and look for project.json in each
      final projectFolders = await projectsDir.list().where((entity) => entity is Directory).cast<Directory>().toList();

      for (final folder in projectFolders) {
        try {
          final projectFile = File('${folder.path}/project.json');
          if (await projectFile.exists()) {
            final jsonString = await projectFile.readAsString();
            final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
            projects.add(ProjectState.fromJson(jsonData));
          }
        } catch (e) {
          // Log error but continue with other files
          debugPrint('Warning: Failed to load project from ${folder.path}: $e');
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

  /// Delete a project by ID (removes the entire folder)
  Future<bool> deleteProject(String projectId) async {
    try {
      final projectsPath = await _getProjectsPath();
      final projectDir = Directory('$projectsPath/$projectId');

      if (!await projectDir.exists()) {
        return false;
      }

      await projectDir.delete(recursive: true);
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

  /// Load session data for a specific project
  Future<Map<String, dynamic>?> getSessionData(String projectId) async {
    try {
      final projectsPath = await _getProjectsPath();
      final sessionFile = File('$projectsPath/$projectId/session_data.json');

      if (!await sessionFile.exists()) {
        return null;
      }

      final jsonString = await sessionFile.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading session data for $projectId: $e');
      return null;
    }
  }
}
