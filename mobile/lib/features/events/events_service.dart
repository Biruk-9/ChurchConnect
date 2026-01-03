import '../../core/services/api_service.dart';

class EventsService {
	static const String _publicPath = '/api/public/events';

	/// Fetch all events (server returns full list, client splits upcoming/past).
	static Future<List<Map<String, dynamic>>> fetchAll() async {
		final resp = await ApiService.get(_publicPath);
		final data = resp['data'] ?? resp['events'] ?? resp['items'] ?? resp;
		if (data is List) {
			return data.cast<Map<String, dynamic>>();
		}
		return [];
	}
}
