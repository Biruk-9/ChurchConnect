import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

class ManageAnnouncements extends StatefulWidget {
	const ManageAnnouncements({super.key});

	@override
	State<ManageAnnouncements> createState() => _ManageAnnouncementsState();
}

class _ManageAnnouncementsState extends State<ManageAnnouncements> {
	final _formKey = GlobalKey<FormState>();
	final _titleCtrl = TextEditingController();
	final _contentCtrl = TextEditingController();

	Uint8List? _imageBytes;
	String? _imageName;

	bool _loadingList = false;
	bool _saving = false;
	String? _error;
	String? _editingId;
	List<Map<String, dynamic>> _items = [];

	@override
	void initState() {
		super.initState();
		_load();
	}

	@override
	void dispose() {
		_titleCtrl.dispose();
		_contentCtrl.dispose();
		super.dispose();
	}

	Future<void> _load() async {
		setState(() {
			_loadingList = true;
			_error = null;
		});
		try {
			final data = await AdminService.fetchAnnouncements();
			if (!mounted) return;
			setState(() => _items = data);
		} catch (e) {
			if (!mounted) return;
			setState(() => _error = e.toString());
		} finally {
			if (mounted) setState(() => _loadingList = false);
		}
	}

	void _resetForm() {
		_formKey.currentState?.reset();
		setState(() {
			_editingId = null;
			_titleCtrl.clear();
			_contentCtrl.clear();
			_imageBytes = null;
			_imageName = null;
			_error = null;
		});
	}

	void _startEdit(Map<String, dynamic> item) {
		setState(() {
			_editingId = item['_id']?.toString();
			_titleCtrl.text = item['title']?.toString() ?? '';
			_contentCtrl.text = item['content']?.toString() ?? '';
			_imageBytes = null;
			_imageName = null;
			_error = null;
		});
	}

	Future<void> _pickImage() async {
		final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
		if (result != null && result.files.single.bytes != null) {
			setState(() {
				_imageBytes = result.files.single.bytes;
				_imageName = result.files.single.name;
			});
		}
	}

	String _imageSummary() {
		if (_imageName != null) return 'Selected: $_imageName';
		return _editingId == null ? 'No image selected (required)' : 'Keep existing image';
	}

	Future<void> _save() async {
		final valid = _formKey.currentState?.validate() ?? false;
		if (!valid) return;
		if (_editingId == null && _imageBytes == null) {
			setState(() => _error = 'Please choose an image to upload');
			return;
		}
		setState(() {
			_saving = true;
			_error = null;
		});
		final wasEditing = _editingId != null;
		try {
			if (wasEditing) {
				await AdminService.updateAnnouncement(
					id: _editingId!,
					title: _titleCtrl.text.trim(),
					content: _contentCtrl.text.trim(),
					imageBytes: _imageBytes,
					filename: _imageName,
				);
			} else {
				await AdminService.createAnnouncement(
					title: _titleCtrl.text.trim(),
					content: _contentCtrl.text.trim(),
					imageBytes: _imageBytes!,
					filename: _imageName ?? 'announcement.jpg',
				);
			}
			if (!mounted) return;
			_resetForm();
			await _load();
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(wasEditing ? 'Announcement updated' : 'Announcement created')),
			);
		} catch (e) {
			if (!mounted) return;
			setState(() => _error = e.toString());
		} finally {
			if (mounted) setState(() => _saving = false);
		}
	}

	Future<void> _delete(String id) async {
		setState(() {
			_saving = true;
			_error = null;
		});
		try {
			await AdminService.deleteAnnouncement(id);
			await _load();
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement deleted')));
			}
		} catch (e) {
			if (!mounted) return;
			setState(() => _error = e.toString());
		} finally {
			if (mounted) setState(() => _saving = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Announcements Management')),
			body: RefreshIndicator(
				onRefresh: _load,
				child: SingleChildScrollView(
					physics: const AlwaysScrollableScrollPhysics(),
					padding: const EdgeInsets.all(16),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Form(
								key: _formKey,
								child: Column(
									children: [
										TextFormField(
											controller: _titleCtrl,
											decoration: const InputDecoration(labelText: 'Title'),
											validator: (v) => (v == null || v.trim().isEmpty) ? 'Title required' : null,
										),
										const SizedBox(height: 8),
										TextFormField(
											controller: _contentCtrl,
											maxLines: 4,
											decoration: const InputDecoration(labelText: 'Content'),
											validator: (v) => (v == null || v.trim().isEmpty) ? 'Content required' : null,
										),
										const SizedBox(height: 8),
										Row(
											children: [
												Expanded(child: Text(_imageSummary())),
												TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.upload_file), label: const Text('Pick image')),
											],
										),
										const SizedBox(height: 12),
										if (_error != null) ...[
											ErrorMessage(message: _error!),
											const SizedBox(height: 8),
										],
										Row(
											children: [
												Expanded(
													child: CustomButton(
														label: _editingId == null ? 'Create Announcement' : 'Update Announcement',
														loading: _saving,
														onPressed: _save,
													),
												),
												const SizedBox(width: 12),
												TextButton(onPressed: _resetForm, child: const Text('Reset')),
											],
										),
									],
								),
							),
							const SizedBox(height: 16),
							if (_loadingList) ...[
								const LoadingIndicator(message: 'Loading announcements...'),
							] else ...[
								const Divider(),
								const Text('Existing announcements', style: TextStyle(fontWeight: FontWeight.w600)),
								const SizedBox(height: 8),
								if (_items.isEmpty)
									const Text('No announcements yet', style: TextStyle(color: Colors.grey))
								else
									ListView.builder(
										shrinkWrap: true,
										physics: const NeverScrollableScrollPhysics(),
										itemCount: _items.length,
										itemBuilder: (context, index) {
											final item = _items[index];
											final id = item['_id']?.toString() ?? '';
											final title = item['title']?.toString() ?? 'Untitled';
											return ListTile(
												contentPadding: EdgeInsets.zero,
												title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
												subtitle: Text(item['content']?.toString() ?? ''),
												trailing: Wrap(
													spacing: 4,
													children: [
														IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _startEdit(item)),
														IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _saving ? null : () => _delete(id)),
												],
											),
											);
										},
									),
							],
						],
					),
				),
			),
		);
	}
}
