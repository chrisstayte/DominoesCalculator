import 'dart:typed_data';
import 'dart:ui';

import 'package:dominoes/models/detection_result.dart';

enum PreviewPixelFormat { bgra8888, yuv420 }

class PreviewPlane {
  final Uint8List bytes;
  final int rowStride;
  final int pixelStride;
  const PreviewPlane(
    this.bytes, {
    required this.rowStride,
    required this.pixelStride,
  });
}

class PreviewFrame {
  final int width;
  final int height;
  final int rotation;
  final PreviewPixelFormat format;
  final List<PreviewPlane> planes;
  const PreviewFrame({
    required this.width,
    required this.height,
    required this.rotation,
    required this.format,
    required this.planes,
  });
}

class PreviewDetections {
  final Size imageSize;
  final List<DetectionResult> detections;
  const PreviewDetections({required this.imageSize, required this.detections});
}
