import 'package:dominoes/enum/app_accent_color.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalSettingsProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<LocalSettingsProvider> _makeProvider() async {
      final provider = LocalSettingsProvider();
      await provider.isReady;
      return provider;
    }

    group('initial state', () {
      test('uses default settings when SharedPreferences has no data', () async {
        final provider = await _makeProvider();
        final s = provider.localSettings;

        expect(s.themeMode, ThemeMode.system);
        expect(s.vibration, isTrue);
        expect(s.soundEffects, isTrue);
        expect(s.showConfidence, isFalse);
        expect(s.showScanLine, isTrue);
        expect(s.coloredPips, isFalse);
        expect(s.showSplashScreen, isTrue);
        expect(s.numberStyle, NumberStyle.pips);
        expect(s.freePointValue, 50);
        expect(s.appAccentColor, AppAccentColor.yellow);
      });
    });

    group('setThemeMode', () {
      test('updates themeMode and notifies listeners', () async {
        final provider = await _makeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setThemeMode(ThemeMode.dark);

        expect(provider.localSettings.themeMode, ThemeMode.dark);
        expect(notified, isTrue);
      });
    });

    group('setVibration', () {
      test('updates vibration to false and notifies', () async {
        final provider = await _makeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setVibration(false);

        expect(provider.localSettings.vibration, isFalse);
        expect(notified, isTrue);
      });

      test('updates vibration to true', () async {
        final provider = await _makeProvider();
        provider.setVibration(false);
        provider.setVibration(true);

        expect(provider.localSettings.vibration, isTrue);
      });
    });

    group('setSoundEffects', () {
      test('updates soundEffects and notifies', () async {
        final provider = await _makeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setSoundEffects(false);

        expect(provider.localSettings.soundEffects, isFalse);
        expect(notified, isTrue);
      });
    });

    group('setShowConfidence', () {
      test('updates showConfidence and notifies', () async {
        final provider = await _makeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setShowConfidence(true);

        expect(provider.localSettings.showConfidence, isTrue);
        expect(notified, isTrue);
      });
    });

    group('setShowScanLine', () {
      test('updates showScanLine and notifies', () async {
        final provider = await _makeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setShowScanLine(false);

        expect(provider.localSettings.showScanLine, isFalse);
        expect(notified, isTrue);
      });
    });

    group('setColoredPips', () {
      test('updates coloredPips and notifies', () async {
        final provider = await _makeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setColoredPips(true);

        expect(provider.localSettings.coloredPips, isTrue);
        expect(notified, isTrue);
      });
    });

    group('setShowSplashScreen', () {
      test('updates showSplashScreen and notifies', () async {
        final provider = await _makeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setShowSplashScreen(false);

        expect(provider.localSettings.showSplashScreen, isFalse);
        expect(notified, isTrue);
      });
    });

    group('setNumberStyle', () {
      test('updates numberStyle and notifies', () async {
        final provider = await _makeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setNumberStyle(NumberStyle.numbers);

        expect(provider.localSettings.numberStyle, NumberStyle.numbers);
        expect(notified, isTrue);
      });
    });

    group('setFreePointValue', () {
      test('updates freePointValue to 25 and notifies', () async {
        final provider = await _makeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setFreePointValue(25);

        expect(provider.localSettings.freePointValue, 25);
        expect(notified, isTrue);
      });

      test('updates freePointValue to 0', () async {
        final provider = await _makeProvider();
        provider.setFreePointValue(0);
        expect(provider.localSettings.freePointValue, 0);
      });
    });

    group('setAppAccentColor', () {
      test('updates appAccentColor and notifies', () async {
        final provider = await _makeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setAppAccentColor(AppAccentColor.electricBlue);

        expect(provider.localSettings.appAccentColor, AppAccentColor.electricBlue);
        expect(notified, isTrue);
      });

      test('round-trips all accent colors', () async {
        final provider = await _makeProvider();
        for (final color in AppAccentColor.values) {
          provider.setAppAccentColor(color);
          expect(provider.localSettings.appAccentColor, color);
        }
      });
    });

    group('persistence', () {
      test('saved settings are reloaded by a new provider instance', () async {
        final provider1 = await _makeProvider();
        provider1.setThemeMode(ThemeMode.dark);
        provider1.setVibration(false);
        provider1.setAppAccentColor(AppAccentColor.coral);
        // Allow async save to complete.
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final provider2 = await _makeProvider();
        expect(provider2.localSettings.themeMode, ThemeMode.dark);
        expect(provider2.localSettings.vibration, isFalse);
        expect(provider2.localSettings.appAccentColor, AppAccentColor.coral);
      });
    });
  });
}
