import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/services/domino_geometry.dart';
import 'package:dominoes/services/image_utils.dart';
import 'package:dominoes/services/tflite_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'rotated NMS decodes channels, rejects threshold and suppresses duplicates',
    () {
      final output = Float32List.fromList([
        .5,
        .5,
        .1,
        .8,
        .5,
        .5,
        .1,
        .8,
        .2,
        .2,
        .1,
        .1,
        .1,
        .1,
        .05,
        .05,
        .9,
        .8,
        .25,
        .7,
        0,
        0,
        0,
        0,
      ]);
      final boxes = decodeDominoBoxes(output, candidates: 4);
      expect(boxes, hasLength(2));
      expect(boxes.first.x, closeTo(320, 1e-5));
      expect(boxes.first.width, closeTo(128, 1e-5));
      expect(
        polygonIou(boxes.first.corners, boxes.first.corners),
        closeTo(1, 1e-6),
      );
    },
  );

  test('letterbox inverse preserves a portrait photo without stretching', () {
    final box = DominoLetterbox(100, 200);
    expect(box.resizedWidth, 320);
    expect(box.left, 160);
    expect(box.toSource(const Offset(320, 320)), const Offset(50, 100));
  });

  test('rectification preserves RGB 0..255 and splits the long edge', () {
    final source = img.Image(width: 256, height: 128);
    for (var y = 0; y < 128; y++) {
      for (var x = 0; x < 256; x++) {
        source.setPixelRgb(x, y, x < 128 ? 255 : 0, y, x < 128 ? 0 : 255);
      }
    }
    final halves = ImageUtils.tileHalves(source, const [
      Offset(0, 0),
      Offset(255, 0),
      Offset(255, 127),
      Offset(0, 127),
    ]);
    expect(halves[0].take(3), [255, 0, 0]);
    expect(halves[1].take(3), [0, 0, 255]);
    expect(halves[0].sublist(127 * 128 * 3, 127 * 128 * 3 + 3), [255, 127, 0]);
    expect(
      () => ImageUtils.tileHalves(source, List.filled(4, Offset.zero)),
      throwsArgumentError,
    );
  });

  test('long-edge orientation matches NumPy float32 tie breaking', () {
    final points = canonicalTileCorners(const [
      Offset(120.234571, 90.654327),
      Offset(32.345678, 41.234567),
      Offset(10.765431, 80.123456),
      Offset(98.654328, 129.543215),
    ]);
    expect(points.first.dx, closeTo(32.34567642211914, 1e-8));
    expect(points.first.dy, closeTo(41.23456573486328, 1e-8));
  });

  test('blank scoring preserves actual zero labels and incomplete tiles', () {
    const tile = DetectionResult(
      label: '0 | 4',
      confidence: .9,
      boundingBox: Rect.zero,
      pipA: 0,
      pipB: 4,
    );
    expect(tile.score(50), 54);
    expect(tile.score(25), 29);
    expect(tile.score(0), 4);
    const unreadable = DetectionResult(
      label: 'Unreadable',
      confidence: .1,
      boundingBox: Rect.zero,
    );
    expect(unreadable.score(50), isNull);
    expect(unreadable.needsReview, isTrue);
  });

  test(
    'native models load, reject bad images, recover and process private test photos',
    () async {
      final detector = TfliteDetector();
      addTearDown(detector.dispose);
      await Future.wait([detector.initialize(), detector.initialize()]);
      expect(detector.isInitialized, isTrue);
      await expectLater(detector.detect(Uint8List(0)), throwsStateError);
      final paths = Platform.environment['DOMINO_PRIVATE_TEST_PHOTOS'];
      final photos = paths == null
          ? <String>[]
          : List<String>.from(
              jsonDecode(File(paths).readAsStringSync()) as List,
            );
      final results = [];
      if (photos.isEmpty) {
        final source = img.Image(width: 256, height: 128);
        img.fill(source, color: img.ColorRgb8(114, 114, 114));
        final report = await detector.detect(img.encodePng(source));
        expect(report.imageSize, const Size(256, 128));
      }
      for (final path in photos) {
        final report = await detector.detect(await File(path).readAsBytes());
        expect(report.imageBytes, isNotEmpty);
        expect(
          report.detections.every(
            (d) => d.hasValues && d.pipA! >= 0 && d.pipB! <= 15,
          ),
          isTrue,
        );
        results.add({
          'tiles': report.detections.length,
          'milliseconds': report.processingTime.inMilliseconds,
          'predictions': [
            for (final d in report.detections)
              {
                'a': d.pipA,
                'b': d.pipB,
                'confidence': d.confidence,
                'corners': d.corners.map((p) => [p.dx, p.dy]).toList(),
                'review': d.reviewReasons,
              },
          ],
        });
      }
      if (paths != null) {
        File(
          '/tmp/domino-mobile-dart-comparison.json',
        ).writeAsStringSync(jsonEncode(results));
      }
    },
    skip: Platform.environment['DOMINO_NATIVE_MODEL_TEST'] != '1',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
