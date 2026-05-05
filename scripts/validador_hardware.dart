import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';

class HardwareValidationResult {
  final bool focusLockSupported;
  final bool flashSupported;
  final bool exposureLockSupported;
  final String model;
  final String? error;

  HardwareValidationResult({
    required this.focusLockSupported,
    required this.flashSupported,
    required this.exposureLockSupported,
    required this.model,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'focusLockSupported': focusLockSupported,
    'flashSupported': flashSupported,
    'exposureLockSupported': exposureLockSupported,
    'model': model,
    'error': error,
  };
}

Future<HardwareValidationResult> validateHardware() async {
  try {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      return HardwareValidationResult(
        focusLockSupported: false,
        flashSupported: false,
        exposureLockSupported: false,
        model: 'No cameras',
        error: 'No cameras available',
      );
    }

    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller.initialize();

    bool focusSupported = false;
    bool flashSupported = false;
    bool exposureSupported = false;

    try {
      await controller.setFocusMode(FocusMode.locked);
      focusSupported = true;
    } catch (_) {}

    try {
      await controller.setFlashMode(FlashMode.torch);
      flashSupported = true;
    } catch (_) {}

    try {
      await controller.setExposureMode(ExposureMode.locked);
      exposureSupported = true;
    } catch (_) {}

    await controller.dispose();

    return HardwareValidationResult(
      focusLockSupported: focusSupported,
      flashSupported: flashSupported,
      exposureLockSupported: exposureSupported,
      model: '${backCamera.lensDirection.name} camera',
    );
  } catch (e) {
    return HardwareValidationResult(
      focusLockSupported: false,
      flashSupported: false,
      exposureLockSupported: false,
      model: 'Unknown',
      error: e.toString(),
    );
  }
}

Future<void> main() async {
  final result = await validateHardware();
  final output = jsonEncode(result.toJson());
  // Using stdout.write instead of print to avoid lint warning
  // ignore: avoid_print
  stdout.write(output);
}
