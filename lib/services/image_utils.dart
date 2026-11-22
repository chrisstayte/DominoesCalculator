import 'dart:typed_data';
import 'dart:ui';

import 'package:dominoes/services/domino_geometry.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  static img.Image decodeUpright(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('Unable to read photo.');
    return img
        .bakeOrientation(decoded)
        .convert(numChannels: 3, format: img.Format.uint8);
  }

  /// OpenCV half-pixel resize, RGB CHW, padding 114, normalization 0..1.
  static Float32List detectorInput(img.Image image, DominoLetterbox box) {
    final plane = box.size * box.size;
    final result = Float32List(plane * 3)..fillRange(0, plane * 3, 114 / 255);
    for (var y = 0; y < box.resizedHeight; y++) {
      final sy = ((y + 0.5) * image.height / box.resizedHeight - 0.5).clamp(
        0.0,
        image.height - 1.0,
      );
      final y0 = sy.floor(), y1 = (y0 + 1).clamp(0, image.height - 1);
      final dy = sy - y0;
      for (var x = 0; x < box.resizedWidth; x++) {
        final sx = ((x + 0.5) * image.width / box.resizedWidth - 0.5).clamp(
          0.0,
          image.width - 1.0,
        );
        final x0 = sx.floor(), x1 = (x0 + 1).clamp(0, image.width - 1);
        final dx = sx - x0;
        final p00 = image.getPixel(x0, y0), p10 = image.getPixel(x1, y0);
        final p01 = image.getPixel(x0, y1), p11 = image.getPixel(x1, y1);
        final index = (y + box.top) * box.size + x + box.left;
        for (var c = 0; c < 3; c++) {
          final value =
              (p00[c] * (1 - dx) + p10[c] * dx) * (1 - dy) +
              (p01[c] * (1 - dx) + p11[c] * dx) * dy;
          result[c * plane + index] = value.round() / 255;
        }
      }
    }
    return result;
  }

  /// Perspective rectification to 256x128, then RGB 128x128 halves.
  /// Match OpenCV INTER_LINEAR 1/32-pixel sampling and constant border 127.
  /// The classifier embeds scaling; external values must stay at 0..255.
  static List<Float32List> tileHalves(img.Image image, List<Offset> corners) {
    final h = tileHomography(corners);
    final halves = [Float32List(128 * 128 * 3), Float32List(128 * 128 * 3)];
    num channel(int x, int y, int c) =>
        x < 0 || y < 0 || x >= image.width || y >= image.height
        ? 127
        : image.getPixel(x, y)[c];
    for (var y = 0; y < 128; y++) {
      for (var x = 0; x < 256; x++) {
        final divisor = h[6] * x + h[7] * y + 1;
        if (divisor.abs() < 1e-10) throw ArgumentError('Degenerate tile.');
        final sx = roundEven((h[0] * x + h[1] * y + h[2]) / divisor * 32);
        final sy = roundEven((h[3] * x + h[4] * y + h[5]) / divisor * 32);
        final x0 = sx >> 5, y0 = sy >> 5;
        final dx = sx & 31, dy = sy & 31;
        final half = halves[x ~/ 128];
        final index = (y * 128 + x % 128) * 3;
        for (var c = 0; c < 3; c++) {
          final value =
              channel(x0, y0, c) * (32 - dx) * (32 - dy) +
              channel(x0 + 1, y0, c) * dx * (32 - dy) +
              channel(x0, y0 + 1, c) * (32 - dx) * dy +
              channel(x0 + 1, y0 + 1, c) * dx * dy;
          half[index + c] = ((value.toInt() + 512) >> 10).toDouble();
        }
      }
    }
    return halves;
  }
}
