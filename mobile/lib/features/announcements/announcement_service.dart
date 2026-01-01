import '../../core/services/api_service.dart';
import 'announcement_model.dart';

class AnnouncementService {
	static const String _publicPath = '/api/public/announcements';

	/// Fetch public announcements list.
	static Future<List<Announcement>> fetchPublic() async {
		final resp = await ApiService.get(_publicPath);
		final data = resp['data'] ?? resp['announcements'] ?? resp['items'] ?? resp;
		if (data is List) {
			return data.map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
		}
		return [];
	}
}
