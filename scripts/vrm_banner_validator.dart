// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps, prefer_interpolation_to_compose_strings

import 'dart:io';

const _usage = '''
VRM Banner Validator — Escanea y verifica consistencia de notificaciones.

USO:
  dart run scripts/vrm_banner_validator.dart <subcomando>

SUBCOMANDOS:
  check        Escanea showSnackBar/showMaterialBanner en lib/
               Reporta tipo, color, contexto y sugiere mejoras.
  fix          Reemplaza SnackBar por MaterialBanner en patrones
               de mensajes persistentes (warnings, estados sistema).
  --help       Muestra esta ayuda
''';

const _libDir = 'lib';
const _projectRoot = '.';

void main(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    print(_usage);
    return;
  }

  final raw = args.first.replaceAll('--', '');
  final subcommand = raw;
  switch (subcommand) {
    case 'check':
      _runCheck();
    case 'fix':
      _runFix();
    default:
      print('Subcomando desconocido: $subcommand');
      print(_usage);
      exitCode = 1;
  }
}

void _runCheck() {
  print('=== VRM Banner Validator — Check ===\n');

  final dartFiles = _findDartFiles('$_projectRoot/$_libDir');
  var totalSnackBar = 0;
  var totalBanner = 0;
  var warningCandidates = <_BannerUsage>[];
  var errorBanners = <String>[];

  for (final file in dartFiles) {
    final lines = File(file).readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;

      if (line.contains('showSnackBar')) {
        totalSnackBar++;
        final color = _extractColor(lines, i);
        final usage = _BannerUsage(
          file: file,
          line: lineNum,
          type: 'SnackBar',
          color: color,
          context: _extractContext(line),
        );
        _printUsage(usage);

        final isWarning = _isWarningContext(lines, i);
        if (isWarning) {
          warningCandidates.add(usage);
        }
      }

      if (line.contains('showMaterialBanner')) {
        totalBanner++;
        final color = _extractColor(lines, i);
        final hasDismiss = _hasDismissAction(lines, i);
        final usage = _BannerUsage(
          file: file,
          line: lineNum,
          type: 'MaterialBanner',
          color: color,
          context: _extractContext(line),
        );
        _printUsage(usage);

        if (!hasDismiss) {
          errorBanners.add(
            '  ⚠️  $file:$lineNum — MaterialBanner sin dismiss action',
          );
        }
      }
    }
  }

  print('\n--- Resumen ---');
  print('  SnackBars encontrados: $totalSnackBar');
  print('  MaterialBanners encontrados: $totalBanner');
  print(
    '  Posibles candidatos a MaterialBanner (warning/persistente): ${warningCandidates.length}',
  );

  if (warningCandidates.isNotEmpty) {
    print('\n--- Candidatos a migrar SnackBar → MaterialBanner ---');
    for (final c in warningCandidates) {
      final ctx = c.context.trim();
      final maxCtx = ctx.length > 60 ? '${ctx.substring(0, 60)}...' : ctx;
      print('  ${c.file}:${c.line} — $maxCtx');
    }
    print(
      '\n  Sugerencia: usa `dart run scripts/vrm_banner_validator.dart fix`',
    );
  }

  if (errorBanners.isNotEmpty) {
    print('\n--- MaterialBanners sin dismiss action ---');
    for (final e in errorBanners) {
      print(e);
    }
  }

  print(
    '\n✅ Check completado. $totalSnackBar SnackBars, $totalBanner MaterialBanners.',
  );
}

void _runFix() {
  print('=== VRM Banner Validator — Fix ===\n');

  final dartFiles = _findDartFiles('$_projectRoot/$_libDir');
  var fixedCount = 0;

  for (final file in dartFiles) {
    final original = File(file).readAsLinesSync();
    final updated = List<String>.from(original);
    var fileChanged = false;

    for (var i = 0; i < updated.length; i++) {
      final line = updated[i];
      if (!line.contains('showSnackBar')) continue;

      final isWarning = _isWarningContext(updated, i);
      if (!isWarning) continue;

      final indent = _getIndent(line);
      final color = _extractColor(updated, i);
      final contentMatch = RegExp(r'content:\s*(.*?)(,|\))').firstMatch(line);

      final bannerLines = <String>[
        '${indent}ScaffoldMessenger.of(context).hideCurrentMaterialBanner();',
        '${indent}ScaffoldMessenger.of(context).showMaterialBanner(',
        '$indent  MaterialBanner(',
        '$indent    padding: const EdgeInsetsDirectional.only(',
        '$indent      top: 2, bottom: 2, end: 8,',
        '$indent    ),',
        '$indent    leading: const Icon(Icons.info_outline, color: Colors.white),',
        '$indent    ${contentMatch?.group(0) ?? "content: const Text('Mensaje persistente')"},',
        '$indent    backgroundColor: $color,',
        '$indent    actions: [',
        '$indent      TextButton(',
        '$indent        onPressed: () => ScaffoldMessenger.of(context)',
        '$indent            .hideCurrentMaterialBanner(),',
        "$indent        child: const Text('OK', style: TextStyle(color: Colors.white)),",
        '$indent      ),',
        '$indent    ],',
        '$indent  ),',
        '$indent);',
      ];

      final blockEnd = _findBlockEnd(updated, i);
      final replacement = [
        '// VRM_BANNER: Reemplazado por MaterialBanner sticky',
        ...bannerLines,
        '// END_VRM_BANNER',
      ];

      if (blockEnd > i) {
        updated.replaceRange(i, blockEnd + 1, replacement);
      } else {
        updated.replaceRange(i, i + 1, replacement);
      }

      fileChanged = true;
      fixedCount++;
      print('  ✅ $file:${i + 1} — SnackBar reemplazado por MaterialBanner');
    }

    if (fileChanged) {
      File(file).writeAsStringSync(updated.join('\n'));
    }
  }

  if (fixedCount == 0) {
    print('  No se encontraron candidatos a migrar.');
  }
  print('\n✅ Fix completado. $fixedCount SnackBars reemplazados.');
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

List<String> _findDartFiles(String dir) {
  final result = <String>[];
  final entities = Directory(dir).listSync(recursive: true);
  for (final e in entities) {
    if (e is File && e.path.endsWith('.dart')) {
      result.add(e.path);
    }
  }
  return result;
}

String _extractColor(List<String> lines, int idx) {
  for (var i = idx; i < lines.length && i < idx + 25; i++) {
    final match = RegExp(r'backgroundColor:\s*(.+?)[,;]').firstMatch(lines[i]);
    if (match != null) return match.group(1)!.trim();
  }
  return 'desconocido';
}

String _extractContext(String line) {
  final cleaned = line.trim();
  return cleaned.length > 80 ? '${cleaned.substring(0, 77)}...' : cleaned;
}

bool _isWarningContext(List<String> lines, int idx) {
  // Busca palabras clave en líneas cercanas
  for (var i = idx > 5 ? idx - 5 : 0; i <= idx + 3 && i < lines.length; i++) {
    final line = lines[i].toLowerCase();
    if (line.contains('warning') ||
        line.contains('advertencia') ||
        line.contains('alerta') ||
        line.contains('fallback') ||
        line.contains('persistente') ||
        line.contains('insuficiente') ||
        line.contains('problema') ||
        line.contains('no soportado') ||
        line.contains('integri')) {
      return true;
    }
  }
  // También detecta naranja como color de warning
  final color = _extractColor(lines, idx);
  if (color.contains('orange')) return true;
  return false;
}

bool _hasDismissAction(List<String> lines, int idx) {
  for (var i = idx; i < lines.length && i < idx + 25; i++) {
    if (lines[i].contains('hideCurrentMaterialBanner')) return true;
  }
  return false;
}

int _findBlockEnd(List<String> lines, int startIdx) {
  // Busca el final del bloque showSnackBar buscando ');' con indentación adecuada
  for (var i = startIdx; i < lines.length; i++) {
    if (lines[i].trimLeft().startsWith(');')) return i;
    if (lines[i].contains('showSnackBar') && i > startIdx) return i;
  }
  return startIdx;
}

String _getIndent(String line) {
  final match = RegExp(r'^(\s*)').firstMatch(line);
  return match?.group(1) ?? '';
}

void _printUsage(_BannerUsage u) {
  final fileShort = u.file.replaceAll('$_projectRoot/', '');
  print('  [${u.type}] $fileShort:${u.line}');
  print('    Color: ${u.color}');
  print('    Contexto: ${u.context}');
  print('');
}

class _BannerUsage {
  final String file;
  final int line;
  final String type;
  final String color;
  final String context;

  const _BannerUsage({
    required this.file,
    required this.line,
    required this.type,
    required this.color,
    required this.context,
  });
}
