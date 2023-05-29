import 'package:dominoes/global/global.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  late final SharedPreferences preferences;

  SettingsProvider() {
    setup();
  }

  void setup() async {
    preferences = await SharedPreferences.getInstance();

    _isDarkMode = preferences.getBool('isDarkMode') ?? false;
    _isDarkDominoes = preferences.getBool('isDarkDominoes') ?? false;
    _isPips = preferences.getBool('isPips') ?? true;
    _doubleZeroValue = preferences.getInt('doubleZeroValue') ?? 50;
    _appAccentColor = Color(
      preferences.getInt('appAccentColor') ??
          Global.colors.accentColors.elementAt(4).value,
    );

    notifyListeners();
  }

  late final bool _isDarkMode;
  bool get isDarkMode => _isDarkMode;

  void setIsDarkMode(bool value) async {
    _isDarkMode = value;
    await preferences.setBool('isDarkMode', value);
    notifyListeners();
  }

  late final Color _appAccentColor;
  Color get appAccentColor => _appAccentColor;

  void setAppAccentColor(Color color) async {
    _appAccentColor = color;
    await preferences.setInt('appAccentColor', color.value);
    notifyListeners();
  }

  late final bool _isDarkDominoes;
  bool get isDarkDominoes => _isDarkDominoes;

  void setIsDarkDominoes(bool value) async {
    _isDarkDominoes = value;
    await preferences.setBool('isDarkDominoes', value);
    notifyListeners();
  }

  late final bool _isPips;
  bool get isPips => _isPips;

  void setIsPips(bool value) async {
    _isPips = value;
    await preferences.setBool('isPips', value);
    notifyListeners();
  }

  late final int _doubleZeroValue;
  int get doubleZeroValue => _doubleZeroValue;

  void setDoubleZeroValue(int value) async {
    _doubleZeroValue = value;
    await preferences.setInt('doubleZeroValue', value);
    notifyListeners();
  }
}
