import 'package:flutter/material.dart';

import '../components/auth_widgets.dart';
import '../services/auth_service.dart';

/// Création de compte via Supabase (email + OAuth).
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _hidePassword = true;
  bool _hidePasswordConfirmation = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _runAuth(Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await action();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyError(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _signUp() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _runAuth(
      () => AuthService.instance.signUp(
        email: AuthService.normalizeEmail(_emailController.text),
        password: _passwordController.text,
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required.';
    final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailPattern.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  String? _validatePasswordConfirm(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                const MelloLogo(height: 56),
                const SizedBox(height: 70),
                const FieldLabel('Email'),
                const SizedBox(height: 6),
                AuthTextField(
                  hint: 'hello@mail.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_loading,
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                const FieldLabel('Password'),
                const SizedBox(height: 6),
                AuthTextField(
                  hint: '************',
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  enabled: !_loading,
                  validator: _validatePassword,
                  textInputAction: TextInputAction.next,
                  suffix: IconButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const FieldLabel('Password Confirmation'),
                const SizedBox(height: 6),
                AuthTextField(
                  hint: '************',
                  controller: _passwordConfirmController,
                  obscureText: _hidePasswordConfirmation,
                  enabled: !_loading,
                  validator: _validatePasswordConfirm,
                  textInputAction: TextInputAction.done,
                  suffix: IconButton(
                    onPressed: _loading
                        ? null
                        : () => setState(
                              () => _hidePasswordConfirmation =
                                  !_hidePasswordConfirmation,
                            ),
                    icon: Icon(
                      _hidePasswordConfirmation
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryAuthButton(
                  text: 'Sign Up',
                  loading: _loading,
                  onPressed: _signUp,
                ),
                const SizedBox(height: 40),
                SocialAuthButton(
                  leading: const Text(
                    'G',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  text: 'Continue with Google',
                  onPressed: _loading
                      ? null
                      : () => _runAuth(AuthService.instance.signInWithGoogle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
