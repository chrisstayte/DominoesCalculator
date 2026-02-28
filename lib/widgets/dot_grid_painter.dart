import 'package:flutter/material.dart';

class DotGridPainter extends CustomPainter {
  DotGridPainter({required this.backgroundColor, required this.dotColor});

  final Color backgroundColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 16.0;
    const radius = 2.0;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) =>
      backgroundColor != oldDelegate.backgroundColor ||
      dotColor != oldDelegate.dotColor;
}
