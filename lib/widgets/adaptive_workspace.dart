import 'package:flutter/material.dart';

bool hasWorkspace(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width >= 700 && size.height >= 620;
}

class WorkspaceSplit extends StatelessWidget {
  const WorkspaceSplit({
    super.key,
    required this.leading,
    required this.trailing,
    this.leadingFlex = 1,
    this.trailingFlex = 2,
  });
  final Widget leading;
  final Widget trailing;
  final int leadingFlex;
  final int trailingFlex;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(flex: leadingFlex, child: leading),
      const SizedBox(width: 16),
      Expanded(flex: trailingFlex, child: trailing),
    ],
  );
}
