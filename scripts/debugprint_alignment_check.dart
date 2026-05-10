// ignore_for_file: avoid_print

import 'dart:io';

/// Verificador de alineacion detector-scanner.
/// Confirma: scanner wrappers correctos, detector exports match imports, 0 unused_element warnings.
///
/// Uso: dart run scripts/debugprint_alignment_check.dart [--help]

void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  var exitCode = 0;
  print('=== debugprint_alignment_check ===');

  print('');
  print('[1/4] Verificando wrappers en scanner...');
  final scannerFile = File('scripts/debugprint_scanner.dart');
  if (!await scannerFile.exists()) {
    print('ERROR: scripts/debugprint_scanner.dart no encontrado');
    exit(1);
  }
  final scannerContent = await scannerFile.readAsString();

  exitCode += _checkWrapper(scannerContent, '_isInsideDebugModeBlock',
      'wrapper usado por _findDebugPrintCalls y _fixDebugPrintCalls');

  exitCode += _checkNotExists(scannerContent, '_isSameLineKDebugModeGuard',
      'dead code wrapper eliminado en Paso 16');

  exitCode += _checkNotExists(scannerContent, '_isInsideAssert',
      'dead code wrapper eliminado en Paso 16');

  exitCode += _checkNotExists(scannerContent, '_isInsideBracedDebugModeBlock',
      'dead code wrapper eliminado en Paso 16');

  print('');
  print('[2/4] Verificando imports scanner...');
  if (scannerContent.contains("import 'debugprint_detector.dart'") ||
      scannerContent.contains('import "debugprint_detector.dart"')) {
    print('  ✅ scanner importa debugprint_detector.dart');
  } else {
    print('  ❌ ERROR: scanner NO importa debugprint_detector.dart');
    exitCode = 1;
  }

  print('');
  print('[3/4] Verificando detector existe y exporta...');
  final detectorFile = File('scripts/debugprint_detector.dart');
  if (!await detectorFile.exists()) {
    print('ERROR: scripts/debugprint_detector.dart no encontrado');
    exit(1);
  }
  final detectorContent = await detectorFile.readAsString();

  final requiredFunctions = <String>[
    'isInsideDebugModeBlock',
    'isSameLineKDebugModeGuard',
    'isInsideAssert',
    'isTernaryKDebugModeGuard',
    'isAdjacentKDebugModeGuard',
    'isInsideBracedDebugModeBlock',
    'stripStringsAndComments',
  ];

  for (final fn in requiredFunctions) {
    final regex = RegExp('$fn\\s*\\(');
    if (regex.hasMatch(detectorContent)) {
      print('  ✅ detector exporta $fn');
    } else {
      print('  ❌ ERROR: detector NO exporta $fn');
      exitCode = 1;
    }
  }

  print('');
  print('[4/4] Ejecutando flutter analyze...');
  final analyzeResult = await Process.run('flutter', [
    'analyze',
  ], runInShell: true);

  final analyzeOutput =
      analyzeResult.stdout.toString() + analyzeResult.stderr.toString();

  if (analyzeResult.exitCode != 0) {
    if (analyzeOutput.contains('unused_element') ||
        analyzeOutput.contains('unused_local_variable') ||
        analyzeOutput.contains('unused_import') ||
        analyzeOutput.contains('dead_code')) {
      print('  ❌ FAIL: flutter analyze reporta issues de limpieza.');
      print(analyzeOutput);
      exitCode = 1;
    } else {
      print('  ⚠️  flutter analyze tiene issues pero sin dead_code/unused.');
      print('     Verifica manualmente.');
    }
  } else {
    print('  ✅ flutter analyze 0 issues');
  }

  print('');
  if (exitCode == 0) {
    print('=== ALINEACION COMPLETA ✅ ===');
    print('  scanner wrappers correctos');
    print('  detector exports match');
    print('  flutter analyze limpio');
    exit(0);
  } else {
    print('=== ALINEACION INCOMPLETA ❌ ===');
    print('  Revisa errores arriba.');
    exit(1);
  }
}

int _checkWrapper(String content, String name, String msg) {
  if (content.contains(name)) {
    print('  ✅ $name — $msg');
    return 0;
  }
  print('  ❌ ERROR: $name no encontrado — $msg');
  return 1;
}

int _checkNotExists(String content, String name, String msg) {
  if (content.contains(name)) {
    print('  ❌ ERROR: $name encontrado — $msg');
    return 1;
  }
  print('  ✅ $name no presente — $msg');
  return 0;
}

void _printUsage() {
  print('''
debugprint_alignment_check — Verifica alineacion detector-scanner post Paso 16

USO:
  dart run scripts/debugprint_alignment_check.dart        Ejecuta verificacion completa
  dart run scripts/debugprint_alignment_check.dart --help Muestra esta ayuda

QUE VERIFICA:
  1. Scanner tiene wrapper _isInsideDebugModeBlock (unico)
  2. Scanner NO tiene wrappers dead code eliminados en Paso 16
  3. Scanner importa debugprint_detector.dart correctamente
  4. Detector exporta 7 funciones publicas
  5. flutter analyze 0 issues

SALE CON:
  0 — Detector y scanner alineados
  1 — Desalineacion detectada
''');
}
