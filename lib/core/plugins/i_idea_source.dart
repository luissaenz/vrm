import '../models/input_schema.dart';

/// Fase 1: Interfaz de Ingesta
/// Cualquier fuente de ideas (Manual, RSS, API, Tendencias) debe implementar este contrato
abstract class IIdeaSource {
  /// Identificador único del plugin
  String get pluginId;

  /// Obtiene una idea desde la fuente configurada
  /// @param params - Parámetros específicos del plugin
  /// @returns InputSchema normalizado
  Future<InputSchema> fetchIdea(Map<String, dynamic> params);

  /// Valida que los parámetros sean correctos para este plugin
  /// @param params - Parámetros a validar
  /// @returns true si son válidos
  bool validateParams(Map<String, dynamic> params);
}
