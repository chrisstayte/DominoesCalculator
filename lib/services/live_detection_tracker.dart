import 'dart:math' as math;
import 'dart:ui';

import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/services/domino_geometry.dart';

/// A live detection that keeps the same [id] while it follows one domino.
class TrackedDetection {
  final int id;
  final DetectionResult detection;
  const TrackedDetection(this.id, this.detection);
}

class _Track {
  final int id;
  List<Offset> corners;
  double confidence;
  int hits = 1;
  int misses = 0;
  bool visible = false;
  _Track(this.id, this.corners, this.confidence);
}

/// Turns independent per-frame detector outputs into stable on-screen boxes.
///
/// The detector reports each frame from scratch: corner order can rotate,
/// positions wobble by a few pixels, and a domino can drop out of a single
/// frame. This tracker
/// * matches detections to existing tracks by polygon IoU (falling back to
///   centre distance for fast motion), so a domino keeps its identity;
/// * aligns corner order and applies an adaptive exponential moving average,
///   which damps small jitter but follows large, deliberate movement;
/// * adds hysteresis: a track appears after [minHits] consecutive frames
///   (or one confident frame) and survives [maxMisses] missed frames.
class LiveDetectionTracker {
  final double matchIou;
  final int minHits;
  final double instantConfidence;
  final int maxMisses;
  final _tracks = <_Track>[];
  int _nextId = 0;

  LiveDetectionTracker({
    this.matchIou = 0.15,
    this.minHits = 2,
    this.instantConfidence = 0.7,
    this.maxMisses = 3,
  });

  List<TrackedDetection> get visible => [
    for (final track in _tracks)
      if (track.visible) TrackedDetection(track.id, _result(track)),
  ];

  void reset() => _tracks.clear();

  List<TrackedDetection> update(List<DetectionResult> detections) {
    final incoming = [
      for (final detection in detections)
        if (_cornersOf(detection) case final corners?)
          (corners: corners, confidence: detection.confidence),
    ];

    // Greedy assignment, best overlap first.
    final pairs = <(double, int, int)>[];
    for (var t = 0; t < _tracks.length; t++) {
      final track = _tracks[t];
      final trackCenter = _center(track.corners);
      final trackSize = _size(track.corners);
      for (var d = 0; d < incoming.length; d++) {
        final corners = incoming[d].corners;
        final iou = polygonIou(track.corners, corners);
        final distance = (_center(corners) - trackCenter).distance;
        if (iou >= matchIou || distance < trackSize * .5) {
          final closeness = 1 - (distance / math.max(trackSize, 1e-6));
          pairs.add((iou + .1 * closeness, t, d));
        }
      }
    }
    pairs.sort((a, b) => b.$1.compareTo(a.$1));
    final matchedTracks = <int>{}, matchedDetections = <int>{};
    for (final (_, t, d) in pairs) {
      if (matchedTracks.contains(t) || matchedDetections.contains(d)) continue;
      matchedTracks.add(t);
      matchedDetections.add(d);
      final track = _tracks[t];
      final target = _align(track.corners, incoming[d].corners);
      // Adaptive smoothing: hold still through small wobble, but snap toward
      // the new position when the domino (or phone) really moves.
      var movement = 0.0;
      for (var i = 0; i < 4; i++) {
        movement += (target[i] - track.corners[i]).distance;
      }
      final ratio = movement / 4 / math.max(_size(track.corners), 1e-6);
      final alpha = (0.35 + ratio * 4).clamp(0.35, 1.0);
      track.corners = [
        for (var i = 0; i < 4; i++)
          Offset.lerp(track.corners[i], target[i], alpha)!,
      ];
      track.confidence += (incoming[d].confidence - track.confidence) * .4;
      track.hits++;
      track.misses = 0;
      if (track.hits >= minHits) track.visible = true;
    }

    for (var t = _tracks.length - 1; t >= 0; t--) {
      if (matchedTracks.contains(t)) continue;
      final track = _tracks[t];
      track.misses++;
      track.hits = 0;
      // Unconfirmed tracks are likely noise; confirmed ones get a grace period.
      if (!track.visible || track.misses > maxMisses) _tracks.removeAt(t);
    }
    for (var d = 0; d < incoming.length; d++) {
      if (matchedDetections.contains(d)) continue;
      final track = _Track(
        _nextId++,
        incoming[d].corners,
        incoming[d].confidence,
      );
      track.visible = incoming[d].confidence >= instantConfidence;
      _tracks.add(track);
    }
    return visible;
  }

  static DetectionResult _result(_Track track) {
    final xs = track.corners.map((p) => p.dx);
    final ys = track.corners.map((p) => p.dy);
    return DetectionResult(
      label: 'Domino',
      confidence: track.confidence,
      boundingBox: Rect.fromLTRB(
        xs.reduce(math.min),
        ys.reduce(math.min),
        xs.reduce(math.max),
        ys.reduce(math.max),
      ),
      corners: List.unmodifiable(track.corners),
    );
  }

  static List<Offset>? _cornersOf(DetectionResult detection) {
    final corners = detection.corners.length == 4
        ? detection.corners
        : [
            detection.boundingBox.topLeft,
            detection.boundingBox.topRight,
            detection.boundingBox.bottomRight,
            detection.boundingBox.bottomLeft,
          ];
    if (corners.any((p) => !p.dx.isFinite || !p.dy.isFinite)) return null;
    // Keep a consistent winding so corner alignment is a rotation only.
    return signedPolygonArea(corners) < 0
        ? corners.reversed.toList()
        : List<Offset>.of(corners);
  }

  static Offset _center(List<Offset> corners) =>
      corners.reduce((a, b) => a + b) / corners.length.toDouble();

  static double _size(List<Offset> corners) =>
      math.sqrt(signedPolygonArea(corners).abs());

  /// The detector can report the same rectangle starting at any corner (and
  /// its angle can flip by 180 degrees). Pick the rotation of [next] closest
  /// to [previous] so smoothing never swings corners across the tile.
  static List<Offset> _align(List<Offset> previous, List<Offset> next) {
    var best = 0, bestCost = double.infinity;
    for (var shift = 0; shift < 4; shift++) {
      var cost = 0.0;
      for (var i = 0; i < 4; i++) {
        cost += (next[(i + shift) % 4] - previous[i]).distanceSquared;
      }
      if (cost < bestCost) {
        bestCost = cost;
        best = shift;
      }
    }
    return [for (var i = 0; i < 4; i++) next[(i + best) % 4]];
  }
}
