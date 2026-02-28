import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:dominoes/screens/licenses_screen.dart';
import 'package:dominoes/widgets/info_row.dart';
import 'package:dominoes/widgets/section_card.dart';
import 'package:dominoes/widgets/segmented_control.dart';
import 'package:dominoes/widgets/setting_row.dart';
import 'package:dominoes/widgets/tappable_row.dart';
import 'package:dominoes/widgets/thick_divider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<LocalSettingsProvider>().localSettings;
    final provider = context.read<LocalSettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Transform(
          transform: Matrix4.skewX(-0.15),
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'SETTINGS',
              style: GoogleFonts.bricolageGrotesque(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: Colors.black, height: 3),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GAMEPLAY Section
            SectionCard(
              label: 'GAMEPLAY',
              children: [
                SettingRow(
                  label: 'FREE_POINT_VALUE',
                  child: SegmentedControl<int>(
                    options: const [0, 25, 50],
                    labels: const ['0', '25', '50'],
                    selected: settings.freePointValue,
                    onSelected: provider.setFreePointValue,
                  ),
                ),
                const ThickDivider(),
                SettingRow(
                  label: 'DISPLAY_STYLE',
                  child: SegmentedControl<NumberStyle>(
                    options: NumberStyle.values,
                    labels: const ['PIPS', 'NUMBERS'],
                    selected: settings.numberStyle,
                    onSelected: provider.setNumberStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // FEEDBACK Section
            SectionCard(
              label: 'FEEDBACK',
              children: [
                SettingRow(
                  label: 'SOUND_EFFECTS',
                  child: SegmentedControl<bool>(
                    options: const [true, false],
                    labels: const ['ON', 'OFF'],
                    selected: settings.soundEffects,
                    onSelected: provider.setSoundEffects,
                  ),
                ),
                const ThickDivider(),
                SettingRow(
                  label: 'VIBRATION',
                  child: SegmentedControl<bool>(
                    options: const [true, false],
                    labels: const ['ON', 'OFF'],
                    selected: settings.vibration,
                    onSelected: provider.setVibration,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ABOUT Section
            SectionCard(
              label: 'ABOUT',
              children: [
                TappableRow(
                  label: 'LICENSES',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LicensesScreen(),
                    ),
                  ),
                ),
                const ThickDivider(),
                TappableRow(
                  label: 'GITHUB',
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://github.com/chrisstayte/DominoesCalculator',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const ThickDivider(),
                TappableRow(
                  label: 'X_(TWITTER)',
                  onTap: () => launchUrl(
                    Uri.parse('https://x.com/chrisstayte'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const ThickDivider(),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? '...';
                    final build = snapshot.data?.buildNumber ?? '';
                    return InfoRow(
                      label: 'VERSION',
                      value: build.isNotEmpty ? '$version+$build' : version,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
