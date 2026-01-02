import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/api_config.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

class ResourceManager extends StatefulWidget {
  const ResourceManager({
    super.key,
    this.showForm = true,
    this.showList = true,
  });

  final bool showForm;
  final bool showList;

  @override
  State<ResourceManager> createState() => _ResourceManagerState();
}

class _PickerType {
  const _PickerType(this.type, {this.extensions});

  final FileType type;
  final List<String>? extensions;
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.showHeader = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.96),
            Colors.white.withOpacity(0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.folder_open_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
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
      final sorted = combined.values.toList()
        ..sort((a, b) => _dateFrom(b).compareTo(_dateFrom(a)));
      setState(() => _items = sorted);
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

    if (!widget.showForm) {
      _showEditDialog();
    }
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

  Future<void> _save({bool closeDialogOnSave = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_editingId == null && _fileBytes == null && _safeTrim(_fileUrlCtrl.text).isEmpty) {
      setState(() => _error = 'Upload a file or enter a link');
      return;
    }
    final wasEditing = _editingId != null;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final desc = _safeTrim(_descCtrl.text);
      final link = _safeTrim(_fileUrlCtrl.text);
      final fields = <String, String>{
        'title': _safeTrim(_titleCtrl.text),
        'category': _category,
        'accessLevel': _accessLevel,
        'mediaType': _category,
      };
      if (desc.isNotEmpty) fields['description'] = desc;
      if (link.isNotEmpty) fields['fileUrl'] = link;

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
      if (closeDialogOnSave && mounted) {
        Navigator.of(context).pop();
      }
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
      case 'image':
        return _PickerType(FileType.image);
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
    final showForm = widget.showForm;
    final showList = widget.showList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showForm) ...[
          _CardShell(
            title: _editingId == null ? 'New Resource' : 'Edit Resource',
            subtitle: 'Upload files or link content for your community',
            child: _buildForm(inDialog: false),
          ),
          const SizedBox(height: 24),
        ],

        if (showList) ...[
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: LoadingIndicator(message: 'Loading resources...'),
              ),
            )
          else if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_off_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No resources yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a file or link to get started',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else ...[
            _CardShell(
              title: 'Existing Resources',
              subtitle: '${_items.length} resources available',
              child: Column(
                children: [
                  ..._items.map((item) => _buildResourceCard(item)),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildForm({required bool inDialog}) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildStyledTextField(
            controller: _titleCtrl,
            label: 'Title',
            icon: Icons.title_outlined,
            validator: (v) => _safeTrim(v).isEmpty ? 'Title required' : null,
          ),
          const SizedBox(height: 16),
          _buildStyledTextField(
            controller: _descCtrl,
            label: 'Description',
            icon: Icons.description_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  value: _category,
                  label: 'Category',
                  icon: Icons.category_outlined,
                  items: const [
                    DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    DropdownMenuItem(value: 'audio', child: Text('Audio')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                    DropdownMenuItem(value: 'image', child: Text('Image')),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? 'pdf'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  value: _accessLevel,
                  label: 'Access',
                  icon: Icons.lock_open_rounded,
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                    DropdownMenuItem(value: 'members', child: Text('Members only')),
                  ],
                  onChanged: (v) => setState(() => _accessLevel = v ?? 'public'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUploadRow(),
          const SizedBox(height: 16),
          _buildStyledTextField(
            controller: _fileUrlCtrl,
            label: 'File URL / Link',
            icon: Icons.link_rounded,
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: ErrorMessage(message: _error!)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6D28D9).withOpacity(0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _save(closeDialogOnSave: inDialog),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 26,
                              width: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _editingId == null ? 'Create Resource' : 'Update Resource',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    if (inDialog) Navigator.of(context).pop();
                    _resetForm();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(96, 52),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    side: const BorderSide(color: Color(0xFF7C3AED)),
                    foregroundColor: const Color(0xFF7C3AED),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: Text(inDialog ? 'Cancel' : 'Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF7C3AED)),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color.fromARGB(255, 186, 182, 182)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color.fromARGB(255, 186, 182, 182)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF7C3AED)),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color.fromARGB(255, 186, 182, 182)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color.fromARGB(255, 186, 182, 182)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildUploadRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 186, 182, 182)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _saving ? null : _pickFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                      ),
                      child: const Text('Upload file'),
                    ),
                    const SizedBox(width: 10),
                    if (_fileBytes != null || _filename != null)
                      IconButton(
                        tooltip: 'Clear file',
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                  _fileBytes = null;
                                  _filename = null;
                                }),
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _fileSummary(),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> item) {
    final id = item['_id']?.toString() ?? '';
    final title = item['title']?.toString() ?? 'Untitled';
    final description = item['description']?.toString() ?? '';
    final category = item['category']?.toString() ?? 'n/a';
    final access = item['accessLevel']?.toString() ?? 'public';
    final rawFileUrl = item['fileUrl']?.toString();
    final fileUrl = _resolveFileUrl(rawFileUrl);
    final isImage = fileUrl != null && _looksLikeImage(fileUrl);
    final hasLink = fileUrl != null;
    final postedAt = _formatPostedAt(_dateFrom(item));
    final mediaTitle = '${category.toUpperCase()} • ${access == 'members' ? 'Members only' : 'Public'}${fileUrl != null ? ' • Link attached' : ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromARGB(255, 186, 182, 182)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _startEdit(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.folder_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mediaTitle,
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                      ),
                    ],
                    if (isImage) ...[
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => _showImagePreview(fileUrl!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              color: Colors.grey.shade100,
                              child: Image.network(
                                fileUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(
                                    'Preview unavailable',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (hasLink)
                          TextButton.icon(
                            onPressed: () => _openResource(fileUrl),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('Open'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6D28D9)),
                          )
                        else
                          const SizedBox.shrink(),
                        Text(
                          postedAt,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF7C3AED)),
                    onPressed: () => _startEdit(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: _saving ? null : () => _delete(id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6D28D9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF6D28D9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.98),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Edit Resource', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(child: _buildForm(inDialog: true)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton(
              onPressed: () => _save(closeDialogOnSave: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  String _safeTrim(String? value) => value?.trim() ?? '';

  Future<void> _openResource(String? url) async {
    final link = url;
    if (link == null || link.isEmpty) return;
    final uri = Uri.parse(link);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  String? _resolveFileUrl(String? url) {
    final value = url?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http')) return value;
    return '${ApiConfig.baseUrl}$value';
  }

  bool _looksLikeImage(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.gif') || lower.endsWith('.webp');
  }

  void _showImagePreview(String url) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              InteractiveViewer(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text('Image unavailable', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaPreview(String url, {required bool isImage, required String title}) {
    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.grey.shade100,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  'Preview unavailable',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconForUrl(url), color: const Color(0xFF6D28D9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _openResource(url),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6D28D9)),
          ),
        ],
      ),
    );
  }

  IconData _iconForUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.mp3') || lower.endsWith('.wav') || lower.endsWith('.aac')) return Icons.audiotrack_rounded;
    if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.mkv') || lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return Icons.smart_display_rounded;
    }
    return Icons.link_rounded;
  }

  DateTime _dateFrom(Map<String, dynamic> item) {
    final raw = item['createdAt']?.toString() ?? item['updatedAt']?.toString() ?? '';
    return DateTime.tryParse(raw)?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatPostedAt(DateTime date) {
    final formatter = DateFormat('MMM d, yyyy h:mma');
    return formatter.format(date);
  }
}
