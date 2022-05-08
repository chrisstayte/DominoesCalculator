import 'package:dominoes/global/global.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SharedPreferences? prefs;

  SettingsProvider() {
    setup();
  }

  void setup() async {
    prefs = await SharedPreferences.getInstance();

    _isDarkMode = prefs?.getBool('isDarkMode') ?? false;
    _isDarkDominoes = prefs?.getBool('isDarkDominoes') ?? false;
    _isPips = prefs?.getBool('isPips') ?? true;
    _appAccentColor = Color(prefs?.getInt('appAccentColor') ??
        Global.colors.accentColors.first.value);

    notifyListeners();
  }

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void setIsDarkMode(bool value) async {
    _isDarkMode = value;
    await prefs?.setBool('isDarkMode', value);
    notifyListeners();
  }

  Color _appAccentColor = Global.colors.accentColors.first;
  Color get appAccentColor => _appAccentColor;

  void setAppAccentColor(Color color) async {
    _appAccentColor = color;
    await prefs?.setInt('appAccentColor', color.value);
    notifyListeners();
  }

  bool _isDarkDominoes = false;
  bool get isDarkDominoes => _isDarkDominoes;

  void setIsDarkDominoes(bool value) async {
    _isDarkDominoes = value;
    await prefs?.setBool('isDarkDominoes', value);
    notifyListeners();
  }

  bool _isPips = true;
  bool get isPips => _isPips;

  void setIsPips(bool value) async {
    _isPips = value;
    await prefs?.setBool('isPips', value);
    notifyListeners();
  }
}
