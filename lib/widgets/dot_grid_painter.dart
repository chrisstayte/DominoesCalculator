import 'package:flutter/material.dart';

class DotGridPainter extends CustomPainter {
  DotGridPainter({
    required this.backgroundColor,
    required this.dotColor,
    this.centered = false,
  });

  final Color backgroundColor;
  final Color dotColor;
  final bool centered;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 16.0;
    const radius = 2.0;

    final startX = centered ? (size.width / 2 + 8) % spacing : spacing;
    final startY = centered ? (size.height / 2 + 8) % spacing : spacing;
    for (double x = startX; x < size.width; x += spacing) {
      for (double y = startY; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) =>
      centered != oldDelegate.centered ||
      backgroundColor != oldDelegate.backgroundColor ||
      dotColor != oldDelegate.dotColor;
}
