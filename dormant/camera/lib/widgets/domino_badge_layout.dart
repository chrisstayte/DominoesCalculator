import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/painting.dart';

class DominoBadgeLayout {
  final TextPainter text;
  final Rect bounds;
  final Offset textOffset;
  const DominoBadgeLayout(this.text, this.bounds, this.textOffset);
}

/// Dimensions are scene units: after the photo's zoom transform, text and
/// padding remain the same size on screen. Anchor above the tile when possible.
DominoBadgeLayout layoutDominoBadge({
  required String label,
  required Rect tileBounds,
  required Size imageSize,
  required double zoom,
  TextStyle style = const TextStyle(
    color: Color(0xff000000),
    fontWeight: FontWeight.w800,
  ),
}) {
  if (!zoom.isFinite || zoom <= 0) throw ArgumentError.value(zoom, 'zoom');
  final horizontal = 5 / zoom, vertical = 3 / zoom;
  final text = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
    text: TextSpan(text: label, style: style.copyWith(fontSize: 13)),
  )..layout();
  final width = text.width / zoom + horizontal * 2,
      height = text.height / zoom + vertical * 2;
  final left = tileBounds.left
      .clamp(0.0, math.max(0.0, imageSize.width - width))
      .toDouble();
  final top = (tileBounds.top - height - 3 / zoom)
      .clamp(0.0, math.max(0.0, imageSize.height - height))
      .toDouble();
  final bounds = Rect.fromLTWH(left, top, width, height);
  return DominoBadgeLayout(
    text,
    bounds,
    Offset(left + horizontal, top + vertical),
  );
}
