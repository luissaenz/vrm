import '../models/input_schema.dart';
import '../models/script_bundle.dart';

/// Fase 2: Interfaz de Procesamiento de Guion
/// Transforma la idea en un guion micro-fragmentado
abstract class IScriptProcessor {
  /// Identificador único del plugin
  String get pluginId;

  /// Procesa la idea y genera el guion fragmentado
  /// @param input - InputSchema de la fase de ingesta
  /// @param configuration - Configuración específica del procesamiento (template, tone, etc.)
  /// @returns ScriptBundle micro-fragmentado
  Future<ScriptBundle> process(
    InputSchema input,
    Map<String, dynamic> configuration,
  );
}
