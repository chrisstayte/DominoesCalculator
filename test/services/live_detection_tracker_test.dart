import 'dart:ui';

import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/services/live_detection_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

DetectionResult tile(
  double x,
  double y, {
  double confidence = .9,
  int start = 0,
}) {
  final corners = [
    Offset(x, y),
    Offset(x + .2, y),
    Offset(x + .2, y + .1),
    Offset(x, y + .1),
  ];
  return DetectionResult(
    label: 'Domino',
    confidence: confidence,
    boundingBox: Rect.fromLTWH(x, y, .2, .1),
    corners: [for (var i = 0; i < 4; i++) corners[(i + start) % 4]],
  );
}

void main() {
  test('a domino keeps its id and small jitter is damped', () {
    final tracker = LiveDetectionTracker();
    final first = tracker.update([tile(.3, .3)]);
    expect(first, hasLength(1));
    final id = first.single.id;
    final next = tracker.update([tile(.305, .3)]);
    expect(next.single.id, id);
    // Moved less than the raw 0.005 wobble.
    final x = next.single.detection.boundingBox.left;
    expect(x, greaterThan(.3));
    expect(x, lessThan(.305));
  });

  test('rotated corner order does not swing the smoothed box', () {
    final tracker = LiveDetectionTracker();
    tracker.update([tile(.3, .3)]);
    final next = tracker.update([tile(.3, .3, start: 2)]);
    expect(next.single.detection.corners.first.dx, closeTo(.3, 1e-9));
    expect(next.single.detection.corners.first.dy, closeTo(.3, 1e-9));
  });

  test('low-confidence detections need two frames before appearing', () {
    final tracker = LiveDetectionTracker();
    expect(tracker.update([tile(.3, .3, confidence: .4)]), isEmpty);
    expect(tracker.update([tile(.3, .3, confidence: .4)]), hasLength(1));
  });

  test('a confirmed box survives brief dropouts, then disappears', () {
    final tracker = LiveDetectionTracker(maxMisses: 2);
    final id = tracker.update([tile(.3, .3)]).single.id;
    expect(tracker.update(const []).single.id, id);
    expect(tracker.update(const []).single.id, id);
    expect(tracker.update(const []), isEmpty);
  });

  test('two dominoes keep separate identities', () {
    final tracker = LiveDetectionTracker();
    final a = tracker.update([tile(.1, .1), tile(.6, .6)]);
    final b = tracker.update([tile(.61, .6), tile(.1, .11)]);
    final before = {for (final t in a) t.id: t.detection.boundingBox.center};
    for (final t in b) {
      expect(
        (t.detection.boundingBox.center - before[t.id]!).distance,
        lessThan(.05),
      );
    }
  });
}
