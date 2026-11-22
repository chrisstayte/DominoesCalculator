import 'dart:ui';
import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/models/domino_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const detections = [
    DetectionResult(
      label: '0 | 4',
      confidence: .9,
      boundingBox: Rect.zero,
      pipA: 0,
      pipB: 4,
    ),
    DetectionResult(
      label: '5 | 6',
      confidence: .7,
      boundingBox: Rect.zero,
      pipA: 5,
      pipB: 6,
    ),
    DetectionResult(
      label: 'Unreadable',
      confidence: .5,
      boundingBox: Rect.zero,
    ),
  ];
  test('only tapped tiles count, and blanks use the blank value', () {
    final review = DominoReview(detections);
    addTearDown(review.dispose);
    expect(review.selectedCount, 0);
    expect(review.canAdd, isFalse);
    expect(review.valuesToAdd(), isEmpty);
    expect(review.toggle(0), isTrue);
    expect(review.canAdd, isTrue);
    expect(review.total(50), 54);
    expect(review.total(0), 4);
    expect(review.valuesToAdd().map((p) => p.value), [0, 4]);
    review.toggle(1);
    expect(review.valuesToAdd().map((p) => p.value), [0, 4, 5, 6]);
    review.toggle(0);
    expect(review.selectedCount, 1);
    expect(review.valuesToAdd().map((p) => p.value), [5, 6]);
  });
  test('unreadable tiles cannot be selected', () {
    final review = DominoReview(detections);
    addTearDown(review.dispose);
    expect(review.toggle(2), isFalse);
    expect(review.selectedCount, 0);
    expect(review.tiles[2].label, '?');
  });
}
