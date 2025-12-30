import 'package:flutter/material.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'verse_service.dart';

class VerseScreen extends StatefulWidget {
	const VerseScreen({super.key});

	@override
	State<VerseScreen> createState() => _VerseScreenState();
}

class _VerseScreenState extends State<VerseScreen> {
	bool _loading = true;
	String? _error;
	Map<String, dynamic>? _verse;

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
			final data = await VerseService.fetchVerse();
			setState(() {
				_verse = data;
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
			appBar: AppBar(title: const Text('Verse of the Day')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: _buildBody(),
			),
		);
	}

	Widget _buildBody() {
		if (_loading) return const LoadingIndicator(message: 'Loading verse...');
		if (_error != null) return ErrorMessage(message: _error!, onRetry: _load);
		if (_verse == null) return const Center(child: Text('No verse available'));

		final ref = _verse?['ref']?.toString() ?? 'Verse';
		final text = _verse?['text']?.toString() ?? '';

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(ref, style: Theme.of(context).textTheme.titleLarge),
				const SizedBox(height: 12),
				Text(text, style: Theme.of(context).textTheme.bodyLarge),
			],
		);
	}
}
