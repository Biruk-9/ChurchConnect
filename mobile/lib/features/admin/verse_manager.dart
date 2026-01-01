import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';
import '../bible_verse/verse_model.dart';

class VerseManager extends StatefulWidget {
  const VerseManager({super.key});

  @override
  State<VerseManager> createState() => _VerseManagerState();
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

class _VerseManagerState extends State<VerseManager> {
  final _formKey = GlobalKey<FormState>();
  final _refCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  String? _error;
  String? _editingId;
  List<Verse> _items = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _syncDateField();
    _load();
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _textCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _syncDateField() {
    final mm = _selectedDate.month.toString().padLeft(2, '0');
    final dd = _selectedDate.day.toString().padLeft(2, '0');
    _dateCtrl.text = '${_selectedDate.year}-$mm-$dd';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _syncDateField();
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminService.fetchVerses();
      if (!mounted) return;
      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startEdit(Verse item) {
    final parsedDate = item.date;
    setState(() {
      _editingId = item.id;
      _refCtrl.text = item.ref;
      _textCtrl.text = item.text;
      _selectedDate = parsedDate ?? DateTime.now();
      _syncDateField();
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _refCtrl.clear();
    _textCtrl.clear();
    _selectedDate = DateTime.now();
    _syncDateField();
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
        'date': _dateCtrl.text.trim(),
        'ref': _refCtrl.text.trim(),
        'text': _textCtrl.text.trim(),
      };
      if (_editingId == null) {
        await AdminService.createVerse(date: payload['date']!, ref: payload['ref']!, text: payload['text']!);
      } else {
        await AdminService.updateVerse(id: _editingId!, date: payload['date'], ref: payload['ref'], text: payload['text']);
      }
      if (!mounted) return;
      _resetForm();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(wasEditing ? 'Verse updated' : 'Verse scheduled')),
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
      await AdminService.deleteVerse(id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verse deleted')));
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
      title: 'Verse of the Day',
      subtitle: 'Schedule seven verses each weekend. Edits blocked after posting.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _refCtrl,
                  decoration: const InputDecoration(labelText: 'Reference (e.g., John 3:16)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Reference required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _textCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Verse text'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Text required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Date'),
                  onTap: _pickDate,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Date required' : null,
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
                        label: _editingId == null ? 'Schedule Verse' : 'Update Verse',
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
          if (_loading) const LoadingIndicator(message: 'Loading verses...')
          else ...[
            const Divider(),
            const Align(alignment: Alignment.centerLeft, child: Text('Scheduled Verses', style: TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(height: 6),
            if (_items.isEmpty)
              const Text('No verses scheduled', style: TextStyle(color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final id = item.id;
                  final ref = item.ref;
                  final text = item.text;
                  final dateStr = item.date != null ? item.date!.toIso8601String().split('T').first : '';
                  final posted = item.posted;
                  final subtitle = [if (dateStr.isNotEmpty) dateStr, if (posted) 'Posted'].join(' • ');
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(ref, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('$subtitle\n$text'),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: posted ? null : () => _startEdit(item),
                          tooltip: posted ? 'Already posted' : 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: _saving || posted || id == null ? null : () => _delete(id),
                          tooltip: posted ? 'Already posted' : 'Delete',
                        ),
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
