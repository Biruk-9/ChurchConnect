import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
	static const String _tokenKey = 'auth_token';
	static const String _roleKey = 'auth_role';

	static Future<void> saveSession({required String token, String? role}) async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.setString(_tokenKey, token);
		if (role != null && role.isNotEmpty) {
			await prefs.setString(_roleKey, role);
		} else {
			await prefs.remove(_roleKey);
		}
	}

	static Future<String?> getToken() async {
		final prefs = await SharedPreferences.getInstance();
		return prefs.getString(_tokenKey);
	}

	static Future<String?> getRole() async {
		final prefs = await SharedPreferences.getInstance();
		return prefs.getString(_roleKey);
	}

	static Future<void> clearSession() async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.remove(_tokenKey);
		await prefs.remove(_roleKey);
	}
}
