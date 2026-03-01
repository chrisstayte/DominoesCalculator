import 'dart:typed_data';

import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/services/image_utils.dart';
import 'package:dominoes/services/object_detector.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_litert/flutter_litert.dart';
import 'dart:ui';

class TfliteDetector implements ObjectDetector {
  static const String _modelPath = 'assets/models/ssd_mobilenet_v1.tflite';
  static const String _labelsPath = 'assets/models/coco_labels.txt';
  static const int _inputSize = 300;
  static const double _confidenceThreshold = 0.5;
  static const int _maxDetections = 10;

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  List<String> _labels = [];
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    _interpreter = await Interpreter.fromAsset(_modelPath);
    _isolateInterpreter = await IsolateInterpreter.create(
      address: _interpreter!.address,
    );

    final labelsData = await rootBundle.loadString(_labelsPath);
    _labels = labelsData
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    _initialized = true;
  }

  @override
  Future<List<DetectionResult>> detect(Uint8List imageBytes) async {
    if (!_initialized) {
      throw StateError('Detector not initialized. Call initialize() first.');
    }

    final inputBuffer = ImageUtils.preprocessForModel(imageBytes, _inputSize);
    final input = inputBuffer.reshape([1, _inputSize, _inputSize, 3]);

    // SSD MobileNet V1 output tensors:
    // 0: detection_boxes [1, 10, 4] - float32
    // 1: detection_classes [1, 10] - float32
    // 2: detection_scores [1, 10] - float32
    // 3: num_detections [1] - float32
    final outputBoxes = List.generate(
      1,
      (_) => List.generate(_maxDetections, (_) => List.filled(4, 0.0)),
    );
    final outputClasses = List.generate(
      1,
      (_) => List.filled(_maxDetections, 0.0),
    );
    final outputScores = List.generate(
      1,
      (_) => List.filled(_maxDetections, 0.0),
    );
    final numDetections = List.filled(1, 0.0);

    final outputs = <int, Object>{
      0: outputBoxes,
      1: outputClasses,
      2: outputScores,
      3: numDetections,
    };

    await _isolateInterpreter!.runForMultipleInputs([input], outputs);

    final results = <DetectionResult>[];
    final count = numDetections[0].toInt();

    for (var i = 0; i < count && i < _maxDetections; i++) {
      final score = outputScores[0][i];
      if (score < _confidenceThreshold) continue;

      final classIndex = outputClasses[0][i].toInt();
      final label = classIndex < _labels.length
          ? _labels[classIndex]
          : 'Unknown ($classIndex)';

      // Bounding box: [top, left, bottom, right] normalized 0-1
      final top = outputBoxes[0][i][0];
      final left = outputBoxes[0][i][1];
      final bottom = outputBoxes[0][i][2];
      final right = outputBoxes[0][i][3];

      results.add(DetectionResult(
        label: label,
        confidence: score,
        boundingBox: Rect.fromLTRB(left, top, right, bottom),
      ));
    }

    return results;
  }

  @override
  void dispose() {
    _isolateInterpreter?.close();
    _interpreter?.close();
    _isolateInterpreter = null;
    _interpreter = null;
    _initialized = false;
  }
}
