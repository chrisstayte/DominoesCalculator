import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:dominoes/widgets/action_button.dart';
import 'package:dominoes/widgets/domino_pip.dart';
import 'package:dominoes/widgets/dot_grid_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<Widget> _buildDominoTiles(
    NumberStyle numberStyle,
    CalculatorProvider calculator,
  ) {
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
        onTap: () => calculator.addPip(pip),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<LocalSettingsProvider>().localSettings;
    final calculator = context.watch<CalculatorProvider>();
    final total = calculator.total(freePointValue: settings.freePointValue);

    return Scaffold(
      appBar: AppBar(
        title: Transform(
          transform: Matrix4.skewX(-0.15),
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'DOMINO_CALC',
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
      body: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: DotGridPainter(),
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
                              color: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Text(
                                'CURRENT_SCORE',
                                style: GoogleFonts.bricolageGrotesque(
                                  color: Colors.white,
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
                              color: Colors.black,
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
                            color: Color(0xFFFF4344),
                            foregroundColor: Colors.black,
                            onTap: () => calculator.removeLast(),
                            onLongPressComplete: () => calculator.clear(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ActionButton(
                            icon: Icons.save_outlined,
                            color: Color(0xFF45FF45),
                            foregroundColor: Colors.black,
                            onTap: () {},
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
              color: Colors.yellow.shade600,
              border: const Border(top: BorderSide(color: Colors.black, width: 3)),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.all(1),
              child: GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                crossAxisCount: 4,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                children: [
                  ..._buildDominoTiles(settings.numberStyle, calculator),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
