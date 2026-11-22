import 'dart:math' as math;

import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/models/domino_review.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:dominoes/widgets/adaptive_workspace.dart';
import 'package:dominoes/widgets/domino_badge_layout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final _list = ScrollController();
  Size _viewport = Size.zero;
  int? _active;
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
      _active = null;
      _submitted = false;
      _transform.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _review.dispose();
    _transform.dispose();
    _list.dispose();
    super.dispose();
  }

  void _focus(int index, {bool select = false}) {
    setState(() => _active = index);
    if (select) _review.toggleMine(index);
    if (_list.hasClients) {
      _list.animateTo(
        (index * _rowHeight).clamp(0.0, _list.position.maxScrollExtent),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _tapPhoto(Offset local, Size size) {
    final tiles = _review.tiles;
    final normalized = Offset(local.dx / size.width, local.dy / size.height);
    final hits = <int>[];
    final zoom = _transform.value.getMaxScaleOnAxis();
    final style = GoogleFonts.bricolageGrotesque(
      color: Colors.black,
      fontWeight: FontWeight.w800,
    );
    for (var i = 0; i < tiles.length; i++) {
      final path = _tilePath(tiles[i].detection, size);
      final badge = layoutDominoBadge(
        label: '#${i + 1}',
        tileBounds: path.getBounds(),
        imageSize: size,
        zoom: zoom,
        style: style,
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
    _focus(hits.first, select: true);
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

  Future<void> _edit(int index) async {
    final tile = _review.tiles[index];
    var a = tile.a, b = tile.b;
    final values = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CORRECT TILE #${index + 1}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var side = 0; side < 2; side++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('edit-${side == 0 ? 'a' : 'b'}'),
                            isExpanded: true,
                            initialValue: side == 0 ? a : b,
                            decoration: InputDecoration(
                              labelText: side == 0
                                  ? 'First half'
                                  : 'Second half',
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              for (var value = 0; value <= 15; value++)
                                DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value == 0 ? '0 · Blank' : '$value',
                                  ),
                                ),
                            ],
                            onChanged: (value) => setModalState(() {
                              if (side == 0) {
                                a = value;
                              } else {
                                b = value;
                              }
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: a == null || b == null
                      ? null
                      : () => Navigator.pop(context, [a!, b!]),
                  child: const Text('SAVE CORRECT VALUES'),
                ),
                TextButton(
                  onPressed: () {
                    _review.reject(index);
                    Navigator.pop(context);
                  },
                  child: const Text('NOT A DOMINO · EXCLUDE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || values == null) return;
    _review.correct(index, values[0], values[1]);
  }

  Widget _photo() => LayoutBuilder(
    builder: (context, constraints) {
      _viewport = constraints.biggest;
      final size = applyBoxFit(
        BoxFit.contain,
        widget.report.imageSize,
        _viewport,
      ).destination;
      return Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
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
                      onTapUp: (details) =>
                          _tapPhoto(details.localPosition, size),
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
                              active: _active,
                              transform: _transform,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
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
            ),
          ),
        ],
      );
    },
  );

  double get _rowHeight =>
      MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 164 : 108;

  Widget _tileRow(int index) {
    final tile = _review.tiles[index];
    final nbt = NeoBrutalistTheme.of(context);
    final rejected = tile.decision == TileDecision.rejected;
    final accepted = tile.decision == TileDecision.accepted;
    final corrected =
        tile.a != tile.detection.pipA || tile.b != tile.detection.pipB;
    final status = rejected
        ? 'EXCLUDED'
        : accepted
        ? (corrected ? 'CORRECTED' : 'CONFIRMED')
        : 'CHECK VALUES';
    final statusLabel = Text(
      '$status${widget.showConfidence && !corrected ? ' · ${(tile.detection.confidence * 100).round()}%' : ''}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: nbt.secondaryTextColor,
      ),
    );
    final controls = <Widget>[
      if (rejected)
        TextButton(
          onPressed: () => _review.restore(index),
          child: const Text('UNDO'),
        )
      else ...[
        TextButton(
          key: ValueKey('yes-$index'),
          onPressed: tile.hasValues ? () => _review.accept(index) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(accepted ? Icons.check_circle : Icons.check, size: 16),
              const Text(' YES'),
            ],
          ),
        ),
        TextButton(
          key: ValueKey('no-$index'),
          onPressed: () => _edit(index),
          child: const Text('NO · EDIT'),
        ),
      ],
    ];
    final largerText = _rowHeight > 108;
    return Semantics(
      label: 'Tile ${index + 1}',
      child: Container(
        height: _rowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _active == index
              ? widget.accentColor.withValues(alpha: .15)
              : nbt.cardColor,
          border: Border(
            bottom: BorderSide(color: nbt.borderColor.withValues(alpha: .25)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Checkbox(
                  key: ValueKey('mine-$index'),
                  value: tile.mine,
                  semanticLabel: 'Tile ${index + 1} is mine',
                  onChanged: (_) => _focus(index, select: true),
                ),
                InkWell(
                  onTap: () => _focus(index, select: true),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: tile.mine
                          ? const Color(0xff00dc83)
                          : const Color(0xffffce32),
                      border: Border.all(color: nbt.borderColor, width: 1.5),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _focus(index, select: true),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${tile.a ?? '?'} | ${tile.b ?? '?'}',
                        style: TextStyle(
                          color: nbt.bodyTextColor,
                          decoration: rejected
                              ? TextDecoration.lineThrough
                              : null,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Edit tile ${index + 1}',
                  onPressed: () => _edit(index),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
              ],
            ),
            if (largerText) ...[
              statusLabel,
              Expanded(
                child: Row(
                  children: [
                    for (final control in controls) Expanded(child: control),
                  ],
                ),
              ),
            ] else
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: statusLabel),
                    ...controls,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _panel() => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final minimum = 328.0 + math.max(0.0, scale - 1) * 140;
      if (constraints.maxHeight < minimum) {
        return SingleChildScrollView(child: _panelContents(scrollWhole: true));
      }
      return _panelContents();
    },
  );

  Widget _panelContents({bool scrollWhole = false}) {
    final nbt = NeoBrutalistTheme.of(context);
    return ColoredBox(
      color: nbt.cardColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          mainAxisSize: scrollWhole ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'YOUR SCORE: ${_review.total(widget.blankValue)}',
              style: TextStyle(
                color: nbt.bodyTextColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${_review.mineCount} yours · ${_review.pendingMine} to confirm · ${widget.report.detections.length} detected · blanks ${widget.blankValue}',
              style: TextStyle(color: nbt.secondaryTextColor, fontSize: 12),
            ),
            const SizedBox(height: 4),
            if (_review.tiles.isEmpty)
              if (scrollWhole)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No dominoes found. Retake closer, with every tile visible.',
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text(
                      'No dominoes found. Retake closer, with every tile visible.',
                    ),
                  ),
                )
            else ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tap boxes or pips to mark yours.\nYES confirms values. NO corrects them.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _review.selectAll(_review.mineCount == 0),
                    child: Text(_review.mineCount == 0 ? 'ALL MINE' : 'CLEAR'),
                  ),
                ],
              ),
              if (scrollWhole)
                SizedBox(
                  height: _rowHeight * 2,
                  child: ListView.builder(
                    key: const ValueKey('review-tile-list'),
                    controller: _list,
                    itemExtent: _rowHeight,
                    itemCount: _review.tiles.length,
                    itemBuilder: (context, index) => _tileRow(index),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    key: const ValueKey('review-tile-list'),
                    controller: _list,
                    itemExtent: _rowHeight,
                    itemCount: _review.tiles.length,
                    itemBuilder: (context, index) => _tileRow(index),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: widget.onRetake,
                  child: const Text('RETAKE'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _review.canAdd && !_submitted
                        ? () {
                            setState(() => _submitted = true);
                            widget.onAdd(_review.valuesToAdd());
                          }
                        : null,
                    child: Text(
                      'ADD ${_review.mineCount} ${_review.mineCount == 1 ? 'TILE' : 'TILES'}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _review,
    builder: (context, child) {
      final nbt = NeoBrutalistTheme.of(context);
      final shape = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
      return Theme(
        data: Theme.of(context).copyWith(
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: nbt.headerColor,
              foregroundColor: nbt.headerTextColor,
              shape: shape,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: nbt.bodyTextColor,
              shape: shape,
              side: BorderSide(color: nbt.borderColor, width: 2),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: nbt.bodyTextColor),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? const Color(0xff00b76b)
                  : null,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (hasWorkspace(context) ||
                constraints.maxWidth > constraints.maxHeight * 1.3) {
              return SafeArea(
                child: Row(
                  children: [
                    Expanded(flex: 3, child: _photo()),
                    Expanded(flex: 2, child: _panel()),
                  ],
                ),
              );
            }
            final panelHeight = math.min(constraints.maxHeight * .65, 440.0);
            return Column(
              children: [
                Expanded(child: _photo()),
                SizedBox(height: panelHeight, child: _panel()),
              ],
            );
          },
        ),
      );
    },
  );
}

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
  final int? active;
  final TransformationController transform;
  final TextStyle labelStyle;
  _ReviewOverlay({
    required this.tiles,
    required this.active,
    required this.transform,
  }) : labelStyle = GoogleFonts.bricolageGrotesque(
         color: Colors.black,
         fontWeight: FontWeight.w800,
       ),
       super(repaint: transform);

  @override
  void paint(Canvas canvas, Size size) {
    final zoom = transform.value.getMaxScaleOnAxis();
    for (var i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      final color = tile.decision == TileDecision.rejected
          ? Colors.grey
          : tile.mine
          ? const Color(0xff00dc83)
          : const Color(0xffffce32);
      final path = _tilePath(tile.detection, size);
      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: tile.mine ? .25 : .04),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = (active == i ? 4 : 2) / zoom,
      );
      final badge = layoutDominoBadge(
        label: '#${i + 1}',
        tileBounds: path.getBounds(),
        imageSize: size,
        zoom: zoom,
        style: labelStyle,
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
      active != oldDelegate.active ||
      transform != oldDelegate.transform;
}

extension on Size {
  double get area => width * height;
}
