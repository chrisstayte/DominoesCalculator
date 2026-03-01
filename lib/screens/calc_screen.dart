import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:dominoes/providers/game_log_provider.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:dominoes/services/sfx_service.dart';
import 'package:dominoes/services/vibration_service.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:dominoes/widgets/action_button.dart';
import 'package:dominoes/widgets/domino_pip.dart';
import 'package:dominoes/widgets/dot_grid_painter.dart';
import 'package:dominoes/widgets/pip_history_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<Widget> _buildDominoTiles(
    BuildContext context,
    NumberStyle numberStyle,
    CalculatorProvider calculator,
  ) {
    final sfx = context.read<SfxService>();
    final vibration = context.read<VibrationService>();

    final orderedPips = [
      ...DominoPips.values.skip(12).take(4), // Row 1 (top): 12, 13, 14, 15
      ...DominoPips.values.skip(8).take(4), // Row 2: 8, 9, 10, 11
      ...DominoPips.values.skip(4).take(4), // Row 3: 4, 5, 6, 7
      ...DominoPips.values.take(4), // Row 4 (bottom): 0, 1, 2, 3
    ];

    return orderedPips.map((pip) {
      return DominoPip(
        pip: pip,
        numberStyle: numberStyle,
        onTap: () {
          sfx.playTap();
          vibration.light();
          calculator.addPip(pip);
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final settings = context.watch<LocalSettingsProvider>().localSettings;
    final calculator = context.watch<CalculatorProvider>();
    final sfx = context.read<SfxService>();
    final vibration = context.read<VibrationService>();
    final total = calculator.total(freePointValue: settings.freePointValue);

    return Scaffold(
      appBar: AppBar(
        title: Transform(
          transform: Matrix4.skewX(-0.15),
          child: Container(
            color: nbt.headerColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'DOMINO_CALC',
              style: GoogleFonts.bricolageGrotesque(
                color: nbt.headerTextColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/icons/history.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(nbt.iconColor, BlendMode.srcIn),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ChangeNotifierProvider.value(
                  value: calculator,
                  child: PipHistoryDialog(
                    freePointValue: settings.freePointValue,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: nbt.borderColor, height: 3),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: DotGridPainter(
                backgroundColor: nbt.dotGridBackground,
                dotColor: nbt.dotGridDotColor,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform(
                            transform: Matrix4.skewX(-0.15),
                            child: Container(
                              color: nbt.headerColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Text(
                                'CURRENT_SCORE',
                                style: GoogleFonts.bricolageGrotesque(
                                  color: nbt.headerTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$total',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 128,
                              fontWeight: FontWeight.w900,
                              color: nbt.bodyTextColor,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ActionButton(
                            icon: Icons.backspace_outlined,
                            color: nbt.accentRed,
                            foregroundColor: Colors.black,
                            onTap: () {
                              sfx.playDelete();
                              vibration.medium();
                              calculator.removeLast();
                            },
                            onLongPressComplete: () {
                              sfx.playClear();
                              vibration.heavy();
                              calculator.clear();
                            },
                            onShakeTick: () => vibration.light(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ActionButton(
                            icon: Icons.save_outlined,
                            color: nbt.accentGreen,
                            foregroundColor: Colors.black,
                            onTap: () {
                              if (calculator.selectedPips.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No pips to save'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                return;
                              }
                              sfx.playSuccess();
                              vibration.medium();
                              context.read<GameLogProvider>().saveGame(
                                calculator,
                                settings.freePointValue,
                              );
                              calculator.clear();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: settings.appAccentColor.color,
              border: Border(top: BorderSide(color: nbt.borderColor, width: 3)),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.all(1),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                crossAxisCount: 4,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                children: [
                  ..._buildDominoTiles(context, settings.numberStyle, calculator),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
