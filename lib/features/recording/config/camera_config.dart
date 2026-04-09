import 'package:camera/camera.dart';

/// ConfiguraciÃ³n centralizada de cÃ¡mara.
/// Garantiza consistencia entre clips y compatibilidad con ffmpeg stitching.
/// Si en el futuro se necesita cambiar resoluciÃ³n o FPS, se modifica aquÃ­.
class CameraConfig {
  /// ResoluciÃ³n target: 1080p.
  static const resolution = ResolutionPreset.high;

  /// Audio habilitado (obligatorio para el producto).
  static const enableAudio = true;

  /// Formato de imagen para la cÃ¡mara.
  static const imageFormat = ImageFormatGroup.jpeg;

  /// CÃ¡mara por defecto: frontal (teleprompter).
  static const defaultDirection = CameraLensDirection.front;

  /// ResoluciÃ³n target para metadata. El dispositivo real puede variar.
  static const targetResolution = '1080x1920';

  /// FPS esperados. El dispositivo real puede variar (device-dependent).
  static const expectedFps = 30;
}
