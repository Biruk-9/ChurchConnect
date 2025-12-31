import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isActive = true;
  bool _includeInactive = true;
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loadingList = true;
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
      if (mounted) setState(() => _loadingList = false);
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
          TextButton(onPressed: () { Navigator.of(context).pop(); _softDelete(id); }, child: const Text('Soft delete')),
          TextButton(onPressed: () { Navigator.of(context).pop(); _hardDelete(id); }, child: const Text('Hard delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users Management')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),
              if (_loadingList) const LoadingIndicator(message: 'Loading members...')
              else ...[
                const Divider(),
                const Text('Members', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
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
                            Switch(value: isActive, onChanged: _saving ? null : (v) => _toggleActive(id, v), activeColor: Colors.green),
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
        ),
      ),
    );
  }
}
