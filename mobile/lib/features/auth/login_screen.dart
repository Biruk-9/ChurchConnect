import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/validators.dart';
import '../../widgets/error_message.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome back! God bless you 🙏')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final raw = e.toString();
    final lower = raw.toLowerCase();

    // Normalize known auth errors to a friendly message
    if (lower.contains('invalid credentials') ||
        (lower.contains('invalid') && lower.contains('password')) ||
        lower.contains('wrong password') ||
        lower.contains('incorrect password') ||
        lower.contains('unauthorized') ||
        lower.contains('401')) {
      return 'Wrong email or password';
    }

    if (raw.startsWith('AuthException:')) {
      return raw.replaceFirst('AuthException:', '').trim();
    }
    if (raw.startsWith('APIException:')) {
      return raw.replaceFirst('APIException:', '').trim();
    }
    return raw;
  }

InputDecoration _inputDecoration({
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    
    // Always visible subtle border
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color.fromARGB(255, 162, 165, 171), // light gray
        width: 1.2,
      ),
    ),
    
    // Enabled (default state)
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFFD1D5DB),
        width: 1.2,
      ),
    ),
    
    // Focused state - stronger color + slight shadow
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFF5B21B6), // your nice purple
        width: 2,
      ),
    ),
    
    // Error state
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Colors.redAccent,
        width: 1.5,
      ),
    ),
    
    // When there's an error but still focused
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Colors.redAccent,
        width: 2,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFFF8FAFC),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),

                  // Header symbol
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.church_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Sign in to connect with your church family',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.5,
                      color: Colors.white.withOpacity(0.78),
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── Improved Card ──
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 35,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.12),
                          blurRadius: 20,
                          
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 36),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email field
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              hint: 'Email address',
                              icon: Icons.email_rounded,
                            ),
                            validator: emailValidator,
                          ),

                          const SizedBox(height: 24),

                          // Password field
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            decoration: _inputDecoration(
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: const Color(0xFF6B7280),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => requiredField(v, fieldName: 'Password'),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ErrorMessage(message: _error!),
                            ),
                          ],

                          const SizedBox(height: 40),

                          // Premium gradient button
                          SizedBox(
                            height: 62,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF6D28D9), // deep purple-indigo
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6D28D9).withOpacity(0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 28,
                                        width: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}