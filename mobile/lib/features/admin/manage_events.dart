import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

class ManageEvents extends StatefulWidget {
    const ManageEvents({super.key});

    @override
    State<ManageEvents> createState() => _ManageEventsState();
}

class _ManageEventsState extends State<ManageEvents> {
    final _formKey = GlobalKey<FormState>();
    final _titleCtrl = TextEditingController();
    final _descCtrl = TextEditingController();
    final _locationCtrl = TextEditingController();

    DateTime _date = DateTime.now();
    TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);

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
        _descCtrl.dispose();
        _locationCtrl.dispose();
        super.dispose();
    }

    Future<void> _load() async {
        setState(() {
            _loadingList = true;
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
            if (mounted) setState(() => _loadingList = false);
        }
    }

    Future<void> _pickDate() async {
        final picked = await showDatePicker(
            context: context,
            initialDate: _date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
        );
        if (picked != null) {
            setState(() => _date = picked);
        }
    }

    Future<void> _pickTime() async {
        final picked = await showTimePicker(
            context: context,
            initialTime: _time,
        );
        if (picked != null) {
            setState(() => _time = picked);
        }
    }

    void _resetForm() {
        _formKey.currentState?.reset();
        setState(() {
            _editingId = null;
            _titleCtrl.clear();
            _descCtrl.clear();
            _locationCtrl.clear();
            _date = DateTime.now();
            _time = const TimeOfDay(hour: 18, minute: 0);
            _error = null;
        });
    }

    TimeOfDay? _parseTime(String? value) {
        if (value == null || value.isEmpty) return null;
        final parts = value.split(':');
        if (parts.length < 2) return null;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) return null;
        return TimeOfDay(hour: hour, minute: minute);
    }

    String _formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    String _formatSchedule(DateTime date, TimeOfDay time) {
        final datePart = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        return '$datePart ${_formatTime(time)}';
    }

    void _startEdit(Map<String, dynamic> item) {
        final existingDate = DateTime.tryParse(item['date']?.toString() ?? '');
        final existingTime = _parseTime(item['time']?.toString());
        setState(() {
            _editingId = item['_id']?.toString();
            _titleCtrl.text = item['title']?.toString() ?? '';
            _descCtrl.text = item['description']?.toString() ?? '';
            _locationCtrl.text = item['location']?.toString() ?? '';
            if (existingDate != null) _date = existingDate;
            if (existingTime != null) {
                _time = existingTime;
            } else if (existingDate != null) {
                _time = TimeOfDay(hour: existingDate.hour, minute: existingDate.minute);
            }
            _error = null;
        });
    }

    Future<void> _save() async {
        final valid = _formKey.currentState?.validate() ?? false;
        if (!valid) return;
        setState(() {
            _saving = true;
            _error = null;
        });
        final wasEditing = _editingId != null;
        try {
            final dateString = '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
            final timeString = _formatTime(_time);
            final description = _descCtrl.text.trim();
            final location = _locationCtrl.text.trim();
            if (wasEditing) {
                await AdminService.updateEvent(
                    id: _editingId!,
                    title: _titleCtrl.text.trim(),
                    date: dateString,
                    time: timeString,
                    description: description.isEmpty ? null : description,
                    location: location.isEmpty ? null : location,
                );
            } else {
                await AdminService.createEvent(
                    title: _titleCtrl.text.trim(),
                    date: dateString,
                    time: timeString,
                    description: description.isEmpty ? null : description,
                    location: location.isEmpty ? null : location,
                );
            }
            if (!mounted) return;
            _resetForm();
            await _load();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(wasEditing ? 'Event updated' : 'Event created')),
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

    String _itemSchedule(Map<String, dynamic> item) {
        final date = DateTime.tryParse(item['date']?.toString() ?? '');
        final time = _parseTime(item['time']?.toString());
        if (date == null || time == null) return 'No date';
        return _formatSchedule(date, time);
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('Events Management')),
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
                                        Row(
                                            children: [
                                                Expanded(
                                                    child: Text(
                                                        'Date/Time: ${_formatSchedule(_date, _time)}',
                                                        overflow: TextOverflow.ellipsis,
                                                    ),
                                                ),
                                                TextButton.icon(
                                                    onPressed: _pickDate,
                                                    icon: const Icon(Icons.calendar_today),
                                                    label: const Text('Pick date'),
                                                ),
                                                TextButton.icon(
                                                    onPressed: _pickTime,
                                                    icon: const Icon(Icons.access_time),
                                                    label: const Text('Pick time'),
                                                ),
                                            ],
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
                            const SizedBox(height: 16),
                            if (_loadingList) ...[
                                const LoadingIndicator(message: 'Loading events...'),
                            ] else ...[
                                const Divider(),
                                const Text('Events', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
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
                                            final schedule = _itemSchedule(item);
                                            final location = item['location']?.toString();
                                            return ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                subtitle: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        Text(schedule),
                                                        if (location != null && location.isNotEmpty)
                                                            Text(location, style: const TextStyle(color: Colors.grey)),
                                                    ],
                                                ),
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
