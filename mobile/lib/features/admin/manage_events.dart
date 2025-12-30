import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_message.dart';

class ManageEvents extends StatefulWidget {
	const ManageEvents({super.key});

	@override
	State<ManageEvents> createState() => _ManageEventsState();
}

class _ManageEventsState extends State<ManageEvents> {
	final _formKey = GlobalKey<FormState>();
	final _titleCtrl = TextEditingController();
	final _descCtrl = TextEditingController();
	final _dateCtrl = TextEditingController();
	bool _loading = false;
	String? _error;

	@override
	void dispose() {
		_titleCtrl.dispose();
		_descCtrl.dispose();
		_dateCtrl.dispose();
		super.dispose();
	}

	Future<void> _submit() async {
		if (!_formKey.currentState!.validate()) return;
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			// TODO: call admin API to create/update event
			await Future.delayed(const Duration(milliseconds: 400));
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event saved (placeholder)')));
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
			appBar: AppBar(title: const Text('Manage Events')),
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
								controller: _descCtrl,
								decoration: const InputDecoration(labelText: 'Description'),
								maxLines: 3,
								validator: (v) => (v == null || v.trim().isEmpty) ? 'Description required' : null,
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _dateCtrl,
								decoration: const InputDecoration(labelText: 'Date'),
								validator: (v) => (v == null || v.trim().isEmpty) ? 'Date required' : null,
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
