import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum DeviceOrientation { portrait, landscapeLeft, landscapeRight, upsideDown }

class ViewfinderOverlay extends CustomPainter {
  final Color color;
  final String label;
  final DeviceOrientation deviceOrientation;

  ViewfinderOverlay({
    required this.color,
    required this.label,
    this.deviceOrientation = DeviceOrientation.portrait,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 8;
    const double dashGap = 5;
    const double strokeWidth = 2.5;
    const double padding = 24;

    final dashedPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    _drawDashedRect(canvas, rect, dashedPaint, dashWidth, dashGap);

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

  void _drawDashedRect(
    Canvas canvas,
    Rect rect,
    Paint paint,
    double dashWidth,
    double dashGap,
  ) {
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint, dashWidth, dashGap);
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint, dashWidth, dashGap);
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint, dashWidth, dashGap);
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint, dashWidth, dashGap);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashGap,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = (end - start).distance;
    final unitDx = dx / length;
    final unitDy = dy / length;

    double drawn = 0;
    bool draw = true;

    while (drawn < length) {
      final segmentLength = draw ? dashWidth : dashGap;
      final remaining = length - drawn;
      final len = segmentLength < remaining ? segmentLength : remaining;

      if (draw) {
        canvas.drawLine(
          Offset(start.dx + unitDx * drawn, start.dy + unitDy * drawn),
          Offset(start.dx + unitDx * (drawn + len), start.dy + unitDy * (drawn + len)),
          paint,
        );
      }

      drawn += len;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant ViewfinderOverlay oldDelegate) =>
      color != oldDelegate.color ||
      label != oldDelegate.label ||
      deviceOrientation != oldDelegate.deviceOrientation;
}
