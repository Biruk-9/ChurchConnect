import '../../core/services/api_service.dart';

class AnnouncementService {
	static const String _publicPath = '/api/public/announcements';

	/// Fetch public announcements list.
	static Future<List<Map<String, dynamic>>> fetchPublic() async {
		final resp = await ApiService.get(_publicPath);
		final data = resp['data'] ?? resp['announcements'] ?? resp['items'] ?? resp;
		if (data is List) {
			return data.cast<Map<String, dynamic>>();
		}
		return [];
	}
}
