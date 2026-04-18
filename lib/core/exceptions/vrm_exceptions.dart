/// Clase base para todas las excepciones del dominio VRM.
abstract class VRMException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  VRMException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'VRMException($code): $message';
}

/// Excepción lanzada cuando hay un fallo en el hardware de la cámara.
class CameraHardwareException extends VRMException {
  CameraHardwareException(super.message, {super.code = 'camera_hardware_error', super.originalError});
}

/// Excepción lanzada cuando el espacio en disco es insuficiente.
class StorageFullException extends VRMException {
  StorageFullException(super.message, {super.code = 'storage_full_error', super.originalError});
}

/// Excepción lanzada cuando falla el proceso de stitching de video.
class VideoProcessingException extends VRMException {
  VideoProcessingException(super.message, {super.code = 'video_processing_error', super.originalError});
}

/// Excepción lanzada cuando falla la integridad de los datos de la sesión.
class SessionIntegrityException extends VRMException {
  SessionIntegrityException(super.message, {super.code = 'session_integrity_error', super.originalError});
}
