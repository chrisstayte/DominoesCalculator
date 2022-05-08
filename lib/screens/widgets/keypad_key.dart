import 'package:dominoes/enums/domino_type.dart';
import 'package:dominoes/global/global.dart';
import 'package:dominoes/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef KeypadKeyCallback(DominoType dominoType);

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
      child: GestureDetector(
        onTap: () => onTap(dominoType),
        child: Container(
          margin: EdgeInsets.all(1),
          color: context.watch<SettingsProvider>().isDarkDominoes
              ? Colors.grey
              : Colors.white,
          child: Center(
            child: Text(
              Global.values.dominoValues[dominoType]?.toString() ??
                  context.watch<SettingsProvider>().doubleZeroValue.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Global.colors.dominoColors[dominoType] ??
                    context.watch<SettingsProvider>().appAccentColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
