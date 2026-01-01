import '../../core/services/api_service.dart';

class VerseService {
	static const String _path = '/api/public/verse';

	/// Fetch verse of the day (public).
	static Future<Map<String, dynamic>> fetchVerse() async {
		final resp = await ApiService.get(_path);
		final data = resp['data'] ?? resp;
		return {
			'ref': data['ref']?.toString(),
			'text': data['text']?.toString(),
		};
	}
}
