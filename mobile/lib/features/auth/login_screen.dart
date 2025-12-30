import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/validators.dart';
import '../../widgets/custom_button.dart';
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
			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged in')));
			Navigator.of(context).maybePop();
		} catch (e) {
			setState(() {
				_error = e.toString();
			});
		} finally {
			setState(() {
				_loading = false;
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Login')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Form(
					key: _formKey,
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							TextFormField(
								controller: _emailCtrl,
								decoration: const InputDecoration(labelText: 'Email'),
								keyboardType: TextInputType.emailAddress,
								validator: emailValidator,
								autofillHints: const [AutofillHints.email],
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _passwordCtrl,
								decoration: const InputDecoration(labelText: 'Password'),
								obscureText: true,
								validator: (v) => requiredField(v, fieldName: 'Password'),
							),
							const SizedBox(height: 16),
							if (_error != null)
								Padding(
									padding: const EdgeInsets.only(bottom: 8),
									child: ErrorMessage(message: _error!),
								),
							CustomButton(
								label: 'Login',
								loading: _loading,
								onPressed: _submit,
							),
						],
					),
				),
			),
		);
	}
}
