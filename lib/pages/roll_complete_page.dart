import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/mello_logo.dart';
import '../services/auth_service.dart';
import '../services/roll_repository.dart';
import '../services/roll_resume.dart';
import 'camera_page.dart';
import 'choose_format_page.dart';
import 'home_page.dart';

/// Fin de rouleau : aperçu flouté (5 + tuile « +19 More »), envoi ou nouveau rouleau.
///
/// Charge les photos depuis [RollRepository] ; [initialPhotoPaths] évite un flash
/// vide quand on arrive depuis [CameraPage].
class RollCompletePage extends StatefulWidget {
  const RollCompletePage({
    super.key,
    this.initialPhotoPaths,
  });

  final List<String>? initialPhotoPaths;

  @override
  State<RollCompletePage> createState() => _RollCompletePageState();
}

class _RollCompletePageState extends State<RollCompletePage> {
  List<String> _photoPaths = [];
  bool _loading = true;

  static const int totalPhotos = CameraPage.maxPhotos;
  static const int previewCount = 5;
  static const int moreCount = totalPhotos - previewCount;

  static const _bg = Color(0xFFFFF9F6);
  static const _accent = Color(0xFFE89F94);
  static const _accentDeep = Color(0xFFD8897E);
  static const _ink = Color(0xFF2A2628);
  static const _muted = Color(0xFF6B5B5F);
  static const _tile = Color(0xFFFFE4E1);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPhotoPaths;
    if (initial != null && initial.length >= CameraPage.maxPhotos) {
      _photoPaths = List.unmodifiable(initial);
      _loading = false;
    }
    unawaited(_loadAndPersist());
  }

  Future<void> _loadAndPersist() async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    await RollRepository.setRollStage(userId, RollStage.complete);

    if (_photoPaths.length >= CameraPage.maxPhotos) return;

    final state = await RollRepository.loadActiveRollState(userId);
    if (!mounted) return;
    setState(() {
      _photoPaths = state.photoPaths;
      _loading = false;
    });
  }

  Future<void> _sendToPrint() async {
    final userId = AuthService.instance.currentUserId;
    if (userId != null) {
      await RollRepository.setRollStage(userId, RollStage.format);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ChooseFormatPage(),
      ),
    );
  }

  Future<void> _startNewRoll() async {
    final discard = await RollResume.confirmDiscardRoll(context);
    if (!discard || !mounted) return;

    final userId = AuthService.instance.currentUserId;
    if (userId != null) {
      await RollRepository.clearActiveRoll(userId);
    }
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MelloLogo(height: 40),
                    const SizedBox(height: 28),
                    Text(
                      'Roll complete!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Your 24 photos are ready. Send them to print\nand we\'ll mail them to you.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: _muted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _PhotoGrid(photoPaths: _photoPaths),
                    const SizedBox(height: 22),
                    const _InfoBanner(),
                    const SizedBox(height: 28),
                    _PrimaryButton(
                      label: 'Send to print',
                      onPressed: () => unawaited(_sendToPrint()),
                    ),
                    const SizedBox(height: 14),
                    _OutlineButton(
                      label: 'Start a new roll',
                      onPressed: () => unawaited(_startNewRoll()),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Grille 3×2 : indices 0–4 verrouillés, index 5 = photo 6 + libellé « +19 More ».
class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.photoPaths});

  final List<String> photoPaths;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        if (index == 5) {
          return _MoreTile(
            imagePath: photoPaths.length > 5 ? photoPaths[5] : null,
          );
        }
        return _LockedPhotoTile(
          imagePath: index < photoPaths.length ? photoPaths[index] : null,
        );
      },
    );
  }
}

class _LockedPhotoTile extends StatelessWidget {
  const _LockedPhotoTile({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imagePath != null)
            // sigmaX/Y : intensité du flou (plus bas = moins flou).
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: _RollCompletePageState._tile),
              ),
            )
          else
            const ColoredBox(color: _RollCompletePageState._tile),
          Container(color: Colors.white.withValues(alpha: 0.12)),
          const Center(
            child: Icon(
              Icons.lock_outline,
              color: _RollCompletePageState._ink,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dernière case : fond = 6e photo floutée, texte indique les photos restantes.
class _MoreTile extends StatelessWidget {
  const _MoreTile({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imagePath != null)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: _RollCompletePageState._tile),
              ),
            )
          else
            const ColoredBox(color: _RollCompletePageState._tile),
          Container(color: Colors.white.withValues(alpha: 0.18)),
          Center(
            child: Text(
              '+${_RollCompletePageState.moreCount} More',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _RollCompletePageState._ink,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rappel : photos verrouillées, facturation seulement à l'envoi.
class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _RollCompletePageState._tile.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _RollCompletePageState._accent.withValues(alpha: 0.85),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: _RollCompletePageState._accentDeep,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your photos are locked until delivery is confirmed. '
              'You won\'t be charged until you tap \'Send to print\'.',
              style: GoogleFonts.lora(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _RollCompletePageState._accentDeep,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [_RollCompletePageState._accentDeep, _RollCompletePageState._accent],
        ),
        boxShadow: [
          BoxShadow(
            color: _RollCompletePageState._accentDeep.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 54,
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OutlineButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: _RollCompletePageState._accent, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        foregroundColor: _RollCompletePageState._accentDeep,
      ),
      child: Text(
        label,
        style: GoogleFonts.lora(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
