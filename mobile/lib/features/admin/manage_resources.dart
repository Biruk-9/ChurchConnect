import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

class ManageResources extends StatefulWidget {
  const ManageResources({super.key});

  @override
  State<ManageResources> createState() => _ManageResourcesState();
}

class _ManageResourcesState extends State<ManageResources> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  String _accessLevel = 'public';
  String _mediaType = 'pdf';
  bool _loadingList = false;
  bool _saving = false;
  String? _error;
  String? _editingId;
  Uint8List? _fileBytes;
  String? _fileName;
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
    _categoryCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loadingList = true;
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
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
      });
    }
  }

  void _startEdit(Map<String, dynamic> item) {
    setState(() {
      _editingId = item['_id']?.toString();
      _titleCtrl.text = item['title']?.toString() ?? '';
      _descCtrl.text = item['description']?.toString() ?? '';
      _categoryCtrl.text = item['category']?.toString() ?? '';
      _linkCtrl.text = item['fileUrl']?.toString() ?? '';
      _accessLevel = item['accessLevel']?.toString() ?? 'public';
      _mediaType = item['mediaType']?.toString() ?? 'pdf';
      _fileBytes = null;
      _fileName = null;
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _descCtrl.clear();
    _categoryCtrl.clear();
    _linkCtrl.clear();
    _accessLevel = 'public';
    _mediaType = 'pdf';
    _fileBytes = null;
    _fileName = null;
    _editingId = null;
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
        await AdminService.createResource(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
          accessLevel: _accessLevel,
          mediaType: _mediaType,
          fileUrl: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
          fileBytes: _linkCtrl.text.trim().isEmpty ? _fileBytes : null,
          filename: _linkCtrl.text.trim().isEmpty ? _fileName : null,
        );
      } else {
        final fields = <String, String>{
          'title': _titleCtrl.text.trim(),
          'accessLevel': _accessLevel,
          'mediaType': _mediaType,
        };
        if (_descCtrl.text.trim().isNotEmpty) fields['description'] = _descCtrl.text.trim();
        if (_categoryCtrl.text.trim().isNotEmpty) fields['category'] = _categoryCtrl.text.trim();
        if (_linkCtrl.text.trim().isNotEmpty) fields['fileUrl'] = _linkCtrl.text.trim();
        await AdminService.updateResource(
          id: _editingId!,
          fields: fields,
          fileBytes: _linkCtrl.text.trim().isEmpty ? _fileBytes : null,
          filename: _linkCtrl.text.trim().isEmpty ? _fileName : null,
        );
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

  String _fileSummary() {
    if (_fileName != null) return 'Selected: $_fileName';
    if (_linkCtrl.text.trim().isNotEmpty) return 'Using link';
    return 'No file selected';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resources Management')),
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
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _categoryCtrl,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _accessLevel,
                      decoration: const InputDecoration(labelText: 'Access'),
                      items: const [
                        DropdownMenuItem(value: 'public', child: Text('Public')),
                        DropdownMenuItem(value: 'members', child: Text('Members only')),
                      ],
                      onChanged: (v) => setState(() => _accessLevel = v ?? 'public'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _mediaType,
                      decoration: const InputDecoration(labelText: 'Media type'),
                      items: const [
                        DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                        DropdownMenuItem(value: 'audio', child: Text('Audio')),
                        DropdownMenuItem(value: 'image', child: Text('Image')),
                        DropdownMenuItem(value: 'video_link', child: Text('Video link')),
                      ],
                      onChanged: (v) => setState(() => _mediaType = v ?? 'pdf'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _linkCtrl,
                      decoration: const InputDecoration(labelText: 'File URL / Link (leave empty to upload)'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text(_fileSummary())),
                        TextButton.icon(onPressed: _pickFile, icon: const Icon(Icons.upload_file), label: const Text('Pick file')),
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
              const SizedBox(height: 16),
              if (_loadingList) const LoadingIndicator(message: 'Loading resources...')
              else ...[
                const Divider(),
                const Text('Resources', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
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
                      final media = item['mediaType']?.toString() ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Access: $access • Type: ${media.isNotEmpty ? media : 'n/a'}'),
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
