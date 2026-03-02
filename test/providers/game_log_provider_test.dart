import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:dominoes/providers/game_log_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GameLogProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<GameLogProvider> _makeProvider() async {
      final provider = GameLogProvider();
      // Allow the async _loadLogs() to complete.
      await Future<void>.delayed(Duration.zero);
      return provider;
    }

    group('initial state', () {
      test('logs is empty when SharedPreferences has no data', () async {
        final provider = await _makeProvider();
        expect(provider.logs, isEmpty);
      });
    });

    group('saveGame', () {
      test('adds a game log entry', () async {
        final provider = await _makeProvider();
        final calc = CalculatorProvider()
          ..addPip(DominoPips.p3)
          ..addPip(DominoPips.p6);

        provider.saveGame(calc, 50);

        expect(provider.logs.length, 1);
      });

      test('log entry has correct pips', () async {
        final provider = await _makeProvider();
        final calc = CalculatorProvider()
          ..addPip(DominoPips.p4)
          ..addPip(DominoPips.p8);

        provider.saveGame(calc, 0);

        expect(provider.logs.first.pips, [4, 8]);
      });

      test('log entry has correct total', () async {
        final provider = await _makeProvider();
        final calc = CalculatorProvider()
          ..addPip(DominoPips.p5)
          ..addPip(DominoPips.p10);

        provider.saveGame(calc, 0);

        expect(provider.logs.first.total, 15);
      });

      test('log entry has correct freePointValue', () async {
        final provider = await _makeProvider();
        final calc = CalculatorProvider()..addPip(DominoPips.p0);

        provider.saveGame(calc, 25);

        expect(provider.logs.first.freePointValue, 25);
        expect(provider.logs.first.total, 25);
      });

      test('newer games appear first (insertion order)', () async {
        final provider = await _makeProvider();
        final calc1 = CalculatorProvider()..addPip(DominoPips.p1);
        final calc2 = CalculatorProvider()..addPip(DominoPips.p2);

        provider.saveGame(calc1, 0);
        await Future<void>.delayed(Duration(milliseconds: 1));
        provider.saveGame(calc2, 0);

        expect(provider.logs.first.total, 2);
        expect(provider.logs.last.total, 1);
      });

      test('notifies listeners after saving', () async {
        final provider = await _makeProvider();
        var notified = false;
        provider.addListener(() => notified = true);

        provider.saveGame(CalculatorProvider()..addPip(DominoPips.p7), 0);

        expect(notified, isTrue);
      });
    });

    group('deleteLog', () {
      test('removes the log with the given id', () async {
        final provider = await _makeProvider();
        provider.saveGame(CalculatorProvider()..addPip(DominoPips.p3), 0);
        await Future<void>.delayed(Duration.zero);

        final id = provider.logs.first.id;
        provider.deleteLog(id);

        expect(provider.logs, isEmpty);
      });

      test('does not remove other logs', () async {
        final provider = await _makeProvider();
        provider.saveGame(CalculatorProvider()..addPip(DominoPips.p1), 0);
        await Future<void>.delayed(Duration(milliseconds: 1));
        provider.saveGame(CalculatorProvider()..addPip(DominoPips.p2), 0);
        await Future<void>.delayed(Duration.zero);

        final idToDelete = provider.logs.last.id;
        provider.deleteLog(idToDelete);

        expect(provider.logs.length, 1);
        expect(provider.logs.first.total, 2);
      });

      test('notifies listeners after deletion', () async {
        final provider = await _makeProvider();
        provider.saveGame(CalculatorProvider()..addPip(DominoPips.p9), 0);
        await Future<void>.delayed(Duration.zero);

        var notified = false;
        provider.addListener(() => notified = true);
        provider.deleteLog(provider.logs.first.id);

        expect(notified, isTrue);
      });

      test('ignores unknown id gracefully', () async {
        final provider = await _makeProvider();
        provider.saveGame(CalculatorProvider()..addPip(DominoPips.p5), 0);
        await Future<void>.delayed(Duration.zero);

        provider.deleteLog('non_existent_id');

        expect(provider.logs.length, 1);
      });
    });

    group('persistence', () {
      test('saved logs are reloaded by a new provider instance', () async {
        final provider1 = await _makeProvider();
        provider1.saveGame(CalculatorProvider()..addPip(DominoPips.p6), 0);
        // Wait for async _saveLogs to write to SharedPreferences.
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final provider2 = await _makeProvider();
        expect(provider2.logs.length, 1);
        expect(provider2.logs.first.total, 6);
      });
    });

    group('logs immutability', () {
      test('logs returns an unmodifiable list', () async {
        final provider = await _makeProvider();
        expect(
          () => provider.logs.add(provider.logs.isNotEmpty
              ? provider.logs.first
              : throw StateError('empty')),
          throwsUnsupportedError,
        );
      });
    });
  });
}
