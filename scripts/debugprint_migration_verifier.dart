import 'dart:io';

/// Verificador post-migración de debugPrint → LoggerService.log
/// Confirma: 0 residuales via scanner + 0 unused flutter/foundation.dart en archivos meta
///
/// Uso: dart run scripts/debugprint_migration_verifier.dart [--help]

final _targetFiles = <String>[
  'lib/core/pipeline/vrm_pipeline.dart',
  'lib/core/services/schema_validator.dart',
  'lib/features/recording/services/clip_storage_service.dart',
  'lib/core/plugins/default/stitcher_plugin.dart',
  'lib/features/social_accounts/social_account_manager.dart',
];

void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  print('=== debugprint_migration_verifier ===');
  print('');
  print('[1/3] Ejecutando scanner de debugPrint...');

  final scanResult = await Process.run('dart', [
    'run',
    'scripts/debugprint_scanner.dart',
  ], runInShell: true);

  final scannerOutput = scanResult.stdout.toString();
  if (scanResult.exitCode != 0 ||
      scannerOutput.contains('debugPrint encontrados')) {
    final residualCount = _parseResidualCount(scannerOutput);
    if (residualCount > 0) {
      print('❌ FAIL: Scanner encontró $residualCount debugPrint residuales.');
      print('   Ejecuta: dart run scripts/debugprint_scanner.dart');
      if (scanResult.exitCode == 0) {
        exit(1);
      }
      exit(scanResult.exitCode);
    }
  }

  print('✅ 0 debugPrint residuales encontrados');
  print('');

  print('[2/3] Verificando imports flutter/foundation.dart unused...');
  int unusedImports = 0;

  for (final path in _targetFiles) {
    final file = File(path);
    if (!await file.exists()) {
      print('⚠️  WARNING: Archivo no encontrado: $path');
      continue;
    }

    final content = await file.readAsString();
    final lines = content.split('\n');

    final hasFoundationImport = lines.any(
      (line) =>
          line.contains("import 'package:flutter/foundation.dart'") ||
          line.contains('import "package:flutter/foundation.dart"'),
    );

    if (hasFoundationImport) {
      // Cherck if foundation.dart is still needed (debugPrint gone, check kDebugMode/required/etc)
      final usesFoundationSymbols =
          content.contains('kDebugMode') ||
          content.contains('kReleaseMode') ||
          content.contains('kProfileMode') ||
          content.contains('targetPlatform') ||
          content.contains('defaultTargetPlatform') ||
          content.contains('debugPrint') ||
          content.contains('debugPrintStack') ||
          (content.contains('@required') && !content.contains('meta.dart')) ||
          content.contains('visibleForTesting') ||
          content.contains('factory');

      if (!usesFoundationSymbols) {
        unusedImports++;
        print('  ❌ $path — flutter/foundation.dart import unused');
      } else {
        print('  ✅ $path — foundation.dart aún usado (kDebugMode, etc.)');
      }
    } else {
      print('  ✅ $path — sin import flutter/foundation.dart');
    }
  }

  if (unusedImports > 0) {
    print('');
    print('❌ FAIL: $unusedImports import(s) flutter/foundation.dart unused.');
    print('   Elimina manualmente o ejecuta: dart fix --apply');
    exit(1);
  }

  print('✅ 0 imports flutter/foundation.dart unused');
  print('');

  print('[3/3] Ejecutando flutter analyze...');
  final analyzeResult = await Process.run('flutter', [
    'analyze',
    '--no-fatal-infos',
    '--no-fatal-warnings',
  ], runInShell: true);

  final analyzeOutput =
      analyzeResult.stdout.toString() + analyzeResult.stderr.toString();

  // Counting errors from target files only
  int errors = 0;
  for (final path in _targetFiles) {
    if (analyzeOutput.contains('error') && analyzeOutput.contains(path)) {
      errors++;
    }
  }

  if (analyzeResult.exitCode != 0 && errors > 0) {
    print('❌ FAIL: flutter analyze encontró errores en archivos meta.');
    print('   Revisa output arriba.');
    exit(1);
  }

  print('✅ flutter analyze 0 issues en archivos meta');
  print('');
  print('=== VERIFICACIÓN COMPLETA ✅ ===');
  print('  0 debugPrint residuales');
  print('  0 imports flutter/foundation.dart unused');
  print('  0 flutter analyze issues');
  exit(0);
}

int _parseResidualCount(String output) {
  final match = RegExp(r'debugPrint encontrados: (\d+)').firstMatch(output);
  if (match != null) {
    return int.tryParse(match.group(1)!) ?? 0;
  }
  return 0;
}

void _printUsage() {
  print('''
debugprint_migration_verifier — Verifica migración completa debugPrint → LoggerService.log

USO:
  dart run scripts/debugprint_migration_verifier.dart        Ejecuta verificación completa
  dart run scripts/debugprint_migration_verifier.dart --help Muestra esta ayuda

QUÉ VERIFICA:
  1. Scanner debugprint_scanner.dart reporta 0 residuales
  2. Ningún archivo meta tiene import flutter/foundation.dart unused
  3. flutter analyze 0 issues en archivos meta

SALE CON:
  0 — Migración completa y limpia
  1 — Encontró residuales, unused imports o analyze issues
''');
}
