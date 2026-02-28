import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LicenseDetailScreen extends StatelessWidget {
  const LicenseDetailScreen({
    super.key,
    required this.packageName,
    required this.entries,
  });

  final String packageName;
  final List<LicenseEntry> entries;

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Transform(
          transform: Matrix4.skewX(-0.15),
          child: Container(
            color: nbt.headerColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              packageName.toUpperCase(),
              style: GoogleFonts.bricolageGrotesque(
                color: nbt.headerTextColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: nbt.iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: nbt.borderColor, height: 3),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < entries.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 16),
                    Container(height: 2, color: nbt.borderColor),
                    const SizedBox(height: 16),
                  ],
                  ...entries[i].paragraphs.map(
                    (p) => Padding(
                      padding: EdgeInsets.only(
                        left: p.indent * 16.0,
                        bottom: 8,
                      ),
                      child: Text(
                        p.text,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
