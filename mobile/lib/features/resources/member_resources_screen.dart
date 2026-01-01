import 'package:flutter/material.dart';
import '../../core/config/app_routes.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'resource_service.dart';

class MemberResourcesScreen extends StatefulWidget {
	const MemberResourcesScreen({super.key});

	@override
	State<MemberResourcesScreen> createState() => _MemberResourcesScreenState();
}

class _MemberResourcesScreenState extends State<MemberResourcesScreen> {
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
			final data = await ResourceService.fetchMember();
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
			appBar: AppBar(title: const Text('Member Resources')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: _buildBody(),
			),
		);
	}

	Widget _buildBody() {
		if (_loading) return const LoadingIndicator(message: 'Loading resources...');
		if (_error != null) {
			final msg = _error!;
			if (msg.contains('Authentication required') || msg.contains('Not authenticated')) {
				return Center(
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							const Text('Please log in to view member resources'),
							const SizedBox(height: 12),
							OutlinedButton(
								onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
								child: const Text('Go to Login'),
							),
						],
					),
				);
			}
			if (msg.contains('Members only')) {
				return const Center(child: Text('This content is available to members only'));
			}
			return ErrorMessage(message: msg, onRetry: _load);
		}
		if (_items.isEmpty) return const Center(child: Text('No member resources available'));

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
