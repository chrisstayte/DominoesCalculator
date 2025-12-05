import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          numberStyle == .pips ? 'pip' : pip.toString().split('.').last,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
