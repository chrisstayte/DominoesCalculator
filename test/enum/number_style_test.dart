import 'package:dominoes/enum/number_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumberStyle', () {
    group('fromJson', () {
      test('returns pips for "pips"', () {
        expect(NumberStyle.fromJson('pips'), NumberStyle.pips);
      });

      test('returns numbers for "numbers"', () {
        expect(NumberStyle.fromJson('numbers'), NumberStyle.numbers);
      });

      test('returns pips (default) for null', () {
        expect(NumberStyle.fromJson(null), NumberStyle.pips);
      });

      test('returns pips (default) for empty string', () {
        expect(NumberStyle.fromJson(''), NumberStyle.pips);
      });

      test('returns pips (default) for unknown string', () {
        expect(NumberStyle.fromJson('dots'), NumberStyle.pips);
      });
    });

    group('toJson', () {
      test('pips serialises to "pips"', () {
        expect(NumberStyle.pips.toJson(), 'pips');
      });

      test('numbers serialises to "numbers"', () {
        expect(NumberStyle.numbers.toJson(), 'numbers');
      });

      test('toJson / fromJson round-trip preserves all values', () {
        for (final style in NumberStyle.values) {
          expect(NumberStyle.fromJson(style.toJson()), style);
        }
      });
    });

    group('label', () {
      test('pips has label "Pips"', () {
        expect(NumberStyle.pips.label, 'Pips');
      });

      test('numbers has label "Numbers"', () {
        expect(NumberStyle.numbers.label, 'Numbers');
      });
    });
  });
}
