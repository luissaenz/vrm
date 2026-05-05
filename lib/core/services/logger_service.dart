import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Logger que persiste errores críticos a archivo rotativo.
/// En Release mode, [debugPrint] es no-op — este logger garantiza
/// que errores de grabación, cámara y exportación queden registrados.
///
/// Guarda en: {getApplicationDocumentsDirectory()}/vrm_data/logs/app.log
class LoggerService {
  static const int _maxFileSize = 1024 * 512;
  static const String _logFileName = 'app.log';
  static const String _logDir = 'vrm_data/logs';

  /// Escribe un mensaje de log al archivo persistente.
  /// Solo para errores críticos (no usar para debug genérico).
  static Future<void> log(
    String tag,
    String message, {
    Object? error,
    StackTrace? stack,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/$_logDir');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final logFile = File('${logDir.path}/$_logFileName');

      // Rotate if too large
      if (await logFile.exists()) {
        final length = await logFile.length();
        if (length > _maxFileSize) {
          await logFile.rename('${logDir.path}/app.old.log');
        }
      }

      final timestamp = DateTime.now().toIso8601String();
      final stackStr = stack != null ? '\n${stack.toString()}' : '';
      final errorStr = error != null ? ' | error: $error' : '';
      final entry = '[$timestamp] [$tag] $message$errorStr$stackStr\n';

      await logFile.writeAsString(entry, mode: FileMode.append);

      // Also print to console in debug mode
      debugPrint(entry);
    } catch (_) {
      // Silent fail — logger nunca debe romper la app
    }
  }
}
