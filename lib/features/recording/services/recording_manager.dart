import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/clip_metadata.dart';
import '../models/session_data.dart';
import '../config/camera_config.dart';
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
        currentChunk: chunkIndex,
        chunksRecorded: updatedChunks,
        takesPerChunk: updatedTakes,
        lastUpdatedAt: DateTime.now(),
      );

      debugPrint(
        '[RecordingManager] Clip saved: chunk=${chunkIndex}, take=${takeNumber}, '
        'duration=${durationMs}ms, size=${fileSize}bytes',
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
}
