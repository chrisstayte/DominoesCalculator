import 'package:dominoes/widgets/scaffold_with_nav_bar.dart';
import 'package:dominoes/widgets/adaptive_workspace.dart';
import 'package:dominoes/enum/app_accent_color.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:dominoes/screens/licenses_screen.dart';
import 'package:dominoes/services/sfx_service.dart';
import 'package:dominoes/services/vibration_service.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
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
    final nbt = NeoBrutalistTheme.of(context);
    final settings = context.watch<LocalSettingsProvider>().localSettings;
    final provider = context.read<LocalSettingsProvider>();
    final vibration = context.read<VibrationService>();

    const gap = SizedBox(height: 16, width: 16);
    final appearance = SectionCard(
      label: 'APPEARANCE',
      titleColor: Colors.teal,
      children: [
        SettingRow(
          label: 'THEME',
          child: SegmentedControl<ThemeMode>(
            options: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
            labels: const ['AUTO', 'LIGHT', 'DARK'],
            selected: settings.themeMode,
            onSelected: provider.setThemeMode,
          ),
        ),
        const ThickDivider(),
        SettingRow(
          label: 'ACCENT',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: AppAccentColor.values.map((accent) {
              final isSelected = settings.appAccentColor == accent;
              return GestureDetector(
                onTap: isSelected
                    ? null
                    : () {
                        provider.setAppAccentColor(accent);
                        context.read<SfxService>().playToggle();
                      },
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: accent.color,
                    border: Border.all(
                      color: nbt.borderColor,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: nbt.shadowColor,
                              offset: const Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        const ThickDivider(),
        SettingRow(
          label: 'SPLASH_SCREEN',
          child: SegmentedControl<bool>(
            options: const [true, false],
            labels: const ['ON', 'OFF'],
            selected: settings.showSplashScreen,
            onSelected: provider.setShowSplashScreen,
          ),
        ),
      ],
    );
    final gameplay = SectionCard(
      label: 'GAMEPLAY',
      titleColor: Colors.blueAccent,
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
        const ThickDivider(),
        SettingRow(
          label: 'PIP_STYLE',
          child: SegmentedControl<bool>(
            options: const [false, true],
            labels: const ['CLASSIC', 'COLORED'],
            selected: settings.coloredPips,
            onSelected: provider.setColoredPips,
          ),
        ),
      ],
    );
    final feedback = SectionCard(
      label: 'FEEDBACK',
      titleColor: Colors.deepOrange,
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
        if (vibration.isSupported) ...[
          const ThickDivider(),
          SettingRow(
            label: 'VIBRATION',
            child: SegmentedControl<bool>(
              options: const [true, false],
              labels: const ['ON', 'OFF'],
              selected: settings.vibration,
              onSelected: (value) {
                provider.setVibration(value);
                vibration.selection();
              },
            ),
          ),
        ],
      ],
    );
    final about = SectionCard(
      label: 'ABOUT',
      titleColor: Colors.purpleAccent,
      children: [
        TappableRow(
          label: 'LICENSES',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LicensesScreen())),
        ),
        const ThickDivider(),
        TappableRow(
          label: 'GITHUB',
          icon: Icons.language,
          onTap: () => launchUrl(
            Uri.parse('https://github.com/chrisstayte/DominoesCalculator'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const ThickDivider(),
        TappableRow(
          label: 'X_(TWITTER)',
          icon: Icons.language,
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
    );
    return Scaffold(
      appBar: AppBar(
        actions: WorkspaceNavigation.actions(context),
        title: Transform(
          transform: Matrix4.skewX(-0.15),
          child: Container(
            color: nbt.headerColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'SETTINGS',
              style: GoogleFonts.bricolageGrotesque(
                color: nbt.headerTextColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: nbt.borderColor, height: 3),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: hasWorkspace(context)
              ? [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(children: [appearance, gap, gameplay]),
                      ),
                      gap,
                      Expanded(child: Column(children: [feedback, gap, about])),
                    ],
                  ),
                ]
              : [appearance, gap, gameplay, gap, feedback, gap, about, gap],
        ),
      ),
    );
  }
}
