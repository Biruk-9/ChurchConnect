import '../../core/services/api_service.dart';
import 'verse_model.dart';

class VerseService {
	static const String _path = '/api/public/verse';

	/// Fetch verse of the day (public).
	static Future<Verse> fetchVerse() async {
		final resp = await ApiService.get(_path);
		final data = resp['data'] ?? resp;
		return Verse.fromJson(data as Map<String, dynamic>);
	}
}
