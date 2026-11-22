import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/services/live_detection_tracker.dart';
import 'package:dominoes/widgets/live_detection_overlay.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

TrackedDetection box(int id, double x) => TrackedDetection(
  id,
  DetectionResult(
    label: 'Domino',
    confidence: .9,
    boundingBox: Rect.fromLTWH(x, .2, .2, .1),
    corners: [
      Offset(x, .2),
      Offset(x + .2, .2),
      Offset(x + .2, .3),
      Offset(x, .3),
    ],
  ),
);

void main() {
  testWidgets('boxes glide, fade out and stop animating when settled', (
    tester,
  ) async {
    final tracks = ValueNotifier<List<TrackedDetection>>([box(1, .1)]);
    addTearDown(tracks.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LiveDetectionBoxes(
          tracks: tracks,
          color: const Color(0xFF00FF00),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tracks.value = [box(1, .4)];
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    tracks.value = const [];
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byKey(const ValueKey('live-domino-boxes')), findsOneWidget);
  });
}
