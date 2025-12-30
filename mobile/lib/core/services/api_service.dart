import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/constants.dart';

class ApiService {
  static final http.Client _client = http.Client();

  static Map<String, String> _jsonHeaders([Map<String, String>? extra]) {
    return {
      'Content-Type': 'application/json',
      ...?extra,
    };
  }

  static Uri _buildUri(String path) {
    if (path.startsWith('http')) return Uri.parse(path);
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.baseUrl}$normalized');
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final resp = await _client
        .get(_buildUri(path), headers: _jsonHeaders(headers))
        .timeout(AppConstants.networkTimeout);
    return _decode(resp);
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final resp = await _client
        .post(
          _buildUri(path),
          headers: _jsonHeaders(headers),
          body: jsonEncode(body ?? {}),
        )
        .timeout(AppConstants.networkTimeout);
    return _decode(resp);
  }

  static Future<bool> healthCheck() async {
    try {
      final resp = await _client
          .get(_buildUri(ApiConfig.healthPath), headers: _jsonHeaders())
          .timeout(AppConstants.networkTimeout);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['ok'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> _decode(http.Response resp) {
    final status = resp.statusCode;
    final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    if (status >= 200 && status < 300) {
      if (body is Map<String, dynamic>) return body;
      return {'data': body};
    }
    throw ApiException(statusCode: status, message: body['message']?.toString() ?? 'Request failed');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
