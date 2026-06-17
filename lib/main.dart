import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/auth_gate.dart';

/// Initialized at startup (same pattern as the reference `photo` project).
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  Widget home = const AuthGate();

  if (supabaseUrl.isEmpty ||
      supabaseAnonKey.isEmpty ||
      supabaseUrl.contains('YOUR_PROJECT')) {
    home = const SupabaseConfigErrorPage(
      message:
          'Add SUPABASE_URL and SUPABASE_ANON_KEY to .env (copy from .env.example).',
    );
  } else {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  try {
    cameras = await availableCameras();
  } on CameraException {
    cameras = [];
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(MelloSnapApp(home: home));
}

class MelloSnapApp extends StatelessWidget {
  const MelloSnapApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MelloSnap',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF3F1F1),
        textTheme: GoogleFonts.loraTextTheme(),
      ),
      home: home,
    );
  }
}
