import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SkewedHeader extends StatelessWidget {
  const SkewedHeader({
    super.key,
    required this.label,
    this.fontSize,
    this.color,
  });

  final String label;
  final double? fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    return Transform(
      transform: Matrix4.skewX(-0.15),
      child: Container(
        color: color ?? nbt.headerColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            color: nbt.headerTextColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
