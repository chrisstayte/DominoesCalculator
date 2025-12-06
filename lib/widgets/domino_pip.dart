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
    return Material(
      borderRadius: BorderRadius.circular(4),
      color: Colors.white,
      child: InkWell(
        onTap: () => onTap(),
        child: Center(
          child: numberStyle == .pips
              ? buildPipImage(pip, context)
              : Text(
                  pip.toString().split('.').last,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
