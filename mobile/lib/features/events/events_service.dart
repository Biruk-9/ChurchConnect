import '../../core/services/api_service.dart';

class EventsService {
	static const String _publicPath = '/api/public/events';

	/// Fetch upcoming events.
	static Future<List<Map<String, dynamic>>> fetchUpcoming() async {
		final resp = await ApiService.get(_publicPath);
		final data = resp['data'] ?? resp['events'] ?? resp['items'] ?? resp;
		if (data is List) {
			return data.cast<Map<String, dynamic>>();
		}
		return [];
	}
}
