import 'dart:convert';

import 'package:dominoes/enum/app_accent_color.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/models/local_settings.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalSettings', () {
    test('round-trips all persisted fields through JSON', () {
      final settings = LocalSettings(
        themeMode: ThemeMode.dark,
        vibration: false,
        soundEffects: false,
        showConfidence: true,
        showScanLine: false,
        coloredPips: true,
        showSplashScreen: false,
        numberStyle: NumberStyle.numbers,
        freePointValue: 25,
        appAccentColor: AppAccentColor.hotPink,
      );

      final restored = LocalSettings.fromJson(settings.toJson());

      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.vibration, isFalse);
      expect(restored.soundEffects, isFalse);
      expect(restored.showConfidence, isTrue);
      expect(restored.showScanLine, isFalse);
      expect(restored.coloredPips, isTrue);
      expect(restored.showSplashScreen, isFalse);
      expect(restored.numberStyle, NumberStyle.numbers);
      expect(restored.freePointValue, 25);
      expect(restored.appAccentColor, AppAccentColor.hotPink);
    });

    test('falls back to safe defaults for unknown persisted values', () {
      final restored = LocalSettings.fromJson({
        'themeMode': 'sepia',
        'numberStyle': 'roman',
        'freePointValue': 100,
        'appAccentColor': 'infrared',
      });

      expect(restored.themeMode, ThemeMode.system);
      expect(restored.numberStyle, NumberStyle.pips);
      expect(restored.freePointValue, 50);
      expect(restored.appAccentColor, AppAccentColor.yellow);
    });
  });

  group('LocalSettingsProvider', () {
    test('loads settings from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'localSettings': jsonEncode(
          LocalSettings(
            themeMode: ThemeMode.light,
            numberStyle: NumberStyle.numbers,
            freePointValue: 0,
            appAccentColor: AppAccentColor.lime,
          ).toJson(),
        ),
      });

      final provider = LocalSettingsProvider();
      await provider.isReady;

      expect(provider.localSettings.themeMode, ThemeMode.light);
      expect(provider.localSettings.numberStyle, NumberStyle.numbers);
      expect(provider.localSettings.freePointValue, 0);
      expect(provider.localSettings.appAccentColor, AppAccentColor.lime);
    });

    test(
      'mutators update memory, notify listeners, and persist JSON',
      () async {
        SharedPreferences.setMockInitialValues({});
        final provider = LocalSettingsProvider();
        await provider.isReady;

        var notifications = 0;
        provider.addListener(() => notifications++);

        provider
          ..setThemeMode(ThemeMode.dark)
          ..setNumberStyle(NumberStyle.numbers)
          ..setVibration(false)
          ..setSoundEffects(false)
          ..setShowConfidence(true)
          ..setShowScanLine(false)
          ..setColoredPips(true)
          ..setFreePointValue(25)
          ..setAppAccentColor(AppAccentColor.coral)
          ..setShowSplashScreen(false);

        await Future<void>.delayed(Duration.zero);

        expect(notifications, 10);
        expect(provider.localSettings.themeMode, ThemeMode.dark);
        expect(provider.localSettings.numberStyle, NumberStyle.numbers);
        expect(provider.localSettings.vibration, isFalse);
        expect(provider.localSettings.soundEffects, isFalse);
        expect(provider.localSettings.showConfidence, isTrue);
        expect(provider.localSettings.showScanLine, isFalse);
        expect(provider.localSettings.coloredPips, isTrue);
        expect(provider.localSettings.freePointValue, 25);
        expect(provider.localSettings.appAccentColor, AppAccentColor.coral);
        expect(provider.localSettings.showSplashScreen, isFalse);

        final preferences = await SharedPreferences.getInstance();
        final persisted = LocalSettings.fromJson(
          jsonDecode(preferences.getString('localSettings')!)
              as Map<String, dynamic>,
        );
        expect(persisted.themeMode, ThemeMode.dark);
        expect(persisted.numberStyle, NumberStyle.numbers);
        expect(persisted.freePointValue, 25);
        expect(persisted.appAccentColor, AppAccentColor.coral);
        expect(persisted.showSplashScreen, isFalse);
      },
    );
  });
}
