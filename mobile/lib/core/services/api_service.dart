import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // ⚠ IMPORTANT:
  // Web (Chrome): talks to backend on localhost:5000
  // Android emulator: use 10.0.2.2:5000 to reach host machine
  // Real device: replace with your computer's local IP:5000
  static String get baseUrl => kIsWeb ? 'http://localhost:5001' : 'http://10.0.2.2:5001';

  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ok'] == true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
