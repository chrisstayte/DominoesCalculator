import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/models/domino_review.dart';
import 'package:dominoes/widgets/domino_badge_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _selectedColor = Color(0xff00dc83);
const _unselectedColor = Color(0xffffce32);

/// Full-screen review of a captured photo. Every detected box is drawn on the
/// image; the user taps the boxes whose readings are correct (they turn green)
/// and taps DONE to add those tiles to the calculator.
class DominoResultsView extends StatefulWidget {
  final DetectionReport report;
  final int blankValue;
  final bool showConfidence;
  final Color accentColor;
  final VoidCallback onRetake;
  final ValueChanged<List<DominoPips>> onAdd;

  const DominoResultsView({
    super.key,
    required this.report,
    required this.blankValue,
    required this.showConfidence,
    required this.accentColor,
    required this.onRetake,
    required this.onAdd,
  });

  @override
  State<DominoResultsView> createState() => _DominoResultsViewState();
}

class _DominoResultsViewState extends State<DominoResultsView> {
  late DominoReview _review;
  final _transform = TransformationController();
  Size _viewport = Size.zero;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _review = DominoReview(widget.report.detections);
  }

  @override
  void didUpdateWidget(DominoResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.report != oldWidget.report) {
      _review.dispose();
      _review = DominoReview(widget.report.detections);
      _submitted = false;
      _transform.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _review.dispose();
    _transform.dispose();
    super.dispose();
  }

  String _label(ReviewedTile tile) => widget.showConfidence && tile.readable
      ? '${tile.label} · ${(tile.detection.confidence * 100).round()}%'
      : tile.label;

  void _tapPhoto(Offset local, Size size) {
    final tiles = _review.tiles;
    final normalized = Offset(local.dx / size.width, local.dy / size.height);
    final hits = <int>[];
    final zoom = _transform.value.getMaxScaleOnAxis();
    for (var i = 0; i < tiles.length; i++) {
      final path = _tilePath(tiles[i].detection, size);
      final badge = layoutDominoBadge(
        label: _label(tiles[i]),
        tileBounds: path.getBounds(),
        imageSize: size,
        zoom: zoom,
        style: _badgeStyle,
      );
      if (_tilePath(
            tiles[i].detection,
            const Size(1, 1),
          ).contains(normalized) ||
          badge.bounds.contains(local))
        hits.add(i);
    }
    if (hits.isEmpty) return;
    // Smaller boxes remain reachable when a false box crosses multiple tiles.
    hits.sort(
      (a, b) => tiles[a].detection.boundingBox.size.area.compareTo(
        tiles[b].detection.boundingBox.size.area,
      ),
    );
    if (!_review.toggle(hits.first)) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("That tile couldn't be read. Retake to try again."),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  void _zoom(double factor) {
    final current = _transform.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(1.0, 8.0);
    final center = _viewport.center(Offset.zero);
    final point = _transform.toScene(center);
    _transform.value = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(next)
      ..translate(-point.dx, -point.dy);
  }

  Widget _photo() => LayoutBuilder(
    builder: (context, constraints) {
      _viewport = constraints.biggest;
      final size = applyBoxFit(
        BoxFit.contain,
        widget.report.imageSize,
        _viewport,
      ).destination;
      return InteractiveViewer(
        key: const ValueKey('review-photo-zoom'),
        transformationController: _transform,
        minScale: 1,
        maxScale: 8,
        boundaryMargin: const EdgeInsets.all(48),
        child: SizedBox(
          width: _viewport.width,
          height: _viewport.height,
          child: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _tapPhoto(details.localPosition, size),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      widget.report.imageBytes,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                    ),
                    CustomPaint(
                      painter: _ReviewOverlay(
                        tiles: _review.tiles,
                        labels: _review.tiles.map(_label).toList(),
                        transform: _transform,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _zoomControls() => Material(
    color: Colors.black87,
    borderRadius: BorderRadius.circular(8),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Zoom out',
          color: Colors.white,
          onPressed: () => _zoom(1 / 1.5),
          icon: const Icon(Icons.remove),
        ),
        IconButton(
          tooltip: 'Fit photo',
          color: Colors.white,
          onPressed: () => _transform.value = Matrix4.identity(),
          icon: const Icon(Icons.fit_screen),
        ),
        IconButton(
          tooltip: 'Zoom in',
          color: Colors.white,
          onPressed: () => _zoom(1.5),
          icon: const Icon(Icons.add),
        ),
      ],
    ),
  );

  Widget _bottomBar() {
    final count = _review.selectedCount;
    final empty = _review.tiles.isEmpty;
    final hint = empty
        ? 'No dominoes found. Retake closer, with every tile visible.'
        : count == 0
        ? 'Tap each box that is correct.'
        : '$count selected · ${_review.total(widget.blankValue)} points';
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
    return Container(
      color: Colors.black.withValues(alpha: .72),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                hint,
                key: const ValueKey('review-hint'),
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: widget.onRetake,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: shape,
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                    child: const Text('RETAKE'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('review-done'),
                      onPressed: _review.canAdd && !_submitted
                          ? () {
                              setState(() => _submitted = true);
                              widget.onAdd(_review.valuesToAdd());
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _selectedColor,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white24,
                        disabledForegroundColor: Colors.white60,
                        shape: shape,
                      ),
                      child: Text(count == 0 ? 'DONE' : 'DONE · ADD $count'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _review,
    builder: (context, child) {
      return ColoredBox(
        color: Colors.black,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _photo()),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: SafeArea(child: _zoomControls()),
                  ),
                ],
              ),
            ),
            _bottomBar(),
          ],
        ),
      );
    },
  );
}

final _badgeStyle = GoogleFonts.bricolageGrotesque(
  color: Colors.black,
  fontWeight: FontWeight.w800,
);

Path _tilePath(DetectionResult detection, Size size) {
  if (detection.corners.length == 4) {
    return Path()..addPolygon(
      detection.corners
          .map((p) => Offset(p.dx * size.width, p.dy * size.height))
          .toList(),
      true,
    );
  }
  return Path()..addRect(
    Rect.fromLTRB(
      detection.boundingBox.left * size.width,
      detection.boundingBox.top * size.height,
      detection.boundingBox.right * size.width,
      detection.boundingBox.bottom * size.height,
    ),
  );
}

class _ReviewOverlay extends CustomPainter {
  final List<ReviewedTile> tiles;
  final List<String> labels;
  final TransformationController transform;
  _ReviewOverlay({
    required this.tiles,
    required this.labels,
    required this.transform,
  }) : super(repaint: transform);

  @override
  void paint(Canvas canvas, Size size) {
    final zoom = transform.value.getMaxScaleOnAxis();
    for (var i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      final color = !tile.readable
          ? Colors.grey
          : tile.selected
          ? _selectedColor
          : _unselectedColor;
      final path = _tilePath(tile.detection, size);
      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: tile.selected ? .35 : .06),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = (tile.selected ? 4 : 2) / zoom,
      );
      final badge = layoutDominoBadge(
        label: labels[i],
        tileBounds: path.getBounds(),
        imageSize: size,
        zoom: zoom,
        style: _badgeStyle,
      );
      canvas.drawRect(badge.bounds, Paint()..color = color);
      // Cancel only the text's zoom transform. Lay it out at its real screen
      // font size so rounding never makes a small scene font grow on screen.
      canvas.save();
      canvas.scale(1 / zoom);
      badge.text.paint(canvas, badge.textOffset * zoom);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ReviewOverlay oldDelegate) =>
      tiles != oldDelegate.tiles ||
      transform != oldDelegate.transform ||
      !listEquals(labels, oldDelegate.labels);
}

extension on Size {
  double get area => width * height;
}
