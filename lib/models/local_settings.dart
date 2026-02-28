import 'package:flutter/material.dart';
import '../enum/number_style.dart';

class LocalSettings {
  ThemeMode themeMode;
  bool vibration;
  bool soundEffects;
  bool showConfidence;
  NumberStyle numberStyle;
  int freePointValue;

  LocalSettings({
    this.themeMode = ThemeMode.system,
    this.vibration = true,
    this.soundEffects = true,
    this.showConfidence = false,
    this.numberStyle = NumberStyle.pips,
    this.freePointValue = 50,
  });

  factory LocalSettings.fromJson(Map<String, dynamic> json) {
    // Parse ThemeMode from string, fallback to system
    final themeName = json['themeMode'] as String?;
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => ThemeMode.system,
    );

    return LocalSettings(
      themeMode: themeMode,
      vibration: json['vibration'] as bool? ?? true,
      soundEffects: json['soundEffects'] as bool? ?? true,
      showConfidence: json['showConfidence'] as bool? ?? false,
      numberStyle: NumberStyle.fromJson(json['numberStyle'] as String?),
      freePointValue: const [0, 25, 50].contains(json['freePointValue'])
          ? json['freePointValue'] as int
          : 50,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'vibration': vibration,
    'soundEffects': soundEffects,
    'numberStyle': numberStyle.toJson(),
    'showConfidence': showConfidence,
    'freePointValue': freePointValue,
  };
}
