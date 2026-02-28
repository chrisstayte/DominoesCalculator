import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class DominoPip extends StatefulWidget {
  const DominoPip({
    super.key,
    required this.pip,
    required this.numberStyle,
    required this.onTap,
  });

  final DominoPips pip;
  final NumberStyle numberStyle;
  final VoidCallback onTap;

  @override
  State<DominoPip> createState() => _DominoPipState();
}

class _DominoPipState extends State<DominoPip> {
  bool _isPressed = false;

  Widget buildPipImage(DominoPips pip, BuildContext context, NeoBrutalistTheme nbt) {
    final valueTextStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: nbt.bodyTextColor,
      letterSpacing: 0.5,
    );

    if (pip.value == 0) {
      final freePointValue = context
          .watch<LocalSettingsProvider>()
          .localSettings
          .freePointValue;
      return Text(freePointValue.toString(), style: valueTextStyle);
    }

    return SvgPicture.asset(
      'assets/images/pips/${pip.readable}_black.svg',
      colorFilter: ColorFilter.mode(nbt.bodyTextColor, BlendMode.srcIn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final valueTextStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: nbt.bodyTextColor,
      letterSpacing: 0.5,
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(4),
        transform: Matrix4.translationValues(
          _isPressed ? 4 : 0,
          _isPressed ? 4 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: nbt.cardColor,
          border: Border.all(color: nbt.borderColor, width: 4),
          boxShadow: [
            BoxShadow(
              color: nbt.shadowColor,
              offset: _isPressed ? const Offset(2, 2) : const Offset(6, 6),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: widget.numberStyle == NumberStyle.pips
              ? buildPipImage(widget.pip, context, nbt)
              : Text(
                  widget.pip.value == 0
                      ? context
                            .watch<LocalSettingsProvider>()
                            .localSettings
                            .freePointValue
                            .toString()
                      : widget.pip.value.toString(),
                  style: valueTextStyle,
                ),
        ),
      ),
    );
  }
}
