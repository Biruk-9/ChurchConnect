import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

class AdminManagementSections extends StatelessWidget {
  const AdminManagementSections({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionHeader(title: 'Management'),
        SizedBox(height: 8),
        AnnouncementManager(),
        SizedBox(height: 16),
        EventManager(),
        SizedBox(height: 16),
        ResourceManager(),
        SizedBox(height: 16),
        UserManager(),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }
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

class AnnouncementManager extends StatefulWidget {
  const AnnouncementManager({super.key});

  @override
  State<AnnouncementManager> createState() => _AnnouncementManagerState();
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
    return _editingId == null ? 'No image selected (required)' : 'Keep existing image';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_editingId == null && _imageBytes == null) {
      setState(() => _error = 'Please choose an image to upload');
      return;
    }
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
          imageBytes: _imageBytes!,
          filename: _imageName ?? 'announcement.jpg',
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

class EventManager extends StatefulWidget {
  const EventManager({super.key});

  @override
  State<EventManager> createState() => _EventManagerState();
}

class _EventManagerState extends State<EventManager> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  String? _error;
  String? _editingId;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateTime.now().toIso8601String();
    _timeCtrl.text = '18:00';
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminService.fetchEvents();
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
      _descCtrl.text = item['description']?.toString() ?? '';
      _dateCtrl.text = item['date']?.toString() ?? '';
      _timeCtrl.text = item['time']?.toString() ?? '';
      _locationCtrl.text = item['location']?.toString() ?? '';
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _descCtrl.clear();
    _locationCtrl.clear();
    _dateCtrl.text = DateTime.now().toIso8601String();
    _timeCtrl.text = '18:00';
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
      final payload = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'date': _dateCtrl.text.trim(),
        'time': _timeCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
      };
      if (_editingId == null) {
        await AdminService.createEvent(
          title: payload['title']!,
          date: payload['date']!,
          time: payload['time']!,
          description: payload['description'],
          location: payload['location'],
        );
      } else {
        await AdminService.updateEvent(
          id: _editingId!,
          title: payload['title']!,
          date: payload['date']!,
          time: payload['time']!,
          description: payload['description'],
          location: payload['location'],
        );
      }
      if (!mounted) return;
      _resetForm();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(wasEditing ? 'Event updated' : 'Event created')),
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
      await AdminService.deleteEvent(id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
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
      title: 'Events Management',
      subtitle: 'Create, edit, delete events. Notifications can be sent after saving.',
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
                  controller: _dateCtrl,
                  decoration: const InputDecoration(labelText: 'Date (ISO or readable)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Date required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _timeCtrl,
                  decoration: const InputDecoration(labelText: 'Time (e.g., 18:30)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Time required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
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
                        label: _editingId == null ? 'Create Event' : 'Update Event',
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
          if (_loading) const LoadingIndicator(message: 'Loading events...')
          else ...[
            const Divider(),
            const Align(alignment: Alignment.centerLeft, child: Text('Upcoming Events', style: TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(height: 6),
            if (_items.isEmpty)
              const Text('No events yet', style: TextStyle(color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final id = item['_id']?.toString() ?? '';
                  final title = item['title']?.toString() ?? 'Untitled';
                  final date = item['date']?.toString() ?? '';
                  final time = item['time']?.toString() ?? '';
                  final location = item['location']?.toString();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${date.isNotEmpty ? date : 'No date'}${time.isNotEmpty ? ' • $time' : ''}${location != null && location.isNotEmpty ? ' • $location' : ''}'),
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

class ResourceManager extends StatefulWidget {
  const ResourceManager({super.key});

  @override
  State<ResourceManager> createState() => _ResourceManagerState();
}

class _ResourceManagerState extends State<ResourceManager> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _fileUrlCtrl = TextEditingController();

  String _category = 'pdf';
  String _accessLevel = 'public';
  String _mediaType = 'pdf';
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
      _mediaType = item['mediaType']?.toString() ?? 'pdf';
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _descCtrl.clear();
    _fileUrlCtrl.clear();
    _category = 'pdf';
    _accessLevel = 'public';
    _mediaType = 'pdf';
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
      final fields = <String, String>{
        'title': _titleCtrl.text.trim(),
        'category': _category,
        'accessLevel': _accessLevel,
        'mediaType': _mediaType,
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
        );
      } else {
        await AdminService.updateResource(id: _editingId!, fields: fields);
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
                  value: _category,
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
    );
  }
}

class UserManager extends StatefulWidget {
  const UserManager({super.key});

  @override
  State<UserManager> createState() => _UserManagerState();
}

class _UserManagerState extends State<UserManager> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isActive = true;
  bool _includeInactive = true;
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminService.listUsers(includeInactive: _includeInactive);
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
      _nameCtrl.text = item['name']?.toString() ?? '';
      _emailCtrl.text = item['email']?.toString() ?? '';
      _passwordCtrl.clear();
      _isActive = item['isActive'] == true;
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _isActive = true;
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
        await AdminService.createUser(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          isActive: _isActive,
        );
      } else {
        await AdminService.updateUser(
          id: _editingId!,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text.trim(),
          isActive: _isActive,
        );
      }
      if (!mounted) return;
      _resetForm();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(wasEditing ? 'Member updated' : 'Member created')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _softDelete(String id) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AdminService.deleteUser(id, hard: false);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member deactivated')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _hardDelete(String id) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AdminService.deleteUser(id, hard: true);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member deleted')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleActive(String id, bool value) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AdminService.updateUser(id: id, isActive: value);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete member'),
        content: const Text('Soft delete deactivates the member. Hard delete removes the record.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () {
            Navigator.of(context).pop();
            _softDelete(id);
          }, child: const Text('Soft delete')),
          TextButton(onPressed: () {
            Navigator.of(context).pop();
            _hardDelete(id);
          }, child: const Text('Hard delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'User Management',
      subtitle: 'Create and maintain members. Admins cannot be modified.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Include inactive members'),
            value: _includeInactive,
            onChanged: (v) {
              setState(() => _includeInactive = v);
              _load();
            },
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Email required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: _editingId == null ? 'Password' : 'Password (leave blank to keep)'),
                  validator: (v) {
                    if (_editingId == null) {
                      if (v == null || v.trim().isEmpty) return 'Password required';
                      if (v.trim().length < 6) return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v ?? true),
                ),
                if (_error != null) ...[
                  ErrorMessage(message: _error!),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: _editingId == null ? 'Create Member' : 'Update Member',
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
          if (_loading) const LoadingIndicator(message: 'Loading members...')
          else ...[
            const Divider(),
            const Align(alignment: Alignment.centerLeft, child: Text('Members', style: TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(height: 6),
            if (_items.isEmpty)
              const Text('No members yet', style: TextStyle(color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final id = item['_id']?.toString() ?? '';
                  final name = item['name']?.toString() ?? 'Unnamed';
                  final email = item['email']?.toString() ?? '';
                  final role = item['role']?.toString() ?? 'member';
                  final isActive = item['isActive'] == true;
                  final createdAt = item['createdAt']?.toString();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('$name (${role.toUpperCase()})'),
                    subtitle: Text('$email${createdAt != null ? ' • Joined: $createdAt' : ''}'),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        Switch(
                          value: isActive,
                          onChanged: _saving ? null : (v) => _toggleActive(id, v),
                          activeColor: Colors.green,
                        ),
                        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _startEdit(item)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _saving ? null : () => _confirmDelete(id)),
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
