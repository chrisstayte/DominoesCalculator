import 'dart:typed_data';

import 'package:dominoes/models/detection_result.dart';

abstract class ObjectDetector {
  Future<void> initialize();
  Future<List<DetectionResult>> detect(Uint8List imageBytes);
  void dispose();
  bool get isInitialized;
}
