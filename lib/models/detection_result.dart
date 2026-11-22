import 'dart:ui';
import 'dart:typed_data';

class DetectionResult {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final List<Offset> corners;
  final int? pipA;
  final int? pipB;
  final List<String> reviewReasons;

  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    this.corners = const [],
    this.pipA,
    this.pipB,
    this.reviewReasons = const [],
  });

  bool get hasValues => pipA != null && pipB != null;
  bool get needsReview => !hasValues || reviewReasons.isNotEmpty;
  int? score(int blankValue) => hasValues
      ? (pipA == 0 ? blankValue : pipA!) + (pipB == 0 ? blankValue : pipB!)
      : null;

  @override
  String toString() =>
      'DetectionResult(label: $label, confidence: ${(confidence * 100).toStringAsFixed(1)}%, box: $boundingBox)';
}

class DetectionReport {
  final List<DetectionResult> detections;
  final Size imageSize;
  final Uint8List imageBytes;
  final Duration processingTime;

  const DetectionReport({
    required this.detections,
    required this.imageSize,
    required this.imageBytes,
    required this.processingTime,
  });
}
