import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Servicio de gestión de permisos de cámara y micrófono.
class PermissionService {
  /// Verifica si ambos permisos (cámara y micrófono) están concedidos.
  Future<bool> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    return cameraStatus.isGranted && micStatus.isGranted;
  }

  /// Solicita ambos permisos. Retorna true si ambos fueron concedidos.
  Future<bool> requestPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    return cameraGranted && micGranted;
  }

  /// Retorna un mapa con el estado de cada permiso.
  /// Útil para determinar cuáles están denegados granularmente.
  Future<Map<Permission, PermissionStatus>> getPermissionStatuses() async {
    return {
      Permission.camera: await Permission.camera.status,
      Permission.microphone: await Permission.microphone.status,
    };
  }

  /// Muestra un diálogo explicativo y abre configuración de la app
  /// si los permisos fueron denegados permanentemente.
  /// Indica granularmente qué permiso(s) fueron denegados.
  Future<void> handleDenied(
    BuildContext context, {
    bool cameraDenied = false,
    bool microphoneDenied = false,
  }) async {
    // Build granular message
    final deniedPermissions = <String>[];
    if (cameraDenied) deniedPermissions.add('Cámara');
    if (microphoneDenied) deniedPermissions.add('Micrófono');

    String message;
    if (deniedPermissions.isEmpty) {
      message =
          'VRM necesita acceso a la cámara y al micrófono para grabar videos. '
          'Los permisos fueron denegados permanentemente. '
          'Ve a Configuración para activarlos manualmente.';
    } else if (deniedPermissions.length == 1) {
      message =
          'VRM necesita acceso al ${deniedPermissions.first.toLowerCase()} para grabar videos. '
          'El permiso de ${deniedPermissions.first.toLowerCase()} fue denegado permanentemente. '
          'Ve a Configuración para activarlo manualmente.';
    } else {
      message =
          'VRM necesita acceso a la cámara y al micrófono para grabar videos. '
          'Los permisos de ${deniedPermissions.join(' y ')} fueron denegados permanentemente. '
          'Ve a Configuración para activarlos manualmente.';
    }

    final shouldOpen = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Permisos requeridos'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ir a Configuración'),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      await openAppSettings();
    }
  }
}
