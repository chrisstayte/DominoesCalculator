import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dominoes/models/local_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsProvider extends ChangeNotifier {
  LocalSettings localSettings = LocalSettings(themeMode: ThemeMode.system);
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
}
