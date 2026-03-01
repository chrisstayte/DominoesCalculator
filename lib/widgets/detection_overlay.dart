import 'package:dominoes/models/detection_result.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DetectionOverlay extends CustomPainter {
  final List<DetectionResult> detections;
  final Color borderColor;
  final Color textColor;
  final Color badgeColor;
  final bool showConfidence;

  DetectionOverlay({
    required this.detections,
    required this.borderColor,
    required this.textColor,
    required this.badgeColor,
    required this.showConfidence,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final badgePaint = Paint()
      ..color = badgeColor
      ..style = PaintingStyle.fill;

    for (final detection in detections) {
      final rect = Rect.fromLTRB(
        detection.boundingBox.left * size.width,
        detection.boundingBox.top * size.height,
        detection.boundingBox.right * size.width,
        detection.boundingBox.bottom * size.height,
      );

      canvas.drawRect(rect, boxPaint);

      final labelText = showConfidence
          ? '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%'
          : detection.label;

      final textSpan = TextSpan(
        text: labelText,
        style: GoogleFonts.bricolageGrotesque(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeRect = Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - 6,
        textPainter.width + 10,
        textPainter.height + 6,
      );

      canvas.drawRect(badgeRect, badgePaint);
      // Badge border
      canvas.drawRect(
        badgeRect,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      textPainter.paint(canvas, Offset(rect.left + 5, rect.top - textPainter.height - 3));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionOverlay oldDelegate) =>
      detections != oldDelegate.detections ||
      showConfidence != oldDelegate.showConfidence;
}
