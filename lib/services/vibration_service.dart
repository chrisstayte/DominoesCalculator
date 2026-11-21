import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:flutter/services.dart';

class VibrationService {
  final LocalSettingsProvider _settingsProvider;
  final bool isSupported;

  VibrationService(this._settingsProvider, {required this.isSupported});

  static Future<bool> checkSupport() async {
    const channel = MethodChannel('dominoes/haptics');
    try {
      return await channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  bool get _enabled => isSupported && _settingsProvider.localSettings.vibration;

  void light() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  void medium() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  void heavy() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  void dispose() {
    // No-op for API symmetry
  }
}
