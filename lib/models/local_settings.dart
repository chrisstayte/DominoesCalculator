import 'package:flutter/material.dart';

class LocalSettings {
  ThemeMode themeMode = ThemeMode.system;
  bool vibration = true;
  bool soundEffects = true;

  LocalSettings({required this.themeMode});

  factory LocalSettings.fromJson(Map<String, dynamic> json) {
    int themeMode = json['themeMode'] as int;

    return LocalSettings(themeMode: ThemeMode.values[themeMode]);
  }

  Map<String, dynamic> toJson() => {'themeMode': themeMode.index};
}
