import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

class EventManager extends StatefulWidget {
  const EventManager({
    super.key,
    this.showForm = true,
    this.showList = true,
  });

  final bool showForm;
  final bool showList;

  @override
  State<EventManager> createState() => _EventManagerState();
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
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
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
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

    if (!widget.showForm) {
      _showEditDialog();
    }
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

  Future<void> _save({bool closeDialogOnSave = false}) async {
    if (!_formKey.currentState!.validate()) return;
    final wasEditing = _editingId != null;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final payload = {
        'title': _safeTrim(_titleCtrl.text),
        'description': _safeTrim(_descCtrl.text),
        'date': _safeTrim(_dateCtrl.text),
        'time': _safeTrim(_timeCtrl.text),
        'location': _safeTrim(_locationCtrl.text),
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
      if (closeDialogOnSave && mounted) {
        Navigator.of(context).pop();
      }
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
              const Text('Edit Event', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(child: _buildForm(inDialog: true)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF7C3AED),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF7C3AED),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
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
    final showForm = widget.showForm;
    final showList = widget.showList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showForm) ...[
          _CardShell(
            title: _editingId == null ? 'New Event' : 'Edit Event',
            subtitle: 'Fill out the details for your church event',
            child: _buildForm(inDialog: false),
          ),
          const SizedBox(height: 24),
        ],

        if (showList) ...[
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: LoadingIndicator(message: 'Loading events...'),
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
                    child: const Icon(Icons.event_busy_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No events scheduled yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first event to get started',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else ...[
            _CardShell(
              title: 'Upcoming Events',
              subtitle: '${_items.length} events scheduled',
              child: Column(
                children: [
                  ..._items.map((item) => _buildEventCard(item)),
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
            label: 'Event Title',
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
                child: _buildStyledTextField(
                  controller: _dateCtrl,
                  label: 'Date',
                  icon: Icons.calendar_today_rounded,
                  readOnly: true,
                  onTap: _pickDate,
                  validator: (v) => _safeTrim(v).isEmpty ? 'Date required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStyledTextField(
                  controller: _timeCtrl,
                  label: 'Time',
                  icon: Icons.access_time_rounded,
                  readOnly: true,
                  onTap: _pickTime,
                  validator: (v) => _safeTrim(v).isEmpty ? 'Time required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStyledTextField(
            controller: _locationCtrl,
            label: 'Location',
            icon: Icons.location_on_outlined,
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
                              _editingId == null ? 'Create Event' : 'Update Event',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (inDialog)
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetForm();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(96, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                )
              else
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _resetForm,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(96, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      foregroundColor: const Color(0xFF7C3AED),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Reset'),
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

  String _safeTrim(String? value) => value?.trim() ?? '';

  Widget _buildEventCard(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? 'Untitled';
    final rawDate = item['date']?.toString() ?? '';
    final date = _formatDisplayDate(rawDate);
    final time = item['time']?.toString() ?? '';
    final location = item['location']?.toString();
    final id = item['_id']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';
    final postedAt = _formatPostedAt(_dateFrom(item));
    final dateTimeText = [date, time].where((v) => v.isNotEmpty).join(' ');

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
                child: const Icon(Icons.event_rounded, color: Colors.white, size: 28),
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
                    if (dateTimeText.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6D28D9)),
                          const SizedBox(width: 8),
                          Text(
                            dateTimeText,
                            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    if (location != null && location.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 18, color: Color(0xFF6D28D9)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey.shade700, height: 1.4),
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

  String _formatDisplayDate(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    final mm = parsed.month.toString().padLeft(2, '0');
    final dd = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}/$mm/$dd';
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