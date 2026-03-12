import 'package:dominoes/enum/domino_pips.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DominoPips', () {
    group('value / asInt', () {
      test('each pip has the correct integer value', () {
        for (int i = 0; i <= 15; i++) {
          final pip = DominoPips.values[i];
          expect(pip.value, i);
          expect(pip.asInt, i);
        }
      });
    });

    group('label', () {
      test('label returns the string representation of the value', () {
        expect(DominoPips.p0.label, '0');
        expect(DominoPips.p7.label, '7');
        expect(DominoPips.p15.label, '15');
      });
    });

    group('readable', () {
      final expected = [
        'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven',
        'eight', 'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen',
        'fifteen',
      ];

      test('readable returns the correct word for each pip', () {
        for (int i = 0; i <= 15; i++) {
          expect(DominoPips.values[i].readable, expected[i]);
        }
      });
    });

    group('fromInt', () {
      test('returns correct enum for values 0..15', () {
        for (int i = 0; i <= 15; i++) {
          expect(DominoPips.fromInt(i), DominoPips.values[i]);
        }
      });

      test('throws RangeError for -1', () {
        expect(() => DominoPips.fromInt(-1), throwsRangeError);
      });

      test('throws RangeError for 16', () {
        expect(() => DominoPips.fromInt(16), throwsRangeError);
      });
    });

    group('tryFromInt', () {
      test('returns correct enum for values 0..15', () {
        for (int i = 0; i <= 15; i++) {
          expect(DominoPips.tryFromInt(i), DominoPips.values[i]);
        }
      });

      test('returns null for -1', () {
        expect(DominoPips.tryFromInt(-1), isNull);
      });

      test('returns null for 16', () {
        expect(DominoPips.tryFromInt(16), isNull);
      });
    });

    group('toString', () {
      test('toString returns the label', () {
        expect(DominoPips.p0.toString(), '0');
        expect(DominoPips.p12.toString(), '12');
      });
    });
  });
}
