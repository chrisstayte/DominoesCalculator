import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dominoes/enum/app_accent_color.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/models/local_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsProvider extends ChangeNotifier {
  LocalSettings localSettings = LocalSettings();
  final Completer _completer = Completer<void>();

  Future<void> get isReady => _completer.future;

  LocalSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? localSettingsJson = preferences.getString('localSettings');

    if (localSettingsJson != null) {
      Map<String, dynamic> json = jsonDecode(localSettingsJson);
      localSettings = LocalSettings.fromJson(json);
    }

    _completer.complete();
  }

  Future<void> saveSettings() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String localSettingsJson = jsonEncode(localSettings.toJson());
    await preferences.setString('localSettings', localSettingsJson);
  }

  void setThemeMode(ThemeMode themeMode) {
    localSettings.themeMode = themeMode;
    saveSettings();
    notifyListeners();
  }

  void setNumberStyle(NumberStyle numberStyle) {
    localSettings.numberStyle = numberStyle;
    saveSettings();
    notifyListeners();
  }

  void setVibration(bool vibration) {
    localSettings.vibration = vibration;
    saveSettings();
    notifyListeners();
  }

  void setSoundEffects(bool soundEffects) {
    localSettings.soundEffects = soundEffects;
    saveSettings();
    notifyListeners();
  }

  void setShowConfidence(bool showConfidence) {
    localSettings.showConfidence = showConfidence;
    saveSettings();
    notifyListeners();
  }

  void setFreePointValue(int freePointValue) {
    localSettings.freePointValue = freePointValue;
    saveSettings();
    notifyListeners();
  }

  void setAppAccentColor(AppAccentColor appAccentColor) {
    localSettings.appAccentColor = appAccentColor;
    saveSettings();
    notifyListeners();
  }
}
