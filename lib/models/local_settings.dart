import 'package:flutter/material.dart';
import '../enum/number_style.dart';
import '../enum/app_accent_color.dart';

class LocalSettings {
  ThemeMode themeMode;
  bool vibration;
  bool soundEffects;
  bool showConfidence;
  bool showScanLine;
  bool coloredPips;
  bool showSplashScreen;
  NumberStyle numberStyle;
  int freePointValue;
  AppAccentColor appAccentColor;

  LocalSettings({
    this.themeMode = ThemeMode.system,
    this.vibration = true,
    this.soundEffects = true,
    this.showConfidence = false,
    this.showScanLine = true,
    this.coloredPips = false,
    this.showSplashScreen = true,
    this.numberStyle = NumberStyle.pips,
    this.freePointValue = 50,
    this.appAccentColor = AppAccentColor.yellow,
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
      showScanLine: json['showScanLine'] as bool? ?? true,
      coloredPips: json['coloredPips'] as bool? ?? false,
      showSplashScreen: json['showSplashScreen'] as bool? ?? true,
      numberStyle: NumberStyle.fromJson(json['numberStyle'] as String?),
      freePointValue: const [0, 25, 50].contains(json['freePointValue'])
          ? json['freePointValue'] as int
          : 50,
      appAccentColor: AppAccentColor.fromJson(json['appAccentColor'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'vibration': vibration,
    'soundEffects': soundEffects,
    'numberStyle': numberStyle.toJson(),
    'showConfidence': showConfidence,
    'showScanLine': showScanLine,
    'coloredPips': coloredPips,
    'showSplashScreen': showSplashScreen,
    'freePointValue': freePointValue,
    'appAccentColor': appAccentColor.toJson(),
  };
}
