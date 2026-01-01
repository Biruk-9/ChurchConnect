import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

class AnnouncementManager extends StatefulWidget {
  const AnnouncementManager({super.key});

  @override
  State<AnnouncementManager> createState() => _AnnouncementManagerState();
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _AnnouncementManagerState extends State<AnnouncementManager> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;

  bool _loading = false;
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
      _loading = true;
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
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startEdit(Map<String, dynamic> item) {
    setState(() {
      _editingId = item['_id']?.toString();
      _titleCtrl.text = item['title']?.toString() ?? '';
      _contentCtrl.text = item['content']?.toString() ?? '';
      _imageBytes = null;
      _imageName = null;
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _contentCtrl.clear();
    _imageBytes = null;
    _imageName = null;
    _editingId = null;
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
    return _editingId == null ? 'No image selected (optional)' : 'Keep existing image';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final wasEditing = _editingId != null;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_editingId == null) {
        await AdminService.createAnnouncement(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          imageBytes: _imageBytes,
          filename: _imageName,
        );
      } else {
        await AdminService.updateAnnouncement(
          id: _editingId!,
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          imageBytes: _imageBytes,
          filename: _imageName,
        );
      }
      if (!mounted) return;
      _resetForm();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(wasEditing ? 'Announcement updated' : 'Announcement created')),
        );
      }
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
    return _CardShell(
      title: 'Announcements Management',
      subtitle: 'Create, edit, delete announcements (admin only).',
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
                  maxLines: 3,
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
          const SizedBox(height: 12),
          if (_loading) const LoadingIndicator(message: 'Loading announcements...')
          else ...[
            const Divider(),
            const Align(alignment: Alignment.centerLeft, child: Text('Existing Announcements', style: TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(height: 6),
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
                  final subtitle = item['content']?.toString() ?? '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(subtitle.isNotEmpty ? subtitle : 'No content'),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () => _startEdit(item)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), tooltip: 'Delete', onPressed: _saving ? null : () => _delete(id)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
