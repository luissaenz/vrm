import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../config/camera_config.dart';

/// Wrapper del plugin `camera` que aisla la lÃ³gica de hardware.
class CameraService {
  CameraController? _controller;
  CameraLensDirection _currentDirection = CameraConfig.defaultDirection;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isRecording => _controller?.value.isRecordingVideo ?? false;
  CameraLensDirection get currentDirection => _currentDirection;

  /// Inicializa la cÃ¡mara con configuraciÃ³n fija.
  Future<void> initialize({CameraLensDirection? direction}) async {
    _currentDirection = direction ?? CameraConfig.defaultDirection;

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No cameras available');
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
  }

  /// Inicia la grabaciÃ³n de video.
  /// Lanza [StateError] si la cÃ¡mara no estÃ¡ inicializada o ya estÃ¡ grabando.
  Future<void> startRecording() async {
    if (_controller == null || !isInitialized) {
      throw StateError('Camera not initialized');
    }
    if (isRecording) {
      throw StateError('Camera is already recording');
    }

    await _controller!.startVideoRecording();
  }

  /// Detiene la grabaciÃ³n y retorna el archivo temporal.
  /// Lanza [StateError] si no estÃ¡ grabando.
  Future<XFile> stopRecording() async {
    if (_controller == null || !isInitialized) {
      throw StateError('Camera not initialized');
    }
    if (!isRecording) {
      throw StateError('Camera is not recording');
    }

    return _controller!.stopVideoRecording();
  }

  /// Cambia entre cÃ¡mara frontal y trasera.
  /// Solo funciona si no estÃ¡ grabando.
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

  /// Configura el modo de exposiciÃ³n.
  Future<void> setExposureMode(ExposureMode mode) async {
    if (_controller == null || !isInitialized) return;
    try {
      await _controller!.setExposureMode(mode);
    } catch (e) {
      debugPrint('CameraService Error: setExposureMode($mode) failing: $e');
    }
  }

  /// Libera todos los recursos de la cÃ¡mara.
  /// Idempotente: seguro llamar mÃºltiples veces.
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
