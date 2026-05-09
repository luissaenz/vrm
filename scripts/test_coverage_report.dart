// ignore_for_file: avoid_print

import 'dart:io';

/// Escanea test/ y lib/features/ para generar reporte de cobertura por feature.
/// Detecta features sin tests, cuenta test()/testWidgets() por archivo.
void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  print('📊 VRM Test Coverage Report');
  print('════════════════════════════════════════');
  print('');

  // 1. Scan lib/features/ for feature directories
  final featuresDir = Directory('lib/features');
  if (!await featuresDir.exists()) {
    print('ERROR: lib/features/ no encontrado');
    exit(1);
  }

  final features = await featuresDir
      .list()
      .where((e) => e is Directory)
      .cast<Directory>()
      .map((d) => d.path.split(Platform.pathSeparator).last)
      .toList();
  features.sort();

  // 2. Scan lib/core/ for core subdirectories
  final coreDir = Directory('lib/core');
  final coreModules = <String>[];
  if (await coreDir.exists()) {
    await for (final entity in coreDir.list()) {
      if (entity is Directory) {
        coreModules.add(
          'core/${entity.path.split(Platform.pathSeparator).last}',
        );
      }
    }
    coreModules.sort();
  }

  // 3. Scan test/ for test files
  final testDir = Directory('test');
  if (!await testDir.exists()) {
    print('ERROR: test/ no encontrado');
    exit(1);
  }

  final testFiles = await testDir
      .list(recursive: true)
      .where((e) => e is File && e.path.endsWith('_test.dart'))
      .cast<File>()
      .toList();

  // 4. Count tests per file
  int totalTests = 0;
  int totalWidgetTests = 0;
  int totalUnitTests = 0;
  final testFileDetails = <_TestFileInfo>[];

  for (final file in testFiles) {
    final content = await file.readAsString();
    final lines = content.split('\n');

    int unitCount = 0;
    int widgetCount = 0;

    for (final line in lines) {
      final trimmed = line.trimLeft();
      // Skip comments
      if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;

      if (trimmed.contains('testWidgets(')) {
        widgetCount++;
      } else if (trimmed.contains("test('") || trimmed.contains('test("')) {
        unitCount++;
      }
    }

    final relativePath = file.path
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^test/'), '');

    testFileDetails.add(
      _TestFileInfo(
        path: relativePath,
        unitTests: unitCount,
        widgetTests: widgetCount,
      ),
    );

    totalTests += unitCount + widgetCount;
    totalUnitTests += unitCount;
    totalWidgetTests += widgetCount;
  }

  // 5. Map test files to features/core modules
  final featuresWithTests = <String, List<_TestFileInfo>>{};
  final featuresWithoutTests = <String>[];

  for (final feature in features) {
    final matching = testFileDetails
        .where(
          (t) =>
              t.path.contains(feature) ||
              t.path.contains('${feature}_test.dart'),
        )
        .toList();
    if (matching.isNotEmpty) {
      featuresWithTests[feature] = matching;
    } else {
      featuresWithoutTests.add(feature);
    }
  }

  // Check core modules
  final coreWithTests = <String, List<_TestFileInfo>>{};
  for (final coreModule in coreModules) {
    final moduleName = coreModule.split('/').last;
    final matching = testFileDetails.where((t) {
      final tLower = t.path.toLowerCase();
      return tLower.contains(moduleName) ||
          tLower.contains('${moduleName}_test.dart');
    }).toList();
    if (matching.isNotEmpty) {
      coreWithTests[coreModule] = matching;
    }
  }

  // Also check for test files matching pipeline/error_handling patterns
  for (final tf in testFileDetails) {
    if (tf.path.contains('pipeline')) {
      coreWithTests.putIfAbsent('core/pipeline', () => []).add(tf);
    }
    if (tf.path.contains('error_handling')) {
      coreWithTests.putIfAbsent('core/exceptions', () => []).add(tf);
    }
    if (tf.path.contains('repository')) {
      coreWithTests.putIfAbsent('core/data', () => []).add(tf);
    }
  }

  // 6. Print summary
  final totalFeatures = features.length + coreModules.length;
  final totalWithTests = featuresWithTests.length + coreWithTests.length;
  final totalWithout = totalFeatures - totalWithTests;

  print(
    '  Modules:       $totalFeatures (${features.length} features + ${coreModules.length} core)',
  );
  print('  Con tests:     $totalWithTests');
  print('  Sin tests:     $totalWithout');
  print('  Test files:    ${testFiles.length}');
  print('  Tests totales: $totalTests');
  print('  Widget tests:  $totalWidgetTests');
  print('  Unit tests:    $totalUnitTests');
  print('');

  // 7. Features with tests
  if (featuresWithTests.isNotEmpty || coreWithTests.isNotEmpty) {
    print('✅ Módulos con tests:');
    for (final entry in {...featuresWithTests, ...coreWithTests}.entries) {
      final testCount = entry.value.fold<int>(
        0,
        (sum, t) => sum + t.unitTests + t.widgetTests,
      );
      final files = entry.value.map((t) => t.path).join(', ');
      print('    ${entry.key} ($testCount tests) ← $files');
    }
    print('');
  }

  // 8. Features without tests
  if (featuresWithoutTests.isNotEmpty) {
    print('⚠️  Features sin tests:');
    for (final feature in featuresWithoutTests) {
      print('    - $feature (0 tests)');
    }
    print('');
  }

  // 9. Test file detail
  if (args.contains('--detail')) {
    print('📄 Detalle por archivo test:');
    for (final tf in testFileDetails) {
      final total = tf.unitTests + tf.widgetTests;
      final types = <String>[];
      if (tf.unitTests > 0) types.add('${tf.unitTests} unit');
      if (tf.widgetTests > 0) types.add('${tf.widgetTests} widget');
      print('    ${tf.path}: $total tests (${types.join(', ')})');
    }
    print('');
  }

  // 10. Exit code
  print('════════════════════════════════════════');
  if (featuresWithoutTests.isEmpty) {
    print('✅ Todas las features tienen tests');
  } else {
    print('⚠️  ${featuresWithoutTests.length} features sin cobertura de tests');
  }

  exit(0);
}

void _printUsage() {
  print('''
test_coverage_report — Reporte de cobertura de tests por feature

USO:
  dart run scripts/test_coverage_report.dart           Reporte resumen
  dart run scripts/test_coverage_report.dart --detail  Incluye detalle por archivo
  dart run scripts/test_coverage_report.dart --help    Muestra esta ayuda

FLAGS:
  --detail  Muestra conteo de tests por archivo individual
''');
}

class _TestFileInfo {
  final String path;
  final int unitTests;
  final int widgetTests;
  _TestFileInfo({
    required this.path,
    required this.unitTests,
    required this.widgetTests,
  });
}
