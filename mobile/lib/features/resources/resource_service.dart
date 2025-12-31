import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart' show ApiException;

class ResourceService {
	static const String _publicPath = '/api/public/resources';
	static const String _memberPath = '/api/member/resources';

	static Future<List<Map<String, dynamic>>> fetchPublic() async {
		final resp = await ApiService.get(_publicPath);
		final data = resp['data'] ?? resp['resources'] ?? resp['items'] ?? resp;
		if (data is List) return data.cast<Map<String, dynamic>>();
		return [];
	}

	static Future<List<Map<String, dynamic>>> fetchMember() async {
		final token = await AuthService.getToken();
		if (token == null || token.isEmpty) {
			throw ResourceException('Not authenticated');
		}
		try {
			final resp = await ApiService.get(
				_memberPath,
				headers: {'Authorization': 'Bearer $token'},
			);
			final data = resp['data'] ?? resp['resources'] ?? resp['items'] ?? resp;
			if (data is List) return data.cast<Map<String, dynamic>>();
			return [];
		} on ApiException catch (e) {
			if (e.statusCode == 401) throw ResourceAuthRequired('Authentication required');
			if (e.statusCode == 403) throw ResourceForbidden('Members only');
			rethrow;
		}
	}
}

class ResourceException implements Exception {
	final String message;
	ResourceException(this.message);
	@override
	String toString() => 'ResourceException: $message';
}

class ResourceAuthRequired extends ResourceException {
	ResourceAuthRequired(String message) : super(message);
}

class ResourceForbidden extends ResourceException {
	ResourceForbidden(String message) : super(message);
}
