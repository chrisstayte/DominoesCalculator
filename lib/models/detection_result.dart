import 'dart:ui';

class DetectionResult {
  final String label;
  final double confidence;
  final Rect boundingBox;

  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  @override
  String toString() =>
      'DetectionResult(label: $label, confidence: ${(confidence * 100).toStringAsFixed(1)}%, box: $boundingBox)';
}
