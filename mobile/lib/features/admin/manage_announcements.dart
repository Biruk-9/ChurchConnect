import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_message.dart';

class ManageAnnouncements extends StatefulWidget {
	const ManageAnnouncements({super.key});

	@override
	State<ManageAnnouncements> createState() => _ManageAnnouncementsState();
}

class _ManageAnnouncementsState extends State<ManageAnnouncements> {
	final _formKey = GlobalKey<FormState>();
	final _titleCtrl = TextEditingController();
	final _bodyCtrl = TextEditingController();
	bool _loading = false;
	String? _error;

	@override
	void dispose() {
		_titleCtrl.dispose();
		_bodyCtrl.dispose();
		super.dispose();
	}

	Future<void> _submit() async {
		if (!_formKey.currentState!.validate()) return;
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			// TODO: call admin API to create announcement
			await Future.delayed(const Duration(milliseconds: 400));
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement saved (placeholder)')));
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
			appBar: AppBar(title: const Text('Manage Announcements')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Form(
					key: _formKey,
					child: Column(
						children: [
							TextFormField(
								controller: _titleCtrl,
								decoration: const InputDecoration(labelText: 'Title'),
								validator: (v) => (v == null || v.trim().isEmpty) ? 'Title required' : null,
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _bodyCtrl,
								decoration: const InputDecoration(labelText: 'Body'),
								maxLines: 4,
								validator: (v) => (v == null || v.trim().isEmpty) ? 'Body required' : null,
							),
							const SizedBox(height: 16),
							if (_error != null) ...[
								ErrorMessage(message: _error!),
								const SizedBox(height: 8),
							],
							CustomButton(label: 'Save', loading: _loading, onPressed: _submit),
						],
					),
				),
			),
		);
	}
}
