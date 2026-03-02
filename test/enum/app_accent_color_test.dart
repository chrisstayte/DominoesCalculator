import 'package:dominoes/enum/app_accent_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppAccentColor', () {
    group('fromJson', () {
      test('returns yellow for "yellow"', () {
        expect(AppAccentColor.fromJson('yellow'), AppAccentColor.yellow);
      });

      test('returns hotPink for "hotPink"', () {
        expect(AppAccentColor.fromJson('hotPink'), AppAccentColor.hotPink);
      });

      test('returns electricBlue for "electricBlue"', () {
        expect(AppAccentColor.fromJson('electricBlue'), AppAccentColor.electricBlue);
      });

      test('returns lime for "lime"', () {
        expect(AppAccentColor.fromJson('lime'), AppAccentColor.lime);
      });

      test('returns coral for "coral"', () {
        expect(AppAccentColor.fromJson('coral'), AppAccentColor.coral);
      });

      test('returns yellow (default) for null', () {
        expect(AppAccentColor.fromJson(null), AppAccentColor.yellow);
      });

      test('returns yellow (default) for unknown string', () {
        expect(AppAccentColor.fromJson('unknown'), AppAccentColor.yellow);
      });
    });

    group('toJson', () {
      test('returns enum name for each value', () {
        expect(AppAccentColor.yellow.toJson(), 'yellow');
        expect(AppAccentColor.hotPink.toJson(), 'hotPink');
        expect(AppAccentColor.electricBlue.toJson(), 'electricBlue');
        expect(AppAccentColor.lime.toJson(), 'lime');
        expect(AppAccentColor.coral.toJson(), 'coral');
      });

      test('toJson / fromJson round-trip preserves all values', () {
        for (final color in AppAccentColor.values) {
          expect(AppAccentColor.fromJson(color.toJson()), color);
        }
      });
    });

    group('properties', () {
      test('each color has a non-null Color', () {
        for (final color in AppAccentColor.values) {
          expect(color.color, isA<Color>());
        }
      });

      test('each color has a non-empty label', () {
        for (final color in AppAccentColor.values) {
          expect(color.label, isNotEmpty);
        }
      });
    });
  });
}
