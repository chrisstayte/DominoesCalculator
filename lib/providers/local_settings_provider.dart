import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dominoes/enum/app_accent_color.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/models/local_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsProvider extends ChangeNotifier {
  LocalSettings localSettings = LocalSettings();
  final Completer<void> _completer = Completer<void>();

  Future<void> get isReady => _completer.future;

  LocalSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences? preferences;

    try {
      preferences = await SharedPreferences.getInstance();
      final localSettingsJson = preferences.getString('localSettings');

      if (localSettingsJson != null) {
        final decoded = jsonDecode(localSettingsJson);
        if (decoded is! Map<String, dynamic>) {
          throw FormatException('Expected localSettings to be a JSON object');
        }
        localSettings = LocalSettings.fromJson(decoded);
      }
    } catch (_) {
      localSettings = LocalSettings();
      try {
        await preferences?.remove('localSettings');
      } catch (_) {
        // Keep startup moving even if the preferences store cannot be repaired.
      }
    } finally {
      _completer.complete();
    }
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

  void setShowScanLine(bool showScanLine) {
    localSettings.showScanLine = showScanLine;
    saveSettings();
    notifyListeners();
  }

  void setColoredPips(bool coloredPips) {
    localSettings.coloredPips = coloredPips;
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

  void setShowSplashScreen(bool showSplashScreen) {
    localSettings.showSplashScreen = showSplashScreen;
    saveSettings();
    notifyListeners();
  }
}
