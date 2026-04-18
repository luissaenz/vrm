import 'package:camera/camera.dart';

/// Configuración centralizada de cámara.
/// Garantiza consistencia entre clips y compatibilidad con ffmpeg stitching.
/// Si en el futuro se necesita cambiar resolución o FPS, se modifica aquí.
class CameraConfig {
  /// Resolución target: 1080p.
  static const resolution = ResolutionPreset.high;

  /// Audio habilitado (obligatorio para el producto).
  static const enableAudio = true;

  /// Formato de imagen para la cámara.
  static const imageFormat = ImageFormatGroup.jpeg;

  /// Cámara por defecto: frontal (teleprompter).
  static const defaultDirection = CameraLensDirection.front;

  /// Resolución target para metadata. El dispositivo real puede variar.
  static const targetResolution = '1080x1920';

  /// FPS esperados. El dispositivo real puede variar (device-dependent).
  static const expectedFps = 30;
}
