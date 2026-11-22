import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/services/domino_geometry.dart';
import 'package:dominoes/services/image_utils.dart';
import 'package:dominoes/services/object_detector.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_litert/flutter_litert.dart';
import 'package:image/image.dart' as img;

/// Both interpreters and all image processing live in a persistent worker.
/// Photos and predictions remain on the device.
class TfliteDetector implements ObjectDetector {
  static const manifestPath = 'assets/models/domino_models.json';
  ReceivePort? _receive;
  SendPort? _worker;
  Future<void>? _initializing;
  Completer<void>? _ready;
  final _pending = <int, Completer<Map<Object?, Object?>>>{};
  int _nextId = 0;
  bool _initialized = false;
  bool _disposed = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() {
    if (_disposed) return Future.error(StateError('Detector is disposed.'));
    if (_initialized) return Future.value();
    return _initializing ??= _start().whenComplete(() => _initializing = null);
  }

  Future<void> _start() async {
    final manifest =
        jsonDecode(await rootBundle.loadString(manifestPath))
            as Map<String, dynamic>;
    final detector = manifest['detector'] as Map<String, dynamic>;
    final classifier = manifest['classifier'] as Map<String, dynamic>;
    final detectorAsset = await rootBundle.load(detector['asset'] as String);
    final classifierAsset = await rootBundle.load(
      classifier['asset'] as String,
    );
    if (_disposed) throw StateError('Detector is disposed.');
    _ready = Completer<void>();
    _receive = ReceivePort();
    _receive!.listen((dynamic message) {
      if (message is! Map) {
        _fail(StateError('Model worker stopped unexpectedly.'));
        return;
      }
      switch (message['type']) {
        case 'port':
          _worker = message['port'] as SendPort;
          if (_disposed) {
            _worker!.send(null);
            _receive?.close();
          }
        case 'ready':
          if (_disposed) return;
          _initialized = true;
          if (!_ready!.isCompleted) _ready!.complete();
        case 'fatal':
          _fail(StateError(message['error'] as String));
        case 'result':
        case 'error':
          final completer = _pending.remove(message['id']);
          if (message['type'] == 'error') {
            completer?.completeError(StateError(message['error'] as String));
          } else {
            completer?.complete(Map<Object?, Object?>.from(message));
          }
      }
    });
    try {
      await Isolate.spawn(
        _modelWorker,
        {
          'reply': _receive!.sendPort,
          'detector': TransferableTypedData.fromList([
            detectorAsset.buffer.asUint8List(
              detectorAsset.offsetInBytes,
              detectorAsset.lengthInBytes,
            ),
          ]),
          'classifier': TransferableTypedData.fromList([
            classifierAsset.buffer.asUint8List(
              classifierAsset.offsetInBytes,
              classifierAsset.lengthInBytes,
            ),
          ]),
          'detectorHash': detector['sha256'],
          'classifierHash': classifier['sha256'],
        },
        onError: _receive!.sendPort,
        onExit: _receive!.sendPort,
      );
      await _ready!.future;
    } catch (_) {
      _worker?.send(null);
      _worker = null;
      _receive?.close();
      _ready = null;
      rethrow;
    }
  }

  void _fail(Object error) {
    _initialized = false;
    if (_ready != null && !_ready!.isCompleted) _ready!.completeError(error);
    for (final pending in _pending.values) {
      pending.completeError(error);
    }
    _pending.clear();
    if (_worker != null) {
      _worker!.send(null);
      _worker = null;
      _receive?.close();
    }
  }

  @override
  Future<DetectionReport> detect(Uint8List imageBytes) async {
    if (!_initialized || _disposed) throw StateError('Detector is not ready.');
    if (_pending.isNotEmpty) {
      throw StateError('A photo is already being processed.');
    }
    final id = _nextId++;
    final completer = Completer<Map<Object?, Object?>>();
    _pending[id] = completer;
    _worker!.send({
      'id': id,
      'image': TransferableTypedData.fromList([imageBytes]),
    });
    final result = await completer.future;
    final size = Size(
      (result['width'] as int).toDouble(),
      (result['height'] as int).toDouble(),
    );
    final detections = (result['detections'] as List).map((dynamic item) {
      final points = (item['corners'] as List)
          .map((dynamic p) => Offset(p[0] / size.width, p[1] / size.height))
          .toList();
      final xs = points.map((p) => p.dx), ys = points.map((p) => p.dy);
      final a = item['a'] as int?, b = item['b'] as int?;
      return DetectionResult(
        label: a == null || b == null ? 'Unreadable tile' : '$a | $b',
        confidence: item['confidence'] as double,
        boundingBox: Rect.fromLTRB(
          xs.reduce(math.min),
          ys.reduce(math.min),
          xs.reduce(math.max),
          ys.reduce(math.max),
        ),
        corners: List.unmodifiable(points),
        pipA: a,
        pipB: b,
        reviewReasons: List<String>.unmodifiable(item['review'] as List),
      );
    }).toList();
    return DetectionReport(
      detections: List.unmodifiable(detections),
      imageSize: size,
      imageBytes: (result['image'] as TransferableTypedData)
          .materialize()
          .asUint8List(),
      processingTime: Duration(microseconds: result['microseconds'] as int),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _fail(StateError('Detector is disposed.'));
  }
}

Float32List _invoke(Interpreter interpreter, Float32List input) {
  interpreter.getInputTensor(0).data = input.buffer.asUint8List(
    input.offsetInBytes,
    input.lengthInBytes,
  );
  interpreter.invoke();
  final data = interpreter.getOutputTensor(0).data;
  return Float32List.fromList(
    data.buffer.asFloat32List(data.offsetInBytes, data.lengthInBytes ~/ 4),
  );
}

void _checkTensor(Interpreter interpreter, List<int> input, List<int> output) {
  if (interpreter.getInputTensors().length != 1 ||
      interpreter.getOutputTensors().length != 1 ||
      interpreter.getInputTensor(0).shape.join(',') != input.join(',') ||
      interpreter.getOutputTensor(0).shape.join(',') != output.join(',') ||
      interpreter.getInputTensor(0).type != TensorType.float32 ||
      interpreter.getOutputTensor(0).type != TensorType.float32) {
    throw StateError('Bundled model tensor contract does not match this app.');
  }
}

void _modelWorker(Map<String, Object?> config) async {
  final reply = config['reply'] as SendPort;
  final port = ReceivePort();
  reply.send({'type': 'port', 'port': port.sendPort});
  Interpreter? detector, classifier;
  try {
    final detectorBytes = (config['detector'] as TransferableTypedData)
        .materialize()
        .asUint8List();
    final classifierBytes = (config['classifier'] as TransferableTypedData)
        .materialize()
        .asUint8List();
    if (sha256.convert(detectorBytes).toString() != config['detectorHash'] ||
        sha256.convert(classifierBytes).toString() !=
            config['classifierHash']) {
      throw StateError('Bundled model integrity check failed.');
    }
    final options = InterpreterOptions()..threads = 2;
    try {
      detector = Interpreter.fromBuffer(detectorBytes, options: options);
      classifier = Interpreter.fromBuffer(classifierBytes, options: options);
    } finally {
      options.delete();
    }
    _checkTensor(detector, [1, 3, 640, 640], [1, 6, 8400]);
    _checkTensor(classifier, [1, 128, 128, 3], [1, 16]);
    reply.send({'type': 'ready'});
    await for (final dynamic message in port) {
      if (message == null) break;
      try {
        final watch = Stopwatch()..start();
        final source = ImageUtils.decodeUpright(
          (message['image'] as TransferableTypedData)
              .materialize()
              .asUint8List(),
        );
        final letterbox = DominoLetterbox(source.width, source.height);
        final boxes = decodeDominoBoxes(
          _invoke(detector, ImageUtils.detectorInput(source, letterbox)),
        );
        final corners = boxes
            .map((b) => b.corners.map(letterbox.toSource).toList())
            .toList();
        final detections = <Map<String, Object?>>[];
        for (var i = 0; i < boxes.length; i++) {
          final review = <String>[];
          if (corners[i].any(
            (p) =>
                p.dx < 0 ||
                p.dy < 0 ||
                p.dx >= source.width ||
                p.dy >= source.height,
          )) {
            review.add('Tile extends outside photo');
          }
          if (boxes[i].confidence < 0.8) review.add('Low detector confidence');
          if (List.generate(
            boxes.length,
            (j) => j,
          ).any((j) => j != i && polygonIou(corners[i], corners[j]) > 0.5)) {
            review.add('Overlapping detections');
          }
          int? a, b;
          var confidence = boxes[i].confidence;
          try {
            final halves = ImageUtils.tileHalves(source, corners[i]);
            final values = <int>[];
            for (final half in halves) {
              final probabilities = _invoke(classifier, half);
              if (probabilities.any((v) => !v.isFinite || v < 0 || v > 1.001)) {
                throw StateError('Invalid classifier output.');
              }
              var best = 0;
              for (var c = 1; c < 16; c++) {
                if (probabilities[c] > probabilities[best]) best = c;
              }
              values.add(best);
              confidence = math.min(confidence, probabilities[best]);
            }
            a = values[0];
            b = values[1];
            if (confidence < 0.8) review.add('Check pip values');
          } on ArgumentError {
            review.add('Unreadable tile geometry');
          }
          detections.add({
            'a': a,
            'b': b,
            'confidence': confidence,
            'review': review,
            'corners': corners[i].map((p) => [p.dx, p.dy]).toList(),
          });
        }
        final display = img.encodeJpg(source, quality: 92);
        reply.send({
          'type': 'result',
          'id': message['id'],
          'detections': detections,
          'width': source.width,
          'height': source.height,
          'image': TransferableTypedData.fromList([display]),
          'microseconds': watch.elapsedMicroseconds,
        });
      } catch (error) {
        reply.send({
          'type': 'error',
          'id': message['id'],
          'error': error.toString(),
        });
      }
    }
  } catch (error) {
    reply.send({'type': 'fatal', 'error': error.toString()});
  } finally {
    detector?.close();
    classifier?.close();
    port.close();
  }
}
