import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:flutter/services.dart';

class VibrationService {
  final LocalSettingsProvider _settingsProvider;

  VibrationService(this._settingsProvider);

  void light() {
    if (!_settingsProvider.localSettings.vibration) return;
    HapticFeedback.lightImpact();
  }

  void medium() {
    if (!_settingsProvider.localSettings.vibration) return;
    HapticFeedback.mediumImpact();
  }

  void heavy() {
    if (!_settingsProvider.localSettings.vibration) return;
    HapticFeedback.heavyImpact();
  }

  void selection() {
    if (!_settingsProvider.localSettings.vibration) return;
    HapticFeedback.selectionClick();
  }

  void dispose() {
    // No-op for API symmetry
  }
}
