import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/models/detection_result.dart';
import 'package:flutter/foundation.dart';

class ReviewedTile {
  final DetectionResult detection;
  final bool selected;

  const ReviewedTile(this.detection, {this.selected = false});

  int? get a => detection.pipA;
  int? get b => detection.pipB;

  /// Only tiles the model could read can be confirmed; there is no editing.
  bool get readable => a != null && b != null;

  String get label => readable ? '$a | $b' : '?';

  ReviewedTile copy({bool? selected}) =>
      ReviewedTile(detection, selected: selected ?? this.selected);
}

/// Review state belongs to this captured photo, never to the trained predictions.
/// The user taps each box whose reading is correct, then adds those tiles.
class DominoReview extends ChangeNotifier {
  final List<ReviewedTile> _tiles;
  DominoReview(List<DetectionResult> detections)
    : _tiles = detections.map(ReviewedTile.new).toList();

  List<ReviewedTile> get tiles => List.unmodifiable(_tiles);
  int get selectedCount => _tiles.where((t) => t.selected).length;
  bool get canAdd => selectedCount > 0;

  /// Returns false when the tile cannot be selected because it is unreadable.
  bool toggle(int index) {
    final tile = _tiles[index];
    if (!tile.readable) return false;
    _tiles[index] = tile.copy(selected: !tile.selected);
    notifyListeners();
    return true;
  }

  int total(int blankValue) => _tiles
      .where((t) => t.selected)
      .fold(
        0,
        (sum, t) =>
            sum +
            (t.a == 0 ? blankValue : t.a!) +
            (t.b == 0 ? blankValue : t.b!),
      );

  List<DominoPips> valuesToAdd() => [
    for (final tile in _tiles.where((t) => t.selected)) ...[
      DominoPips.fromInt(tile.a!),
      DominoPips.fromInt(tile.b!),
    ],
  ];
}
