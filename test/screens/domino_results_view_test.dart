import 'dart:io';
import 'dart:convert';
import 'dart:ui';

import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:dominoes/widgets/domino_results_view.dart';
import 'package:dominoes/widgets/domino_badge_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../helpers/test_app.dart';

DetectionReport exampleReport({bool unreadable = false}) {
  final image = img.Image(width: 600, height: 400);
  img.fill(image, color: img.ColorRgb8(95, 75, 58));
  for (final rect in [
    const Rect.fromLTWH(.1, .2, .35, .3),
    const Rect.fromLTWH(.55, .5, .35, .3),
  ]) {
    img.fillRect(
      image,
      x1: (rect.left * 600).round(),
      y1: (rect.top * 400).round(),
      x2: (rect.right * 600).round(),
      y2: (rect.bottom * 400).round(),
      color: img.ColorRgb8(244, 234, 207),
    );
    img.drawLine(
      image,
      x1: (rect.center.dx * 600).round(),
      y1: (rect.top * 400).round() + 8,
      x2: (rect.center.dx * 600).round(),
      y2: (rect.bottom * 400).round() - 8,
      color: img.ColorRgb8(30, 30, 30),
      thickness: 3,
    );
  }
  final patterns = <int, List<List<int>>>{
    0: [],
    4: [
      [0, 0],
      [2, 0],
      [0, 2],
      [2, 2],
    ],
    5: [
      [0, 0],
      [2, 0],
      [1, 1],
      [0, 2],
      [2, 2],
    ],
    6: [
      [0, 0],
      [2, 0],
      [0, 1],
      [2, 1],
      [0, 2],
      [2, 2],
    ],
  };
  for (final entry in [(60, 80, 0, 4), (330, 200, 5, 6)]) {
    for (var half = 0; half < 2; half++) {
      for (final dot in patterns[half == 0 ? entry.$3 : entry.$4]!) {
        img.fillCircle(
          image,
          x: entry.$1 + half * 105 + 24 + dot[0] * 28,
          y: entry.$2 + 25 + dot[1] * 35,
          radius: 7,
          color: img.ColorRgb8(20, 20, 20),
        );
      }
    }
  }
  return DetectionReport(
    detections: [
      const DetectionResult(
        label: '0 | 4',
        confidence: .95,
        boundingBox: Rect.fromLTWH(.1, .2, .35, .3),
        pipA: 0,
        pipB: 4,
      ),
      DetectionResult(
        label: unreadable ? 'Unreadable' : '5 | 6',
        confidence: .7,
        boundingBox: const Rect.fromLTWH(.55, .5, .35, .3),
        pipA: unreadable ? null : 5,
        pipB: unreadable ? null : 6,
      ),
    ],
    imageSize: const Size(600, 400),
    imageBytes: img.encodePng(image),
    processingTime: Duration.zero,
  );
}

Future<void> openReview(
  WidgetTester tester, {
  ValueChanged<List<DominoPips>>? onAdd,
  DetectionReport? report,
  Key? captureKey,
}) async {
  useLargeDisplay(tester);
  await tester.pumpWidget(
    buildProviderHarness(
      child: RepaintBoundary(
        key: captureKey,
        child: Scaffold(
          appBar: AppBar(title: const Text('DETECT')),
          bottomNavigationBar: const SizedBox(height: 70),
          body: DominoResultsView(
            report: report ?? exampleReport(),
            blankValue: 50,
            showConfidence: true,
            accentColor: Colors.yellow,
            onRetake: () {},
            onAdd: onAdd ?? (_) {},
          ),
        ),
      ),
    ),
  );
  if (Platform.environment['DOMINO_REVIEW_FONT_DIR'] != null)
    await tester.runAsync(() async {
      final view = tester.widget<DominoResultsView>(
        find.byType(DominoResultsView),
      );
      await precacheImage(
        MemoryImage(view.report.imageBytes),
        tester.element(find.byType(DominoResultsView)),
      );
    });
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final directory = Platform.environment['DOMINO_REVIEW_FONT_DIR'];
    if (directory == null) return;
    final fontAssets = <String, ByteData>{};
    const variants = {
      'regular': 'Regular',
      '200': 'ExtraLight',
      '300': 'Light',
      '500': 'Medium',
      '600': 'SemiBold',
      '700': 'Bold',
      '800': 'ExtraBold',
    };
    for (final file in Directory(directory).listSync().whereType<File>()) {
      if (!file.path.endsWith('.ttf')) continue;
      final suffix = file.uri.pathSegments.last
          .replaceAll('.ttf', '')
          .split('_')
          .last;
      final asset = 'fonts/BricolageGrotesque-${variants[suffix]}.ttf';
      fontAssets[asset] = ByteData.sublistView(await file.readAsBytes());
    }
    final manifest = {
      for (final asset in fontAssets.keys)
        asset: [
          {'asset': asset},
        ],
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final asset = utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          if (asset == 'AssetManifest.bin')
            return const StandardMessageCodec().encodeMessage(manifest);
          return fontAssets[asset];
        });
    final icons = Platform.environment['DOMINO_MATERIAL_ICON_FONT'];
    if (icons != null) {
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(ByteData.sublistView(await File(icons).readAsBytes())),
          ))
          .load();
    }
  });

  testWidgets('select and confirm only mine, preserve blanks and append once', (
    tester,
  ) async {
    final calculator = CalculatorProvider()..addPip(DominoPips.p3);
    var calls = 0;
    await openReview(
      tester,
      onAdd: (pips) {
        calls++;
        calculator.addPips(pips);
      },
    );
    expect(find.text('YOUR SCORE: 0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mine-0')));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('yes-0')));
    await tester.pump();
    expect(find.text('YOUR SCORE: 54'), findsOneWidget);
    await tester.tap(find.text('ADD 1 TILE'));
    await tester.pump();
    expect(calculator.selectedPips, [
      DominoPips.p3,
      DominoPips.p0,
      DominoPips.p4,
    ]);
    expect(calculator.total(freePointValue: 50), 57);
    expect(calls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap a photo box after zoom and keep selection when reset', (
    tester,
  ) async {
    await openReview(tester);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      closeTo(1.5, .01),
    );
    final photo = find.byType(Image);
    // Flutter hit testing must account for the viewer transform and letterboxing.
    final scene = tester.getRect(photo);
    await tester.tapAt(
      Offset(scene.left + scene.width * .275, scene.top + scene.height * .35),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Checkbox>(find.byKey(const ValueKey('mine-0'))).value,
      isTrue,
    );
    await tester.tap(find.byTooltip('Fit photo'));
    await tester.pump();
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
    expect(
      tester.widget<Checkbox>(find.byKey(const ValueKey('mine-0'))).value,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a zoomed number badge selects its linked tile outside the box', (
    tester,
  ) async {
    await openReview(tester);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    await tester.drag(find.byType(InteractiveViewer), const Offset(100, 70));
    await tester.pumpAndSettle();
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final zoom = viewer.transformationController!.value.getMaxScaleOnAxis();
    final photo = tester.getRect(find.byType(Image));
    final baseSize = Size(photo.width / zoom, photo.height / zoom);
    final badge = layoutDominoBadge(
      label: '#1',
      tileBounds: Rect.fromLTWH(
        baseSize.width * .1,
        baseSize.height * .2,
        baseSize.width * .35,
        baseSize.height * .3,
      ),
      imageSize: baseSize,
      zoom: zoom,
    );
    final point = photo.topLeft + badge.bounds.center * zoom;
    expect(
      tester.getRect(find.byType(InteractiveViewer)).contains(point),
      isTrue,
    );
    await tester.tapAt(point);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Checkbox>(find.byKey(const ValueKey('mine-0'))).value,
      isTrue,
    );
  });

  testWidgets('pinch zoom changes the image scale without selecting a tile', (
    tester,
  ) async {
    await openReview(tester);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final center = tester.getCenter(find.byType(InteractiveViewer));
    final first = await tester.startGesture(
      center + const Offset(-30, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 2,
    );
    await tester.pump();
    await first.moveTo(center + const Offset(-90, 0));
    await second.moveTo(center + const Offset(90, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );
    expect(
      tester.widget<Checkbox>(find.byKey(const ValueKey('mine-0'))).value,
      isFalse,
    );
  });

  testWidgets(
    'correcting a pip updates both its score and confirmation state',
    (tester) async {
      final report = exampleReport();
      await openReview(tester, report: report);
      await tester.tap(find.byKey(const ValueKey('mine-0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('no-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('edit-a')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('15').last,
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('15').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SAVE CORRECT VALUES'));
      await tester.pumpAndSettle();
      expect(find.text('YOUR SCORE: 19'), findsOneWidget);
      expect(report.detections.first.pipA, 0);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('no opens correction and can exclude a false detection', (
    tester,
  ) async {
    await openReview(tester);
    await tester.tap(find.byKey(const ValueKey('mine-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('no-0')));
    await tester.pumpAndSettle();
    expect(find.text('CORRECT TILE #1'), findsOneWidget);
    await tester.tap(find.text('NOT A DOMINO · EXCLUDE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('EXCLUDED'), findsOneWidget);
    expect(find.text('ADD 0 TILES'), findsOneWidget);
    await tester.tap(find.text('UNDO'));
    await tester.pump();
    expect(find.textContaining('EXCLUDED'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('maximum pips remain usable with larger text on a small phone', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final original = exampleReport();
    final report = DetectionReport(
      detections: const [
        DetectionResult(
          label: '15 | 15',
          confidence: .9,
          boundingBox: Rect.fromLTWH(.1, .2, .35, .3),
          pipA: 15,
          pipB: 15,
        ),
      ],
      imageSize: original.imageSize,
      imageBytes: original.imageBytes,
      processingTime: Duration.zero,
    );
    await openReview(tester, report: report);
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('review fits a narrow phone and captures its actual appearance', (
    tester,
  ) async {
    final key = GlobalKey();
    await openReview(tester, captureKey: key);
    await tester.tap(find.byKey(const ValueKey('mine-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('yes-0')));
    await tester.pump();
    await tester.pumpAndSettle();
    final output = Platform.environment['DOMINO_REVIEW_SCREENSHOT'];
    if (output != null) {
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ImageByteFormat.png);
        await File(output).writeAsBytes(bytes!.buffer.asUint8List());
      });
    }
    for (final size in [
      const Size(375, 667),
      const Size(320, 568),
      const Size(844, 390),
      const Size(1194, 834),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Review should fit $size');
    }
  });
}
