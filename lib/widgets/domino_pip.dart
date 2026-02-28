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
          style: const TextStyle(fontSize: 25),
        );
      },
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
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
