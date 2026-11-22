import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/models/detection_result.dart';
import 'package:flutter/foundation.dart';

enum TileDecision { pending, accepted, rejected }

class ReviewedTile {
  final DetectionResult detection;
  final int? a;
  final int? b;
  final bool mine;
  final TileDecision decision;

  ReviewedTile(
    this.detection, {
    int? a,
    int? b,
    this.mine = false,
    this.decision = TileDecision.pending,
  }) : a = a ?? detection.pipA,
       b = b ?? detection.pipB;

  bool get hasValues => a != null && b != null;
  bool get counts => mine && decision == TileDecision.accepted && hasValues;

  ReviewedTile copy({int? a, int? b, bool? mine, TileDecision? decision}) =>
      ReviewedTile(
        detection,
        a: a ?? this.a,
        b: b ?? this.b,
        mine: mine ?? this.mine,
        decision: decision ?? this.decision,
      );
}

/// Review state belongs to this captured photo, never to the trained predictions.
class DominoReview extends ChangeNotifier {
  final List<ReviewedTile> _tiles;
  DominoReview(List<DetectionResult> detections)
    : _tiles = detections.map(ReviewedTile.new).toList();

  List<ReviewedTile> get tiles => List.unmodifiable(_tiles);
  int get mineCount =>
      _tiles.where((t) => t.mine && t.decision != TileDecision.rejected).length;
  int get pendingMine => _tiles.where((t) => t.mine && !t.counts).length;
  bool get canAdd => mineCount > 0 && pendingMine == 0;

  void toggleMine(int index) {
    final tile = _tiles[index];
    _tiles[index] = tile.copy(
      mine: !tile.mine,
      decision: tile.decision == TileDecision.rejected
          ? TileDecision.pending
          : tile.decision,
    );
    notifyListeners();
  }

  void selectAll(bool selected) {
    for (var i = 0; i < _tiles.length; i++) {
      if (_tiles[i].decision != TileDecision.rejected)
        _tiles[i] = _tiles[i].copy(mine: selected);
    }
    notifyListeners();
  }

  void accept(int index) {
    if (!_tiles[index].hasValues) return;
    _tiles[index] = _tiles[index].copy(decision: TileDecision.accepted);
    notifyListeners();
  }

  void reject(int index) {
    _tiles[index] = _tiles[index].copy(
      mine: false,
      decision: TileDecision.rejected,
    );
    notifyListeners();
  }

  void restore(int index) {
    _tiles[index] = _tiles[index].copy(decision: TileDecision.pending);
    notifyListeners();
  }

  void correct(int index, int a, int b) {
    DominoPips.fromInt(a);
    DominoPips.fromInt(b);
    _tiles[index] = _tiles[index].copy(
      a: a,
      b: b,
      decision: TileDecision.accepted,
    );
    notifyListeners();
  }

  int total(int blankValue) => _tiles
      .where((t) => t.counts)
      .fold(
        0,
        (sum, t) =>
            sum +
            (t.a == 0 ? blankValue : t.a!) +
            (t.b == 0 ? blankValue : t.b!),
      );

  List<DominoPips> valuesToAdd() {
    if (!canAdd)
      throw StateError('Confirm the values of your selected tiles first.');
    return [
      for (final tile in _tiles.where((t) => t.counts)) ...[
        DominoPips.fromInt(tile.a!),
        DominoPips.fromInt(tile.b!),
      ],
    ];
  }
}
