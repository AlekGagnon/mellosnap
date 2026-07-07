import 'dart:io';

import 'package:image/image.dart' as img;

/// Builds a square splash icon: Mello wordmark on #FFF9F6, no transparency halos.
Future<void> main() async {
  final cream = img.ColorRgb8(255, 249, 246);
  const canvasSize = 1152;
  const logoWidthFraction = 0.62;

  final logoFile = File('lib/images/logo-text.png');
  final logo = img.decodePng(await logoFile.readAsBytes());
  if (logo == null) {
    stderr.writeln('Could not decode lib/images/logo-text.png');
    exit(1);
  }

  final cleaned = img.Image.from(logo);
  for (var y = 0; y < cleaned.height; y++) {
    for (var x = 0; x < cleaned.width; x++) {
      final pixel = cleaned.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final a = pixel.a.toInt();
      if (a < 16) {
        cleaned.setPixelRgba(x, y, 255, 249, 246, 255);
        continue;
      }
      final isNearWhite = r > 210 && g > 210 && b > 210;
      final isNearBlack = r < 40 && g < 40 && b < 40;
      if (isNearWhite || isNearBlack) {
        cleaned.setPixelRgba(x, y, 255, 249, 246, 255);
      }
    }
  }

  final targetWidth = (canvasSize * logoWidthFraction).round();
  final resized = img.copyResize(
    cleaned,
    width: targetWidth,
    height: (cleaned.height * targetWidth / cleaned.width).round(),
    interpolation: img.Interpolation.linear,
  );

  final square = img.Image(width: canvasSize, height: canvasSize);
  img.fill(square, color: cream);
  img.compositeImage(
    square,
    resized,
    dstX: (canvasSize - resized.width) ~/ 2,
    dstY: (canvasSize - resized.height) ~/ 2,
  );

  final out = File('lib/images/splash_icon.png');
  await out.writeAsBytes(img.encodePng(square));
  stdout.writeln('Wrote ${out.path} (${square.width}x${square.height})');
}
