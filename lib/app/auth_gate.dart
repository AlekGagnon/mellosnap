import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/camera_page.dart';
import '../pages/home_page.dart';
import '../pages/sign_in_page.dart';
import '../services/roll_repository.dart';

/// Route initiale selon session Supabase et état du rouleau actif.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const SignInPage();
        }

        return _AuthenticatedRouter(userId: session.user.id);
      },
    );
  }
}

class _AuthenticatedRouter extends StatefulWidget {
  const _AuthenticatedRouter({required this.userId});

  final String userId;

  @override
  State<_AuthenticatedRouter> createState() => _AuthenticatedRouterState();
}

class _AuthenticatedRouterState extends State<_AuthenticatedRouter> {
  late Future<Widget> _destinationFuture;

  @override
  void initState() {
    super.initState();
    _destinationFuture = _resolveDestination();
  }

  @override
  void didUpdateWidget(covariant _AuthenticatedRouter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _destinationFuture = _resolveDestination();
    }
  }

  Future<Widget> _resolveDestination() async {
    final paths = await RollRepository.loadActiveRoll(widget.userId);
    if (RollRepository.isRollIncomplete(paths)) {
      return CameraPage(initialPhotoPaths: paths);
    }
    return const HomePage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _destinationFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }
}

/// Affiché si Supabase n'est pas configuré au démarrage.
class SupabaseConfigErrorPage extends StatelessWidget {
  const SupabaseConfigErrorPage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.settings_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                'Configuration required',
                style: GoogleFonts.lora(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: GoogleFonts.lora(fontSize: 15, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'See SUPABASE_SETUP.md',
                style: GoogleFonts.lora(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
