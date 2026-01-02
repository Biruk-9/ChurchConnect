import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
	static const String _tokenKey = 'auth_token';
	static const String _roleKey = 'auth_role';
	static const String _nameKey = 'auth_name';

	static Future<void> saveSession({required String token, String? role, String? name}) async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.setString(_tokenKey, token);
		if (role != null && role.isNotEmpty) {
			await prefs.setString(_roleKey, role);
		} else {
			await prefs.remove(_roleKey);
		}
		if (name != null && name.isNotEmpty) {
			await prefs.setString(_nameKey, name);
		} else {
			await prefs.remove(_nameKey);
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

	static Future<String?> getUserName() async {
		final prefs = await SharedPreferences.getInstance();
		return prefs.getString(_nameKey);
	}

	static Future<void> clearSession() async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.remove(_tokenKey);
		await prefs.remove(_roleKey);
		await prefs.remove(_nameKey);
	}
}
