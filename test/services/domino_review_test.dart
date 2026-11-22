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
  test('only selected and explicitly confirmed tiles count', () {
    final review = DominoReview(detections);
    addTearDown(review.dispose);
    expect(review.mineCount, 0);
    expect(review.canAdd, isFalse);
    review.toggleMine(0);
    expect(review.pendingMine, 1);
    expect(review.total(50), 0);
    expect(review.valuesToAdd, throwsStateError);
    review.accept(0);
    review.accept(1);
    expect(review.canAdd, isTrue);
    expect(review.total(50), 54);
    expect(review.valuesToAdd().map((p) => p.value), [0, 4]);
    expect(review.total(25), 29);
    expect(review.total(0), 4);
  });
  test(
    'reject, restore and correct keep stable IDs and protect original results',
    () {
      final review = DominoReview(detections);
      addTearDown(review.dispose);
      review.toggleMine(1);
      review.reject(1);
      expect(review.mineCount, 0);
      expect(review.tiles, hasLength(3));
      review.restore(1);
      review.toggleMine(1);
      review.correct(1, 15, 0);
      expect(review.total(50), 65);
      expect(detections[1].pipA, 5);
      expect(review.valuesToAdd().map((p) => p.value), [15, 0]);
      expect(() => review.correct(1, 16, 0), throwsRangeError);
      expect(review.tiles[1].a, 15);
    },
  );
  test('unreadable selected tile blocks acceptance until corrected', () {
    final review = DominoReview(detections);
    addTearDown(review.dispose);
    review.toggleMine(2);
    review.accept(2);
    expect(review.canAdd, isFalse);
    review.correct(2, 3, 4);
    expect(review.canAdd, isTrue);
    expect(review.total(50), 7);
  });
  test(
    'select all excludes rejected tiles and never confirms values implicitly',
    () {
      final review = DominoReview(detections);
      addTearDown(review.dispose);
      review.reject(1);
      review.selectAll(true);
      expect(review.mineCount, 2);
      expect(review.pendingMine, 2);
      expect(review.canAdd, isFalse);
      review.selectAll(false);
      expect(review.mineCount, 0);
    },
  );
}
