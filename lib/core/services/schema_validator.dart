import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:json_schema/json_schema.dart';
import 'package:flutter/foundation.dart';

/// Servicio para validar contratos de datos contra esquemas JSON en tiempo real
class SchemaValidator {
  static final Map<String, JsonSchema> _cache = {};

  /// Valida un objeto [data] contra el esquema [schemaName].
  /// [schemaName] debe coincidir con el nombre de archivo en lib/core/schemas/ (sin .json).
  static Future<void> validate(
    String schemaName,
    Map<String, dynamic> data,
  ) async {
    try {
      final JsonSchema schema = await _getSchema(schemaName);
      final validationResult = schema.validate(data);

      if (!validationResult.isValid) {
        debugPrint('❌ [SchemaValidator] Error de contrato en $schemaName');
        for (var error in validationResult.errors) {
          debugPrint('   - ${error.message} en path: ${error.instancePath}');
        }
        throw Exception(
          'El contrato "$schemaName" ha sido violado. Errores: ${validationResult.errors.join(", ")}',
        );
      }
      debugPrint(
        '✅ [SchemaValidator] Contrato "$schemaName" validado correctamente',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Fallo catastrófico al validar esquema $schemaName: $e');
    }
  }

  static Future<JsonSchema> _getSchema(String schemaName) async {
    if (_cache.containsKey(schemaName)) {
      return _cache[schemaName]!;
    }

    try {
      // Intentamos cargar desde lib/core/schemas/ que es donde están actualmente
      // NOTA: Para producción, estos deberían estar en la carpeta 'assets' y definidos en pubspec.yaml
      final String schemaString = await rootBundle.loadString(
        'lib/core/schemas/$schemaName.json',
      );
      final schema = JsonSchema.create(jsonDecode(schemaString));
      _cache[schemaName] = schema;
      return schema;
    } catch (e) {
      throw Exception('No se pudo cargar el esquema $schemaName: $e');
    }
  }
}
