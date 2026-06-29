import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import '../main.dart' show cameras;
import '../services/auth_service.dart';
import '../services/roll_repository.dart';
import 'home_page.dart';
import 'roll_complete_page.dart';

/// Prise de vue : 24 photos en ratio 2:3, overlay minimal.
class CameraPage extends StatefulWidget {
  const CameraPage({super.key, this.initialPhotoPaths = const []});

  static const int maxPhotos = 24;
  static const double captureAspectRatio = 2 / 3;

  final List<String> initialPhotoPaths;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraColors {
  static const scaffold = Color(0xFFFAF6F3);
  static const primary = Color(0xFF9B8B9E);
  static const overlayText = Color(0xBFFFFFFF); // rgba(255,255,255,0.75)
  static const overlayIcon = Color(0xB3FFFFFF); // rgba(255,255,255,0.7)
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  bool _initializing = true;
  String? _error;
  bool _capturing = false;
  int _lensIndex = 0;
  late List<String> _photoPaths;

  int get _taken => _photoPaths.length;

  bool get _canTakePhoto =>
      _taken < CameraPage.maxPhotos && !_capturing && !_initializing;

  String? get _userId => AuthService.instance.currentUserId;

  @override
  void initState() {
    super.initState();
    _photoPaths = List<String>.from(widget.initialPhotoPaths);
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
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
      await Future<void>.delayed(const Duration(milliseconds: 150));

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.unlockCaptureOrientation();

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

  Future<Uint8List> _captureAndCropTo2x3(CameraController controller) async {
    final file = await controller.takePicture();
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode captured image.');
    }

    // Apply EXIF orientation without touching preview orientation.
    final original = img.bakeOrientation(decoded);

    const targetRatio = CameraPage.captureAspectRatio;
    final sourceRatio = original.width / original.height;

    late int cropWidth;
    late int cropHeight;
    late int x;
    late int y;

    if (sourceRatio > targetRatio) {
      cropHeight = original.height;
      cropWidth = (cropHeight * targetRatio).round();
      x = ((original.width - cropWidth) / 2).round();
      y = 0;
    } else {
      cropWidth = original.width;
      cropHeight = (cropWidth / targetRatio).round();
      x = 0;
      y = ((original.height - cropHeight) / 2).round();
    }

    final cropped = img.copyCrop(
      original,
      x: x,
      y: y,
      width: cropWidth,
      height: cropHeight,
    );

    return Uint8List.fromList(img.encodeJpg(cropped, quality: 85));
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }
    if (_taken >= CameraPage.maxPhotos) return;

    setState(() => _capturing = true);

    try {
      final croppedBytes = await _captureAndCropTo2x3(controller);

      if (mounted) {
        setState(() => _capturing = false);
      } else {
        _capturing = false;
      }

      unawaited(_persistPhoto(croppedBytes));
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

  Future<void> _persistPhoto(Uint8List bytes) async {
    final userId = _userId;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save photos.')),
      );
      return;
    }

    try {
      final filePath = await RollRepository.savePhotoFromBytes(
        userId: userId,
        bytes: bytes,
        photoIndex: _taken + 1,
        existingPaths: _photoPaths,
      );

      if (!mounted) return;

      setState(() => _photoPaths.add(filePath));

      if (_photoPaths.length >= CameraPage.maxPhotos) {
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

  Future<void> _confirmExit() async {
    if (_taken > 0) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave this roll?'),
          content: Text(
            'You have taken $_taken photos. Leaving will keep your progress '
            'locally, but you will exit the camera.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    if (mounted) await _leaveCamera();
  }

  Future<void> _leaveCamera() async {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_confirmExit());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildPreview(),
            if (!_initializing && _error == null)
              Positioned.fill(child: _buildOrientedOverlay()),
            if (_initializing) const ColoredBox(color: Colors.black),
            if (_error != null) _buildError(),
          ],
        ),
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

    final previewSize = controller.value.previewSize!;

    // Keep a stable CameraPreview child; only resize the cover box on rotation.
    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final orientation = value.deviceOrientation;
        final isPortrait = orientation == DeviceOrientation.portraitUp ||
            orientation == DeviceOrientation.portraitDown;
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: isPortrait ? previewSize.height : previewSize.width,
            height: isPortrait ? previewSize.width : previewSize.height,
            child: child,
          ),
        );
      },
      child: CameraPreview(controller),
    );
  }

  int _overlayQuarterTurns(DeviceOrientation orientation) {
    return switch (orientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeRight => 1,
      DeviceOrientation.portraitDown => 2,
      DeviceOrientation.landscapeLeft => 3,
    };
  }

  Widget _buildRotatedOverlayLayer(
    Widget overlay,
    int turns,
    BoxConstraints constraints,
  ) {
    if (turns == 0) return overlay;

    final swapDimensions = turns == 1 || turns == 3;
    return Center(
      child: RotatedBox(
        quarterTurns: turns,
        child: SizedBox(
          width: swapDimensions ? constraints.maxHeight : constraints.maxWidth,
          height: swapDimensions ? constraints.maxWidth : constraints.maxHeight,
          child: overlay,
        ),
      ),
    );
  }

  Widget _buildOrientedOverlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: ValueListenableBuilder<CameraValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final deviceOrientation = value.deviceOrientation;
          final turns = _overlayQuarterTurns(deviceOrientation);
          final overlay = _MinimalCameraOverlay(
            photoCount: _taken,
            canFlip: cameras.length > 1,
            flipEnabled: !_initializing,
            canTakePhoto: _canTakePhoto,
            onExit: _confirmExit,
            onFlip: _flipCamera,
            onTakePhoto: _takePhoto,
          );

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            ),
            child: KeyedSubtree(
              key: ValueKey(deviceOrientation),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildRotatedOverlayLayer(
                    overlay,
                    turns,
                    constraints,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return ColoredBox(
      color: _CameraColors.scaffold,
      child: SafeArea(
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
      ),
    );
  }
}

class _MinimalCameraOverlay extends StatelessWidget {
  const _MinimalCameraOverlay({
    required this.photoCount,
    required this.canFlip,
    required this.flipEnabled,
    required this.canTakePhoto,
    required this.onExit,
    required this.onFlip,
    required this.onTakePhoto,
  });

  final int photoCount;
  final bool canFlip;
  final bool flipEnabled;
  final bool canTakePhoto;
  final Future<void> Function() onExit;
  final Future<void> Function() onFlip;
  final Future<void> Function() onTakePhoto;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '$photoCount / ${CameraPage.maxPhotos}',
              style: GoogleFonts.lora(
                fontSize: 24,
                color: _CameraColors.overlayText,
                letterSpacing: 0.65,
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: _SubtleIconButton(
            icon: Icons.close_rounded,
            onPressed: onExit,
          ),
        ),
        if (canFlip)
          Positioned(
            bottom: 30,
            right: 24,
            child: _SubtleIconButton(
              icon: Icons.cameraswitch_rounded,
              onPressed: flipEnabled ? onFlip : null,
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Center(
            child: _ShutterButton(
              enabled: canTakePhoto,
              onTakePhoto: onTakePhoto,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubtleIconButton extends StatelessWidget {
  const _SubtleIconButton({
    required this.icon,
    this.onPressed,
  });

  final IconData icon;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed == null ? null : () => unawaited(onPressed!()),
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 32,
          color: _CameraColors.overlayIcon,
        ),
      ),
    );
  }
}

class _ShutterButton extends StatefulWidget {
  const _ShutterButton({
    required this.enabled,
    required this.onTakePhoto,
  });

  final bool enabled;
  final Future<void> Function() onTakePhoto;

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!widget.enabled) return;
    await _scaleController.forward();
    await _scaleController.reverse();
    await widget.onTakePhoto();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _handleTap : null,
      child: AnimatedOpacity(
        opacity: widget.enabled ? 1 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
