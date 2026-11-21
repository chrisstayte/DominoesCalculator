import 'dart:ui';

import 'package:dominoes/enum/app_accent_color.dart';
import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/models/detection_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DominoPips', () {
    test('maps integer values to labels and readable asset names', () {
      expect(DominoPips.p0.value, 0);
      expect(DominoPips.p0.label, '0');
      expect(DominoPips.p0.readable, 'zero');
      expect(DominoPips.p15.value, 15);
      expect(DominoPips.p15.label, '15');
      expect(DominoPips.p15.readable, 'fifteen');
      expect(DominoPips.p12.toString(), '12');
    });

    test('converts valid and invalid integers', () {
      expect(DominoPips.fromInt(8), DominoPips.p8);
      expect(DominoPips.tryFromInt(8), DominoPips.p8);
      expect(DominoPips.tryFromInt(99), isNull);
      expect(() => DominoPips.fromInt(99), throwsRangeError);
    });
  });

  group('NumberStyle', () {
    test('serializes and defaults invalid JSON to pips', () {
      expect(NumberStyle.numbers.toJson(), 'numbers');
      expect(NumberStyle.fromJson('numbers'), NumberStyle.numbers);
      expect(NumberStyle.fromJson(null), NumberStyle.pips);
      expect(NumberStyle.fromJson('bogus'), NumberStyle.pips);
    });
  });

  group('AppAccentColor', () {
    test('serializes and defaults invalid JSON to yellow', () {
      expect(AppAccentColor.electricBlue.toJson(), 'electricBlue');
      expect(
        AppAccentColor.fromJson('electricBlue'),
        AppAccentColor.electricBlue,
      );
      expect(AppAccentColor.fromJson('bogus'), AppAccentColor.yellow);
    });
  });

  test('DetectionResult has a useful diagnostic string', () {
    const detection = DetectionResult(
      label: 'double six',
      confidence: 0.876,
      boundingBox: Rect.fromLTWH(1, 2, 3, 4),
    );

    expect(detection.toString(), contains('double six'));
    expect(detection.toString(), contains('87.6%'));
    expect(detection.toString(), contains('Rect'));
  });
}
