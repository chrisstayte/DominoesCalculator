import 'package:dominoes/enums/domino_type.dart';
import 'package:flutter/material.dart';

class Global {
  static final colors = _Colors();
  static final ui = _UI();
  static final values = _Values();
}

class _UI {
  final double cornerRadius = 15;
}

class _Colors {
  final Color darkThemeColor = Colors.grey.shade800;

  final List<Color> accentColors = [
    Colors.red.shade200,
    Colors.orange.shade200,
    Colors.teal.shade200,
    Colors.green.shade200,
    Colors.blue.shade200,
    Colors.purple.shade200,
    Colors.pink.shade100
  ];

  final Map<DominoType, Color> dominoColors = {
    DominoType.one: const Color(0XFF4290D8),
    DominoType.two: const Color(0XFF5BD171),
    DominoType.three: const Color(0XFFE23C32),
    DominoType.four: const Color(0XFFB25E30),
    DominoType.five: const Color(0XFF346A98),
    DominoType.six: const Color(0XFFEAC846),
    DominoType.seven: const Color(0XFF9D4CB4),
    DominoType.eight: const Color(0XFF57BE9D),
    DominoType.nine: const Color(0XFF8F2DAA),
    DominoType.ten: const Color(0XFFEF9D39),
    DominoType.eleven: const Color(0XFFBC352F),
    DominoType.twelve: const Color(0XFF8FA0A0),
    DominoType.thirteen: const Color(0XFF53B566),
    DominoType.fourteen: const Color(0XFF3004BD),
    DominoType.fifteen: const Color(0XFFDAB425),
  };
}

class _Values {
  final Map<DominoType, int> dominoValues = {
    DominoType.one: 1,
    DominoType.two: 2,
    DominoType.three: 3,
    DominoType.four: 4,
    DominoType.five: 5,
    DominoType.six: 6,
    DominoType.seven: 7,
    DominoType.eight: 8,
    DominoType.nine: 9,
    DominoType.ten: 10,
    DominoType.eleven: 11,
    DominoType.twelve: 12,
    DominoType.thirteen: 13,
    DominoType.fourteen: 14,
    DominoType.fifteen: 15,
  };
}
