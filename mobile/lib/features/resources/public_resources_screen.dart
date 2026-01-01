import 'package:flutter/material.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'resource_service.dart';

class PublicResourcesScreen extends StatefulWidget {
	const PublicResourcesScreen({super.key});

	@override
	State<PublicResourcesScreen> createState() => _PublicResourcesScreenState();
}

class _PublicResourcesScreenState extends State<PublicResourcesScreen> {
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
			final data = await ResourceService.fetchPublic();
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
			appBar: AppBar(title: const Text('Resources')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: _buildBody(),
			),
		);
	}

	Widget _buildBody() {
		if (_loading) return const LoadingIndicator(message: 'Loading resources...');
		if (_error != null) return ErrorMessage(message: _error!, onRetry: _load);
		if (_items.isEmpty) return const Center(child: Text('No resources available'));

		return ListView.separated(
			itemCount: _items.length,
			separatorBuilder: (_, index) => const Divider(height: 16),
			itemBuilder: (_, index) {
				final item = _items[index];
				final title = item['title']?.toString() ?? 'Untitled';
				final desc = item['description']?.toString() ?? '';
				final url = item['url']?.toString();
				return ListTile(
					title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
					subtitle: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							if (desc.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(desc)),
							if (url != null && url.isNotEmpty)
								Padding(padding: const EdgeInsets.only(top: 4), child: Text(url, style: const TextStyle(fontSize: 12, color: Colors.blue))),
						],
					),
					onTap: url != null && url.isNotEmpty ? () => _openUrl(context, url) : null,
				);
			},
		);
	}

	void _openUrl(BuildContext context, String url) {
		// TODO: integrate url_launcher; for now just show a snackbar.
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text('Open: $url')),
		);
	}
}
