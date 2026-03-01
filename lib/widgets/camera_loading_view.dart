import 'dart:math' as math;

import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:dominoes/widgets/dot_grid_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CameraLoadingView extends StatefulWidget {
  const CameraLoadingView({super.key, this.accentColor});

  final Color? accentColor;

  @override
  State<CameraLoadingView> createState() => _CameraLoadingViewState();
}

class _CameraLoadingViewState extends State<CameraLoadingView>
    with TickerProviderStateMixin {
  late final AnimationController _scanController;
  late final AnimationController _cornerController;
  late final AnimationController _textController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _cornerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _cornerController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final accent = widget.accentColor ?? nbt.accentYellow;

    return CustomPaint(
      painter: DotGridPainter(
        backgroundColor: nbt.dotGridBackground,
        dotColor: nbt.dotGridDotColor,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_scanController, _cornerController]),
            builder: (context, _) => CustomPaint(
              painter: _CameraLoadingPainter(
                scanProgress: _scanController.value,
                cornerPulse: _cornerController.value,
                accentColor: accent,
                bracketColor: nbt.borderColor,
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.4, end: 1.0)
                  .animate(_textController),
              child: Transform(
                transform: Matrix4.skewX(-0.15),
                child: Container(
                  color: nbt.headerColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'INITIALIZING',
                    style: GoogleFonts.bricolageGrotesque(
                      color: nbt.headerTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraLoadingPainter extends CustomPainter {
  _CameraLoadingPainter({
    required this.scanProgress,
    required this.cornerPulse,
    required this.accentColor,
    required this.bracketColor,
  });

  final double scanProgress;
  final double cornerPulse;
  final Color accentColor;
  final Color bracketColor;

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 48.0;
    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    _drawCornerBrackets(canvas, rect);
    _drawScanLine(canvas, rect);
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect) {
    final baseLength = math.min(rect.width, rect.height) * 0.12;
    final length = baseLength * (0.8 + 0.2 * cornerPulse);
    const strokeWidth = 3.0;

    final paint = Paint()
      ..color = bracketColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(length, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, length), paint);

    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-length, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, length), paint);

    // Bottom-left
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft + Offset(length, 0), paint);
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft + Offset(0, -length), paint);

    // Bottom-right
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight + Offset(-length, 0), paint);
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight + Offset(0, -length), paint);
  }

  void _drawScanLine(Canvas canvas, Rect rect) {
    final y = rect.top + rect.height * scanProgress;
    const inset = 8.0;

    // Glow
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(
      Offset(rect.left + inset, y),
      Offset(rect.right - inset, y),
      glowPaint,
    );

    // Solid line
    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(rect.left + inset, y),
      Offset(rect.right - inset, y),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CameraLoadingPainter oldDelegate) =>
      scanProgress != oldDelegate.scanProgress ||
      cornerPulse != oldDelegate.cornerPulse ||
      accentColor != oldDelegate.accentColor ||
      bracketColor != oldDelegate.bracketColor;
}
