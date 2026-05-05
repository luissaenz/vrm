import 'package:camera/camera.dart';
import '../../../core/exceptions/vrm_exceptions.dart';
import '../../../core/services/logger_service.dart';
import '../config/camera_config.dart';

/// Wrapper del plugin `camera` que aisla la lógica de hardware.
class CameraService {
  CameraController? _controller;
  CameraLensDirection _currentDirection = CameraConfig.defaultDirection;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isRecording => _controller?.value.isRecordingVideo ?? false;
  CameraLensDirection get currentDirection => _currentDirection;

  static const _resolutionFallbacks = [
    ResolutionPreset.high,
    ResolutionPreset.medium,
    ResolutionPreset.low,
  ];

  /// Inicializa la cámara con configuración fija.
  /// Si la resolución [CameraConfig.resolution] falla, degrada automáticamente:
  /// high → medium → low.
  Future<void> initialize({CameraLensDirection? direction}) async {
    _currentDirection = direction ?? CameraConfig.defaultDirection;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraHardwareException(
          'No cameras available on this device',
          code: 'no_cameras',
        );
      }

      CameraDescription selectedCamera;
      try {
        selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == _currentDirection,
        );
      } catch (_) {
        selectedCamera = cameras.first;
      }

      var lastError = '';
      for (final res in _resolutionFallbacks) {
        try {
          _controller = CameraController(
            selectedCamera,
            res,
            enableAudio: CameraConfig.enableAudio,
            imageFormatGroup: CameraConfig.imageFormat,
          );
          await _controller!.initialize();
          if (res != CameraConfig.resolution) {
            LoggerService.log(
              'CameraService',
              'Camera initialized with fallback resolution: $res',
            );
          }
          return;
        } on CameraException catch (e) {
          lastError = '${e.code}: ${e.description}';
          await _controller?.dispose();
          _controller = null;
        }
      }

      throw CameraHardwareException(
        'Failed to initialize camera with all resolutions: $lastError',
        code: 'init_failed',
      );
    } on CameraHardwareException {
      rethrow;
    } catch (e) {
      throw CameraHardwareException(
        'Unexpected error during camera initialization',
        originalError: e,
      );
    }
  }

  /// Inicia la grabación de video.
  Future<void> startRecording() async {
    if (_controller == null || !isInitialized) {
      throw CameraHardwareException(
        'Camera not initialized',
        code: 'not_initialized',
      );
    }
    if (isRecording) return;

    try {
      await _controller!.startVideoRecording();
    } on CameraException catch (e) {
      throw CameraHardwareException(
        'Failed to start recording: ${e.description}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw CameraHardwareException(
        'Unexpected error starting recording',
        originalError: e,
      );
    }
  }

  /// Detiene la grabación y retorna el archivo temporal.
  Future<XFile> stopRecording() async {
    if (_controller == null || !isInitialized) {
      throw CameraHardwareException(
        'Camera not initialized',
        code: 'not_initialized',
      );
    }
    if (!isRecording) {
      throw CameraHardwareException(
        'Camera is not recording',
        code: 'not_recording',
      );
    }

    try {
      return await _controller!.stopVideoRecording();
    } on CameraException catch (e) {
      throw CameraHardwareException(
        'Failed to stop recording: ${e.description}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw CameraHardwareException(
        'Unexpected error stopping recording',
        originalError: e,
      );
    }
  }

  /// Cambia entre cámara frontal y trasera.
  /// Solo funciona si no está grabando.
  Future<void> switchCamera() async {
    if (isRecording) {
      throw StateError('Cannot switch camera while recording');
    }

    final newDirection = _currentDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    await dispose();
    await initialize(direction: newDirection);
  }

  /// Configura el modo de flash.
  /// Lanza [CameraHardwareException] si el hardware no soporta el modo.
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null || !isInitialized) return;
    try {
      await _controller!.setFlashMode(mode);
    } catch (e) {
      throw CameraHardwareException(
        'Flash mode $mode not supported: $e',
        code: 'flash_mode_error',
        originalError: e,
      );
    }
  }

  /// Configura el modo de enfoque.
  /// Lanza [CameraHardwareException] si el hardware no soporta el modo.
  Future<void> setFocusMode(FocusMode mode) async {
    if (_controller == null || !isInitialized) return;
    try {
      await _controller!.setFocusMode(mode);
    } catch (e) {
      throw CameraHardwareException(
        'Focus mode $mode not supported: $e',
        code: 'focus_mode_error',
        originalError: e,
      );
    }
  }

  /// Configura el modo de exposición.
  /// Lanza [CameraHardwareException] si el hardware no soporta el modo.
  Future<void> setExposureMode(ExposureMode mode) async {
    if (_controller == null || !isInitialized) return;
    try {
      await _controller!.setExposureMode(mode);
    } catch (e) {
      throw CameraHardwareException(
        'Exposure mode $mode not supported: $e',
        code: 'exposure_mode_error',
        originalError: e,
      );
    }
  }

  /// Libera todos los recursos de la cámara.
  /// Idempotente: seguro llamar múltiples veces.
  Future<void> dispose() async {
    if (_controller != null) {
      // If recording, stop first (best effort)
      if (isRecording) {
        try {
          await _controller!.stopVideoRecording();
        } catch (_) {
          // Ignore errors during cleanup
        }
      }
      await _controller!.dispose();
      _controller = null;
    }
  }
}
