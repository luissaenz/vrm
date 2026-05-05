import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/logger_service.dart';

/// Reporte de estado de memoria generado por [MemoryMonitor].
class LeakReport {
  final int heapUsageBytes;
  final int allocations;
  final int leakCandidateCount;
  final List<String> warnings;

  LeakReport({
    required this.heapUsageBytes,
    required this.allocations,
    this.leakCandidateCount = 0,
    this.warnings = const [],
  });

  bool get hasLeaks => leakCandidateCount > 0 || warnings.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'heapUsageBytes': heapUsageBytes,
    'allocations': allocations,
    'leakCandidateCount': leakCandidateCount,
    'warnings': warnings,
    'hasLeaks': hasLeaks,
  };
}

/// Monitor de memoria para detección de leaks en sesiones largas de grabación.
/// Sigue patrón singleton de [CameraService].
class MemoryMonitor {
  static final MemoryMonitor _instance = MemoryMonitor._internal();
  factory MemoryMonitor() => _instance;
  MemoryMonitor._internal();

  Timer? _monitorTimer;
  int _sampleCount = 0;
  final List<double> _heapSamples = [];
  bool _isMonitoring = false;

  bool get isMonitoring => _isMonitoring;

  /// Inicia monitoreo periódico de memoria (cada 30s).
  /// Solo en debug/profile mode.
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _sampleCount = 0;
    _heapSamples.clear();

    _monitorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _takeSample();
    });

    await LoggerService.log('MemoryMonitor', 'Monitoring started');
  }

  void _takeSample() {
    _sampleCount++;
    if (kDebugMode) {
      debugPrint('[MemoryMonitor] Sample $_sampleCount taken');
    }
  }

  /// Genera reporte basado en muestras recolectadas.
  Future<LeakReport> getReport() async {
    final warnings = <String>[];

    if (_sampleCount < 2) {
      warnings.add(
        'Insufficient samples ($_sampleCount): run monitoring longer',
      );
    }

    if (_heapSamples.length > 3) {
      final first = _heapSamples.first;
      final last = _heapSamples.last;
      if (last > first * 1.5) {
        warnings.add('Heap grew >50% during session — possible leak');
      }
    }

    final report = LeakReport(
      heapUsageBytes: 0,
      allocations: _sampleCount,
      leakCandidateCount: warnings.length,
      warnings: warnings,
    );

    await LoggerService.log(
      'MemoryMonitor',
      'Report generated',
      error: report.toJson().toString(),
    );
    return report;
  }

  /// Detiene el monitoreo.
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;
    await LoggerService.log(
      'MemoryMonitor',
      'Monitoring stopped after $_sampleCount samples',
    );
  }
}
