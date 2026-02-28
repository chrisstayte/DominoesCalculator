import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings =
        context.watch<LocalSettingsProvider>().localSettings;
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
            _SectionCard(
              label: 'GAMEPLAY',
              children: [
                _SettingRow(
                  label: 'FREE_POINT_VALUE',
                  child: _SegmentedControl<int>(
                    options: const [0, 25, 50],
                    labels: const ['0', '25', '50'],
                    selected: settings.freePointValue,
                    onSelected: provider.setFreePointValue,
                  ),
                ),
                const _Divider(),
                _SettingRow(
                  label: 'DISPLAY_STYLE',
                  child: _SegmentedControl<NumberStyle>(
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
            _SectionCard(
              label: 'FEEDBACK',
              children: [
                _SettingRow(
                  label: 'SOUND_EFFECTS',
                  child: _SegmentedControl<bool>(
                    options: const [true, false],
                    labels: const ['ON', 'OFF'],
                    selected: settings.soundEffects,
                    onSelected: provider.setSoundEffects,
                  ),
                ),
                const _Divider(),
                _SettingRow(
                  label: 'VIBRATION',
                  child: _SegmentedControl<bool>(
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
            _SectionCard(
              label: 'ABOUT',
              children: [
                _TappableRow(
                  label: 'LICENSES',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Domino Calc',
                  ),
                ),
                const _Divider(),
                _TappableRow(
                  label: 'GITHUB',
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://github.com/chrisstayte/DominoesCalculator',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const _Divider(),
                _TappableRow(
                  label: 'X_(TWITTER)',
                  onTap: () => launchUrl(
                    Uri.parse('https://x.com/chrisstayte'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const _Divider(),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version =
                        snapshot.data?.version ?? '...';
                    final build =
                        snapshot.data?.buildNumber ?? '';
                    return _InfoRow(
                      label: 'VERSION',
                      value: build.isNotEmpty
                          ? '$version+$build'
                          : version,
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

// ---------------------------------------------------------------------------
// Section card with skewed header and offset shadow
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform(
          transform: Matrix4.skewX(-0.15),
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              label,
              style: GoogleFonts.bricolageGrotesque(
                color: Colors.white,
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
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(4, 4),
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

// ---------------------------------------------------------------------------
// Setting row — label on left, control on right
// ---------------------------------------------------------------------------

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tappable row with chevron
// ---------------------------------------------------------------------------

class _TappableRow extends StatelessWidget {
  const _TappableRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Non-interactive info row (e.g. version)
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Segmented control (mirrors bottom nav bar toggle pattern)
// ---------------------------------------------------------------------------

class _SegmentedControl<T> extends StatelessWidget {
  const _SegmentedControl({
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<T> options;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(options.length, (i) {
            final isSelected = options[i] == selected;
            return GestureDetector(
              onTap: () => onSelected(options[i]),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  border: i > 0
                      ? const Border(
                          left: BorderSide(color: Colors.black, width: 3),
                        )
                      : null,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Text(
                  labels[i],
                  style: GoogleFonts.bricolageGrotesque(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2px divider between rows
// ---------------------------------------------------------------------------

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 2, color: Colors.black);
  }
}
