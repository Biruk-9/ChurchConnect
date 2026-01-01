import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

class EventManager extends StatefulWidget {
  const EventManager({super.key});

  @override
  State<EventManager> createState() => _EventManagerState();
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

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _syncDateTimeFields();
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
    final parsedDate = DateTime.tryParse(item['date']?.toString() ?? '');
    final parsedTime = _tryParseTime(item['time']?.toString() ?? '');

    setState(() {
      _editingId = item['_id']?.toString();
      _titleCtrl.text = item['title']?.toString() ?? '';
      _descCtrl.text = item['description']?.toString() ?? '';
      _selectedDate = parsedDate ?? DateTime.now();
      _selectedTime = parsedTime ?? const TimeOfDay(hour: 18, minute: 0);
      _syncDateTimeFields();
      _locationCtrl.text = item['location']?.toString() ?? '';
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _descCtrl.clear();
    _locationCtrl.clear();
    _selectedDate = DateTime.now();
    _selectedTime = const TimeOfDay(hour: 18, minute: 0);
    _syncDateTimeFields();
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

  void _syncDateTimeFields() {
    _dateCtrl.text = _formatDate(_selectedDate);
    _timeCtrl.text = _formatTime(_selectedTime);
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  String _formatTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  TimeOfDay? _tryParseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _syncDateTimeFields();
      });
    }
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _syncDateTimeFields();
      });
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
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Date'),
                  onTap: _pickDate,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Date required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _timeCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Time'),
                  onTap: _pickTime,
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
