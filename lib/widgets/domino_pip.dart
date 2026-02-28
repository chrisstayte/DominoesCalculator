import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class DominoPip extends StatelessWidget {
  const DominoPip({
    super.key,
    required this.pip,
    required this.numberStyle,
    required this.onTap,
  });

  final DominoPips pip;
  final NumberStyle numberStyle;
  final Function onTap;

  Widget buildPipImage(DominoPips pip, BuildContext context) {
    final freePointValue = context
        .watch<LocalSettingsProvider>()
        .localSettings
        .freePointValue;

    return SvgPicture.asset(
      'assets/images/pips/${pip.readable}_black.svg',
      errorBuilder: (_, _, stack) {
        return Text(
          pip.value == 0 ? freePointValue.toString() : pip.value.toString(),
          style: const TextStyle(fontSize: 16),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(6, 6),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(),
          child: Center(
            child: numberStyle == NumberStyle.pips
                ? buildPipImage(pip, context)
                : Text(
                    pip.value == 0
                        ? context
                              .watch<LocalSettingsProvider>()
                              .localSettings
                              .freePointValue
                              .toString()
                        : pip.value.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
