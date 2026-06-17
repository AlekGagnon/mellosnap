import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show cameras;
import '../services/auth_service.dart';
import '../services/roll_repository.dart';
import 'roll_complete_page.dart';

/// Prise de vue : 24 photos sans aperçu, sauvegardées dans `mellosnap_roll`.
///
/// Logique héritée du projet `photo` (preview, flip caméra, anti-flash rouge).
/// Navigation : après la 24e photo → [RollCompletePage].
class CameraPage extends StatefulWidget {
  const CameraPage({super.key, this.initialPhotoPaths = const []});

  static const int maxPhotos = 24;

  /// Chemins restaurés depuis [RollRepository] (reprise après redémarrage).
  final List<String> initialPhotoPaths;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraColors {
  static const softWhite = Color(0xFFFDFCFB);
  static const overlay = Color(0x99000000);
  static const rose = Color(0xFFC4A4A0);
  static const scaffold = Color(0xFFFAF6F3);
  static const primary = Color(0xFF9B8B9E);
}

class _CameraPageState extends State<CameraPage> {
  /// Liste globale initialisée dans [main.dart] via `availableCameras()`.
  CameraController? _controller;
  bool _initializing = true;
  String? _error;
  bool _capturing = false;
  int _lensIndex = 0;
  late List<String> _photoPaths;

  int get _remaining => CameraPage.maxPhotos - _photoPaths.length;
  int get _taken => _photoPaths.length;

  String? get _userId => AuthService.instance.currentUserId;

  @override
  void initState() {
    super.initState();
    _photoPaths = List<String>.from(widget.initialPhotoPaths);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initCamera();
    });
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      setState(() {
        _error = 'No camera found on this device.';
        _initializing = false;
      });
      return;
    }

    await _openCamera(_lensIndex);
  }

  Future<void> _openCamera(int index) async {
    if (!mounted) return;

    final previous = _controller;
    setState(() {
      _initializing = true;
      _error = null;
      _controller = null;
    });

    // Black frame must paint before disposing native camera (avoids red flash).
    await SchedulerBinding.instance.endOfFrame;

    await previous?.dispose();

    final camera = cameras[index % cameras.length];
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();

      // Skip first unstable frames some devices render as red/green tint.
      await Future<void>.delayed(const Duration(milliseconds: 150));

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } on CameraException catch (e) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _error = e.description ?? 'Could not access the camera.';
        _initializing = false;
      });
    }
  }

  Future<void> _flipCamera() async {
    if (cameras.length < 2 || _capturing) return;
    _lensIndex = (_lensIndex + 1) % cameras.length;
    await _openCamera(_lensIndex);
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }
    if (_remaining <= 0) return;

    if (!mounted) return;
    setState(() => _capturing = true);

    try {
      final file = await controller.takePicture();

      if (mounted) {
        setState(() => _capturing = false);
      } else {
        _capturing = false;
      }

      // Sauvegarde en arrière-plan pour ne pas bloquer le déclencheur.
      unawaited(_persistPhoto(file.path));
    } on CameraException catch (e) {
      _releaseCapturing();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.description ?? 'Could not take photo.')),
      );
    } catch (_) {
      _releaseCapturing();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not take photo.')),
      );
    }
  }

  void _releaseCapturing() {
    if (!mounted) {
      _capturing = false;
      return;
    }
    setState(() => _capturing = false);
  }

  /// Copie le JPEG temporaire vers le rouleau persistant de l'utilisateur.
  Future<void> _persistPhoto(String tempPath) async {
    final userId = _userId;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save photos.')),
      );
      return;
    }

    try {
      final filePath = await RollRepository.savePhoto(
        userId: userId,
        tempPath: tempPath,
        photoIndex: _taken + 1,
        existingPaths: _photoPaths,
      );

      if (!mounted) return;

      setState(() => _photoPaths.add(filePath));

      // Rouleau plein : on remplace la caméra par l'écran de fin.
      if (_remaining == 0) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => RollCompletePage(
              photoPaths: List.unmodifiable(_photoPaths),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save photo.')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),
          _buildGradientOverlay(),
          SafeArea(child: _buildTopBar()),
          _buildRemainingCounter(),
          SafeArea(child: _buildBottomControls()),
          if (_initializing) _buildLoading(),
          if (_error != null) _buildError(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_initializing) {
      return const ColoredBox(color: Colors.black);
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    // previewSize est en paysage : on inverse largeur/hauteur pour le portrait.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize!.height,
        height: controller.value.previewSize!.width,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x66000000),
            Colors.transparent,
            Colors.transparent,
            Color(0x99000000),
          ],
          stops: [0, 0.2, 0.65, 1],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: _CameraColors.softWhite,
          ),
          const Spacer(),
          if (cameras.length > 1)
            IconButton(
              onPressed: _initializing ? null : _flipCamera,
              icon: const Icon(Icons.cameraswitch_rounded),
              color: _CameraColors.softWhite,
            ),
        ],
      ),
    );
  }

  Widget _buildRemainingCounter() {
    return Center(
      child: IgnorePointer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_remaining',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 120,
                fontWeight: FontWeight.w300,
                color: _CameraColors.softWhite.withValues(alpha: 0.92),
                height: 1,
                shadows: const [
                  Shadow(
                    color: _CameraColors.overlay,
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _remaining == 1 ? 'photo remaining' : 'photos remaining',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
                color: _CameraColors.softWhite.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '$_taken / ${CameraPage.maxPhotos}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: _CameraColors.softWhite.withValues(alpha: 0.5),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: GestureDetector(
          onTap: _remaining > 0 && !_capturing && !_initializing
              ? _takePhoto
              : null,
          child: AnimatedOpacity(
            opacity: _remaining > 0 && !_capturing && !_initializing ? 1 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _CameraColors.softWhite,
                  width: 3,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _capturing
                      ? _CameraColors.rose.withValues(alpha: 0.6)
                      : _CameraColors.softWhite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    // Fully opaque — semi-transparent overlay let red camera buffers show through.
    return const ColoredBox(color: Colors.black);
  }

  Widget _buildError() {
    return ColoredBox(
      color: _CameraColors.scaffold,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 48,
                color: _CameraColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: const Color(0xFF2A2628)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
