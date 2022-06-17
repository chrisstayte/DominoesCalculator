import 'package:auto_size_text/auto_size_text.dart';
import 'package:dominoes/enums/domino_type.dart';
import 'package:dominoes/global/global.dart';
import 'package:dominoes/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

typedef KeypadKeyCallback = Function(DominoType dominoType);

class KeypadKey extends StatelessWidget {
  const KeypadKey({
    Key? key,
    required this.dominoType,
    required this.onTap,
  }) : super(key: key);

  final DominoType dominoType;
  final KeypadKeyCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(1),
        color: context.watch<SettingsProvider>().isDarkDominoes
            ? Colors.grey.shade900
            : Colors.white,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              onTap(dominoType);
              HapticFeedback.mediumImpact();
            },
            child: Center(
              child: context.watch<SettingsProvider>().isPips &&
                      dominoType != DominoType.blank
                  ? FractionallySizedBox(
                      widthFactor: 0.85,
                      child: SvgPicture.asset(
                        'assets/pips/${dominoType.name}_colored.svg',
                      ),
                    )
                  : AutoSizeText(
                      Global.values.dominoValues[dominoType]?.toString() ??
                          context
                              .watch<SettingsProvider>()
                              .doubleZeroValue
                              .toString(),
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.bold,
                        color: Global.colors.dominoColors[dominoType] ??
                            context.watch<SettingsProvider>().appAccentColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
