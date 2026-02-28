import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';

class ThickDivider extends StatelessWidget {
  const ThickDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    return Container(height: 2, color: nbt.borderColor);
  }
}
