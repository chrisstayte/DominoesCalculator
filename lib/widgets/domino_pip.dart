import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
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

  static const _valueTextStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: Colors.black,
    letterSpacing: 0.5,
  );

  Widget buildPipImage(DominoPips pip, BuildContext context) {
    if (pip.value == 0) {
      final freePointValue = context
          .watch<LocalSettingsProvider>()
          .localSettings
          .freePointValue;
      return Text(freePointValue.toString(), style: _valueTextStyle);
    }

    return SvgPicture.asset(
      'assets/images/pips/${pip.readable}_black.svg',
    );
  }

  @override
  Widget build(BuildContext context) {
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
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: _isPressed ? const Offset(2, 2) : const Offset(6, 6),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: widget.numberStyle == NumberStyle.pips
              ? buildPipImage(widget.pip, context)
              : Text(
                  widget.pip.value == 0
                      ? context
                            .watch<LocalSettingsProvider>()
                            .localSettings
                            .freePointValue
                            .toString()
                      : widget.pip.value.toString(),
                  style: _valueTextStyle,
                ),
        ),
      ),
    );
  }
}
