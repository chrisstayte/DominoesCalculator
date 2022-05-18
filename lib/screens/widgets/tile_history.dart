import 'package:auto_size_text/auto_size_text.dart';
import 'package:dominoes/enums/domino_type.dart';
import 'package:dominoes/global/global.dart';
import 'package:dominoes/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

typedef TileHistoryCallback(int index);

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

  Future<bool> _fileExists() async {
    try {
      ByteData data = await rootBundle
          .load('assets/pips/${this.dominoType.name}_colored.svg');
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            Global.ui.cornerRadius,
          ),
          color: Colors.white,
        ),
        child: Center(
          child: FutureBuilder(
              future: _fileExists(),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (context.watch<SettingsProvider>().isPips) {
                  if (snapshot.hasData) {
                    if (snapshot.data) {
                      return FractionallySizedBox(
                        heightFactor: 0.75,
                        widthFactor: 0.85,
                        child: SvgPicture.asset(
                          'assets/pips/${this.dominoType.name}_colored.svg',
                        ),
                      );
                    }
                  }
                }
                return AutoSizeText(
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
                );
              }),
        ),
      ),
    );
  }
}
