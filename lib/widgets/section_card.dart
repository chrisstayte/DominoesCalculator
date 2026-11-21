import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.label,
    required this.children,
    this.titleColor,
  });

  final String label;
  final List<Widget> children;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final resolvedTitleColor = titleColor ?? nbt.headerColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform(
          transform: Matrix4.skewX(-0.15),
          child: Container(
            color: resolvedTitleColor,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              label,
              style: GoogleFonts.bricolageGrotesque(
                color: nbt.headerTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: nbt.cardColor,
            border: Border.all(color: nbt.borderColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: nbt.shadowColor,
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
