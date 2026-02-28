import 'package:dominoes/screens/license_detail_screen.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:dominoes/widgets/tappable_row.dart';
import 'package:dominoes/widgets/thick_divider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  final Map<String, List<LicenseEntry>> _licenses = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        _licenses.putIfAbsent(package, () => []).add(entry);
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final sortedPackages = _licenses.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Transform(
          transform: Matrix4.skewX(-0.15),
          child: Container(
            color: nbt.headerColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'LICENSES',
              style: GoogleFonts.bricolageGrotesque(
                color: nbt.headerTextColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
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
      body: !_loaded
          ? Center(
              child: Text(
                'LOADING...',
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 1,
              itemBuilder: (context, _) => Container(
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
                child: Column(
                  children: [
                    for (int i = 0; i < sortedPackages.length; i++) ...[
                      if (i > 0) const ThickDivider(),
                      TappableRow(
                        label: sortedPackages[i].toUpperCase(),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LicenseDetailScreen(
                                packageName: sortedPackages[i],
                                entries: _licenses[sortedPackages[i]]!,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
