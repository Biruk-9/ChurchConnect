import '../config/api_config.dart';
import '../utils/validators.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
	static Future<String> login({required String email, required String password}) async {
		// basic client-side validation
		final emailError = emailValidator(email);
		if (emailError != null) throw AuthException(emailError);
		final pwError = minLength(password, 6, fieldName: 'Password');
		if (pwError != null) throw AuthException(pwError);

		final resp = await ApiService.post(ApiConfig.loginPath, body: {
			'email': email.trim(),
			'password': password,
		});
		final data = (resp['data'] is Map) ? resp['data'] as Map : resp;
		final token = data['token']?.toString();
		final role = data['role']?.toString();
		if (token == null || token.isEmpty) {
			throw AuthException('Missing token from server');
		}

		await StorageService.saveSession(token: token, role: role);
		return token;
	}

	static Future<void> logout() async {
		await StorageService.clearSession();
	}

	static Future<bool> isLoggedIn() async {
		final token = await StorageService.getToken();
		return token != null && token.isNotEmpty;
	}

	static Future<String?> getToken() => StorageService.getToken();

	static Future<String?> getRole() => StorageService.getRole();
}

class AuthException implements Exception {
	final String message;
	AuthException(this.message);

	@override
	String toString() => 'AuthException: $message';
}
