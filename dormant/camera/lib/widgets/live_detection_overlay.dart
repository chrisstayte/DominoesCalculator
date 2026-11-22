import 'dart:math' as math;

import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/services/live_detection_tracker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Painted in the same portrait scene as CameraPreview, before BoxFit.cover.
/// Thus cropping and rotation move the camera texture and boxes together.
class LiveDetectionOverlay extends CustomPainter {
  final List<DetectionResult> detections;
  final List<double>? opacities;
  final Color color;
  const LiveDetectionOverlay({
    required this.detections,
    required this.color,
    this.opacities,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < detections.length; i++) {
      final detection = detections[i];
      final opacity = opacities?[i] ?? 1.0;
      if (opacity <= 0) continue;
      final path = Path();
      if (detection.corners.length == 4) {
        path.addPolygon(
          detection.corners
              .map((p) => Offset(p.dx * size.width, p.dy * size.height))
              .toList(),
          true,
        );
      } else {
        path.addRect(
          Rect.fromLTRB(
            detection.boundingBox.left * size.width,
            detection.boundingBox.top * size.height,
            detection.boundingBox.right * size.width,
            detection.boundingBox.bottom * size.height,
          ),
        );
      }
      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: .12 * opacity),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 4,
      );
    }
  }

  @override
  bool shouldRepaint(LiveDetectionOverlay oldDelegate) =>
      !identical(detections, oldDelegate.detections) ||
      !identical(opacities, oldDelegate.opacities) ||
      color != oldDelegate.color;
}

class _ShownBox {
  List<Offset> corners;
  List<Offset> target;
  double opacity = 0;
  double targetOpacity = 1;
  _ShownBox(List<Offset> corners)
    : corners = List.of(corners),
      target = corners;
}

/// Draws tracked live boxes and glides them between detector updates at the
/// display refresh rate, so ~5–10 Hz detections read as smooth motion. Boxes
/// fade in and out instead of popping. Only this layer repaints per frame.
class LiveDetectionBoxes extends StatefulWidget {
  final ValueListenable<List<TrackedDetection>> tracks;
  final Color color;
  const LiveDetectionBoxes({
    super.key,
    required this.tracks,
    required this.color,
  });

  @override
  State<LiveDetectionBoxes> createState() => _LiveDetectionBoxesState();
}

class _LiveDetectionBoxesState extends State<LiveDetectionBoxes>
    with SingleTickerProviderStateMixin {
  static const _positionTau = 70.0; // ms
  static const _fadeTau = 90.0; // ms
  final _boxes = <int, _ShownBox>{};
  final _repaint = ValueNotifier<int>(0);
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  List<DetectionResult> _detections = const [];
  List<double> _opacities = const [];

  @override
  void initState() {
    super.initState();
    widget.tracks.addListener(_onTracks);
    _onTracks();
  }

  @override
  void didUpdateWidget(LiveDetectionBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tracks != widget.tracks) {
      oldWidget.tracks.removeListener(_onTracks);
      widget.tracks.addListener(_onTracks);
      _onTracks();
    }
  }

  @override
  void dispose() {
    widget.tracks.removeListener(_onTracks);
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _onTracks() {
    final seen = <int>{};
    for (final track in widget.tracks.value) {
      seen.add(track.id);
      final corners = track.detection.corners.length == 4
          ? track.detection.corners
          : [
              track.detection.boundingBox.topLeft,
              track.detection.boundingBox.topRight,
              track.detection.boundingBox.bottomRight,
              track.detection.boundingBox.bottomLeft,
            ];
      final box = _boxes.putIfAbsent(track.id, () => _ShownBox(corners));
      box.target = corners;
      box.targetOpacity = 1;
    }
    for (final entry in _boxes.entries) {
      if (!seen.contains(entry.key)) entry.value.targetOpacity = 0;
    }
    _publish();
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 16.0
        : (elapsed - _last).inMicroseconds / 1000;
    _last = elapsed;
    final move = 1 - math.exp(-dt / _positionTau);
    final fade = 1 - math.exp(-dt / _fadeTau);
    var settled = true;
    _boxes.removeWhere((_, box) {
      box.opacity += (box.targetOpacity - box.opacity) * fade;
      if ((box.targetOpacity - box.opacity).abs() < .01) {
        box.opacity = box.targetOpacity;
      } else {
        settled = false;
      }
      if (box.targetOpacity == 0 && box.opacity == 0) return true;
      for (var i = 0; i < box.corners.length; i++) {
        final delta = box.target[i] - box.corners[i];
        if (delta.distanceSquared < 1e-8) {
          box.corners[i] = box.target[i];
        } else {
          box.corners[i] += delta * move;
          settled = false;
        }
      }
      return false;
    });
    _publish();
    if (settled) _ticker.stop();
  }

  void _publish() {
    final ids = _boxes.keys.toList();
    _detections = [
      for (final id in ids)
        DetectionResult(
          label: 'Domino',
          confidence: 1,
          boundingBox: Rect.zero,
          corners: List.of(_boxes[id]!.corners),
        ),
    ];
    _opacities = [for (final id in ids) _boxes[id]!.opacity];
    _repaint.value++;
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    key: const ValueKey('live-domino-boxes'),
    painter: _AnimatedOverlay(this, widget.color),
  );
}

class _AnimatedOverlay extends CustomPainter {
  final _LiveDetectionBoxesState state;
  final Color color;
  _AnimatedOverlay(this.state, this.color) : super(repaint: state._repaint);

  @override
  void paint(Canvas canvas, Size size) => LiveDetectionOverlay(
    detections: state._detections,
    opacities: state._opacities,
    color: color,
  ).paint(canvas, size);

  @override
  bool shouldRepaint(_AnimatedOverlay oldDelegate) =>
      color != oldDelegate.color;
}
