import 'package:dominoes/models/detection_result.dart';
import 'package:flutter/material.dart';

/// Painted in the same portrait scene as CameraPreview, before BoxFit.cover.
/// Thus cropping and rotation move the camera texture and boxes together.
class LiveDetectionOverlay extends CustomPainter {
  final List<DetectionResult> detections;
  final Color color;
  const LiveDetectionOverlay({required this.detections, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      final path = Path();
      if (detection.corners.length == 4) {
        path.addPolygon(
          detection.corners
              .map((p) => Offset(p.dx * size.width, p.dy * size.height))
              .toList(),
          true,
        );
      } else {
        path.addRect(
          Rect.fromLTRB(
            detection.boundingBox.left * size.width,
            detection.boundingBox.top * size.height,
            detection.boundingBox.right * size.width,
            detection.boundingBox.bottom * size.height,
          ),
        );
      }
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: .12));
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
  }

  @override
  bool shouldRepaint(LiveDetectionOverlay oldDelegate) =>
      detections != oldDelegate.detections || color != oldDelegate.color;
}
