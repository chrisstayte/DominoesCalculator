import 'dart:ui';

import 'package:dominoes/models/detection_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DetectionResult', () {
    const result = DetectionResult(
      label: 'domino_6',
      confidence: 0.95,
      boundingBox: Rect.fromLTWH(10, 20, 100, 50),
    );

    test('stores label correctly', () {
      expect(result.label, 'domino_6');
    });

    test('stores confidence correctly', () {
      expect(result.confidence, closeTo(0.95, 0.0001));
    });

    test('stores boundingBox correctly', () {
      expect(result.boundingBox, const Rect.fromLTWH(10, 20, 100, 50));
    });

    group('toString', () {
      test('includes label', () {
        expect(result.toString(), contains('domino_6'));
      });

      test('includes confidence formatted as percentage', () {
        // 0.95 * 100 = 95.0%
        expect(result.toString(), contains('95.0%'));
      });

      test('includes bounding box', () {
        expect(result.toString(), contains('box:'));
      });

      test('full format matches pattern', () {
        expect(
          result.toString(),
          'DetectionResult(label: domino_6, confidence: 95.0%, box: Rect.fromLTRB(10.0, 20.0, 110.0, 70.0))',
        );
      });
    });
  });
}
