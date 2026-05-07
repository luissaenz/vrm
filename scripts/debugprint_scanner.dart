// ignore_for_file: avoid_print

import 'dart:io';

/// Escanea lib/ buscando debugPrint residuales.
/// Modo scan: reporta archivo, línea, contenido.
/// Modo --fix: reemplaza automáticamente por LoggerService.log().
void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final fixMode = args.contains('--fix');
  print(
    fixMode
        ? '=== debugprint_scanner: MODO --FIX ==='
        : '=== debugprint_scanner: SCAN ===',
  );
  print('');

  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    print('ERROR: lib/ no encontrado');
    exit(1);
  }

  final dartFiles = await libDir
      .list(recursive: true)
      .where((e) => e is File && e.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  int totalFixed = 0;
  final results = <_MatchResult>[];

  for (final file in dartFiles) {
    if (file.path.endsWith('logger_service.dart')) continue;

    final content = await file.readAsString();
    final lines = content.split('\n');
    final matches = _findDebugPrintCalls(lines);

    if (matches.isEmpty) continue;

    for (final m in matches) {
      results.add(
        _MatchResult(
          file: file.path.replaceAll('\\', '/'),
          line: m.line,
          column: m.column,
          snippet: m.snippet,
        ),
      );
    }

    if (fixMode && matches.isNotEmpty) {
      final fixed = _fixDebugPrintCalls(file, content, lines);
      if (fixed > 0) {
        totalFixed += fixed;
        print('  ✏️  ${file.path.replaceAll('\\', '/')}: $fixed reemplazos');
      }
    }
  }

  print('');
  if (!fixMode) {
    if (results.isEmpty) {
      print('✅ No se encontraron debugPrint residuales en lib/');
    } else {
      _printResults(results, dartFiles.length);
    }
  } else {
    print('=== Resumen ===');
    print('  Archivos escaneados: ${dartFiles.length}');
    if (results.isNotEmpty) {
      print('  debugPrint encontrados: ${results.length}');
      _printResults(results, dartFiles.length);
      print('  Reemplazos aplicados: $totalFixed');
    } else {
      print('  debugPrint encontrados: 0');
      print('  Reemplazos aplicados: 0');
    }
  }

  if (results.isNotEmpty &&
      results.any(
        (r) =>
            r.file.contains('recording_page.dart') ||
            r.file.contains('recording_end_page.dart'),
      )) {
    print('');
    print('⚠️  WARNING: debugPrint encontrado en archivos del Paso 08!');
    print(
      '   recording_page.dart y recording_end_page.dart deberían tener 0 debugPrint.',
    );
  }

  exit(results.isEmpty ? 0 : 1);
}

void _printUsage() {
  print('''
debugprint_scanner — Escanea debugPrint residuales en lib/

USO:
  dart run scripts/debugprint_scanner.dart        Escanea y reporta
  dart run scripts/debugprint_scanner.dart --fix  Reemplaza automáticamente
  dart run scripts/debugprint_scanner.dart --help Muestra esta ayuda

FLAGS:
  --fix   Reemplaza debugPrint() por LoggerService.log()
''');
}

List<_DebugPrintMatch> _findDebugPrintCalls(List<String> lines) {
  final result = <_DebugPrintMatch>[];

  for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
    final line = lines[lineIdx];
    int searchFrom = 0;

    while (true) {
      final idx = line.indexOf('debugPrint(', searchFrom);
      if (idx == -1) break;

      // Check it's not a comment
      final lineBefore = line.substring(0, idx).trim();
      if (lineBefore.startsWith('//') ||
          lineBefore.startsWith('*') ||
          lineBefore.startsWith('///')) {
        searchFrom = idx + 1;
        continue;
      }

      // Skip if inside kDebugMode or !kReleaseMode guard (intentional, not residual)
      if (_isInsideDebugModeBlock(lines, lineIdx)) {
        searchFrom = idx + 1;
        continue;
      }

      result.add(
        _DebugPrintMatch(
          line: lineIdx + 1,
          column: idx + 1,
          snippet: line.trim(),
        ),
      );

      searchFrom = idx + 1;
    }
  }

  return result;
}

/// Scan backwards from [lineIdx] to detect if code is inside
/// `if (kDebugMode)` or `if (!kReleaseMode)` block.
/// These debugPrint calls are intentional — only run in debug mode.
bool _isInsideDebugModeBlock(List<String> lines, int lineIdx) {
  int braceDepth = 0;

  for (int i = lineIdx; i >= 0; i--) {
    final l = lines[i];

    for (int j = 0; j < l.length; j++) {
      if (l[j] == '{') braceDepth++;
      if (l[j] == '}') braceDepth--;
    }

    if (braceDepth > 0 &&
        (l.contains('kDebugMode') || l.contains('!kReleaseMode'))) {
      return true;
    }
  }

  return false;
}

int _fixDebugPrintCalls(File file, String content, List<String> lines) {
  final tag = _deriveTag(file.path);
  int replacements = 0;
  final newLines = <String>[];
  bool needsImport = true;

  // Check if already imported
  for (final line in lines) {
    if (line.contains("import '") && line.contains("logger_service.dart'")) {
      needsImport = false;
      break;
    }
    if (line.contains('import "') && line.contains('logger_service.dart"')) {
      needsImport = false;
      break;
    }
  }

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    var modified = line;
    int searchFrom = 0;

    while (true) {
      final idx = modified.indexOf('debugPrint(', searchFrom);
      if (idx == -1) break;

      // Skip if in comment
      final lineBefore = modified.substring(0, idx).trim();
      if (lineBefore.startsWith('//') ||
          lineBefore.startsWith('*') ||
          lineBefore.startsWith('///')) {
        searchFrom = idx + 1;
        continue;
      }

      // Skip if inside kDebugMode guard (intentional)
      if (_isInsideDebugModeBlock(lines, i)) {
        searchFrom = idx + 1;
        continue;
      }

      // Find matching closing paren
      int depth = 0;
      int endIdx = -1;
      for (int j = idx + 'debugPrint('.length; j < modified.length; j++) {
        if (modified[j] == '(') depth++;
        if (modified[j] == ')') {
          if (depth == 0) {
            endIdx = j;
            break;
          }
          depth--;
        }
      }

      if (endIdx == -1) {
        // Malformed, skip
        searchFrom = idx + 1;
        continue;
      }

      final arg = modified.substring(idx + 'debugPrint('.length, endIdx).trim();
      final replacement = "LoggerService.log('$tag', $arg)";

      modified =
          modified.substring(0, idx) +
          replacement +
          modified.substring(endIdx + 1);
      searchFrom = idx + replacement.length;
      replacements++;
    }

    newLines.add(modified);
  }

  if (replacements > 0) {
    String newContent = newLines.join('\n');

    if (needsImport) {
      // Find last import line
      int lastImportIdx = -1;
      final nl = newContent.split('\n');
      for (int i = 0; i < nl.length; i++) {
        if (nl[i].trimLeft().startsWith('import ')) {
          lastImportIdx = i;
        }
      }

      if (lastImportIdx >= 0) {
        final importLine =
            "import 'package:vrm_app/core/services/logger_service.dart';";
        nl.insert(lastImportIdx + 1, importLine);
        newContent = nl.join('\n');
      }
    }

    file.writeAsStringSync(newContent);
  }

  return replacements;
}

String _deriveTag(String path) {
  // Extract filename without extension, PascalCase
  final name = path.split('/').last.split('\\').last;
  return name.replaceAll('.dart', '');
}

void _printResults(List<_MatchResult> results, int totalFiles) {
  print('Archivos escaneados: $totalFiles');
  print('debugPrint encontrados: ${results.length}');
  print('');

  // Group by file
  final byFile = <String, List<_MatchResult>>{};
  for (final r in results) {
    byFile.putIfAbsent(r.file, () => []).add(r);
  }

  for (final entry in byFile.entries) {
    print('  📄 ${entry.key}');
    for (final m in entry.value) {
      print('     L${m.line}:${m.column}  ${m.snippet}');
    }
    print('');
  }
}

class _DebugPrintMatch {
  final int line;
  final int column;
  final String snippet;
  _DebugPrintMatch({
    required this.line,
    required this.column,
    required this.snippet,
  });
}

class _MatchResult {
  final String file;
  final int line;
  final int column;
  final String snippet;
  _MatchResult({
    required this.file,
    required this.line,
    required this.column,
    required this.snippet,
  });
}
