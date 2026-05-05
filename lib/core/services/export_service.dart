import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'logger_service.dart';

/// Resultado de la operación de guardado en galería.
typedef ExportResult = ({bool success, String? assetId, String? error});

/// Servicio singleton para exportar videos a la galería y share sheet.
/// Implementa el flujo del Día 6: saveToGallery → shareVideo.
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  /// Stream de progreso para la operación saveToGallery (0.0 a 1.0).
  Stream<double> get progressStream => _progressController.stream;

  void _emitProgress(double progress) {
    _progressController.add(progress.clamp(0.0, 1.0));
  }

  /// Guarda un video en la galería nativa del dispositivo.
  ///
  /// Flujo:
  /// 1. Verifica que el archivo existe en disco.
  /// 2. Verifica/solicita permisos de fotos via permission_handler.
  /// 3. Si permiso permanentemente denegado, retorna error.
  /// 4. Usa photo_manager para guardar el video.
  ///
  /// El progreso se emite via [progressStream].
  Future<ExportResult> saveToGallery(String filePath) async {
    _emitProgress(0.0);

    // 1. Verificar existencia del archivo
    final file = File(filePath);
    if (!file.existsSync()) {
      _emitProgress(1.0);
      return (success: false, assetId: null, error: 'file_not_found');
    }
    _emitProgress(0.2);

    // 2. Verificar permisos via permission_handler
    final photosStatus = await Permission.photos.status;
    if (photosStatus.isPermanentlyDenied) {
      _emitProgress(1.0);
      return (success: false, assetId: null, error: 'permanently_denied');
    }
    _emitProgress(0.4);

    if (!photosStatus.isGranted) {
      final result = await Permission.photos.request();
      if (!result.isGranted) {
        _emitProgress(1.0);
        final isPermanentlyDenied = result.isPermanentlyDenied;
        return (
          success: false,
          assetId: null,
          error: isPermanentlyDenied ? 'permanently_denied' : 'denied',
        );
      }
    }
    _emitProgress(0.6);

    // 3. Guardar en galería usando photo_manager
    try {
      _emitProgress(0.8);
      final result = await PhotoManager.editor.saveVideo(file);
      _emitProgress(1.0);
      return (success: true, assetId: result.id, error: null);
    } catch (e) {
      _emitProgress(1.0);
      LoggerService.log('ExportService', 'Error saving to gallery', error: e);
      return (success: false, assetId: null, error: 'exception');
    }
  }

  /// Abre el share sheet nativo con el video adjunto.
  ///
  /// Flujo:
  /// 1. Copia el archivo a getTemporaryDirectory() (Android FileProvider).
  /// 2. Comparte via share_plus.
  /// 3. Limpia el archivo temporal en finally.
  Future<void> shareVideo(String filePath, {String? subject}) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      LoggerService.log(
        'ExportService',
        'shareVideo: file not found at $filePath',
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/vrm_final.mp4';

    try {
      // Copiar a directorio temporal para Android FileProvider
      await file.copy(tempFilePath);
      final xFile = XFile(tempFilePath);

      await Share.shareXFiles([xFile], subject: subject);
    } finally {
      // Limpiar archivo temporal
      try {
        final tempFile = File(tempFilePath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        LoggerService.log(
          'ExportService',
          'Failed to delete temp file',
          error: e,
        );
      }
    }
  }

  /// Libera recursos del StreamController.
  void dispose() {
    _progressController.close();
  }
}
