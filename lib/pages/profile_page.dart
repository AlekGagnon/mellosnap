import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/mello_logo.dart';
import '../services/auth_service.dart';
import 'settings_page.dart';

const _accent = Color(0xFFE8A399);
const _accentDeep = Color(0xFFD8897E);
const _ink = Color(0xFF3D2F33);
const _muted = Color(0xFF7A6569);

/// Profil utilisateur — accès aux réglages et déconnexion.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _signingOut = false;

  String get _email => AuthService.instance.currentUser?.email ?? 'Signed in';

  String get _displayName {
    final meta = AuthService.instance.currentUser?.userMetadata;
    final name = meta?['full_name'] ?? meta?['name'];
    if (name is String && name.trim().isNotEmpty) {
      return name.trim();
    }
    final email = _email;
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return 'Mello member';
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign out?',
          style: GoogleFonts.lora(
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        content: Text(
          'You will need to sign in again to access your account.',
          style: GoogleFonts.lora(color: _muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.lora(color: _muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Sign out',
              style: GoogleFonts.lora(
                color: _accentDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyError(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _ProfileBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 36),
                  _UserCard(displayName: _displayName, email: _email),
                  const SizedBox(height: 28),
                  _ProfileActionTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: _signingOut
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SettingsPage(),
                              ),
                            );
                          },
                  ),
                  const SizedBox(height: 12),
                  _ProfileActionTile(
                    icon: Icons.logout_rounded,
                    label: 'Sign out',
                    destructive: true,
                    loading: _signingOut,
                    onTap: _signingOut ? null : _signOut,
                  ),
                  const Spacer(),
                  Center(
                    child: MelloLogo(height: 24, alignment: Alignment.center),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF9F6),
            Color(0xFFF7EDE8),
            Color(0xFFF3F1F1),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -30,
            child: _GlowOrb(
              size: 200,
              color: _accent.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -50,
            child: _GlowOrb(
              size: 160,
              color: _accentDeep.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.45,
            spreadRadius: size * 0.08,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _ProfileHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: onBack,
        ),
        const SizedBox(width: 16),
        Text(
          'Profile',
          style: GoogleFonts.lora(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final String displayName;
  final String email;

  const _UserCard({required this.displayName, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_accentDeep, _accent],
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentDeep.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: GoogleFonts.lora(
              fontSize: 14,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  final bool loading;

  const _ProfileActionTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.destructive = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = destructive ? _accentDeep : _accentDeep;
    final textColor = destructive ? _accentDeep : _ink;

    return Material(
      color: Colors.white.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: destructive
                  ? _accent.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.85),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: destructive
                      ? _accent.withValues(alpha: 0.15)
                      : _accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.lora(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: destructive ? _accentDeep : _muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.75),
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white),
      ),
      elevation: 0,
      shadowColor: _accent.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: _accentDeep, size: 22),
        ),
      ),
    );
  }
}
