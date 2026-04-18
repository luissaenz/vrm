import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/native_stitcher_service.dart';
import '../models/clip_metadata.dart';
import '../models/session_data.dart';
import '../config/camera_config.dart';
import '../../../core/exceptions/vrm_exceptions.dart';
import 'camera_service.dart';
import 'clip_storage_service.dart';

/// Orquestador de grabación.
/// Une [CameraService] + [ClipStorageService] y maneja debounce + estado.
class RecordingManager {
  final CameraService _camera;
  final ClipStorageService _storage;

  bool _isProcessing = false;
  bool _isRecording = false;
  int? _currentChunkIndex;
  DateTime? _recordingStartedAt;

  /// Sesión en memoria (persiste en Día 7-8).
  SessionData sessionData;

  RecordingManager({
    required CameraService camera,
    required ClipStorageService storage,
    required this.sessionData,
  }) : _camera = camera,
       _storage = storage;

  bool get isProcessing => _isProcessing;
  bool get isRecording => _isRecording;
  int? get currentChunkIndex => _currentChunkIndex;

  /// Duración de la grabación actual en milisegundos.
  /// Retorna null si no está grabando.
  int? get currentRecordingDurationMs {
    if (_recordingStartedAt == null || !_isRecording) return null;
    return DateTime.now().difference(_recordingStartedAt!).inMilliseconds;
  }

  /// Inicia la grabación para el chunk dado.
  /// Lanza [StateError] si ya está grabando o procesando.
  Future<void> startRecording(int chunkIndex) async {
    if (_isProcessing) {
      throw StateError('Recording operation in progress');
    }
    if (_isRecording) {
      throw StateError('Already recording');
    }

    _isProcessing = true;
    _currentChunkIndex = chunkIndex;

    try {
      // Día 15: Verificación proactiva de espacio en disco
      final hasSpace = await _storage.hasFreeSpace();
      if (!hasSpace) {
        throw StorageFullException(
          'Insufficient disk space to start recording. At least ${ClipStorageService.minFreeSpaceMB}MB required.',
        );
      }

      await _camera.startRecording();
      _isRecording = true;
      _recordingStartedAt = DateTime.now();
      debugPrint('[RecordingManager] Recording started for chunk $chunkIndex');
    } catch (e) {
      // Reset state on failure so caller can retry
      _isRecording = false;
      _currentChunkIndex = null;
      rethrow;
    } finally {
      // Clear processing flag ONLY after the hardware operation has fully resolved
      _isProcessing = false;
    }
  }

  /// Detiene la grabación, guarda el clip y retorna su ruta absoluta.
  /// Lanza [StateError] si no está grabando.
  Future<String> stopRecording() async {
    if (!_isRecording) {
      throw StateError('Not recording');
    }
    if (_isProcessing) {
      throw StateError('Recording operation in progress');
    }

    _isProcessing = true;
    final chunkIndex = _currentChunkIndex!;
    final durationMs = _recordingStartedAt != null
        ? DateTime.now().difference(_recordingStartedAt!).inMilliseconds
        : 0;

    try {
      // Stop camera recording
      final xFile = await _camera.stopRecording();
      _isRecording = false;

      // Determine take number
      final takeNumber = await _storage.getNextTakeNumber(chunkIndex);

      // Build metadata
      final metadata = ClipMetadata(
        chunkIndex: chunkIndex,
        takeNumber: takeNumber,
        durationMs: durationMs,
        resolution: CameraConfig.targetResolution,
        fps: CameraConfig.expectedFps,
        hasAudio: CameraConfig.enableAudio,
        fileSizeBytes: 0, // Will be updated after save
        createdAt: DateTime.now(),
      );

      // Save clip to persistent storage
      final savedPath = await _storage.saveClip(
        sourceFile: xFile,
        chunkIndex: chunkIndex,
        takeNumber: takeNumber,
        metadata: metadata,
      );

      // Update file size in metadata
      final savedFile = File(savedPath);
      final fileSize = await savedFile.length();

      // Update session data
      final existingInfo = sessionData.takesPerChunk[chunkIndex];
      final updatedTakes = Map<int, ChunkTakeInfo>.from(
        sessionData.takesPerChunk,
      );
      updatedTakes[chunkIndex] = ChunkTakeInfo(
        total: existingInfo != null ? existingInfo.total + 1 : 1,
        selectedTake: takeNumber, // latest take is the selected one
      );

      final updatedChunks = sessionData.chunksRecorded.contains(chunkIndex)
          ? sessionData.chunksRecorded
          : [...sessionData.chunksRecorded, chunkIndex];

      sessionData = sessionData.copyWith(
        currentChunkIndex: chunkIndex,
        chunksRecorded: updatedChunks,
        takesPerChunk: updatedTakes,
        lastUpdatedAt: DateTime.now(),
      );

      debugPrint(
        '[RecordingManager] Clip saved: chunk=$chunkIndex, take=$takeNumber, '
        'duration=$durationMs ms, size=$fileSize bytes',
      );

      return savedPath;
    } finally {
      _isProcessing = false;
      _currentChunkIndex = null;
      _recordingStartedAt = null;
    }
  }

  /// Cambia la cámara activa (solo si no está grabando ni procesando).
  Future<void> switchCamera() async {
    if (_isRecording || _isProcessing) {
      throw StateError('Cannot switch camera while recording or processing');
    }
    await _camera.switchCamera();
  }

  /// Detiene la grabación actual y guarda el clip parcial.
  /// Se usa para interceptar app lifecycle (background).
  /// Retorna un resultado tipado: el path del clip guardado o el error ocurrido.
  Future<({String? clipPath, Object? error})> stopAndSavePartial() async {
    if (!_isRecording) {
      return (clipPath: null, error: null);
    }

    try {
      final path = await stopRecording();
      return (clipPath: path, error: null);
    } catch (e) {
      debugPrint('[RecordingManager] Partial clip save failed: $e');
      // Force stop camera as last resort
      try {
        if (_camera.isRecording) {
          await _camera.stopRecording();
        }
      } catch (_) {
        // Give up
      }
      _isRecording = false;
      _isProcessing = false;
      return (clipPath: null, error: e);
    }
  }

  /// Acepta el clip actual y avanza al siguiente fragmento.
  /// Actualiza sessionData con el clip aprobado y incrementa currentChunkIndex.
  Future<void> acceptCurrentClip(String clipPath) async {
    final currentChunk = sessionData.currentChunkIndex;

    // Actualizar approvedClips
    final updatedApproved = Map<int, String>.from(sessionData.approvedClips);
    updatedApproved[currentChunk] = clipPath;

    // Avanzar al siguiente fragmento
    final nextChunk = currentChunk + 1;

    sessionData = sessionData.copyWith(
      currentChunkIndex: nextChunk,
      approvedClips: updatedApproved,
      lastUpdatedAt: DateTime.now(),
    );

    // Persistir cambios en disco
    await _saveSessionDataToDisk();

    debugPrint('[RecordingManager] Clip accepted for chunk $currentChunk: $clipPath');
  }

  /// Guarda sessionData en disco como JSON.
  Future<void> _saveSessionDataToDisk() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final projectDir = Directory('${directory.path}/vrm_data/projects/${sessionData.projectId}');
      await projectDir.create(recursive: true);

      final sessionFile = File('${projectDir.path}/session_data.json');
      final jsonData = jsonEncode(sessionData.toJson());
      await sessionFile.writeAsString(jsonData);

      debugPrint('[RecordingManager] Session data saved to ${sessionFile.path}');
    } catch (e) {
      debugPrint('[RecordingManager] Failed to save session data: $e');
      // No lanzamos error para no bloquear el flujo de grabación
    }
  }

  /// Rechaza el clip actual, elimina el archivo y mantiene el fragmento actual para re-grabación.
  /// Lanza [Exception] si falla el borrado del archivo.
  Future<void> rejectCurrentClip(String clipPath) async {
    try {
      final file = File(clipPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[RecordingManager] Rejected clip deleted: $clipPath');
      } else {
        debugPrint('[RecordingManager] Rejected clip not found: $clipPath');
      }
    } catch (e) {
      debugPrint('[RecordingManager] Failed to delete rejected clip: $e');
      // No lanzamos error, solo logueamos para no bloquear el flujo
    }

    // No actualizamos sessionData ya que permanecemos en el mismo fragmento
  }

  /// Inicia el proceso de stitching de los clips aprobados.
  /// Actualiza sessionData con el resultado.
  Future<String> startStitching({
    required void Function(double progress, String status) onProgress,
    required void Function(String error) onError,
  }) async {
    final approvedClips = (sessionData.approvedClips.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => e.value)
        .toList();
    if (approvedClips.isEmpty) {
      throw StateError('No approved clips to stitch');
    }

    final stitcherService = NativeStitcherService();
    final finalVideoPath = await stitcherService.stitchVideos(
      projectId: sessionData.projectId,
      clipPaths: approvedClips,
      onProgress: (progress) {
        onProgress(progress.progress, progress.status);
      },
      onError: onError,
    );

    // Update session data
    sessionData = sessionData.copyWith(
      stitchingCompleted: true,
      finalVideoPath: finalVideoPath,
      stitchedAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    );

    // Persist changes
    await _saveSessionDataToDisk();

    debugPrint('[RecordingManager] Stitching completed: $finalVideoPath');

    return finalVideoPath;
  }

  /// Limpia recursos. Llamar al salir de la página.
  /// Asegura que todas las operaciones asíncronas finalicen antes de destruir.
  Future<void> dispose() async {
    // If recording, wait for partial save to complete atomically
    if (_isRecording) {
      debugPrint(
        '[RecordingManager] Disposing while recording — saving partial clip',
      );
      await stopAndSavePartial();
    }
    // Ensure camera dispose completes before continuing
    try {
      await _camera.dispose();
    } catch (e) {
      debugPrint('[RecordingManager] Camera dispose error: $e');
    }
    // Clean up temp files
    try {
      await _storage.cleanupTemp();
    } catch (e) {
      debugPrint('[RecordingManager] Temp cleanup error: $e');
    }
    debugPrint('[RecordingManager] Disposed successfully');
  }

  /// Día 14: Verifica que todos los clips aprobados existan físicamente en disco.
  /// Lanza [SessionIntegrityException] si faltan archivos críticos.
  /// Devuelve una versión actualizada de [SessionData] si hubo cambios.
  static Future<SessionData> verifyIntegrityStatic(SessionData data) async {
    final missingClips = <int>[];

    for (final entry in data.approvedClips.entries) {
      final chunkIndex = entry.key;
      final clipPath = entry.value;
      final file = File(clipPath);

      if (!await file.exists()) {
        missingClips.add(chunkIndex);
      }
    }

    if (missingClips.isNotEmpty) {
      // Acción de recuperación: eliminamos las referencias a clips faltantes
      final updatedApproved = Map<int, String>.from(data.approvedClips);
      for (final chunk in missingClips) {
        updatedApproved.remove(chunk);
      }

      final newData = data.copyWith(
        approvedClips: updatedApproved,
        lastUpdatedAt: DateTime.now(),
      );

      // Notificamos al usuario mediante una excepción informativa
      throw SessionIntegrityException(
        'Some approved clips are missing from storage. Chunks affected: ${missingClips.join(", ")}. '
        'These fragments have been reset for re-recording.',
        code: 'missing_files',
        originalError: newData, // Pasamos la data corregida en el error para que la UI la use
      );
    }

    debugPrint('[RecordingManager] Session integrity verified successfully');
    return data;
  }

  /// Instanced version for convenience
  Future<void> verifySessionIntegrity() async {
    try {
      sessionData = await verifyIntegrityStatic(sessionData);
    } on SessionIntegrityException catch (e) {
      sessionData = e.originalError as SessionData;
      rethrow;
    }
  }
}
