import 'package:flutter/material.dart';

import '../components/auth_widgets.dart';
import '../services/auth_service.dart';
import 'sign_up_page.dart';

/// Écran de connexion — email et Google via Supabase.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showAuthError(Object error) {
    final message = AuthService.friendlyError(error);
    final messenger = ScaffoldMessenger.of(context);

    if (AuthService.isEmailNotConfirmed(error)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Resend',
            onPressed: _resendConfirmation,
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _runAuth(Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await action();
      // AuthGate rebuilds automatically via onAuthStateChange.
    } catch (e) {
      if (!mounted) return;
      _showAuthError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _signIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and password.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _runAuth(
      () => AuthService.instance.signIn(email: email, password: password),
    );
  }

  Future<void> _resendConfirmation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email above, then tap Resend.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await AuthService.instance.resendConfirmationEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirmation email sent. Check your inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showAuthError(e);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your email and we will send you a reset link.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              hint: 'hello@mail.com',
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send link'),
          ),
        ],
      ),
    );

    if (submitted != true || !mounted) {
      resetEmailController.dispose();
      return;
    }

    final email = resetEmailController.text.trim();
    resetEmailController.dispose();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await AuthService.instance.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check your email for a password reset link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showAuthError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                textInputAction: TextInputAction.done,
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
              const SizedBox(height: 22),
              PrimaryAuthButton(
                text: 'Sign In',
                loading: _loading,
                onPressed: _signIn,
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
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No Account ? ', style: TextStyle(color: Colors.black54)),
                  GestureDetector(
                    onTap: _loading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SignUpPage(),
                              ),
                            );
                          },
                    child: const Text(
                      'Sign up here',
                      style: TextStyle(
                        color: Color(0xFFE1A09D),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _loading ? null : _showForgotPasswordDialog,
                child: const Text(
                  'Forgot my Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE1A09D),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
