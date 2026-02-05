import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_app/core/data/project_repository.dart';
import 'package:vrm_app/core/models/project_state.dart';
import 'package:vrm_app/core/models/input_schema.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'dart:io';

void main() {
  group('ProjectRepository Tests', () {
    late ProjectRepository repository;
    late Directory testDir;

    setUp(() async {
      repository = ProjectRepository();

      // Setup test directory
      testDir = Directory.systemTemp.createTempSync('vrm_test_');

      // Mock path_provider
      PathProviderPlatform.instance = FakePathProviderPlatform(testDir.path);
    });

    tearDown(() async {
      // Cleanup test directory
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('saveProject creates JSON file', () async {
      final project = ProjectState(
        projectId: 'test-123',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        input: InputSchema(
          ideaId: 'idea-1',
          rawTopic: 'Test Topic',
          sourceType: 'manual',
          contextData: 'Test context',
        ),
      );

      await repository.saveProject(project);

      final loaded = await repository.loadProject('test-123');
      expect(loaded, isNotNull);
      expect(loaded!.projectId, equals('test-123'));
      expect(loaded.input?.rawTopic, equals('Test Topic'));
    });

    test('loadProject returns null for non-existent project', () async {
      final result = await repository.loadProject('non-existent');
      expect(result, isNull);
    });

    test('listProjects returns all saved projects', () async {
      final project1 = ProjectState(
        projectId: 'test-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
      final project2 = ProjectState(
        projectId: 'test-2',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 3),
      );

      await repository.saveProject(project1);
      await repository.saveProject(project2);

      final projects = await repository.listProjects();
      expect(projects.length, equals(2));

      // Should be sorted by updatedAt desc
      expect(projects[0].projectId, equals('test-2'));
      expect(projects[1].projectId, equals('test-1'));
    });

    test('deleteProject removes file', () async {
      final project = ProjectState(
        projectId: 'test-delete',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await repository.saveProject(project);
      expect(await repository.projectExists('test-delete'), isTrue);

      final deleted = await repository.deleteProject('test-delete');
      expect(deleted, isTrue);
      expect(await repository.projectExists('test-delete'), isFalse);
    });

    test('searchProjects filters by topic', () async {
      final project1 = ProjectState(
        projectId: 'test-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        input: InputSchema(
          ideaId: 'idea-1',
          rawTopic: 'How to create viral videos',
          sourceType: 'manual',
          contextData: '',
        ),
      );
      final project2 = ProjectState(
        projectId: 'test-2',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        input: InputSchema(
          ideaId: 'idea-2',
          rawTopic: 'Cooking tutorial',
          sourceType: 'manual',
          contextData: '',
        ),
      );

      await repository.saveProject(project1);
      await repository.saveProject(project2);

      final results = await repository.searchProjects('viral');
      expect(results.length, equals(1));
      expect(results[0].projectId, equals('test-1'));
    });

    test('getProjectCount returns correct count', () async {
      expect(await repository.getProjectCount(), equals(0));

      await repository.saveProject(
        ProjectState(
          projectId: 'test-1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      expect(await repository.getProjectCount(), equals(1));
    });
  });
}

/// Fake path provider for testing
class FakePathProviderPlatform extends PathProviderPlatform {
  final String basePath;

  FakePathProviderPlatform(this.basePath);

  @override
  Future<String?> getApplicationDocumentsPath() async => basePath;

  @override
  Future<String?> getTemporaryPath() async => basePath;

  @override
  Future<String?> getApplicationSupportPath() async => basePath;
}
