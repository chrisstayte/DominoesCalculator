import 'dart:ui';

class AppRoutes {
  static const String calc = 'calc';
  static const String logs = 'logs';
  static const String settings = 'settings';
}

class AppColorsValues {
  static const int primaryValue = 0xFF111821;
}

class AppColors {
  static const Color primary = Color(AppColorsValues.primaryValue);
}

/// Public source for the app, offered to users under AGPL-3.0.
const String sourceRepositoryUrl =
    'https://github.com/chrisstayte/DominoesCalculator';
const String sourceRepositoryDisplay =
    'github.com/chrisstayte/DominoesCalculator';
