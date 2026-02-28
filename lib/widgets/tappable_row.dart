import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TappableRow extends StatelessWidget {
  const TappableRow({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.chevron_right,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
