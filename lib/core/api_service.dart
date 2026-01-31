import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../features/onboarding/data/user_profile.dart';

class ApiService {
  // En el emulador de Android, localhost es 10.0.2.2
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static String mapIdentityToProfileId(UserIdentity identity) {
    switch (identity) {
      case UserIdentity.leader:
        return 'authority_builder';
      case UserIdentity.influencer:
        return 'emotional_connector';
      case UserIdentity.seller:
        return 'conversion_driver';
      default:
        return 'authority_builder';
    }
  }

  static Future<Map<String, dynamic>> callPrompt({
    required String category,
    required String name,
    required Map<String, dynamic> payload,
  }) async {
    final url = Uri.parse('$baseUrl/prompt/$category/$name');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al llamar al backend: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService Error: $e');
      rethrow;
    }
  }
}
