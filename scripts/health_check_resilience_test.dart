// ignore_for_file: avoid_print

import 'dart:io';

/// Verifica que vrm_health_check check --fix no aborta con archivos bloqueados.
///
/// Simula escenario real: crea archivos en vrm_data/tmp/ (directorio real que
/// procesa el health check), marca uno como read-only, ejecuta --fix y verifica
/// que el try/catch atrapa FileSystemException sin crash.
void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    print('''
Uso: dart run scripts/health_check_resilience_test.dart [--keep]

Flags:
  --keep   Conserva archivos de prueba en vrm_data/ (default: limpia)
  --help   Muestra esta ayuda

Verifica que vrm_health_check.dart check --fix no aborta con archivos bloqueados.
Simula archivos read-only en vrm_data/tmp/ real + sesión huérfana en vrm_data/projects/.
''');
    return;
  }

  final keep = args.contains('--keep');

  // Paths reales que health check procesa
  const testProjectId = '__resilience_test__';
  final tmpDir = Directory('vrm_data/tmp');
  final testProjectDir = Directory('vrm_data/projects/$testProjectId');

  // Archivos de prueba (guardamos paths para limpiar después)
  final testPaths = <String>[];
  String? lockedFilePath;
  var passed = 0;
  var total = 0;

  try {
    print('=== Health Check Resilience Test ===');
    print('');

    // ── Setup: crear archivos en vrm_data/ real ──
    print('Configurando escenario en vrm_data/ real...');

    await tmpDir.create(recursive: true);
    testPaths.add('${tmpDir.path}/normal_temp.mp4');
    testPaths.add('${tmpDir.path}/old_cache.json');

    await File('${tmpDir.path}/normal_temp.mp4').writeAsString('fake data');
    await File('${tmpDir.path}/old_cache.json').writeAsString('{}');

    // Archivo read-only → debe generar warning sin crash
    lockedFilePath = '${tmpDir.path}/locked_temp.mp4';
    await File(lockedFilePath).writeAsString('locked data');
    testPaths.add(lockedFilePath);

    final attribResult = await Process.run('attrib', ['+R', lockedFilePath]);
    if (attribResult.exitCode == 0) {
      print('  ✅ locked_temp.mp4 marcado como read-only');
    } else {
      print('  ⚠️  attrib +R falló: ${attribResult.stderr}');
    }

    // Sesión huérfana en projects/
    await testProjectDir.create(recursive: true);
    await File('${testProjectDir.path}/session_data.json').writeAsString('{}');
    testPaths.add('${testProjectDir.path}/session_data.json');

    // Proyecto con clips/ vacío
    final emptyClipsDir = Directory(
      'vrm_data/projects/${testProjectId}_empty_clips',
    );
    await emptyClipsDir.create(recursive: true);
    await File('${emptyClipsDir.path}/project.json').writeAsString('{}');
    await File('${emptyClipsDir.path}/session_data.json').writeAsString('{}');
    await Directory('${emptyClipsDir.path}/clips').create();
    testPaths.add(emptyClipsDir.path);

    print(
      '  ✅ Escenario: tmp/ (3 files, 1 read-only) + sesión huérfana + clips/ vacío',
    );
    print('');

    // ── Test 1: --fix con archivo read-only ──
    total++;
    print('[1] Ejecutando check --fix con archivo read-only...');
    print('');

    final result = await Process.run('dart', [
      'run',
      'scripts/vrm_health_check.dart',
      'check',
      '--fix',
    ], runInShell: true);

    final stdout = (result.stdout as String).trim();
    final stderr = (result.stderr as String).trim();

    if (result.exitCode == 0) {
      passed++;
      print('    ✅ vrm_health_check completó sin crash (exitCode=0)');
    } else {
      print('    ❌ vrm_health_check falló con exitCode=${result.exitCode}');
    }

    // ── Test 2: Verificar warning en output (prueba positiva de try/catch) ──
    total++;
    print('');
    print(
      '[2] Verificando warning de archivo no eliminado (try/catch activo)...',
    );

    final hasWarning =
        stdout.contains('⚠️ No se pudo eliminar') &&
        stdout.contains('locked_temp.mp4');
    final hasNoCrash =
        !stdout.contains('Unhandled exception') &&
        !stderr.contains('Unhandled exception');

    if (hasWarning) {
      passed++;
      print(
        '    ✅ Output contiene "⚠️ No se pudo eliminar: ...locked_temp.mp4"',
      );
      print('    ✅ Try/catch atrapó FileSystemException correctamente');
    } else {
      print('    ❌ Output NO contiene warning de archivo bloqueado');
      print(
        '    ℹ️  Posible causa: sistema permitió borrar read-only (privilegios admin)',
      );
      if (stdout.isNotEmpty) {
        print('    stdout excerpt:');
        for (final line in stdout.split('\n')) {
          if (line.contains('⚠️') || line.contains('tmp')) {
            print('      $line');
          }
        }
      }
    }

    if (hasNoCrash) {
      passed++;
      print('    ✅ Sin "Unhandled exception"');
    } else {
      print('    ❌ "Unhandled exception" en output');
    }

    // ── Test 3: --dry-run ──
    total++;
    print('');
    print('[3] Verificando --dry-run...');

    final dryRunResult = await Process.run('dart', [
      'run',
      'scripts/vrm_health_check.dart',
      'check',
      '--fix',
      '--dry-run',
    ], runInShell: true);

    if (dryRunResult.exitCode == 0) {
      passed++;
      print('    ✅ --dry-run completó sin errores');
    } else {
      print('    ❌ --dry-run falló con exitCode=${dryRunResult.exitCode}');
    }

    // ── Test 4: Verificar resumen ARCHIVOS NO ELIMINADOS ──
    total++;
    print('');
    print('[4] Verificando resumen final de archivos no eliminados...');

    if (stdout.contains('⚠️ ARCHIVOS NO ELIMINADOS')) {
      passed++;
      print('    ✅ Resumen "⚠️ ARCHIVOS NO ELIMINADOS:" presente');
    } else if (hasWarning) {
      print('    ⚠️  Warning individual presente pero sin resumen final');
    } else {
      print('    ℹ️  Sin archivos fallidos — resumen no esperado');
      passed++;
    }
  } catch (e, stack) {
    print('');
    print('❌ ERROR INESPERADO: $e');
    print('   $stack');
  } finally {
    // ── Cleanup: restaurar permisos + borrar archivos ──
    if (!keep) {
      print('');
      print('🧹 Limpiando...');

      if (lockedFilePath != null) {
        await Process.run('attrib', ['-R', lockedFilePath]);
      }

      // Borrar archivos de tmp/
      for (final path in testPaths) {
        try {
          final entity = FileSystemEntity.typeSync(path);
          if (entity == FileSystemEntityType.directory) {
            await Directory(path).delete(recursive: true);
          } else if (entity == FileSystemEntityType.file) {
            await File(path).delete();
          }
        } catch (e) {
          print('  ⚠️  No se pudo eliminar: $path ($e)');
        }
      }

      // Borrar directorios de proyectos de prueba
      try {
        if (await testProjectDir.exists()) {
          await testProjectDir.delete(recursive: true);
        }
      } catch (_) {}

      final emptyClipsDir = Directory(
        'vrm_data/projects/${testProjectId}_empty_clips',
      );
      try {
        if (await emptyClipsDir.exists()) {
          await emptyClipsDir.delete(recursive: true);
        }
      } catch (_) {}

      print('  ✅ Archivos de prueba eliminados de vrm_data/');
    } else {
      print('');
      print('⚠️  Archivos conservados en vrm_data/. Borrar manualmente:');
      print('   Remove-Item -Recurse -Force vrm_data/tmp/locked_temp.mp4');
      print(
        '   Remove-Item -Recurse -Force vrm_data/projects/__resilience_test__',
      );
    }
  }

  // ── Resumen ──
  print('');
  print('=== RESULT ===');
  print('Passed: $passed/$total tests');

  if (passed == total) {
    print(
      '✅ Todos los tests pasaron — _runFixCleanup() es resiliente a archivos bloqueados.',
    );
  } else {
    print('❌ ${total - passed} test(s) fallaron.');
    exitCode = 1;
  }
}
