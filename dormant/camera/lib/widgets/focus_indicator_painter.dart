import 'package:flutter/material.dart';

class FocusIndicatorPainter extends CustomPainter {
  FocusIndicatorPainter({
    required this.point,
    required this.color,
    required this.progress,
  });

  final Offset point;
  final Color color;
  final double progress; // 0→1: brackets contract inward, then fade out

  @override
  void paint(Canvas canvas, Size size) {
    // Bracket size contracts from expanded to tight
    const double bracketLength = 12.0;
    const double strokeWidth = 2.5;
    final double startHalf = 28.0; // initial half-size of the square
    final double endHalf = 14.0; // final half-size of the square
    final double half = startHalf + (endHalf - startHalf) * progress;

    // Fade out in the last 40% of the animation
    final double opacity = progress < 0.6
        ? 1.0
        : 1.0 - ((progress - 0.6) / 0.4);

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    final topLeft = Offset(point.dx - half, point.dy - half);
    final topRight = Offset(point.dx + half, point.dy - half);
    final bottomLeft = Offset(point.dx - half, point.dy + half);
    final bottomRight = Offset(point.dx + half, point.dy + half);

    // Top-left
    canvas.drawLine(topLeft, topLeft + Offset(bracketLength, 0), paint);
    canvas.drawLine(topLeft, topLeft + Offset(0, bracketLength), paint);

    // Top-right
    canvas.drawLine(topRight, topRight + Offset(-bracketLength, 0), paint);
    canvas.drawLine(topRight, topRight + Offset(0, bracketLength), paint);

    // Bottom-left
    canvas.drawLine(bottomLeft, bottomLeft + Offset(bracketLength, 0), paint);
    canvas.drawLine(bottomLeft, bottomLeft + Offset(0, -bracketLength), paint);

    // Bottom-right
    canvas.drawLine(bottomRight, bottomRight + Offset(-bracketLength, 0), paint);
    canvas.drawLine(bottomRight, bottomRight + Offset(0, -bracketLength), paint);
  }

  @override
  bool shouldRepaint(covariant FocusIndicatorPainter oldDelegate) =>
      point != oldDelegate.point ||
      color != oldDelegate.color ||
      progress != oldDelegate.progress;
}
