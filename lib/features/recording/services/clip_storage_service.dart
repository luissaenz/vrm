import 'dart:io';
import 'package:camera/camera.dart';
import 'package:storage_space/storage_space.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/clip_metadata.dart';
import 'package:vrm_app/core/services/logger_service.dart';

/// Servicio de gestión de almacenamiento para clips de video.
class ClipStorageService {
  final String projectId;

  static const _clipsDirName = 'clips';
  static const _dataDirName = 'vrm_data';
  static const _projectsDirName = 'projects';

  /// Espacio mínimo requerido en MB para permitir una grabación.
  static const int minFreeSpaceMB = 500;

  ClipStorageService({required this.projectId});

  /// Retorna la ruta del directorio de clips del proyecto.
  /// Crea la estructura si no existe.
  Future<Directory> ensureClipsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final clipsDir = Directory(
      p.join(
        appDir.path,
        _dataDirName,
        _projectsDirName,
        projectId,
        _clipsDirName,
      ),
    );

    if (!await clipsDir.exists()) {
      await clipsDir.create(recursive: true);
      LoggerService.log(
        'clip_storage_service',
        '[ClipStorage] Clips directory created: ${clipsDir.path}',
      );
    }

    return clipsDir;
  }

  /// Genera la ruta canónica para un clip.
  String clipPath({required int chunkIndex, required int takeNumber}) {
    return p.join(
      _dataDirName,
      _projectsDirName,
      projectId,
      _clipsDirName,
      'chunk_${chunkIndex}_take_$takeNumber.mp4',
    );
  }

  /// Retorna la ruta absoluta completa para un clip.
  Future<String> absoluteClipPath({
    required int chunkIndex,
    required int takeNumber,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(
      appDir.path,
      clipPath(chunkIndex: chunkIndex, takeNumber: takeNumber),
    );
  }

  /// Escanea el directorio de clips y retorna el siguiente número de take.
  /// Si no existen takes para este chunk, retorna 1.
  Future<int> getNextTakeNumber(int chunkIndex) async {
    final clipsDir = await ensureClipsDirectory();

    if (!await clipsDir.exists()) {
      return 1;
    }

    int maxTake = 0;
    final pattern = 'chunk_${chunkIndex}_take_';

    await for (final entity in clipsDir.list()) {
      final filename = p.basename(entity.path);
      if (filename.startsWith(pattern) && filename.endsWith('.mp4')) {
        // Extract take number: chunk_X_take_N.mp4
        final takePart = filename
            .substring(pattern.length)
            .replaceAll('.mp4', '');
        final takeNum = int.tryParse(takePart);
        if (takeNum != null && takeNum > maxTake) {
          maxTake = takeNum;
        }
      }
    }

    return maxTake + 1;
  }

  /// Copia un XFile del cache de la cámara al directorio de clips.
  /// Retorna la ruta absoluta del clip guardado.
  Future<String> saveClip({
    required XFile sourceFile,
    required int chunkIndex,
    required int takeNumber,
    required ClipMetadata metadata,
  }) async {
    final clipsDir = await ensureClipsDirectory();
    final destPath = p.join(
      clipsDir.path,
      'chunk_${chunkIndex}_take_$takeNumber.mp4',
    );
    final destFile = File(destPath);

    try {
      // Primary: File.copy()
      final sourcePath = sourceFile.path;
      if (sourcePath != destPath) {
        await File(sourcePath).copy(destPath);
        // Clean up source (camera cache)
        try {
          await File(sourcePath).delete();
        } catch (_) {
          LoggerService.log(
            'clip_storage_service',
            '[ClipStorage] Could not delete source: $sourcePath',
          );
        }
      }

      // Verify file was created and has content
      if (!await destFile.exists()) {
        throw FileSystemException('Destination file was not created');
      }

      final size = await destFile.length();
      if (size == 0) {
        // Corrupt clip - delete and rethrow
        await destFile.delete();
        throw FileSystemException('Recorded clip is empty (corrupt)');
      }

      LoggerService.log(
        'clip_storage_service',
        '[ClipStorage] Clip saved: $destPath ($size bytes)',
      );

      return destPath;
    } catch (e) {
      // Fallback: read bytes and write manually
      LoggerService.log(
        'clip_storage_service',
        '[ClipStorage] copy() failed, trying writeAsBytes: $e',
      );
      try {
        final bytes = await File(sourceFile.path).readAsBytes();
        await destFile.writeAsBytes(bytes);
        try {
          await File(sourceFile.path).delete();
        } catch (_) {}

        final size = await destFile.length();
        if (size == 0) {
          await destFile.delete();
          throw FileSystemException('Recorded clip is empty after fallback');
        }

        LoggerService.log(
          'ClipStorageService',
          '[ClipStorage] Clip saved (fallback): $destPath ($size bytes)',
        );
        return destPath;
      } catch (fallbackError) {
        LoggerService.log(
          'clip_storage_service',
          '[ClipStorage] Fallback also failed: $fallbackError',
        );
        // Clean up corrupt file if it exists
        if (await destFile.exists()) {
          try {
            await destFile.delete();
          } catch (_) {}
        }
        rethrow;
      }
    }
  }

  /// Elimina un clip específico.
  Future<void> deleteClip({
    required int chunkIndex,
    required int takeNumber,
  }) async {
    final clipsDir = await ensureClipsDirectory();
    final filePath = p.join(
      clipsDir.path,
      'chunk_${chunkIndex}_take_$takeNumber.mp4',
    );
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      LoggerService.log(
        'clip_storage_service',
        '[ClipStorage] Deleted clip: $filePath',
      );
    }
  }

  /// Verifica el espacio libre real del dispositivo usando disk_space.
  /// Retorna los MB disponibles en el volumen donde se almacenan los datos.
  Future<int> getFreeSpaceMB() async {
    try {
      final storageSpace = await getStorageSpace(
        lowOnSpaceThreshold: minFreeSpaceMB * 1024 * 1024,
        fractionDigits: 2,
      );
      final freeMB = storageSpace.free ~/ (1024 * 1024);
      LoggerService.log(
        'clip_storage_service',
        '[ClipStorage] Real free space: ${freeMB}MB',
      );
      return freeMB;
    } catch (e) {
      LoggerService.log(
        'clip_storage_service',
        '[ClipStorage] Could not determine real free space: $e',
      );
      return minFreeSpaceMB;
    }
  }

  /// Retorna true si hay al menos [requiredMB] megabytes disponibles.
  Future<bool> hasFreeSpace({int requiredMB = minFreeSpaceMB}) async {
    final freeMB = await getFreeSpaceMB();
    return freeMB >= requiredMB;
  }

  /// Limpia archivos temporales del cache de la cámara.
  Future<void> cleanupTemp() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        int deleted = 0;
        await for (final entity in tempDir.list()) {
          if (entity is File) {
            final filename = p.basename(entity.path);
            // Delete camera temp files (*.mp4, *.tmp, *.3gp)
            if (filename.endsWith('.mp4') ||
                filename.endsWith('.tmp') ||
                filename.endsWith('.3gp')) {
              try {
                await entity.delete();
                deleted++;
              } catch (_) {}
            }
          }
        }
        if (deleted > 0) {
          LoggerService.log(
            'clip_storage_service',
            '[ClipStorage] Cleaned $deleted temp files',
          );
        }
      }
    } catch (e) {
      LoggerService.log(
        'clip_storage_service',
        '[ClipStorage] Cleanup error: $e',
      );
    }
  }
}
