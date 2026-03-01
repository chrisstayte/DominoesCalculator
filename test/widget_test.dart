import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/models/game_log.dart';
import 'package:dominoes/models/local_settings.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorProvider', () {
    late CalculatorProvider calculator;

    setUp(() {
      calculator = CalculatorProvider();
    });

    test('starts with empty selected pips', () {
      expect(calculator.selectedPips, isEmpty);
      expect(calculator.total(freePointValue: 50), 0);
    });

    test('addPip adds a pip and updates total', () {
      calculator.addPip(DominoPips.p5);
      expect(calculator.selectedPips.length, 1);
      expect(calculator.total(freePointValue: 50), 5);
    });

    test('addPip with multiple pips accumulates total', () {
      calculator.addPip(DominoPips.p3);
      calculator.addPip(DominoPips.p7);
      calculator.addPip(DominoPips.p10);
      expect(calculator.selectedPips.length, 3);
      expect(calculator.total(freePointValue: 50), 20);
    });

    test('p0 (free/blank) uses freePointValue', () {
      calculator.addPip(DominoPips.p0);
      expect(calculator.total(freePointValue: 50), 50);
      expect(calculator.total(freePointValue: 25), 25);
      expect(calculator.total(freePointValue: 0), 0);
    });

    test('removeLast removes the last added pip', () {
      calculator.addPip(DominoPips.p5);
      calculator.addPip(DominoPips.p10);
      calculator.removeLast();
      expect(calculator.selectedPips.length, 1);
      expect(calculator.total(freePointValue: 50), 5);
    });

    test('removeLast on empty list does nothing', () {
      calculator.removeLast();
      expect(calculator.selectedPips, isEmpty);
    });

    test('removeAt removes pip at specific index', () {
      calculator.addPip(DominoPips.p1);
      calculator.addPip(DominoPips.p2);
      calculator.addPip(DominoPips.p3);
      calculator.removeAt(1);
      expect(calculator.selectedPips.length, 2);
      expect(calculator.total(freePointValue: 50), 4); // 1 + 3
    });

    test('removeAt with invalid index does nothing', () {
      calculator.addPip(DominoPips.p5);
      calculator.removeAt(-1);
      calculator.removeAt(5);
      expect(calculator.selectedPips.length, 1);
    });

    test('clear removes all pips', () {
      calculator.addPip(DominoPips.p5);
      calculator.addPip(DominoPips.p10);
      calculator.clear();
      expect(calculator.selectedPips, isEmpty);
      expect(calculator.total(freePointValue: 50), 0);
    });

    test('clear on empty list does nothing', () {
      calculator.clear();
      expect(calculator.selectedPips, isEmpty);
    });

    test('selectedPips returns unmodifiable list', () {
      calculator.addPip(DominoPips.p5);
      expect(
        () => calculator.selectedPips.add(DominoPips.p1),
        throwsUnsupportedError,
      );
    });
  });

  group('DominoPips', () {
    test('fromInt returns correct pip', () {
      expect(DominoPips.fromInt(0), DominoPips.p0);
      expect(DominoPips.fromInt(15), DominoPips.p15);
      expect(DominoPips.fromInt(7), DominoPips.p7);
    });

    test('fromInt throws for invalid value', () {
      expect(() => DominoPips.fromInt(16), throwsRangeError);
      expect(() => DominoPips.fromInt(-1), throwsRangeError);
    });

    test('tryFromInt returns null for invalid value', () {
      expect(DominoPips.tryFromInt(16), isNull);
      expect(DominoPips.tryFromInt(-1), isNull);
    });

    test('tryFromInt returns pip for valid value', () {
      expect(DominoPips.tryFromInt(0), DominoPips.p0);
      expect(DominoPips.tryFromInt(15), DominoPips.p15);
    });

    test('label returns string of value', () {
      expect(DominoPips.p0.label, '0');
      expect(DominoPips.p15.label, '15');
    });

    test('readable returns word form', () {
      expect(DominoPips.p0.readable, 'zero');
      expect(DominoPips.p1.readable, 'one');
      expect(DominoPips.p15.readable, 'fifteen');
    });
  });

  group('GameLog', () {
    test('serializes to and from JSON', () {
      final log = GameLog(
        id: '123',
        timestamp: DateTime(2025, 1, 15, 10, 30),
        pips: [5, 3, 0, 10],
        freePointValue: 50,
        total: 68,
      );

      final json = log.toJson();
      final restored = GameLog.fromJson(json);

      expect(restored.id, '123');
      expect(restored.pips, [5, 3, 0, 10]);
      expect(restored.freePointValue, 50);
      expect(restored.total, 68);
      expect(restored.timestamp, log.timestamp);
    });
  });

  group('LocalSettings', () {
    test('has sensible defaults', () {
      final settings = LocalSettings();
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.vibration, true);
      expect(settings.soundEffects, true);
      expect(settings.freePointValue, 50);
      expect(settings.coloredPips, false);
    });

    test('serializes to and from JSON', () {
      final settings = LocalSettings(
        themeMode: ThemeMode.dark,
        vibration: false,
        soundEffects: false,
        freePointValue: 25,
        coloredPips: true,
      );

      final json = settings.toJson();
      final restored = LocalSettings.fromJson(json);

      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.vibration, false);
      expect(restored.soundEffects, false);
      expect(restored.freePointValue, 25);
      expect(restored.coloredPips, true);
    });

    test('fromJson uses defaults for missing fields', () {
      final settings = LocalSettings.fromJson({});
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.vibration, true);
      expect(settings.freePointValue, 50);
    });

    test('fromJson rejects invalid freePointValue', () {
      final settings = LocalSettings.fromJson({'freePointValue': 99});
      expect(settings.freePointValue, 50);
    });
  });
}
