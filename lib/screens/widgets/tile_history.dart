import 'package:auto_size_text/auto_size_text.dart';
import 'package:dominoes/enums/domino_type.dart';
import 'package:dominoes/global/global.dart';
import 'package:dominoes/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

typedef TileHistoryCallback = Function(int index);

class TileHistory extends StatelessWidget {
  const TileHistory({
    super.key,
    required this.index,
    required this.dominoType,
    required this.onTap,
  });

  final int index;
  final DominoType dominoType;
  final TileHistoryCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap(index);
        HapticFeedback.mediumImpact();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        width: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            Global.ui.cornerRadius,
          ),
          color: context.watch<SettingsProvider>().isDarkDominoes
              ? Colors.grey.shade900
              : Colors.white,
        ),
        child: Center(
          child: context.watch<SettingsProvider>().isPips &&
                  dominoType != DominoType.blank
              ? FractionallySizedBox(
                  heightFactor: 0.75,
                  widthFactor: 0.85,
                  child: SvgPicture.asset(
                    'assets/pips/${dominoType.name}_colored.svg',
                  ),
                )
              : AutoSizeText(
                  Global.values.dominoValues[dominoType] != null
                      ? Global.values.dominoValues[dominoType].toString()
                      : context
                          .watch<SettingsProvider>()
                          .doubleZeroValue
                          .toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Global.colors.dominoColors[dominoType] ??
                        context.watch<SettingsProvider>().appAccentColor,
                  ),
                ),
        ),
      ),
    );
  }
}
