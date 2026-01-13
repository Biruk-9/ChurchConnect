import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API endpoints and host resolution.
class ApiConfig {
	// Default port for local dev (update to match backend). Server uses 5000 by default.
	static const int _defaultPort = 5001;

	// Allow overriding host/port at build/run time: flutter run --dart-define=API_HOST=192.168.1.10 --dart-define=API_PORT=5001
	static const String _envHost = String.fromEnvironment('API_HOST', defaultValue: '');
	static const String _envPort = String.fromEnvironment('API_PORT', defaultValue: '');

	// Base host per platform. Update these if your backend host changes.
	static String get _host {
		if (_envHost.isNotEmpty) return _envHost;
		if (kIsWeb) return 'localhost';
		// Android emulator reaches host via 10.0.2.2; real devices need your LAN IP via API_HOST
		return '10.0.2.2';
	}

	static int get _port {
		if (_envPort.isNotEmpty) {
			final parsed = int.tryParse(_envPort);
			if (parsed != null) return parsed;
		}
		return _defaultPort;
	}

	/// Full base URL (protocol + host + port) for REST calls.
	static String get baseUrl => 'http://$_host:$_port';

	// Paths (relative) used with ApiService builders
	static const String healthPath = '/health';
	static const String loginPath = '/api/auth/login';
	static const String adminBasePath = '/api/_admin_9b27';

}
