import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

class ResourceManager extends StatefulWidget {
  const ResourceManager({super.key});

  @override
  State<ResourceManager> createState() => _ResourceManagerState();
}

class _PickerType {
  const _PickerType(this.type, {this.extensions});

  final FileType type;
  final List<String>? extensions;
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

class _ResourceManagerState extends State<ResourceManager> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _fileUrlCtrl = TextEditingController();

  Uint8List? _fileBytes;
  String? _filename;

  String _category = 'pdf';
  String _accessLevel = 'public';
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
    _descCtrl.dispose();
    _fileUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final public = await AdminService.fetchPublicResources();
      List<Map<String, dynamic>> members = [];
      try {
        members = await AdminService.fetchMemberResources();
      } catch (_) {
        members = [];
      }
      final combined = <String, Map<String, dynamic>>{};
      for (final item in [...public, ...members]) {
        final id = item['_id']?.toString() ?? item['id']?.toString();
        if (id != null) combined[id] = item;
      }
      if (!mounted) return;
      setState(() => _items = combined.values.toList());
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
      _descCtrl.text = item['description']?.toString() ?? '';
      _category = item['category']?.toString() ?? 'pdf';
      _fileUrlCtrl.text = item['fileUrl']?.toString() ?? '';
      _accessLevel = item['accessLevel']?.toString() ?? 'public';
      _fileBytes = null;
      _filename = null;
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _descCtrl.clear();
    _fileUrlCtrl.clear();
    _category = 'pdf';
    _accessLevel = 'public';
    _fileBytes = null;
    _filename = null;
    _editingId = null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_editingId == null && _fileBytes == null && _fileUrlCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Upload a file or enter a link');
      return;
    }
    final wasEditing = _editingId != null;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final fields = <String, String>{
        'title': _titleCtrl.text.trim(),
        'category': _category,
        'accessLevel': _accessLevel,
        'mediaType': _category,
      };
      if (_descCtrl.text.trim().isNotEmpty) fields['description'] = _descCtrl.text.trim();
      if (_fileUrlCtrl.text.trim().isNotEmpty) fields['fileUrl'] = _fileUrlCtrl.text.trim();

      if (_editingId == null) {
        await AdminService.createResource(
          title: fields['title']!,
          description: fields['description'],
          category: fields['category'],
          accessLevel: fields['accessLevel']!,
          mediaType: fields['mediaType']!,
          fileUrl: fields['fileUrl'],
          fileBytes: _fileBytes,
          filename: _filename,
        );
      } else {
        await AdminService.updateResource(id: _editingId!, fields: fields, fileBytes: _fileBytes, filename: _filename);
      }
      if (!mounted) return;
      _resetForm();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(wasEditing ? 'Resource updated' : 'Resource created')),
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
      await AdminService.deleteResource(id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resource deleted')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickFile() async {
    final type = _pickerTypeForCategory(_category);
    final result = await FilePicker.platform.pickFiles(type: type.type, allowedExtensions: type.extensions, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes;
        _filename = result.files.single.name;
      });
    }
  }

  _PickerType _pickerTypeForCategory(String category) {
    switch (category) {
      case 'audio':
        return _PickerType(FileType.audio);
      case 'video':
        return _PickerType(FileType.video);
      case 'pdf':
        return _PickerType(FileType.custom, extensions: const ['pdf']);
      default:
        return _PickerType(FileType.any);
    }
  }

  String _fileSummary() {
    if (_filename != null) return 'Selected: $_filename';
    return _editingId == null ? 'No file selected (optional if link provided)' : 'Keep existing file';
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Resource Management',
      subtitle: 'Upload, edit, delete resources. Choose access level (public or members-only).',
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
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    DropdownMenuItem(value: 'audio', child: Text('Audio')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? 'pdf'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _accessLevel,
                  decoration: const InputDecoration(labelText: 'Access'),
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                    DropdownMenuItem(value: 'members', child: Text('Members only')),
                  ],
                  onChanged: (v) => setState(() => _accessLevel = v ?? 'public'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Upload file'),
                            onPressed: _saving ? null : _pickFile,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _fileSummary(),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (_fileBytes != null || _filename != null)
                      IconButton(
                        tooltip: 'Clear file',
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                  _fileBytes = null;
                                  _filename = null;
                                }),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fileUrlCtrl,
                  decoration: const InputDecoration(labelText: 'File URL / Link'),
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
                        label: _editingId == null ? 'Create Resource' : 'Update Resource',
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
          if (_loading) const LoadingIndicator(message: 'Loading resources...')
          else ...[
            const Divider(),
            const Align(alignment: Alignment.centerLeft, child: Text('Existing Resources', style: TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(height: 6),
            if (_items.isEmpty)
              const Text('No resources yet', style: TextStyle(color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final id = item['_id']?.toString() ?? '';
                  final title = item['title']?.toString() ?? 'Untitled';
                  final access = item['accessLevel']?.toString() ?? 'public';
                  final category = item['category']?.toString() ?? '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Access: $access • Category: ${category.isNotEmpty ? category : 'n/a'}'),
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
    );
  }
}
