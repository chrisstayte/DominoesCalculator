import 'dart:ui';

import 'package:dominoes/models/detection_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
