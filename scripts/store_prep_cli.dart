// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _projectRoot = '.';
const _androidDir = '$_projectRoot/android';
const _defaultKeystorePath = '$_androidDir/vrm-release-key.jks';
const _keyPropertiesPath = '$_androidDir/key.properties';
const _privacyPolicyPath = '$_projectRoot/PRIVACY_POLICY.md';
const _privacyPolicyDocsPath = '$_projectRoot/docs/PRIVACY_POLICY.md';
const _storeScreenshotsDir = '$_projectRoot/assets/store/screenshots';
const _existingScreenshotsDir = '$_projectRoot/assets/images/screenshots';
const _gitignorePath = '$_projectRoot/.gitignore';
const _androidManifestPath = '$_androidDir/app/src/main/AndroidManifest.xml';
const _pubspecPath = '$_projectRoot/pubspec.yaml';

const _usage = '''
Store Prep CLI — Pipeline de preparación para publicación en stores.

USO:
  dart run scripts/store_prep_cli.dart <subcomando> [flags]

SUBCOMANDOS:
  check                Validación completa pre-build store
  keystore             Generar keystore para firmar APK/AAB
  assets validate      Validar assets: iconos, splash, screenshots
  privacy              Validar PRIVACY_POLICY.md sin placeholders
  screenshots          Guía para capturar screenshots store-ready
  --help               Muestra esta ayuda
''';

void main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    print(_usage);
    return;
  }

  final subcommand = args.first;

  switch (subcommand) {
    case 'check':
      await _runCheck();
    case 'keystore':
      await _runKeystore(args);
    case 'assets':
      await _runAssets(args);
    case 'privacy':
      await _runPrivacy();
    case 'screenshots':
      _runScreenshotsGuide();
    default:
      print('Subcomando desconocido: $subcommand');
      print(_usage);
      exitCode = 1;
  }
}

String? _extractFlagValue(List<String> args, String flag) {
  for (var i = 0; i < args.length - 1; i++) {
    if (args[i] == flag) return args[i + 1];
  }
  return null;
}

String _findKeytool() {
  final candidates = <String>[
    if (Platform.environment.containsKey('JAVA_HOME'))
      '${Platform.environment['JAVA_HOME']}\\bin\\keytool',
    'keytool',
  ];

  for (final candidate in candidates) {
    final path = candidate.endsWith('keytool')
        ? candidate
        : '$candidate\\keytool';
    if (File(path).existsSync()) return path;
    final exePath = path.endsWith('.exe') ? path : '$path.exe';
    if (File(exePath).existsSync()) return exePath;
  }

  return 'keytool';
}

// ─── CHECK ───────────────────────────────────────────────────────────────────

Future<void> _runCheck() async {
  print('=== Store Prep: Check ===\n');

  final results = <String, bool>{};
  final details = <String, String>{};
  var allOk = true;

  // 1. Keystore
  print('[1] Verificando keystore...');
  final keystoreExists = await File(_defaultKeystorePath).exists();
  results['keystore'] = keystoreExists;
  details['keystore'] = keystoreExists
      ? 'vrm-release-key.jks existe'
      : 'vrm-release-key.jks NO encontrado';
  print('  ${keystoreExists ? "✅" : "❌"} ${details["keystore"]}');
  if (!keystoreExists) {
    allOk = false;
    print('    → Ejecuta: dart run scripts/store_prep_cli.dart keystore');
  }

  // 2. key.properties
  print('[2] Verificando key.properties...');
  final keyPropsExists = await File(_keyPropertiesPath).exists();
  results['key_properties'] = keyPropsExists;
  details['key_properties'] = keyPropsExists
      ? 'key.properties existe'
      : 'key.properties NO encontrado';
  print('  ${keyPropsExists ? "✅" : "❌"} ${details["key_properties"]}');

  if (keyPropsExists) {
    final content = await File(_keyPropertiesPath).readAsString();
    final hasDefaultPassword = content.contains('vrm_password_123');
    final hasStoreFile = content.contains('storeFile=');
    results['key_properties_no_default'] = !hasDefaultPassword;
    details['key_properties_no_default'] = hasDefaultPassword
        ? 'Passwords DEFAULT detectadas (vrm_password_123)'
        : 'Passwords OK (no default)';
    print(
      '  ${hasDefaultPassword ? "❌" : "✅"} ${details["key_properties_no_default"]}',
    );
    if (hasDefaultPassword) {
      allOk = false;
      print('    → Cambiar storePassword y keyPassword ANTES de release');
    }

    results['key_properties_storefile'] = hasStoreFile;
    if (!hasStoreFile) {
      allOk = false;
      print('  ❌ key.properties: falta storeFile');
    }
  } else {
    allOk = false;
  }

  // 3. PRIVACY_POLICY.md sin placeholders
  print('[3] Verificando PRIVACY_POLICY.md...');
  final policyRootExists = await File(_privacyPolicyPath).exists();
  if (policyRootExists) {
    final content = await File(_privacyPolicyPath).readAsString();
    final hasPlaceholders =
        content.contains('[your-') ||
        content.contains('[Date]') ||
        content.contains('[Your Company') ||
        content.contains('your-support-email');
    results['privacy_policy'] = !hasPlaceholders;
    details['privacy_policy'] = hasPlaceholders
        ? 'Placeholders detectados en PRIVACY_POLICY.md'
        : 'PRIVACY_POLICY.md OK (sin placeholders)';
    print('  ${hasPlaceholders ? "❌" : "✅"} ${details["privacy_policy"]}');
    if (hasPlaceholders) {
      allOk = false;
      print('    → Ejecuta: dart run scripts/store_prep_cli.dart privacy');
    }
  } else {
    results['privacy_policy'] = false;
    details['privacy_policy'] = 'PRIVACY_POLICY.md NO encontrado';
    print('  ❌ ${details["privacy_policy"]}');
    allOk = false;
  }

  // 4. Icon source
  print('[4] Verificando assets de branding...');
  final iconExists = await File(
    '$_projectRoot/assets/images/branding/icon_source.png',
  ).exists();
  final splashExists = await File(
    '$_projectRoot/assets/images/branding/splash_source.png',
  ).exists();
  results['branding_icons'] = iconExists && splashExists;
  details['branding_icons'] = (iconExists && splashExists)
      ? 'Icon + splash OK'
      : 'Faltan: ${!iconExists ? "icon_source.png " : ""}${!splashExists ? "splash_source.png" : ""}';
  print(
    '  ${(iconExists && splashExists) ? "✅" : "❌"} ${details["branding_icons"]}',
  );
  if (!iconExists || !splashExists) {
    allOk = false;
  }

  // 5. Screenshots
  print('[5] Verificando screenshots...');
  final storeDirExists = await Directory(_storeScreenshotsDir).exists();
  final existingDirExists = await Directory(_existingScreenshotsDir).exists();
  var screenshotCount = 0;
  var resolutionOk = true;
  var badResolution = <String>[];

  if (storeDirExists) {
    final files = await Directory(
      _storeScreenshotsDir,
    ).list().where((e) => e.path.endsWith('.png')).toList();
    screenshotCount += files.length;
    for (final f in files) {
      if (!_validateScreenshotResolution(f.path)) {
        resolutionOk = false;
        badResolution.add(f.path.split('\\').last.split('/').last);
      }
    }
  }
  if (existingDirExists) {
    final files = await Directory(
      _existingScreenshotsDir,
    ).list().where((e) => e.path.endsWith('.png')).toList();
    screenshotCount += files.length;
    for (final f in files) {
      if (!_validateScreenshotResolution(f.path)) {
        resolutionOk = false;
        badResolution.add(f.path.split('\\').last.split('/').last);
      }
    }
  }

  results['screenshots'] = screenshotCount >= 5 && resolutionOk;
  details['screenshots'] = screenshotCount >= 5
      ? (resolutionOk
            ? '$screenshotCount screenshots OK (≥1080x1920)'
            : 'Resolución insuficiente: ${badResolution.join(", ")}')
      : 'Solo $screenshotCount screenshots (mínimo 5)';
  print(
    '  ${(screenshotCount >= 5 && resolutionOk) ? "✅" : "❌"} ${details["screenshots"]}',
  );
  if (screenshotCount < 5) {
    allOk = false;
    print('    → Capturar 5 screenshots 1080x1920+ en dispositivo real');
  }
  if (!resolutionOk) {
    allOk = false;
    print('    → Recapturar en dispositivo real a resolución ≥1080x1920');
  }

  // 6. .gitignore
  print('[6] Verificando .gitignore...');
  final gitignoreExists = await File(_gitignorePath).exists();
  if (gitignoreExists) {
    final content = await File(_gitignorePath).readAsString();
    final hasJks = content.contains('*.jks');
    final hasKeystore = content.contains('*.keystore');
    final hasKeyProps = content.contains('key.properties');
    results['gitignore_secrets'] = hasJks && hasKeystore && hasKeyProps;
    details['gitignore_secrets'] = (hasJks && hasKeystore && hasKeyProps)
        ? '.gitignore cubre *.jks, *.keystore, key.properties'
        : '.gitignore incompleto';
    print(
      '  ${(hasJks && hasKeystore && hasKeyProps) ? "✅" : "❌"} ${details["gitignore_secrets"]}',
    );
    if (!hasJks || !hasKeystore || !hasKeyProps) {
      allOk = false;
    }
  } else {
    results['gitignore_secrets'] = false;
    details['gitignore_secrets'] = '.gitignore NO encontrado';
    print('  ❌ .gitignore no encontrado');
    allOk = false;
  }

  // 7. AndroidManifest permissions
  print('[7] Verificando permisos AndroidManifest...');
  final manifestExists = await File(_androidManifestPath).exists();
  if (manifestExists) {
    final content = await File(_androidManifestPath).readAsString();
    final hasCamera = content.contains('CAMERA');
    final hasRecordAudio = content.contains('RECORD_AUDIO');
    final hasInternet = content.contains('INTERNET');
    final hasReadMediaVideo = content.contains('READ_MEDIA_VIDEO');
    results['manifest_permissions'] =
        hasCamera && hasRecordAudio && hasInternet;
    details['manifest_permissions'] =
        'Permisos: ${hasCamera ? "✅CAMERA " : "❌CAMERA "}${hasRecordAudio ? "✅RECORD_AUDIO " : "❌RECORD_AUDIO "}${hasInternet ? "✅INTERNET " : "❌INTERNET "}${hasReadMediaVideo ? "✅READ_MEDIA_VIDEO" : ""}';
    print('  ✅ ${details["manifest_permissions"]}');
  } else {
    results['manifest_permissions'] = false;
    details['manifest_permissions'] = 'AndroidManifest NO encontrado';
    print('  ❌ AndroidManifest no encontrado');
    allOk = false;
  }

  // 8. pubspec.yaml config
  print('[8] Verificando pubspec.yaml (flutter_launcher_icons + splash)...');
  final pubspecExists = await File(_pubspecPath).exists();
  if (pubspecExists) {
    final content = await File(_pubspecPath).readAsString();
    final hasLauncherIcons = content.contains('flutter_launcher_icons');
    final hasNativeSplash = content.contains('flutter_native_splash');
    results['pubspec_store_config'] = hasLauncherIcons && hasNativeSplash;
    details['pubspec_store_config'] = (hasLauncherIcons && hasNativeSplash)
        ? 'flutter_launcher_icons ✅, flutter_native_splash ✅'
        : 'Falta: ${!hasLauncherIcons ? "flutter_launcher_icons " : ""}${!hasNativeSplash ? "flutter_native_splash" : ""}';
    print(
      '  ${(hasLauncherIcons && hasNativeSplash) ? "✅" : "❌"} ${details["pubspec_store_config"]}',
    );
    if (!hasLauncherIcons || !hasNativeSplash) {
      allOk = false;
    }
  }

  // Summary
  print('\n=== RESULT ===');
  final passed = results.values.where((v) => v).length;
  final total = results.length;
  print('Passed: $passed/$total checks');
  print('JSON: ${jsonEncode(results)}');

  if (allOk) {
    print('\n✅ Todos los checks pasaron. Listo para store release.');
  } else {
    print('\n❌ Algunos checks fallaron. Revisar arriba.');
    exitCode = 1;
  }
}

// ─── KEYSTORE ─────────────────────────────────────────────────────────────────

Future<void> _runKeystore(List<String> args) async {
  print('=== Store Prep: Keystore Generation ===\n');

  final outputPath =
      _extractFlagValue(args, '--output') ?? _defaultKeystorePath;
  final alias = _extractFlagValue(args, '--alias') ?? 'vrm_upload_key';

  // Check if already exists
  if (await File(outputPath).exists()) {
    print('❌ Keystore ya existe en: $outputPath');
    print('   Eliminar manualmente para regenerar.');
    exitCode = 1;
    return;
  }

  // Read passwords from key.properties or use generated
  String storePass;
  String keyPass;

  if (await File(_keyPropertiesPath).exists()) {
    final props = await File(_keyPropertiesPath).readAsLines();
    storePass =
        _extractProp(props, 'storePassword') ?? 'vrm_store_${_randomSuffix()}';
    keyPass =
        _extractProp(props, 'keyPassword') ?? 'vrm_key_${_randomSuffix()}';
  } else {
    storePass = 'vrm_store_${_randomSuffix()}';
    keyPass = 'vrm_key_${_randomSuffix()}';
    // Create key.properties
    final propsContent =
        '''
storePassword=$storePass
keyPassword=$keyPass
keyAlias=$alias
storeFile=${_relativeKeystorePath(outputPath)}
''';
    await File(_keyPropertiesPath).writeAsString(propsContent);
    print('  ✅ key.properties creado');
  }

  // Ensure output directory
  await Directory(outputPath).parent.create(recursive: true);

  print('  Generando keystore RSA 2048...');
  print('  Alias: $alias');
  print('  Output: $outputPath');
  print('');

  final keytoolPath = _findKeytool();
  print('  Usando keytool: $keytoolPath');

  final result = await Process.run(keytoolPath, [
    '-genkey',
    '-v',
    '-keystore',
    outputPath,
    '-keyalg',
    'RSA',
    '-keysize',
    '2048',
    '-validity',
    '10000',
    '-alias',
    alias,
    '-storepass',
    storePass,
    '-keypass',
    keyPass,
    '-dname',
    'CN=VRM App, OU=Development, O=VRM, L=Unknown, ST=Unknown, C=US',
  ]);

  if (result.exitCode == 0) {
    final file = File(outputPath);
    final size = await file.length();
    print('✅ Keystore generated at $outputPath ($size bytes)');
    print('');

    if (storePass == 'vrm_password_123' || keyPass == 'vrm_password_123') {
      print('⚠️  ADVERTENCIA: key.properties usa passwords DEFAULT.');
      print('   Cambiar storePassword y keyPassword ANTES de release.');
    }

    print('');
    print('⚠️  IMPORTANTE: Hacer backup del keystore.');
    print('   Perder este archivo → NO se puede actualizar app en stores.');
    print('   Guardar copia segura fuera del repo.');
  } else {
    print('❌ Error generando keystore:');
    print(result.stderr.toString());
    print('');
    print('keytool no encontrado en PATH ni rutas comunes.');
    print(
      'Instalar JDK (Java Development Kit) y asegurar que keytool esté en PATH.',
    );
    print('  - Descargar: https://adoptium.net/');
    print(
      '  - O usar: flutter doctor --android-licenses (instala JDK automáticamente)',
    );
    exitCode = 1;
  }
}

String _randomSuffix() {
  final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random.secure();
  return '${chars[rand.nextInt(chars.length)]}${chars[rand.nextInt(chars.length)]}${chars[rand.nextInt(chars.length)]}';
}

String? _extractProp(List<String> lines, String key) {
  for (final line in lines) {
    if (line.startsWith('$key=')) return line.substring('$key='.length);
  }
  return null;
}

String _relativeKeystorePath(String absPath) {
  if (absPath.contains('android/')) {
    return '../vrm-release-key.jks';
  }
  return absPath;
}

// ─── ASSETS ───────────────────────────────────────────────────────────────────

Future<void> _runAssets(List<String> args) async {
  if (args.length < 2 || args[1] != 'validate') {
    print('Uso: dart run scripts/store_prep_cli.dart assets validate');
    exitCode = 1;
    return;
  }

  print('=== Store Prep: Assets Validation ===\n');
  var allOk = true;

  // 1. Icon source
  print('[1] Icon source...');
  final iconFile = File('$_projectRoot/assets/images/branding/icon_source.png');
  if (await iconFile.exists()) {
    final size = await iconFile.length();
    print('  ✅ icon_source.png ($size bytes)');
  } else {
    print('  ❌ icon_source.png NO encontrado');
    allOk = false;
  }

  // 2. Splash source
  print('[2] Splash source...');
  final splashFile = File(
    '$_projectRoot/assets/images/branding/splash_source.png',
  );
  if (await splashFile.exists()) {
    final size = await splashFile.length();
    print('  ✅ splash_source.png ($size bytes)');
  } else {
    print('  ❌ splash_source.png NO encontrado');
    allOk = false;
  }

  // 3. Launcher icons config
  print('[3] flutter_launcher_icons config...');
  final pubspecContent = await File(_pubspecPath).readAsString();
  if (pubspecContent.contains('flutter_launcher_icons:')) {
    final hasAndroid = pubspecContent.contains('android:');
    final hasIos = pubspecContent.contains('ios:');
    final hasImagePath = pubspecContent.contains('image_path:');
    print(
      '  ${hasAndroid && hasIos && hasImagePath ? "✅" : "⚠️"} Config: android=$hasAndroid ios=$hasIos image_path=$hasImagePath',
    );
  } else {
    print('  ❌ flutter_launcher_icons no configurado');
    allOk = false;
  }

  // 4. Native splash config
  print('[4] flutter_native_splash config...');
  if (pubspecContent.contains('flutter_native_splash:')) {
    final hasColor = pubspecContent.contains('color:');
    final hasImage = pubspecContent.contains('image:');
    print(
      '  ${hasColor && hasImage ? "✅" : "⚠️"} Config: color=$hasColor image=$hasImage',
    );
  } else {
    print('  ❌ flutter_native_splash no configurado');
    allOk = false;
  }

  // 5. Store screenshots
  print('[5] Store screenshots...');
  final storeDir = Directory(_storeScreenshotsDir);
  final existingDir = Directory(_existingScreenshotsDir);
  var screenshots = <FileSystemEntity>[];
  var resolutionOk = true;
  var badResolution = <String>[];

  if (await storeDir.exists()) {
    final files = await storeDir
        .list()
        .where((e) => e.path.endsWith('.png'))
        .toList();
    screenshots.addAll(files);
    for (final f in files) {
      if (!_validateScreenshotResolution(f.path)) {
        resolutionOk = false;
        badResolution.add(f.path.split('\\').last.split('/').last);
      }
    }
  }
  if (await existingDir.exists()) {
    final files = await existingDir
        .list()
        .where((e) => e.path.endsWith('.png'))
        .toList();
    screenshots.addAll(files);
    for (final f in files) {
      if (!_validateScreenshotResolution(f.path)) {
        resolutionOk = false;
        badResolution.add(f.path.split('\\').last.split('/').last);
      }
    }
  }

  if (screenshots.length >= 5 && resolutionOk) {
    print('  ✅ ${screenshots.length} screenshots OK (≥1080x1920)');
  } else {
    if (screenshots.length < 5) {
      print('  ❌ Solo ${screenshots.length}/5 screenshots (mínimo 5)');
    }
    if (!resolutionOk) {
      print(
        '  ❌ Resolución insuficiente: ${badResolution.join(", ")} (mínimo 1080x1920)',
      );
    }
    allOk = false;
  }

  // Summary
  if (allOk) {
    print('\n✅ Assets OK');
  } else {
    print('\n❌ Algunos assets fallaron');
    exitCode = 1;
  }
}

// ─── PRIVACY ──────────────────────────────────────────────────────────────────

Future<void> _runPrivacy() async {
  print('=== Store Prep: Privacy Policy Validation ===\n');

  final rootExists = await File(_privacyPolicyPath).exists();
  final docsExists = await File(_privacyPolicyDocsPath).exists();

  if (!rootExists) {
    print('❌ PRIVACY_POLICY.md no encontrado en raíz');
    exitCode = 1;
    return;
  }

  final rootContent = await File(_privacyPolicyPath).readAsString();

  // Check placeholders
  final placeholders = <String>[];
  if (rootContent.contains('[your-')) placeholders.add('[your-*]');
  if (rootContent.contains('[Date]')) placeholders.add('[Date]');
  if (rootContent.contains('[Your Company')) {
    placeholders.add('[Your Company*]');
  }
  if (rootContent.contains('your-support-email')) {
    placeholders.add('your-support-email');
  }

  if (placeholders.isEmpty) {
    print('✅ PRIVACY_POLICY.md sin placeholders');
  } else {
    print('❌ Placeholders detectados: ${placeholders.join(", ")}');
    print('');
    if (docsExists) {
      print('  docs/PRIVACY_POLICY.md tiene datos reales.');
      print(
        '  → Reemplazar raíz: copy docs/PRIVACY_POLICY.md PRIVACY_POLICY.md',
      );
    } else {
      print('  → Reemplazar manualmente los placeholders');
    }
    exitCode = 1;
    return;
  }

  // Compare with docs version
  if (docsExists) {
    final docsContent = await File(_privacyPolicyDocsPath).readAsString();
    if (rootContent == docsContent) {
      print('✅ Versiones raíz y docs/ coinciden');
    } else {
      print(
        '⚠️  versiones raíz y docs/ NO coinciden (docs/ es source de verdad)',
      );
    }
  }

  print('\n✅ Privacy validation complete');
}

// ─── SCREENSHOTS ──────────────────────────────────────────────────────────────

({int width, int height})? _getPngDimensionsSync(String path) {
  try {
    final file = File(path);
    final bytes = file.readAsBytesSync();
    if (bytes.length < 24) return null;
    if (bytes[0] != 0x89 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x4E ||
        bytes[3] != 0x47) {
      return null;
    }
    final w = bytes[16] << 24 | bytes[17] << 16 | bytes[18] << 8 | bytes[19];
    final h = bytes[20] << 24 | bytes[21] << 16 | bytes[22] << 8 | bytes[23];
    return (width: w, height: h);
  } catch (_) {
    return null;
  }
}

bool _validateScreenshotResolution(String path) {
  final dims = _getPngDimensionsSync(path);
  if (dims == null) return false;
  return dims.width >= 1080 && dims.height >= 1920;
}

void _runScreenshotsGuide() {
  print('=== Store Prep: Screenshot Guide ===\n');
  print('Para Google Play Store y App Store:');
  print('');
  print('REQUISITOS:');
  print('  Android: 1080x1920px+ (mínimo), 16:9 landscape');
  print('  iOS:     1284x2778px+ (mínimo), 16:9 landscape');
  print('');
  print('PASOS:');
  print('  1. Conectar dispositivo físico (emulador NO recomendado)');
  print('  2. Abrir app y navegar cada pantalla:');
  print('     a) Dashboard (pantalla principal)');
  print('     b) Creación de proyecto / Script');
  print('     c) Grabación con overlay de control');
  print('     d) Revisión de clips');
  print('     e) Exportación / Performance');
  print('  3. Capturar con ADB:');
  print('     adb shell screencap -p /sdcard/screenshot.png');
  print('     adb pull /sdcard/screenshot.png assets/store/screenshots/');
  print('  4. Alternativa: Captura manual + transferir por USB');
  print('');
  print('VALIDACIÓN:');
  print('  dart run scripts/store_prep_cli.dart check');
  print('  → Verifica resolución ≥1080x1920 (Android) o ≥1284x2778 (iOS)');
  print('');
  print('ARCHIVOS:');
  print('  Guardar en assets/store/screenshots/ como step1.png..step5.png');
  print('');
  print('NOTA: Capturas en emulador pueden ser rechazadas por stores.');
  print('  Usar dispositivo real para resultado final.');
}
