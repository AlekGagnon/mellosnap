import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentification Supabase (email, Google) avec session persistante.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  String? get currentUserId => currentUser?.id;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  static String? get _googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: normalizeEmail(email),
      password: password,
    );
    if (response.user == null) {
      throw AuthException('Sign up failed. Please try again.');
    }
    if (response.session == null) {
      throw AuthException(
        'Account created. Check your email to confirm before signing in.',
        code: 'email_not_confirmed',
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: normalizeEmail(email),
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
    final webClientId = _googleWebClientId;
    if (webClientId == null || webClientId.isEmpty || webClientId.startsWith('your_')) {
      throw AuthException(
        'Google sign-in is not configured. Set GOOGLE_WEB_CLIENT_ID in .env',
      );
    }

    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      scopes: const ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw AuthException('No Google ID token received.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  Future<void> resetPasswordForEmail(String email) async {
    final normalizedEmail = normalizeEmail(email);
    if (normalizedEmail.isEmpty) {
      throw AuthException('Email is required.');
    }
    await _client.auth.resetPasswordForEmail(normalizedEmail);
  }

  Future<void> resendConfirmationEmail(String email) async {
    final normalizedEmail = normalizeEmail(email);
    if (normalizedEmail.isEmpty) {
      throw AuthException('Email is required.');
    }
    await _client.auth.resend(
      email: normalizedEmail,
      type: OtpType.signup,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut(scope: SignOutScope.global);
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  static bool isEmailNotConfirmed(Object error) {
    return error is AuthException && error.code == 'email_not_confirmed';
  }

  static String friendlyError(Object error) {
    if (error is AuthException) {
      switch (error.code) {
        case 'email_not_confirmed':
          return 'Confirm your email before signing in. Check your inbox.';
        case 'invalid_credentials':
          return 'Wrong email or password. Try again or reset your password.';
        case 'user_not_found':
          return 'No account found for this email. Sign up first.';
        case 'over_request_rate_limit':
          return 'Too many attempts. Please wait a moment and try again.';
      }
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }
}
