import 'dart:ui';
import 'package:dominoes/widgets/domino_badge_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('photo zoom keeps badge screen dimensions fixed and above the pips', () {
    const tile = Rect.fromLTWH(100, 100, 120, 80);
    final base = layoutDominoBadge(
      label: '#123',
      tileBounds: tile,
      imageSize: const Size(500, 400),
      zoom: 1,
    );
    for (final zoom in [1.5, 4.0, 8.0]) {
      final badge = layoutDominoBadge(
        label: '#123',
        tileBounds: tile,
        imageSize: const Size(500, 400),
        zoom: zoom,
      );
      expect(badge.bounds.width * zoom, closeTo(base.bounds.width, .01));
      expect(badge.bounds.height * zoom, closeTo(base.bounds.height, .01));
      expect(badge.bounds.bottom, lessThan(tile.top));
      expect(badge.text.text!.toPlainText(), '#123');
    }
  });
  test('edge badges remain reachable within the photo', () {
    final badge = layoutDominoBadge(
      label: '#1',
      tileBounds: const Rect.fromLTWH(-4, -5, 60, 30),
      imageSize: const Size(100, 100),
      zoom: 4,
    );
    expect(badge.bounds.left, 0);
    expect(badge.bounds.top, 0);
    expect(badge.bounds.right, lessThanOrEqualTo(100));
    expect(
      () => layoutDominoBadge(
        label: '#1',
        tileBounds: Rect.zero,
        imageSize: const Size(100, 100),
        zoom: 0,
      ),
      throwsArgumentError,
    );
  });
}
