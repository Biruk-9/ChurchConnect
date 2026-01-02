import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/config/api_config.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

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
                    child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
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

class AnnouncementManager extends StatefulWidget {
  const AnnouncementManager({
    super.key,
    this.showForm = true,
    this.showList = true,
  });

  final bool showForm;
  final bool showList;

  @override
  State<AnnouncementManager> createState() => _AnnouncementManagerState();
}

class _AnnouncementManagerState extends State<AnnouncementManager> {
  bool _loading = false;
  bool _saving = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  String? _editingId;

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminService.fetchAnnouncements();
      final sorted = List<Map<String, dynamic>>.from(data)
        ..sort((a, b) => _dateFrom(b).compareTo(_dateFrom(a)));
      if (!mounted) return;
      setState(() => _items = sorted);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _contentCtrl.clear();
    _imageBytes = null;
    _imageName = null;
    _editingId = null;
    _error = null;
    setState(() {});
  }

  void _startEditMode(Map<String, dynamic> item) {
    setState(() {
      _editingId = item['_id']?.toString();
      _titleCtrl.text = item['title']?.toString() ?? '';
      _contentCtrl.text = item['content']?.toString() ?? '';
      _imageBytes = null;
      _imageName = null;
      _error = null;
    });

    if (!widget.showForm) {
      _showEditDialog();
    }
  }

  String _imageSummaryText() {
    if (_imageName != null) return 'Selected: $_imageName';
    return _editingId == null ? 'No image selected (optional)' : 'Keep current image';
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result?.files.single.bytes != null) {
      setState(() {
        _imageBytes = result!.files.single.bytes;
        _imageName = result.files.single.name;
      });
    }
  }

  Future<void> _saveAnnouncement({bool closeDialogOnSave = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final wasEditing = _editingId != null;
      final title = _safeTrim(_titleCtrl.text);
      final content = _safeTrim(_contentCtrl.text);

      if (!wasEditing) {
        await AdminService.createAnnouncement(
          title: title,
          content: content,
          imageBytes: _imageBytes,
          filename: _imageName,
        );
      } else {
        await AdminService.updateAnnouncement(
          id: _editingId!,
          title: title,
          content: content,
          imageBytes: _imageBytes,
          filename: _imageName,
        );
      }

      if (!mounted) return;
      _resetForm();
      await _loadItems();
      if (closeDialogOnSave && mounted) {
        Navigator.of(context).pop();
      }
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

  Future<void> _deleteAnnouncement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AdminService.deleteAnnouncement(id);
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            title: _editingId == null ? 'New Announcement' : 'Edit Announcement',
            subtitle: 'Share updates with your community',
            child: _buildForm(inDialog: false),
          ),
          const SizedBox(height: 24),
        ],

        if (showList) ...[
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: LoadingIndicator(message: 'Loading announcements...'),
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
                    child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No announcements yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first announcement to get started',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else ...[
            _CardShell(
              title: 'Existing Announcements',
              subtitle: '${_items.length} announcement(s) posted',
              child: Column(
                children: [
                  ..._items.map((item) => _buildAnnouncementCard(item)),
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
            validator: (v) => _safeTrim(v).isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),
          _buildStyledTextField(
            controller: _contentCtrl,
            label: 'Content',
            icon: Icons.description_outlined,
            maxLines: 5,
            validator: (v) => _safeTrim(v).isEmpty ? 'Content is required' : null,
          ),
          const SizedBox(height: 16),
          _buildUploadRow(),
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
                      onPressed: _saving ? null : () => _saveAnnouncement(closeDialogOnSave: inDialog),
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
                              _editingId == null ? 'Create Announcement' : 'Update Announcement',
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
            child: const Icon(Icons.image_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _saving ? null : _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                      ),
                      child: const Text('Choose image'),
                    ),
                    const SizedBox(width: 10),
                    if (_imageBytes != null || _imageName != null)
                      IconButton(
                        tooltip: 'Clear image',
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                  _imageBytes = null;
                                  _imageName = null;
                                }),
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _imageSummaryText(),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> item) {
    final id = item['_id']?.toString() ?? '';
    final title = item['title']?.toString() ?? 'Untitled';
    final content = item['content']?.toString() ?? '';
    final imageUrl = _resolveImageUrl(item['imageUrl']?.toString());
    final hasImage = imageUrl != null;
    final postedAt = _formatPostedAt(_dateFrom(item));

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
        onTap: () => _startEditMode(item),
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
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
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
                    const SizedBox(height: 10),
                    Text(
                      content,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                    ),
                    if (hasImage) ...[
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => _showImagePreview(imageUrl!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              color: Colors.grey.shade100,
                              child: Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(
                                    'Image unavailable',
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
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        postedAt,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF7C3AED)),
                    onPressed: () => _startEditMode(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: _saving ? null : () => _deleteAnnouncement(id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _resolveImageUrl(String? url) {
    final value = url?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http')) return value;
    return '${ApiConfig.baseUrl}$value';
  }

  DateTime _dateFrom(Map<String, dynamic> item) {
    final raw = item['createdAt']?.toString() ?? item['updatedAt']?.toString() ?? '';
    return DateTime.tryParse(raw)?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatPostedAt(DateTime date) {
    final formatter = DateFormat('MMM d, yyyy h:mma');
    return formatter.format(date);
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
              const Text('Edit Announcement', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(child: _buildForm(inDialog: true)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton(
              onPressed: () => _saveAnnouncement(closeDialogOnSave: true),
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
}