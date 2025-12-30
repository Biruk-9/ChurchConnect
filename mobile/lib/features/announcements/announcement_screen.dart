import 'package:flutter/material.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'announcement_service.dart';

class AnnouncementScreen extends StatefulWidget {
	const AnnouncementScreen({super.key});

	@override
	State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
	bool _loading = true;
	String? _error;
	List<Map<String, dynamic>> _items = const [];

	@override
	void initState() {
		super.initState();
		_load();
	}

	Future<void> _load() async {
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			final data = await AnnouncementService.fetchPublic();
			setState(() {
				_items = data;
			});
		} catch (e) {
			setState(() {
				_error = e.toString();
			});
		} finally {
			setState(() {
				_loading = false;
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Announcements')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: _buildBody(),
			),
		);
	}

	Widget _buildBody() {
		if (_loading) return const LoadingIndicator(message: 'Loading announcements...');
		if (_error != null) return ErrorMessage(message: _error!, onRetry: _load);
		if (_items.isEmpty) return const Center(child: Text('No announcements')); 

		return ListView.separated(
			itemCount: _items.length,
			separatorBuilder: (_, __) => const Divider(height: 16),
			itemBuilder: (_, index) {
				final item = _items[index];
				final title = item['title']?.toString() ?? 'Untitled';
				final body = item['body']?.toString() ?? item['description']?.toString() ?? '';
				final date = item['date']?.toString() ?? item['createdAt']?.toString();
				return ListTile(
					title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
					subtitle: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							if (body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(body)),
							if (date != null && date.isNotEmpty)
								Padding(padding: const EdgeInsets.only(top: 4), child: Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey))),
						],
					),
				);
			},
		);
	}
}
