import 'dart:typed_data';

import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/models/preview_frame.dart';

abstract class ObjectDetector {
  Future<void> initialize();
  Future<DetectionReport> detect(Uint8List imageBytes);
  Future<PreviewDetections> detectPreview(PreviewFrame frame);
  void dispose();
  bool get isInitialized;
}
