import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API endpoints and host resolution.
class ApiConfig {
	// Default port for local dev (update to match backend). Server uses 5000 by default.
	static const int _defaultPort = 5001;

	// Base host per platform. Update these if your backend host changes.
	static String get _host {
		if (kIsWeb) return 'localhost';
		// Android emulator reaches host via 10.0.2.2
		return '10.0.2.2';
	}

	/// Full base URL (protocol + host + port) for REST calls.
	static String get baseUrl => 'http://$_host:$_defaultPort';

	// Paths (relative) used with ApiService builders
	static const String healthPath = '/health';
	static const String loginPath = '/api/auth/login';
	static const String adminBasePath = '/api/_admin_9b27';

}
