// ignore_for_file: avoid_print

import 'dart:io';

import 'utils.dart';

const _usage = '''
Capture Store Screenshots — Captura 5 screenshots store-ready via ADB.

USO:
  dart run scripts/capture_store_screenshots.dart [flags]

FLAGS:
  --interactive    Modo interactivo (por defecto)
  --device <id>    ID del dispositivo ADB especifico
  --clean          Eliminar screenshots existentes + dir legacy
  --help, -h       Muestra esta ayuda

PASOS:
  1. Dashboard (pantalla principal con proyectos)
  2. Creacion/Script (nuevo proyecto con guion generado)
  3. Grabacion (overlay de control visible)
  4. Revision de clips (video reproduciendose)
  5. Exportacion (metricas y boton exportar)

REQUISITOS:
  - Dispositivo Android conectado por USB con depuracion USB activada
  - App compilada en modo debug instalada
  - Resolucion minima: 1080x1920
''';

const _screenshotsDir = 'assets/store/screenshots';
const _legacyDir = 'assets/images/screenshots';

void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    print(_usage);
    return;
  }

  if (args.contains('--clean')) {
    await _clean();
    return;
  }

  final deviceId = _extractFlagValue(args, '--device');
  await _capture(deviceId);
}

String? _extractFlagValue(List<String> args, String flag) {
  for (var i = 0; i < args.length - 1; i++) {
    if (args[i] == flag) return args[i + 1];
  }
  return null;
}

Future<void> _clean() async {
  print('=== Limpiando screenshots existentes ===\n');

  final storeDir = Directory(_screenshotsDir);
  if (await storeDir.exists()) {
    final files = await storeDir.list().toList();
    for (final f in files) {
      if (f.path.endsWith('.gitkeep')) continue;
      await f.delete();
      print('  Eliminado: ${f.path}');
    }
  }

  final legacyDir = Directory(_legacyDir);
  if (await legacyDir.exists()) {
    await legacyDir.delete(recursive: true);
    print('  Eliminado dir legacy: $_legacyDir');
  }

  print('\nLimpiado completado.');
}

Future<({String id, String model})> _getDevice(String? deviceId) async {
  if (deviceId != null) {
    final result = await Process.run('adb', [
      '-s',
      deviceId,
      'shell',
      'getprop',
      'ro.product.model',
    ]);
    final model = result.stdout.toString().trim();
    return (id: deviceId, model: model.isNotEmpty ? model : 'desconocido');
  }

  final result = await Process.run('adb', ['devices']);
  final output = result.stdout.toString().trim();
  final lines = output.split('\n');
  final devices = <String>[];
  for (final line in lines) {
    if (line.contains('\tdevice')) {
      devices.add(line.split('\t')[0].trim());
    }
  }

  if (devices.isEmpty) {
    print('ERROR: No hay dispositivos Android conectados.');
    print('1. Conectar dispositivo con depuracion USB activada');
    print('2. Verificar con: adb devices');
    exit(1);
  }

  if (devices.length > 1) {
    print('Multiples dispositivos detectados:');
    for (var i = 0; i < devices.length; i++) {
      print('  [$i] ${devices[i]}');
    }
    print('Usar --device <id> para especificar uno.');
    exit(1);
  }

  final id = devices.first;
  final modelResult = await Process.run('adb', [
    'shell',
    'getprop',
    'ro.product.model',
  ]);
  final model = modelResult.stdout.toString().trim();
  return (id: id, model: model.isNotEmpty ? model : 'desconocido');
}

Future<void> _checkResolution(String deviceId) async {
  final args = deviceId.isNotEmpty
      ? ['-s', deviceId, 'shell', 'wm', 'size']
      : ['shell', 'wm', 'size'];
  final result = await Process.run('adb', args);
  final output = result.stdout.toString().trim();
  print('  Resolucion: $output');

  final match = RegExp(r'(\d+)x(\d+)').firstMatch(output);
  if (match != null) {
    final w = int.parse(match.group(1)!);
    final h = int.parse(match.group(2)!);
    final portraitW = w < h ? w : h;
    final portraitH = w > h ? w : h;
    if (portraitW < 1080 || portraitH < 1920) {
      print('  ADVERTENCIA: Resolucion < minimo 1080x1920');
      print('  Capturas pueden ser rechazadas en stores.');
      print('  Continuar? (s/N)');
      final input = stdin.readLineSync()?.toLowerCase();
      if (input != 's' && input != 'si') {
        print('Cancelado.');
        exit(1);
      }
    } else {
      print('  OK: $portraitW x $portraitH >= 1080x1920');
    }
  }
}

Future<void> _capture(String? deviceId) async {
  print('=== Capture Store Screenshots ===');

  try {
    final adbCheck = await Process.run('adb', ['--version']);
    if (adbCheck.exitCode != 0) throw Exception();
  } catch (_) {
    print('ERROR: ADB no encontrado en PATH.');
    print('Instalar Android SDK Platform Tools.');
    exit(1);
  }

  final device = await _getDevice(deviceId);
  print('\nDispositivo: ${device.model} (${device.id})');

  await _checkResolution(device.id);
  print('');

  await Directory(_screenshotsDir).create(recursive: true);

  final steps = [
    'Dashboard (pantalla principal con proyectos)',
    'Creacion/Script (nuevo proyecto con guion generado)',
    'Grabacion (overlay de control visible)',
    'Revision de clips (video reproduciendose)',
    'Exportacion (metricas y boton exportar)',
  ];

  var ok = 0;
  var fail = 0;

  for (var i = 0; i < steps.length; i++) {
    final n = i + 1;
    final step = steps[i];
    final outPath = '$_screenshotsDir/step$n.png';

    print('\n--- Paso $n: $step ---');
    print('Navegar a la pantalla. Enter cuando lista...');
    stdin.readLineSync();

    final idArgs = device.id.isNotEmpty ? ['-s', device.id] : <String>[];

    print('  Capturando...');
    final cap = await Process.run('adb', [
      ...idArgs,
      'shell',
      'screencap',
      '-p',
      '/sdcard/step$n.png',
    ]);
    if (cap.exitCode != 0) {
      print('  ERROR screencap: ${cap.stderr}');
      fail++;
      continue;
    }

    print('  Transfiriendo...');
    final pull = await Process.run('adb', [
      ...idArgs,
      'pull',
      '/sdcard/step$n.png',
      outPath,
    ]);
    if (pull.exitCode != 0) {
      print('  ERROR pull: ${pull.stderr}');
      fail++;
      continue;
    }

    await Process.run('adb', [...idArgs, 'shell', 'rm', '/sdcard/step$n.png']);

    final file = File(outPath);
    if (await file.exists()) {
      final size = await file.length();
      final isPng = validatePngHeader(outPath);
      if (isPng && size > 10240) {
        final dims = getPngDimensions(outPath);
        if (dims != null) {
          print('  OK: step$n.png (${size}B, ${dims.width}x${dims.height})');
          ok++;
        } else {
          print('  ERROR: step$n.png dimensiones no legibles');
          fail++;
        }
      } else {
        print('  ERROR: step$n.png corrupto/invalido (${size}B)');
        fail++;
      }
    } else {
      print('  ERROR: step$n.png no encontrado post-pull');
      fail++;
    }
  }

  print('\n=== RESULT ===');
  print('OK: $ok/5');
  if (fail > 0) print('FAIL: $fail/5 - reintentar script');
  if (ok == 5) {
    print('\nTodas capturadas. Validar:');
    print('  dart run scripts/store_prep_cli.dart check');
  }
}
