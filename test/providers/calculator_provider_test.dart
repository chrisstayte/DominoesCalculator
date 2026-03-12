import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorProvider', () {
    late CalculatorProvider provider;

    setUp(() {
      provider = CalculatorProvider();
    });

    group('initial state', () {
      test('selectedPips is empty', () {
        expect(provider.selectedPips, isEmpty);
      });

      test('total is 0 with any freePointValue when no pips added', () {
        expect(provider.total(freePointValue: 0), 0);
        expect(provider.total(freePointValue: 50), 0);
      });
    });

    group('addPip', () {
      test('adds a pip to selectedPips', () {
        provider.addPip(DominoPips.p5);
        expect(provider.selectedPips, [DominoPips.p5]);
      });

      test('can add multiple pips', () {
        provider.addPip(DominoPips.p3);
        provider.addPip(DominoPips.p7);
        provider.addPip(DominoPips.p12);
        expect(provider.selectedPips, [DominoPips.p3, DominoPips.p7, DominoPips.p12]);
      });

      test('notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.addPip(DominoPips.p1);
        expect(notified, isTrue);
      });
    });

    group('removeAt', () {
      setUp(() {
        provider.addPip(DominoPips.p2);
        provider.addPip(DominoPips.p4);
        provider.addPip(DominoPips.p6);
      });

      test('removes the pip at the given index', () {
        provider.removeAt(1);
        expect(provider.selectedPips, [DominoPips.p2, DominoPips.p6]);
      });

      test('removes the first pip', () {
        provider.removeAt(0);
        expect(provider.selectedPips, [DominoPips.p4, DominoPips.p6]);
      });

      test('removes the last pip by index', () {
        provider.removeAt(2);
        expect(provider.selectedPips, [DominoPips.p2, DominoPips.p4]);
      });

      test('does nothing for a negative index', () {
        provider.removeAt(-1);
        expect(provider.selectedPips.length, 3);
      });

      test('does nothing for an index equal to length', () {
        provider.removeAt(3);
        expect(provider.selectedPips.length, 3);
      });

      test('notifies listeners on valid removal', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.removeAt(0);
        expect(notified, isTrue);
      });

      test('does not notify listeners on invalid index', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.removeAt(99);
        expect(notified, isFalse);
      });
    });

    group('removeLast', () {
      test('removes the last pip', () {
        provider.addPip(DominoPips.p1);
        provider.addPip(DominoPips.p2);
        provider.removeLast();
        expect(provider.selectedPips, [DominoPips.p1]);
      });

      test('does nothing when list is empty', () {
        provider.removeLast();
        expect(provider.selectedPips, isEmpty);
      });

      test('notifies listeners when a pip is removed', () {
        provider.addPip(DominoPips.p3);
        var notified = false;
        provider.addListener(() => notified = true);
        provider.removeLast();
        expect(notified, isTrue);
      });

      test('does not notify listeners when list is already empty', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.removeLast();
        expect(notified, isFalse);
      });
    });

    group('clear', () {
      test('removes all pips', () {
        provider.addPip(DominoPips.p5);
        provider.addPip(DominoPips.p10);
        provider.clear();
        expect(provider.selectedPips, isEmpty);
      });

      test('does nothing when already empty', () {
        provider.clear();
        expect(provider.selectedPips, isEmpty);
      });

      test('notifies listeners when pips exist', () {
        provider.addPip(DominoPips.p1);
        var notified = false;
        provider.addListener(() => notified = true);
        provider.clear();
        expect(notified, isTrue);
      });

      test('does not notify listeners when already empty', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.clear();
        expect(notified, isFalse);
      });
    });

    group('total', () {
      test('sums non-zero pips correctly', () {
        provider.addPip(DominoPips.p3);
        provider.addPip(DominoPips.p7);
        provider.addPip(DominoPips.p10);
        expect(provider.total(freePointValue: 0), 20);
      });

      test('p0 uses freePointValue=0', () {
        provider.addPip(DominoPips.p0);
        expect(provider.total(freePointValue: 0), 0);
      });

      test('p0 uses freePointValue=25', () {
        provider.addPip(DominoPips.p0);
        expect(provider.total(freePointValue: 25), 25);
      });

      test('p0 uses freePointValue=50', () {
        provider.addPip(DominoPips.p0);
        expect(provider.total(freePointValue: 50), 50);
      });

      test('mix of p0 and regular pips', () {
        provider.addPip(DominoPips.p0);
        provider.addPip(DominoPips.p5);
        provider.addPip(DominoPips.p0);
        // freePointValue=50: 50 + 5 + 50 = 105
        expect(provider.total(freePointValue: 50), 105);
      });

      test('all 15 non-zero pips sum correctly', () {
        for (int i = 1; i <= 15; i++) {
          provider.addPip(DominoPips.fromInt(i));
        }
        // 1+2+...+15 = 120
        expect(provider.total(freePointValue: 0), 120);
      });
    });

    group('selectedPips immutability', () {
      test('selectedPips returns an unmodifiable list', () {
        provider.addPip(DominoPips.p4);
        expect(() => provider.selectedPips.add(DominoPips.p5), throwsUnsupportedError);
      });
    });
  });
}
