import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewfinderOverlay extends CustomPainter {
  final Color color;
  final String label;

  ViewfinderOverlay({required this.color, required this.label});

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

    // Draw dashed rectangle
    _drawDashedRect(canvas, rect, dashedPaint, dashWidth, dashGap);

    // Label badge centered at top of rect
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
    final badgeLeft = rect.center.dx - badgeWidth / 2;
    final badgeTop = rect.top - badgeHeight / 2;

    final badgeRect = Rect.fromLTWH(
      badgeLeft,
      badgeTop,
      badgeWidth,
      badgeHeight,
    );

    canvas.drawRect(badgeRect, Paint()..color = color);
    textPainter.paint(canvas, Offset(badgeLeft + 7, badgeTop + 4));
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
      color != oldDelegate.color || label != oldDelegate.label;
}
