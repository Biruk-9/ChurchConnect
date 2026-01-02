import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../../features/bible_verse/verse_model.dart';

class AdminService {
  static Future<String> _requireToken() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw AdminAuthException('Authentication required');
    }
    return token;
  }

  static Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  static Future<Map<String, dynamic>> fetchSummary() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw AdminAuthException('Authentication required');
    }
    final resp = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/dashboard/summary'),
          headers: _authHeaders(token),
        )
        .timeout(AppConstants.networkTimeout);
    return _decode(resp);
  }

  static Future<Map<String, dynamic>> fetchRecent() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw AdminAuthException('Authentication required');
    }
    final resp = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/dashboard/recent'),
          headers: _authHeaders(token),
        )
        .timeout(AppConstants.networkTimeout);
    return _decode(resp);
  }

  // Announcements
  static Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    final resp = await ApiService.get('/api/public/announcements');
    return _asList(resp);
  }

  static Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String content,
    Uint8List? imageBytes,
    String? filename,
  }) async {
    return _multipartUpload(
      path: '${ApiConfig.adminBasePath}/announcements',
      method: 'POST',
      fields: {'title': title, 'content': content},
      fileField: 'image',
      fileBytes: imageBytes,
      filename: filename,
    );
  }

  static Future<Map<String, dynamic>> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    Uint8List? imageBytes,
    String? filename,
  }) async {
    return _multipartUpload(
      path: '${ApiConfig.adminBasePath}/announcements/$id',
      method: 'PUT',
      fields: {'title': title, 'content': content},
      fileField: 'image',
      fileBytes: imageBytes,
      filename: filename,
    );
  }

  static Future<void> deleteAnnouncement(String id) async {
    final token = await _requireToken();
    final resp = await http
      .delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/announcements/$id'),
        headers: _authHeaders(token),
      )
      .timeout(AppConstants.networkTimeout);
    _decode(resp);
  }

  // Verses of the Day
  static Future<List<Verse>> fetchVerses() async {
    final token = await _requireToken();
    final resp = await http
      .get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/verses'),
        headers: _authHeaders(token),
      )
      .timeout(AppConstants.networkTimeout);
    final list = _asList(_decode(resp));
    return list.map((e) => Verse.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> createVerse({
    required String date,
    required String ref,
    required String text,
  }) async {
    final token = await _requireToken();
    final resp = await http
      .post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/verses'),
        headers: _authHeaders(token),
        body: jsonEncode({'date': date, 'ref': ref, 'text': text}),
      )
      .timeout(AppConstants.networkTimeout);
    return _decode(resp);
  }

  static Future<Map<String, dynamic>> updateVerse({
    required String id,
    String? date,
    String? ref,
    String? text,
  }) async {
    final token = await _requireToken();
    final resp = await http
      .put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/verses/$id'),
        headers: _authHeaders(token),
        body: jsonEncode({
          if (date != null) 'date': date,
          if (ref != null) 'ref': ref,
          if (text != null) 'text': text,
        }),
      )
      .timeout(AppConstants.networkTimeout);
    return _decode(resp);
  }

  static Future<void> deleteVerse(String id) async {
    final token = await _requireToken();
    final resp = await http
      .delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/verses/$id'),
        headers: _authHeaders(token),
      )
      .timeout(AppConstants.networkTimeout);
    _decode(resp);
  }

  // Events
  static Future<List<Map<String, dynamic>>> fetchEvents() async {
    final resp = await ApiService.get('/api/public/events');
    return _asList(resp);
  }

  static Future<Map<String, dynamic>> createEvent({
    required String title,
    required String date,
    required String time,
    String? description,
    String? location,
  }) async {
    final token = await _requireToken();
    final resp = await http
      .post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/events'),
        headers: _authHeaders(token),
        body: jsonEncode({'title': title, 'description': description, 'date': date, 'time': time, 'location': location}),
      )
      .timeout(AppConstants.networkTimeout);
    return _decode(resp);
  }

  static Future<Map<String, dynamic>> updateEvent({
    required String id,
    required String title,
    required String date,
    required String time,
    String? description,
    String? location,
  }) async {
    final token = await _requireToken();
    final resp = await http
      .put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/events/$id'),
        headers: _authHeaders(token),
        body: jsonEncode({'title': title, 'description': description, 'date': date, 'time': time, 'location': location}),
      )
      .timeout(AppConstants.networkTimeout);
    return _decode(resp);
  }

  static Future<void> deleteEvent(String id) async {
    final token = await _requireToken();
    final resp = await http
      .delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/events/$id'),
        headers: _authHeaders(token),
      )
      .timeout(AppConstants.networkTimeout);
    _decode(resp);
  }

  // Resources (multipart friendly)
  static Future<List<Map<String, dynamic>>> fetchPublicResources() async {
    final resp = await ApiService.get('/api/public/resources');
    return _asList(resp);
  }

  static Future<List<Map<String, dynamic>>> fetchMemberResources() async {
    final token = await _requireToken();
    final resp = await http
      .get(
        Uri.parse('${ApiConfig.baseUrl}/api/member/resources'),
        headers: _authHeaders(token),
      )
      .timeout(AppConstants.networkTimeout);
    return _asList(_decode(resp));
  }

  static Future<Map<String, dynamic>> createResource({
    required String title,
    String? description,
    String? category,
    required String accessLevel,
    required String mediaType,
    String? fileUrl,
    Uint8List? fileBytes,
    String? filename,
  }) async {
    return _resourceMultipart(
      path: '${ApiConfig.adminBasePath}/resources',
      method: 'POST',
      fields: {
        'title': title,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        'accessLevel': accessLevel,
        'mediaType': mediaType,
        if (fileUrl != null) 'fileUrl': fileUrl,
      },
      fileBytes: fileBytes,
      filename: filename,
    );
  }

  static Future<Map<String, dynamic>> updateResource({
    required String id,
    required Map<String, String> fields,
    Uint8List? fileBytes,
    String? filename,
  }) async {
    return _resourceMultipart(
      path: '${ApiConfig.adminBasePath}/resources/$id',
      method: 'PUT',
      fields: fields,
      fileBytes: fileBytes,
      filename: filename,
    );
  }

  static Future<void> deleteResource(String id) async {
    final token = await _requireToken();
    final resp = await http
      .delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/resources/$id'),
        headers: _authHeaders(token),
      )
      .timeout(AppConstants.networkTimeout);
    _decode(resp);
  }

  static Future<Map<String, dynamic>> _resourceMultipart({
    required String path,
    required String method,
    required Map<String, String> fields,
    Uint8List? fileBytes,
    String? filename,
  }) async {
    return _multipartUpload(
      path: path,
      method: method,
      fields: fields,
      fileField: 'file',
      fileBytes: fileBytes,
      filename: filename,
    );
  }

  static Future<Map<String, dynamic>> _multipartUpload({
    required String path,
    required String method,
    required Map<String, String> fields,
    required String fileField,
    Uint8List? fileBytes,
    String? filename,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = http.MultipartRequest(method, uri);
    request.headers['Authorization'] = 'Bearer $token';
    fields.forEach((key, value) => request.fields[key] = value);
    if (fileBytes != null && filename != null && filename.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: filename));
    }
    final streamed = await request.send().timeout(AppConstants.networkTimeout);
    final resp = await http.Response.fromStream(streamed);
    return _decode(resp);
  }

  // Users (members)
  static Future<List<Map<String, dynamic>>> listUsers({bool includeInactive = true}) async {
    final token = await _requireToken();
    final query = includeInactive ? '?includeInactive=true' : '';
    final resp = await http
      .get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/users$query'),
        headers: _authHeaders(token),
      )
      .timeout(AppConstants.networkTimeout);
    return _asList(_decode(resp));
  }

  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    bool isActive = true,
    String role = 'member',
  }) async {
    final token = await _requireToken();
    final resp = await http
      .post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/users'),
        headers: _authHeaders(token),
        body: jsonEncode({'name': name, 'email': email, 'password': password, 'isActive': isActive, 'role': role}),
      )
      .timeout(AppConstants.networkTimeout);
    return _decode(resp);
  }

  static Future<Map<String, dynamic>> updateUser({
    required String id,
    String? name,
    String? email,
    String? password,
    bool? isActive,
    String? role,
  }) async {
    final token = await _requireToken();
    final resp = await http
      .put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/users/$id'),
        headers: _authHeaders(token),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
          if (isActive != null) 'isActive': isActive,
          if (role != null) 'role': role,
        }),
      )
      .timeout(AppConstants.networkTimeout);
    return _decode(resp);
  }

  static Future<void> deleteUser(String id, {bool hard = false}) async {
    final token = await _requireToken();
    final resp = await http
      .delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminBasePath}/users/$id${hard ? '?hard=true' : ''}'),
        headers: _authHeaders(token),
      )
      .timeout(AppConstants.networkTimeout);
    _decode(resp);
  }

  static Map<String, dynamic> _decode(http.Response resp) {
    final status = resp.statusCode;
    final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    if (status >= 200 && status < 300) {
      if (body is Map<String, dynamic>) return body['data'] is Map ? body['data'] : body;
      return {'data': body};
    }
    if (status == 401) throw AdminAuthException('Authentication required');
    if (status == 403) throw AdminForbiddenException('Admin access required');
    throw AdminApiException(status, body['message']?.toString() ?? 'Request failed');
  }

  static List<Map<String, dynamic>> _asList(Map<String, dynamic> resp) {
    final data = resp['data'] ?? resp['items'] ?? resp['announcements'] ?? resp['events'] ?? resp['resources'] ?? resp['users'] ?? resp;
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }
}

class AdminApiException implements Exception {
  final int status;
  final String message;
  AdminApiException(this.status, this.message);
  @override
  String toString() => 'AdminApiException($status): $message';
}

class AdminAuthException extends AdminApiException {
  AdminAuthException(String message) : super(401, message);
}

class AdminForbiddenException extends AdminApiException {
  AdminForbiddenException(String message) : super(403, message);
}
