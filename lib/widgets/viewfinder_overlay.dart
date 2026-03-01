import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum DeviceOrientation { portrait, landscapeLeft, landscapeRight, upsideDown }

class ViewfinderOverlay extends CustomPainter {
  final Color color;
  final String label;
  final DeviceOrientation deviceOrientation;
  final double? scanProgress;

  ViewfinderOverlay({
    required this.color,
    required this.label,
    this.deviceOrientation = DeviceOrientation.portrait,
    this.scanProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 2.5;
    const double padding = 24;

    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    _drawCornerBrackets(canvas, rect, strokeWidth);

    if (scanProgress != null) {
      _drawScanLine(canvas, rect);
    }

    final textSpan = TextSpan(
      text: label,
      style: GoogleFonts.bricolageGrotesque(
        color: Colors.black,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final badgeWidth = textPainter.width + 14;
    final badgeHeight = textPainter.height + 8;

    // Position badge on the edge that is physically "up"
    // and rotate text to read correctly
    switch (deviceOrientation) {
      case DeviceOrientation.portrait:
        // Badge on top edge, centered
        final badgeLeft = rect.center.dx - badgeWidth / 2;
        final badgeTop = rect.top - badgeHeight / 2;
        _drawBadge(canvas, textPainter, badgeLeft, badgeTop, badgeWidth, badgeHeight, 0);

      case DeviceOrientation.upsideDown:
        // Badge on bottom edge, centered, text rotated 180°
        final badgeLeft = rect.center.dx - badgeWidth / 2;
        final badgeTop = rect.bottom - badgeHeight / 2;
        _drawBadge(canvas, textPainter, badgeLeft, badgeTop, badgeWidth, badgeHeight, math.pi);

      case DeviceOrientation.landscapeLeft:
        // Badge on left edge, centered vertically, text rotated -90°
        final badgeLeft = rect.left - badgeHeight / 2;
        final badgeTop = rect.center.dy - badgeWidth / 2;
        _drawBadgeRotated(canvas, textPainter, badgeLeft, badgeTop, badgeWidth, badgeHeight, -math.pi / 2);

      case DeviceOrientation.landscapeRight:
        // Badge on right edge, centered vertically, text rotated 90°
        final badgeLeft = rect.right - badgeHeight / 2;
        final badgeTop = rect.center.dy - badgeWidth / 2;
        _drawBadgeRotated(canvas, textPainter, badgeLeft, badgeTop, badgeWidth, badgeHeight, math.pi / 2);
    }
  }

  void _drawBadge(
    Canvas canvas,
    TextPainter textPainter,
    double badgeLeft,
    double badgeTop,
    double badgeWidth,
    double badgeHeight,
    double rotation,
  ) {
    final center = Offset(badgeLeft + badgeWidth / 2, badgeTop + badgeHeight / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawRect(
      Rect.fromLTWH(badgeLeft, badgeTop, badgeWidth, badgeHeight),
      Paint()..color = color,
    );
    textPainter.paint(canvas, Offset(badgeLeft + 7, badgeTop + 4));

    canvas.restore();
  }

  void _drawBadgeRotated(
    Canvas canvas,
    TextPainter textPainter,
    double anchorX,
    double anchorY,
    double badgeWidth,
    double badgeHeight,
    double rotation,
  ) {
    // For sideways orientations, we swap width/height for positioning
    // but draw the badge in its normal orientation then rotate
    final centerX = anchorX + badgeHeight / 2;
    final centerY = anchorY + badgeWidth / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(rotation);
    canvas.translate(-badgeWidth / 2, -badgeHeight / 2);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, badgeWidth, badgeHeight),
      Paint()..color = color,
    );
    textPainter.paint(canvas, const Offset(7, 4));

    canvas.restore();
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, double strokeWidth) {
    final bracketLength = math.min(rect.width, rect.height) * 0.12;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(bracketLength, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, bracketLength), paint);

    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-bracketLength, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, bracketLength), paint);

    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(bracketLength, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -bracketLength), paint);

    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-bracketLength, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -bracketLength), paint);
  }

  void _drawScanLine(Canvas canvas, Rect rect) {
    final y = rect.top + rect.height * scanProgress!;
    const inset = 8.0;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(
      Offset(rect.left + inset, y),
      Offset(rect.right - inset, y),
      glowPaint,
    );

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(rect.left + inset, y),
      Offset(rect.right - inset, y),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant ViewfinderOverlay oldDelegate) =>
      color != oldDelegate.color ||
      label != oldDelegate.label ||
      deviceOrientation != oldDelegate.deviceOrientation ||
      scanProgress != oldDelegate.scanProgress;
}
