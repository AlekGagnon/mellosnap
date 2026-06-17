import 'package:flutter/material.dart';

/// Wordmark from [assetPath].
class MelloLogo extends StatelessWidget {
  const MelloLogo({
    super.key,
    this.height = 48,
    this.alignment = Alignment.center,
  });

  static const assetPath = 'lib/images/logo-text.png';

  final double height;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Image.asset(
        assetPath,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
