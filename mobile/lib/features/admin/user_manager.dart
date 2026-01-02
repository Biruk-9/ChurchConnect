import 'package:flutter/material.dart';
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
                    child: const Icon(Icons.group_rounded, color: Colors.white, size: 24),
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

class UserManager extends StatefulWidget {
  const UserManager({
    super.key,
    this.showForm = true,
    this.showList = true,
  });

  final bool showForm;
  final bool showList;

  @override
  State<UserManager> createState() => _UserManagerState();
}

class _UserManagerState extends State<UserManager> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isActive = true;
  String _role = 'member';
  bool _hidePassword = true;
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
      _role = item['role']?.toString() ?? 'member';
    });

    if (!widget.showForm) {
      _showEditDialog();
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _isActive = true;
    _role = 'member';
    _editingId = null;
    _error = null;
    setState(() {});
  }

  Future<void> _save({bool closeDialogOnSave = false}) async {
    if (!_formKey.currentState!.validate()) return;
    final wasEditing = _editingId != null;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final name = _safeTrim(_nameCtrl.text);
      final email = _safeTrim(_emailCtrl.text);
      final password = _safeTrim(_passwordCtrl.text);

      if (!wasEditing) {
        await AdminService.createUser(
          name: name,
          email: email,
          password: password,
          isActive: _isActive,
          role: _role,
        );
      } else {
        await AdminService.updateUser(
          id: _editingId!,
          name: name,
          email: email,
          password: password.isEmpty ? null : password,
          isActive: _isActive,
          role: _role,
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
    final showForm = widget.showForm;
    final showList = widget.showList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showForm) ...[
          _CardShell(
            title: _editingId == null ? 'New Member' : 'Edit Member',
            subtitle: 'Create and maintain member accounts',
            child: _buildForm(inDialog: false),
          ),
          const SizedBox(height: 24),
        ],

        if (showList) ...[
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: LoadingIndicator(message: 'Loading members...'),
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
                    child: const Icon(Icons.group_off_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No members yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first member to get started',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else ...[
            _CardShell(
              title: 'Members',
              subtitle: '${_items.length} account(s)',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Include inactive', style: TextStyle(fontWeight: FontWeight.w600)),
                      Switch(
                        value: _includeInactive,
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.red.withOpacity(0.35),
                        onChanged: (v) {
                          setState(() => _includeInactive = v);
                          _load();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._items.map((item) => _buildUserCard(item)),
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
            controller: _nameCtrl,
            label: 'Full name',
            icon: Icons.person_outline,
            validator: (v) => _safeTrim(v).isEmpty ? 'Name required' : null,
          ),
          const SizedBox(height: 16),
          _buildStyledTextField(
            controller: _emailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            validator: (v) => _safeTrim(v).isEmpty ? 'Email required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: InputDecoration(
              labelText: 'Role',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield, color: Color(0xFF7C3AED)),
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
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Color(0xFF7C3AED), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            items: const [
              DropdownMenuItem(value: 'member', child: Text('Member')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (v) => setState(() => _role = v ?? 'member'),
          ),
          const SizedBox(height: 16),
          _buildStyledTextField(
            controller: _passwordCtrl,
            label: _editingId == null ? 'Password' : 'Password (leave blank to keep)',
            icon: Icons.lock_outline,
            obscure: true,
            showToggle: true,
            obscured: _hidePassword,
            onToggle: () => setState(() => _hidePassword = !_hidePassword),
            validator: (v) {
              if (_editingId == null) {
                if (v == null || v.trim().isEmpty) return 'Password required';
                if (v.trim().length < 6) return 'At least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            value: _isActive,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
            inactiveTrackColor: Colors.red.withOpacity(0.35),
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: 16),
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
                              _editingId == null ? 'Create Member' : 'Update Member',
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
    bool obscure = false,
    bool showToggle = false,
    bool obscured = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    final effectiveObscure = showToggle ? obscured : obscure;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      obscureText: effectiveObscure,
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
        suffixIcon: showToggle
            ? IconButton(
                icon: Icon(
                  effectiveObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.grey.shade600,
                ),
                onPressed: onToggle,
              )
            : null,
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

  Widget _buildUserCard(Map<String, dynamic> item) {
    final id = item['_id']?.toString() ?? '';
    final name = item['name']?.toString() ?? 'Unnamed';
    final email = item['email']?.toString() ?? '';
    final role = item['role']?.toString() ?? 'member';
    final isActive = item['isActive'] == true;
    final createdAt = item['createdAt']?.toString();

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
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pill(
                          role.toUpperCase(),
                          Icons.shield,
                          color: role == 'admin' ? const Color(0xFF7C3AED) : const Color(0xFF2563EB),
                        ),
                        _pill(
                          isActive ? 'Active' : 'Inactive',
                          isActive ? Icons.check_circle : Icons.pause_circle_filled,
                          color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                        if (createdAt != null && createdAt.isNotEmpty)
                          _pill('Joined: ${_formatDate(createdAt)}', Icons.calendar_today_outlined, color: Colors.grey.shade700),
                        if (email.isNotEmpty) _pill(email, Icons.email_outlined, color: Colors.grey.shade700),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Switch(
                    value: isActive,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    inactiveTrackColor: Colors.red.withOpacity(0.35),
                    onChanged: _saving ? null : (v) => _toggleActive(id, v),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF7C3AED)),
                    onPressed: () => _startEdit(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: _saving ? null : () => _confirmDelete(id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, IconData icon, {Color? color}) {
    final base = color ?? const Color(0xFF6D28D9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: base.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: base),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: base,
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
              const Text('Edit Member', style: TextStyle(fontWeight: FontWeight.w700)),
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

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final mm = parsed.month.toString().padLeft(2, '0');
    final dd = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}/$mm/$dd';
  }

  String _safeTrim(String? value) => value?.trim() ?? '';
}
