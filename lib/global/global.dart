import 'package:flutter/material.dart';

class Global {
  static final colors = _Colors();
  static final ui = _UI();
}

class _UI {
  final double cornerRadius = 15;
}

class _Colors {
  final Color darkThemeColor = Colors.grey.shade800;

  final List<Color> accentColors = [
    Colors.blue.shade200,
    Colors.red.shade200,
    Colors.orange.shade200,
    Colors.purple.shade200,
    Colors.green.shade200,
    Colors.pink.shade100
  ];
}
