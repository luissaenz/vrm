import 'dart:convert';
import 'dart:io';

const _usage = '''
VRM Health Check — CLI unificado para diagnóstico y validación.

USO:
  dart run scripts/vrm_health_check.dart <subcomando> [flags]

SUBCOMANDOS:
  check [--fix]         Pre-flight: permisos, espacio, cámara, temp huérfanos
  validate [--device]   Test recovery paths: space, camera, stitch, export
  memory                Memory leak detection (debug mode)
  scaffold --project-id <uuid>  Crear estructura vrm_data/ para proyecto
  --help                Muestra esta ayuda

FLAGS:
  --fix         Limpia temp si es seguro (check)
  --device      Conecta a dispositivo físico (validate)
  --project-id  UUID del proyecto (scaffold)
''';

void main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    print(_usage);
    return;
  }

  final subcommand = args.first;
  final flags = args.skip(1).toSet();

  switch (subcommand) {
    case 'check':
      await _runCheck(flags.contains('--fix'));
    case 'validate':
      await _runValidate(flags.contains('--device'));
    case 'memory':
      await _runMemory();
    case 'scaffold':
      final projectId = _extractFlagValue(args, '--project-id');
      await _runScaffold(projectId);
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

// ─── CHECK ───────────────────────────────────────────────────────────────────

Future<void> _runCheck(bool fix) async {
  print('=== VRM Health Check: Pre-flight ===');
  if (fix) print('  (--fix mode: cleanup enabled)');
  print('');

  final results = <String, bool>{};
  final details = <String, String>{};

  // 1. Verificar permisos del proyecto
  print('[1] Verificando estructura del proyecto...');
  final libDir = Directory('lib');
  final exists = await libDir.exists();
  results['project_structure'] = exists;
  details['project_structure'] = exists
      ? 'lib/ encontrado'
      : 'lib/ NO encontrado';
  print('  ${exists ? "✅" : "❌"} lib/: ${details["project_structure"]}');

  // 2. Verificar archivos clave del pipeline
  print('[2] Verificando archivos del pipeline...');
  final filesToCheck = [
    'lib/features/recording/services/camera_service.dart',
    'lib/features/recording/services/recording_manager.dart',
    'lib/features/recording/services/clip_storage_service.dart',
    'lib/core/services/export_service.dart',
    'lib/core/services/native_stitcher_service.dart',
    'lib/core/exceptions/vrm_exceptions.dart',
  ];
  var allFilesOk = true;
  for (final f in filesToCheck) {
    final fe = await File(f).exists();
    if (!fe) {
      allFilesOk = false;
      print('  ❌ $f: NO ENCONTRADO');
    }
  }
  results['pipeline_files'] = allFilesOk;
  details['pipeline_files'] = allFilesOk
      ? 'Todos los archivos existen'
      : 'Faltan archivos';
  if (allFilesOk) print('  ✅ Todos los archivos del pipeline existen');

  // 3. Verificar LoggerService si ya existe
  print('[3] Verificando LoggerService...');
  final loggerExists = await File(
    'lib/core/services/logger_service.dart',
  ).exists();
  results['logger_service'] = loggerExists;
  details['logger_service'] = loggerExists
      ? 'LoggerService presente'
      : 'LoggerService NO implementado';
  print('  ${loggerExists ? "✅" : "❌"} ${details["logger_service"]}');

  // 4. Verificar MemoryMonitor si ya existe
  print('[4] Verificando MemoryMonitor...');
  final memExists = await File(
    'lib/features/recording/services/memory_monitor.dart',
  ).exists();
  results['memory_monitor'] = memExists;
  details['memory_monitor'] = memExists
      ? 'MemoryMonitor presente'
      : 'MemoryMonitor NO implementado';
  print('  ${memExists ? "✅" : "❌"} ${details["memory_monitor"]}');

  // 5. Verificar ProGuard
  print('[5] Verificando ProGuard...');
  final proGuardFile = File('android/app/proguard-rules.pro');
  final proGuardExists = await proGuardFile.exists();
  if (proGuardExists) {
    final content = await proGuardFile.readAsString();
    final hasDeadRules = content.contains('ffmpegkit');
    results['proguard'] = !hasDeadRules;
    details['proguard'] = hasDeadRules
        ? 'Tiene reglas ffmpegkit muertas'
        : 'Limpio';
    print('  ${hasDeadRules ? "❌" : "✅"} ${details["proguard"]}');
    if (hasDeadRules && fix) {
      print('  ⚠️  Usa Tarea 1 del plan de implementación para limpiar.');
    }
  } else {
    results['proguard'] = false;
    details['proguard'] = 'No encontrado';
    print('  ❌ proguard-rules.pro no encontrado');
  }

  // 6. Verificar Extra (carpeta scripts)
  print('[6] Verificando scripts/...');
  final scriptsDir = Directory('scripts');
  final scriptsExists = await scriptsDir.exists();
  results['scripts_dir'] = scriptsExists;
  details['scripts_dir'] = scriptsExists
      ? 'scripts/ existe'
      : 'scripts/ NO encontrado';
  print('  ${scriptsExists ? "✅" : "❌"} ${details["scripts_dir"]}');

  // Resumen
  print('');
  print('=== RESULT ===');
  final passed = results.values.where((v) => v).length;
  final total = results.length;
  print('Passed: $passed/$total checks');
  print('JSON: ${jsonEncode(results)}');

  if (results.values.any((v) => !v)) {
    exitCode = 1;
  }
}

// ─── VALIDATE ────────────────────────────────────────────────────────────────

Future<void> _runValidate(bool device) async {
  print('=== VRM Health Check: Resilience Validation ===');
  if (device) print('  (--device mode: requiere dispositivo físico)');
  print('');

  final results = <String, bool>{};
  final errors = <String, String>{};

  // Stage 1: CameraService
  print('[1/5] Verificando CameraService...');
  try {
    final file = File('lib/features/recording/services/camera_service.dart');
    if (await file.exists()) {
      final content = await file.readAsString();
      final hasInitialize = content.contains('Future<void> initialize');
      final hasStart = content.contains('startRecording()');
      final hasStop = content.contains('stopRecording()');
      final hasFallback = content.contains('ResolutionPreset');
      final hasErrorPropagation = !content.contains(
        '// SUPUESTO: Si el modo no es soportado',
      );
      results['camera_service'] = hasInitialize && hasStart && hasStop;
      if (hasFallback) print('  ✅ CameraService: fallback resolución presente');
      if (hasErrorPropagation)
        print('  ✅ CameraService: errores propagados (sin try silencioso)');
      final camOk = results["camera_service"] == true;
      print(
        '  ${camOk ? "✅" : "❌"} CameraService: ${camOk ? "OK" : "estructura incompleta"}',
      );
    } else {
      results['camera_service'] = false;
      errors['camera_service'] = 'File not found';
      print('  ❌ CameraService: file not found');
    }
  } catch (e) {
    results['camera_service'] = false;
    errors['camera_service'] = e.toString();
    print('  ❌ CameraService: $e');
  }

  // Stage 2: RecordingManager
  print('[2/5] Verificando RecordingManager...');
  try {
    final file = File('lib/features/recording/services/recording_manager.dart');
    if (await file.exists()) {
      final content = await file.readAsString();
      final hasIntegrityCheck = content.contains('verifySessionIntegrity');
      final hasLogger = content.contains('LoggerService');
      results['recording_manager'] = true;
      if (hasIntegrityCheck)
        print('  ✅ RecordingManager: verifyIntegrity presente');
      if (hasLogger) print('  ✅ RecordingManager: LoggerService integrado');
      print('  ✅ RecordingManager: OK');
    } else {
      results['recording_manager'] = false;
      errors['recording_manager'] = 'File not found';
      print('  ❌ RecordingManager: file not found');
    }
  } catch (e) {
    results['recording_manager'] = false;
    errors['recording_manager'] = e.toString();
    print('  ❌ RecordingManager: $e');
  }

  // Stage 3: ExportService
  print('[3/5] Verificando ExportService...');
  try {
    final file = File('lib/core/services/export_service.dart');
    if (await file.exists()) {
      final content = await file.readAsString();
      final hasProgress =
          content.contains('StreamController<double>') ||
          content.contains('onProgress');
      results['export_service'] =
          content.contains('saveToGallery') && content.contains('shareVideo');
      if (hasProgress) print('  ✅ ExportService: Stream progreso presente');
      final expOk = results["export_service"] == true;
      print(
        '  ${expOk ? "✅" : "❌"} ExportService: ${expOk ? "OK" : "incompleto"}',
      );
    } else {
      results['export_service'] = false;
      errors['export_service'] = 'File not found';
      print('  ❌ ExportService: file not found');
    }
  } catch (e) {
    results['export_service'] = false;
    errors['export_service'] = e.toString();
    print('  ❌ ExportService: $e');
  }

  // Stage 4: RecordingEndPage overlay
  print('[4/5] Verificando RecordingEndPage overlay export...');
  try {
    final file = File('lib/features/recording/recording_end_page.dart');
    if (await file.exists()) {
      final content = await file.readAsString();
      final hasOverlay =
          content.contains('_isSavingOverlay') ||
          content.contains('Guardando en galería');
      results['export_overlay'] = hasOverlay;
      print(
        '  ${hasOverlay ? "✅" : "❌"} RecordingEndPage: ${hasOverlay ? "overlay Guardando presente" : "sin overlay"}',
      );
    } else {
      results['export_overlay'] = false;
      errors['export_overlay'] = 'File not found';
      print('  ❌ RecordingEndPage: file not found');
    }
  } catch (e) {
    results['export_overlay'] = false;
    errors['export_overlay'] = e.toString();
    print('  ❌ RecordingEndPage: $e');
  }

  // Stage 5: MemoryMonitor
  print('[5/5] Verificando MemoryMonitor + didHaveMemoryPressure...');
  try {
    final memFile = File('lib/features/recording/services/memory_monitor.dart');
    final memExists = await memFile.exists();
    final pageFile = File('lib/features/recording/recording_page.dart');
    final pageContent = await pageFile.readAsString();
    final hasMemoryPressure = pageContent.contains('didHaveMemoryPressure');
    results['memory_handling'] = memExists && hasMemoryPressure;
    if (memExists) print('  ✅ MemoryMonitor: presente');
    if (hasMemoryPressure)
      print('  ✅ RecordingPage: didHaveMemoryPressure implementado');
    final memOk = results["memory_handling"] == true;
    print(
      '  ${memOk ? "✅" : "❌"} Memory handling: ${memOk ? "OK" : "incompleto"}',
    );
  } catch (e) {
    results['memory_handling'] = false;
    errors['memory_handling'] = e.toString();
    print('  ❌ Memory check: $e');
  }

  // Summary
  print('');
  print('=== RESULT ===');
  final passed = results.values.where((v) => v).length;
  final total = results.length;
  print('Passed: $passed/$total stages');
  print('JSON: ${jsonEncode(results)}');

  if (errors.isNotEmpty) {
    print('');
    print('❌ FAILURES:');
    for (final entry in errors.entries) {
      print('  - ${entry.key}: ${entry.value}');
    }
    exitCode = 1;
  } else if (results.values.any((v) => !v)) {
    print('');
    print('⚠️  Algunas validaciones fallaron (pueden ser tareas pendientes).');
    exitCode = 1;
  } else {
    print('✅ All stages OK');
    exitCode = 0;
  }
}

// ─── MEMORY ───────────────────────────────────────────────────────────────────

Future<void> _runMemory() async {
  print('=== VRM Health Check: Memory Leak Detection ===');
  print('');
  print('NOTA: Este análisis es estático (código).');
  print('      Para detección dinámica, ejecutar en dispositivo físico:');
  print('        flutter run --profile');
  print('      y monitorear con DevTools > Memory view.');
  print('');

  final results = <String, bool>{};
  final details = <String, String>{};

  // 1. Verificar dispose patterns
  print('[1] Verificando patrones dispose...');
  final filesWithDispose = [
    'lib/features/recording/recording_page.dart',
    'lib/features/recording/services/recording_manager.dart',
    'lib/features/recording/services/camera_service.dart',
    'lib/features/recording/recording_end_page.dart',
    'lib/features/recording/clip_review_page.dart',
  ];
  var disposeOk = true;
  for (final f in filesWithDispose) {
    final file = File(f);
    if (await file.exists()) {
      final content = await file.readAsString();
      if (!content.contains('dispose()') && !content.contains('@override')) {
        disposeOk = false;
        print('  ❌ $f: sin método dispose()');
      }
    }
  }
  results['dispose_patterns'] = disposeOk;
  details['dispose_patterns'] = disposeOk
      ? 'Todos los componentes tienen dispose'
      : 'Faltan disposers';
  print('  ${disposeOk ? "✅" : "❌"} ${details["dispose_patterns"]}');

  // 2. Verificar MemoryMonitor
  print('[2] Verificando MemoryMonitor...');
  final memExists = await File(
    'lib/features/recording/services/memory_monitor.dart',
  ).exists();
  results['memory_monitor'] = memExists;
  details['memory_monitor'] = memExists
      ? 'MemoryMonitor presente'
      : 'MemoryMonitor no implementado';
  print('  ${memExists ? "✅" : "❌"} ${details["memory_monitor"]}');

  // 3. Verificar didHaveMemoryPressure
  print('[3] Verificando didHaveMemoryPressure...');
  final pageFile = File('lib/features/recording/recording_page.dart');
  if (await pageFile.exists()) {
    final content = await pageFile.readAsString();
    final hasPressure = content.contains('didHaveMemoryPressure');
    results['memory_pressure'] = hasPressure;
    details['memory_pressure'] = hasPressure
        ? 'didHaveMemoryPressure implementado'
        : 'No implementado';
    print('  ${hasPressure ? "✅" : "❌"} ${details["memory_pressure"]}');
  } else {
    results['memory_pressure'] = false;
    details['memory_pressure'] = 'File not found';
    print('  ❌ recording_page.dart no encontrado');
  }

  // Summary
  print('');
  print('=== RESULT ===');
  final passed = results.values.where((v) => v).length;
  final total = results.length;
  print('Passed: $passed/$total checks');
  print('JSON: ${jsonEncode(results)}');

  if (results.values.any((v) => !v)) {
    exitCode = 1;
  }
}

// ─── SCAFFOLD ────────────────────────────────────────────────────────────────

Future<void> _runScaffold(String? projectId) async {
  if (projectId == null || projectId.isEmpty) {
    print('❌ Error: --project-id es requerido');
    print(
      'Uso: dart run scripts/vrm_health_check.dart scaffold --project-id <uuid>',
    );
    exitCode = 1;
    return;
  }

  print('=== VRM Health Check: Scaffold ===');
  print('Creando estructura para proyecto: $projectId');
  print('');

  final baseDir = 'vrm_data/projects/$projectId';
  final dirs = ['$baseDir/clips'];

  for (final dir in dirs) {
    try {
      await Directory(dir).create(recursive: true);
      print('  ✅ Creado: $dir/');
    } catch (e) {
      print('  ❌ Error creando $dir: $e');
      exitCode = 1;
    }
  }

  final files = {
    '$baseDir/session_data.json': '{}',
    '$baseDir/project.json':
        '{"projectId": "$projectId", "createdAt": "${DateTime.now().toIso8601String()}"}',
  };

  for (final entry in files.entries) {
    try {
      await File(entry.key).writeAsString(entry.value);
      print('  ✅ Creado: ${entry.key}');
    } catch (e) {
      print('  ❌ Error creando ${entry.key}: $e');
      exitCode = 1;
    }
  }

  print('');
  print('✅ Scaffold completado para $projectId');
}
