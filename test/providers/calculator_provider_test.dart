import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorProvider', () {
    test('adds pips and totals blank pips with the configured free value', () {
      final calculator = CalculatorProvider();

      calculator
        ..addPip(DominoPips.p0)
        ..addPip(DominoPips.p5)
        ..addPip(DominoPips.p15);

      expect(calculator.selectedPips, [
        DominoPips.p0,
        DominoPips.p5,
        DominoPips.p15,
      ]);
      expect(calculator.total(freePointValue: 50), 70);
      expect(calculator.total(freePointValue: 25), 45);
      expect(calculator.total(freePointValue: 0), 20);
    });

    test('exposes selected pips as an immutable copy', () {
      final calculator = CalculatorProvider()..addPip(DominoPips.p3);

      expect(
        () => calculator.selectedPips.add(DominoPips.p4),
        throwsUnsupportedError,
      );
      expect(calculator.selectedPips, [DominoPips.p3]);
    });

    test('removes by index, removes last, and ignores invalid removals', () {
      final calculator = CalculatorProvider()
        ..addPip(DominoPips.p1)
        ..addPip(DominoPips.p2)
        ..addPip(DominoPips.p3);

      calculator.removeAt(1);
      expect(calculator.selectedPips, [DominoPips.p1, DominoPips.p3]);

      calculator.removeAt(-1);
      calculator.removeAt(99);
      expect(calculator.selectedPips, [DominoPips.p1, DominoPips.p3]);

      calculator.removeLast();
      expect(calculator.selectedPips, [DominoPips.p1]);
    });

    test('clear empties selections and leaves empty state stable', () {
      final calculator = CalculatorProvider()
        ..addPip(DominoPips.p8)
        ..clear()
        ..clear();

      expect(calculator.selectedPips, isEmpty);
      expect(calculator.total(freePointValue: 50), 0);
    });
  });
}
