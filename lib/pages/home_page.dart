import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/mello_logo.dart';
import '../services/auth_service.dart';
import '../services/roll_repository.dart';
import '../services/roll_resume.dart';
import 'camera_page.dart';
import 'profile_page.dart';

class _HomeColors {
  static const accent = Color(0xFFE8A399);
  static const accentDeep = Color(0xFFD8897E);
  static const ink = Color(0xFF3D2F33);
  static const muted = Color(0xFF7A6569);
}

/// Landing après authentification : présentation du produit et CTA caméra.
///
/// Navigation : « Get started » → nouveau rouleau ; « Continue roll » → reprise.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ActiveRollState _activeRoll = const ActiveRollState(photoPaths: []);
  bool _loadingRoll = true;

  bool get _hasIncompleteRoll => _activeRoll.isIncomplete;

  bool get _hasResumableRoll =>
      _activeRoll.isIncomplete || _activeRoll.isComplete;

  @override
  void initState() {
    super.initState();
    unawaited(_loadActiveRoll());
  }

  Future<void> _loadActiveRoll() async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) {
      if (mounted) setState(() => _loadingRoll = false);
      return;
    }

    final state = await RollRepository.loadActiveRollState(userId);
    if (!mounted) return;
    setState(() {
      _activeRoll = state;
      _loadingRoll = false;
    });
  }

  Future<void> _openCamera({List<String>? initialPhotoPaths}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CameraPage(
          initialPhotoPaths: initialPhotoPaths ?? const [],
        ),
      ),
    );
    if (mounted) await _loadActiveRoll();
  }

  Future<void> _resumeRoll() async {
    await RollResume.navigate(context, _activeRoll);
    if (mounted) await _loadActiveRoll();
  }

  Future<void> _startNewRoll() async {
    if (_hasResumableRoll) {
      final discard = await RollResume.confirmDiscardRoll(context);
      if (!discard || !mounted) return;
    }

    final userId = AuthService.instance.currentUserId;
    if (userId != null) {
      await RollRepository.clearActiveRoll(userId);
    }
    if (!mounted) return;
    await _openCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _HomeBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HomeHeader(),
                  const Spacer(flex: 2),
                  const _HeroSection(),
                  const Spacer(flex: 3),
                  const _FeatureRow(),
                  const SizedBox(height: 28),
                  if (!_loadingRoll && _hasResumableRoll) ...[
                    _ContinueRollButton(
                      label: RollResume.continueButtonLabel(_activeRoll),
                      onPressed: () => unawaited(_resumeRoll()),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _StartButton(
                    label: _hasIncompleteRoll ? 'Start a new roll' : 'Get started',
                    onPressed: () => unawaited(_startNewRoll()),
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

/// Fond dégradé avec orbes floues (effet « glow »).
class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

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
            top: -80,
            right: -40,
            child: _GlowOrb(size: 220, color: _HomeColors.accent.withValues(alpha: 0.35)),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: _GlowOrb(size: 180, color: _HomeColors.accentDeep.withValues(alpha: 0.22)),
          ),
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.35,
            left: MediaQuery.sizeOf(context).width * 0.55,
            child: _GlowOrb(size: 100, color: Colors.white.withValues(alpha: 0.7)),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const MelloLogo(height: 28, alignment: Alignment.centerLeft),
        Material(
          color: Colors.white.withValues(alpha: 0.75),
          shape: const CircleBorder(side: BorderSide(color: Colors.white)),
          elevation: 0,
          shadowColor: _HomeColors.accent.withValues(alpha: 0.15),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _HomeColors.accent.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: _HomeColors.accentDeep,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Disposable camera, reimagined',
          textAlign: TextAlign.center,
          style: GoogleFonts.lora(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _HomeColors.muted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Shoot it.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lora(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: _HomeColors.ink,
            height: 1.05,
            letterSpacing: -1,
          ),
        ),
        Text(
          'Forget it.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lora(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: _HomeColors.ink,
            height: 1.05,
            letterSpacing: -1,
          ),
        ),
        // Dernier mot du hero en dégradé saumon.
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_HomeColors.accentDeep, _HomeColors.accent],
          ).createShader(bounds),
          child: Text(
            'Receive it.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.05,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: _HomeColors.accent.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Text(
            '24 photos without peeking. We develop and ship real prints to your door.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: _HomeColors.muted,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _FeatureChip(icon: Icons.camera_alt_outlined, label: '24 shots')),
        SizedBox(width: 10),
        Expanded(child: _FeatureChip(icon: Icons.visibility_off_outlined, label: 'No peeking')),
        SizedBox(width: 10),
        Expanded(child: _FeatureChip(icon: Icons.local_shipping_outlined, label: 'Real prints')),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: _HomeColors.accentDeep),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _HomeColors.ink,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _StartButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [_HomeColors.accentDeep, _HomeColors.accent],
        ),
        boxShadow: [
          BoxShadow(
            color: _HomeColors.accentDeep.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueRollButton extends StatelessWidget {
  const _ContinueRollButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        side: const BorderSide(color: _HomeColors.accentDeep, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        foregroundColor: _HomeColors.accentDeep,
      ),
      child: Text(
        label,
        style: GoogleFonts.lora(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
