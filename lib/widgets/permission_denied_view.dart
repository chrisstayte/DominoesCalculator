import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:dominoes/widgets/action_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({super.key, required this.onRequestPermission});

  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: nbt.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'CAMERA ACCESS REQUIRED',
              style: GoogleFonts.bricolageGrotesque(
                color: nbt.bodyTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Grant camera permission to detect domino pips for scoring.',
              style: GoogleFonts.bricolageGrotesque(
                color: nbt.secondaryTextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ActionButton(
                icon: Icons.camera_alt,
                color: nbt.accentYellow,
                foregroundColor: Colors.black,
                onTap: onRequestPermission,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
