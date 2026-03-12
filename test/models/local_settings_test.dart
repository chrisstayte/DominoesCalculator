import 'package:dominoes/enum/app_accent_color.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/models/local_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalSettings', () {
    group('defaults', () {
      final settings = LocalSettings();

      test('themeMode defaults to system', () {
        expect(settings.themeMode, ThemeMode.system);
      });

      test('vibration defaults to true', () {
        expect(settings.vibration, isTrue);
      });

      test('soundEffects defaults to true', () {
        expect(settings.soundEffects, isTrue);
      });

      test('showConfidence defaults to false', () {
        expect(settings.showConfidence, isFalse);
      });

      test('showScanLine defaults to true', () {
        expect(settings.showScanLine, isTrue);
      });

      test('coloredPips defaults to false', () {
        expect(settings.coloredPips, isFalse);
      });

      test('showSplashScreen defaults to true', () {
        expect(settings.showSplashScreen, isTrue);
      });

      test('numberStyle defaults to pips', () {
        expect(settings.numberStyle, NumberStyle.pips);
      });

      test('freePointValue defaults to 50', () {
        expect(settings.freePointValue, 50);
      });

      test('appAccentColor defaults to yellow', () {
        expect(settings.appAccentColor, AppAccentColor.yellow);
      });
    });

    group('toJson', () {
      test('serialises all fields', () {
        final s = LocalSettings(
          themeMode: ThemeMode.dark,
          vibration: false,
          soundEffects: false,
          showConfidence: true,
          showScanLine: false,
          coloredPips: true,
          showSplashScreen: false,
          numberStyle: NumberStyle.numbers,
          freePointValue: 25,
          appAccentColor: AppAccentColor.lime,
        );
        final json = s.toJson();

        expect(json['themeMode'], 'dark');
        expect(json['vibration'], false);
        expect(json['soundEffects'], false);
        expect(json['showConfidence'], true);
        expect(json['showScanLine'], false);
        expect(json['coloredPips'], true);
        expect(json['showSplashScreen'], false);
        expect(json['numberStyle'], 'numbers');
        expect(json['freePointValue'], 25);
        expect(json['appAccentColor'], 'lime');
      });
    });

    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'themeMode': 'light',
          'vibration': false,
          'soundEffects': false,
          'showConfidence': true,
          'showScanLine': false,
          'coloredPips': true,
          'showSplashScreen': false,
          'numberStyle': 'numbers',
          'freePointValue': 0,
          'appAccentColor': 'hotPink',
        };
        final s = LocalSettings.fromJson(json);

        expect(s.themeMode, ThemeMode.light);
        expect(s.vibration, false);
        expect(s.soundEffects, false);
        expect(s.showConfidence, true);
        expect(s.showScanLine, false);
        expect(s.coloredPips, true);
        expect(s.showSplashScreen, false);
        expect(s.numberStyle, NumberStyle.numbers);
        expect(s.freePointValue, 0);
        expect(s.appAccentColor, AppAccentColor.hotPink);
      });

      test('falls back to defaults when fields are missing', () {
        final s = LocalSettings.fromJson({});

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

      test('freePointValue 25 is valid', () {
        final s = LocalSettings.fromJson({'freePointValue': 25});
        expect(s.freePointValue, 25);
      });

      test('freePointValue 0 is valid', () {
        final s = LocalSettings.fromJson({'freePointValue': 0});
        expect(s.freePointValue, 0);
      });

      test('invalid freePointValue falls back to 50', () {
        final s = LocalSettings.fromJson({'freePointValue': 99});
        expect(s.freePointValue, 50);
      });

      test('unknown themeMode string falls back to system', () {
        final s = LocalSettings.fromJson({'themeMode': 'unknown'});
        expect(s.themeMode, ThemeMode.system);
      });
    });

    group('round-trip serialisation', () {
      test('toJson then fromJson restores all fields', () {
        final original = LocalSettings(
          themeMode: ThemeMode.dark,
          vibration: false,
          soundEffects: true,
          showConfidence: true,
          showScanLine: false,
          coloredPips: true,
          showSplashScreen: false,
          numberStyle: NumberStyle.numbers,
          freePointValue: 25,
          appAccentColor: AppAccentColor.coral,
        );

        final restored = LocalSettings.fromJson(original.toJson());

        expect(restored.themeMode, original.themeMode);
        expect(restored.vibration, original.vibration);
        expect(restored.soundEffects, original.soundEffects);
        expect(restored.showConfidence, original.showConfidence);
        expect(restored.showScanLine, original.showScanLine);
        expect(restored.coloredPips, original.coloredPips);
        expect(restored.showSplashScreen, original.showSplashScreen);
        expect(restored.numberStyle, original.numberStyle);
        expect(restored.freePointValue, original.freePointValue);
        expect(restored.appAccentColor, original.appAccentColor);
      });
    });
  });
}
