import 'dart:typed_data';
import 'dart:math' as math;
import 'package:dominoes/models/preview_frame.dart';
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

  /// Decode only a detector-sized live frame; never retain or classify a stream
  /// of full camera photos. Plane strides are independent on Android YUV420.
  static img.Image previewImage(PreviewFrame frame) {
    if (frame.width <= 0 ||
        frame.height <= 0 ||
        frame.rotation % 90 != 0 ||
        frame.planes.length !=
            (frame.format == PreviewPixelFormat.bgra8888 ? 1 : 3)) {
      throw const FormatException('Unsupported camera frame.');
    }
    final scale = math.min(1.0, 640 / math.max(frame.width, frame.height));
    final width = math.max(1, (frame.width * scale).round());
    final height = math.max(1, (frame.height * scale).round());
    final image = img.Image(width: width, height: height);
    int byte(int plane, int x, int y, [int channel = 0]) {
      final p = frame.planes[plane];
      return p.bytes[y * p.rowStride + x * p.pixelStride + channel];
    }

    for (var y = 0; y < height; y++) {
      final sy = ((y + .5) * frame.height / height).floor().clamp(
        0,
        frame.height - 1,
      );
      for (var x = 0; x < width; x++) {
        final sx = ((x + .5) * frame.width / width).floor().clamp(
          0,
          frame.width - 1,
        );
        if (frame.format == PreviewPixelFormat.bgra8888) {
          image.setPixelRgb(
            x,
            y,
            byte(0, sx, sy, 2),
            byte(0, sx, sy, 1),
            byte(0, sx, sy),
          );
        } else {
          final luminance = byte(0, sx, sy).toDouble();
          final u = byte(1, sx ~/ 2, sy ~/ 2) - 128;
          final v = byte(2, sx ~/ 2, sy ~/ 2) - 128;
          // Android camera YUV420 is full-range YCbCr, matching its image stream.
          image.setPixelRgb(
            x,
            y,
            (luminance + 1.402 * v).round().clamp(0, 255),
            (luminance - .344136 * u - .714136 * v).round().clamp(0, 255),
            (luminance + 1.772 * u).round().clamp(0, 255),
          );
        }
      }
    }
    return frame.rotation % 360 == 0
        ? image
        : img.copyRotate(image, angle: frame.rotation);
  }

  /// Size of the upright, detector-sized live frame that [previewImage] and
  /// [previewDetectorInput] produce. Detections are reported in this space.
  static Size previewSize(PreviewFrame frame) {
    final scale = math.min(1.0, 640 / math.max(frame.width, frame.height));
    final width = math.max(1, (frame.width * scale).round());
    final height = math.max(1, (frame.height * scale).round());
    return frame.rotation % 180 == 0
        ? Size(width.toDouble(), height.toDouble())
        : Size(height.toDouble(), width.toDouble());
  }

  /// Fast live path: sample camera planes straight into the letterboxed
  /// detector tensor in one pass. Equivalent to [previewImage] followed by
  /// [detectorInput] for a <=640px frame, without building an intermediate
  /// image or doing per-pixel object lookups (the dominant live-frame cost).
  static Float32List previewDetectorInput(
    PreviewFrame frame,
    DominoLetterbox box,
  ) {
    if (frame.width <= 0 ||
        frame.height <= 0 ||
        frame.rotation % 90 != 0 ||
        frame.planes.length !=
            (frame.format == PreviewPixelFormat.bgra8888 ? 1 : 3)) {
      throw const FormatException('Unsupported camera frame.');
    }
    final rotation = ((frame.rotation % 360) + 360) % 360;
    // Upright frame dimensions before downscaling.
    final uprightWidth = rotation % 180 == 0 ? frame.width : frame.height;
    final uprightHeight = rotation % 180 == 0 ? frame.height : frame.width;
    final plane = box.size * box.size;
    final result = Float32List(plane * 3)..fillRange(0, plane * 3, 114 / 255);
    final bgra = frame.format == PreviewPixelFormat.bgra8888;
    final p0 = frame.planes[0];
    final b0 = p0.bytes, r0 = p0.rowStride, s0 = p0.pixelStride;
    final p1 = bgra ? null : frame.planes[1];
    final p2 = bgra ? null : frame.planes[2];
    const inv = 1 / 255;
    for (var y = 0; y < box.resizedHeight; y++) {
      final uy = ((y + .5) * uprightHeight / box.resizedHeight).floor().clamp(
        0,
        uprightHeight - 1,
      );
      final row = (y + box.top) * box.size + box.left;
      for (var x = 0; x < box.resizedWidth; x++) {
        final ux = ((x + .5) * uprightWidth / box.resizedWidth).floor().clamp(
          0,
          uprightWidth - 1,
        );
        // Inverse of a clockwise rotation by [rotation] degrees.
        final int sx, sy;
        switch (rotation) {
          case 90:
            sx = uy;
            sy = frame.height - 1 - ux;
          case 180:
            sx = frame.width - 1 - ux;
            sy = frame.height - 1 - uy;
          case 270:
            sx = frame.width - 1 - uy;
            sy = ux;
          default:
            sx = ux;
            sy = uy;
        }
        final int r, g, b;
        if (bgra) {
          final i = sy * r0 + sx * s0;
          b = b0[i];
          g = b0[i + 1];
          r = b0[i + 2];
        } else {
          final luminance = b0[sy * r0 + sx * s0].toDouble();
          final cx = sx ~/ 2, cy = sy ~/ 2;
          final u = p1!.bytes[cy * p1.rowStride + cx * p1.pixelStride] - 128;
          final v = p2!.bytes[cy * p2.rowStride + cx * p2.pixelStride] - 128;
          r = (luminance + 1.402 * v).round().clamp(0, 255);
          g = (luminance - .344136 * u - .714136 * v).round().clamp(0, 255);
          b = (luminance + 1.772 * u).round().clamp(0, 255);
        }
        final index = row + x;
        result[index] = r * inv;
        result[plane + index] = g * inv;
        result[2 * plane + index] = b * inv;
      }
    }
    return result;
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
