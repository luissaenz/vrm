import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../../../core/exceptions/vrm_exceptions.dart';
import '../config/camera_config.dart';

/// Wrapper del plugin `camera` que aisla la lógica de hardware.
class CameraService {
  CameraController? _controller;
  CameraLensDirection _currentDirection = CameraConfig.defaultDirection;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isRecording => _controller?.value.isRecordingVideo ?? false;
  CameraLensDirection get currentDirection => _currentDirection;

  /// Inicializa la cámara con configuración fija.
  Future<void> initialize({CameraLensDirection? direction}) async {
    _currentDirection = direction ?? CameraConfig.defaultDirection;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraHardwareException('No cameras available on this device', code: 'no_cameras');
      }

      CameraDescription selectedCamera;
      try {
        selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == _currentDirection,
        );
      } catch (_) {
        // Fallback to first available camera
        selectedCamera = cameras.first;
      }

      _controller = CameraController(
        selectedCamera,
        CameraConfig.resolution,
        enableAudio: CameraConfig.enableAudio,
        imageFormatGroup: CameraConfig.imageFormat,
      );

      await _controller!.initialize();
    } on CameraException catch (e) {
      throw CameraHardwareException(
        'Failed to initialize camera: ${e.description}',
        code: e.code,
        originalError: e,
      );
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
      throw CameraHardwareException('Camera not initialized', code: 'not_initialized');
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
      throw CameraHardwareException('Camera not initialized', code: 'not_initialized');
    }
    if (!isRecording) {
      throw CameraHardwareException('Camera is not recording', code: 'not_recording');
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
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null || !isInitialized) return;
    try {
      await _controller!.setFlashMode(mode);
    } catch (e) {
      // SUPUESTO: Si el modo no es soportado por el hardware, ignoramos silenciosamente
      // para evitar crashes en la pÃ¡gina de grabaciÃ³n.
      debugPrint('CameraService Error: setFlashMode($mode) failing: $e');
    }
  }

  /// Configura el modo de enfoque.
  Future<void> setFocusMode(FocusMode mode) async {
    if (_controller == null || !isInitialized) return;
    try {
      await _controller!.setFocusMode(mode);
    } catch (e) {
      debugPrint('CameraService Error: setFocusMode($mode) failing: $e');
    }
  }

  /// Configura el modo de exposición.
  Future<void> setExposureMode(ExposureMode mode) async {
    if (_controller == null || !isInitialized) return;
    try {
      await _controller!.setExposureMode(mode);
    } catch (e) {
      debugPrint('CameraService Error: setExposureMode($mode) failing: $e');
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
