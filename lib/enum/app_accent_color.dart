import 'package:flutter/material.dart';

enum AppAccentColor {
  yellow(Color(0xFFFFFF04), 'YELLOW'),
  hotPink(Color(0xFFFF5CA2), 'PINK'),
  electricBlue(Color(0xFF3B82F6), 'BLUE'),
  lime(Color(0xFF84CC16), 'LIME'),
  coral(Color(0xFFFF6B6B), 'CORAL');

  const AppAccentColor(this.color, this.label);

  final Color color;
  final String label;

  static AppAccentColor fromJson(String? name) {
    return AppAccentColor.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppAccentColor.yellow,
    );
  }

  String toJson() => name;
}
