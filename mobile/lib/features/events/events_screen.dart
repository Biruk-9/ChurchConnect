import 'package:flutter/material.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'events_service.dart';

class EventsScreen extends StatefulWidget {
	const EventsScreen({super.key});

	@override
	State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
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
			final data = await EventsService.fetchUpcoming();
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
			appBar: AppBar(title: const Text('Events')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: _buildBody(),
			),
		);
	}

	Widget _buildBody() {
		if (_loading) return const LoadingIndicator(message: 'Loading events...');
		if (_error != null) return ErrorMessage(message: _error!, onRetry: _load);
		if (_items.isEmpty) return const Center(child: Text('No events')); 

		return ListView.separated(
			itemCount: _items.length,
			separatorBuilder: (_, index) => const Divider(height: 16),
			itemBuilder: (_, index) {
				final item = _items[index];
				final title = item['title']?.toString() ?? 'Untitled';
				final desc = item['description']?.toString() ?? '';
				final date = item['date']?.toString() ?? item['startDate']?.toString();
				final location = item['location']?.toString();
				return ListTile(
					title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
					subtitle: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							if (desc.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(desc)),
							if (location != null && location.isNotEmpty)
								Padding(padding: const EdgeInsets.only(top: 4), child: Text(location)),
							if (date != null && date.isNotEmpty)
								Padding(padding: const EdgeInsets.only(top: 4), child: Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey))),
						],
					),
				);
			},
		);
	}
}
