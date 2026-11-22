import 'dart:ui';

import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:dominoes/widgets/domino_results_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../helpers/test_app.dart';

void main() {
  testWidgets('blank values transfer once and append to existing calculator', (
    tester,
  ) async {
    useLargeDisplay(tester);
    final calculator = CalculatorProvider()..addPip(DominoPips.p3);
    var notifications = 0;
    calculator.addListener(() => notifications++);
    final report = DetectionReport(
      detections: const [
        DetectionResult(
          label: '0 | 4',
          confidence: .9,
          boundingBox: Rect.fromLTWH(.1, .1, .8, .8),
          pipA: 0,
          pipB: 4,
        ),
      ],
      imageSize: const Size(200, 100),
      imageBytes: img.encodePng(img.Image(width: 200, height: 100)),
      processingTime: Duration.zero,
    );
    await tester.pumpWidget(
      buildProviderHarness(
        child: Scaffold(
          body: DominoResultsView(
            report: report,
            blankValue: 50,
            showConfidence: true,
            accentColor: Colors.yellow,
            onRetake: () {},
            onAdd: calculator.addPips,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('TOTAL: 54 · 1 TILES'), findsOneWidget);
    await tester.tap(find.text('ADD TO CALC'));
    expect(calculator.selectedPips, [
      DominoPips.p3,
      DominoPips.p0,
      DominoPips.p4,
    ]);
    expect(calculator.total(freePointValue: 50), 57);
    expect(notifications, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unreadable tiles show subtotal and cannot transfer', (
    tester,
  ) async {
    useLargeDisplay(tester);
    final report = DetectionReport(
      detections: const [
        DetectionResult(
          label: '3 | 4',
          confidence: .9,
          boundingBox: Rect.zero,
          pipA: 3,
          pipB: 4,
        ),
        DetectionResult(
          label: 'Unreadable tile',
          confidence: .1,
          boundingBox: Rect.zero,
        ),
      ],
      imageSize: const Size(100, 200),
      imageBytes: img.encodePng(img.Image(width: 100, height: 200)),
      processingTime: Duration.zero,
    );
    await tester.pumpWidget(
      buildProviderHarness(
        child: Scaffold(
          body: DominoResultsView(
            report: report,
            blankValue: 50,
            showConfidence: false,
            accentColor: Colors.yellow,
            onRetake: () {},
            onAdd: (_) => fail('Incomplete results were transferred'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('READABLE SUBTOTAL: 7 · 2 TILES'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
