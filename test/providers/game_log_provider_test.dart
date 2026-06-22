import 'dart:convert';

import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/models/game_log.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:dominoes/providers/game_log_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> waitForLogs(GameLogProvider provider, int count) async {
  for (var i = 0; i < 10; i++) {
    if (provider.logs.length == count) return;
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('GameLog', () {
    test('round-trips through JSON', () {
      final log = GameLog(
        id: 'abc',
        timestamp: DateTime(2026, 6, 21, 9, 30),
        pips: [0, 6, 15],
        freePointValue: 50,
        total: 71,
      );

      final restored = GameLog.fromJson(log.toJson());

      expect(restored.id, 'abc');
      expect(restored.timestamp, DateTime(2026, 6, 21, 9, 30));
      expect(restored.pips, [0, 6, 15]);
      expect(restored.freePointValue, 50);
      expect(restored.total, 71);
    });
  });

  group('GameLogProvider', () {
    test('loads persisted logs newest-first as stored', () async {
      final first = GameLog(
        id: 'first',
        timestamp: DateTime(2026, 1, 1),
        pips: [4],
        freePointValue: 50,
        total: 4,
      );
      final second = GameLog(
        id: 'second',
        timestamp: DateTime(2026, 1, 2),
        pips: [5, 6],
        freePointValue: 50,
        total: 11,
      );
      SharedPreferences.setMockInitialValues({
        'gameLogs': jsonEncode([first.toJson(), second.toJson()]),
      });

      final provider = GameLogProvider();
      await waitForLogs(provider, 2);

      expect(provider.logs.map((log) => log.id), ['first', 'second']);
      expect(provider.logs.first.total, 4);
      expect(provider.logs.last.pips, [5, 6]);
    });

    test(
      'saves selected calculator pips, computed total, and clears nothing',
      () async {
        SharedPreferences.setMockInitialValues({});
        final provider = GameLogProvider();
        final calculator = CalculatorProvider()
          ..addPip(DominoPips.p0)
          ..addPip(DominoPips.p7);

        provider.saveGame(calculator, 25);
        await waitForLogs(provider, 1);

        expect(provider.logs, hasLength(1));
        expect(provider.logs.first.pips, [0, 7]);
        expect(provider.logs.first.freePointValue, 25);
        expect(provider.logs.first.total, 32);
        expect(calculator.selectedPips, [DominoPips.p0, DominoPips.p7]);

        final preferences = await SharedPreferences.getInstance();
        final persisted =
            jsonDecode(preferences.getString('gameLogs')!) as List<dynamic>;
        expect(persisted, hasLength(1));
        expect(persisted.first['total'], 32);
      },
    );

    test('deletes logs and persists the remaining list', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = GameLogProvider();
      final calculator = CalculatorProvider()..addPip(DominoPips.p4);

      provider.saveGame(calculator, 50);
      await waitForLogs(provider, 1);
      final id = provider.logs.first.id;

      provider.deleteLog(id);
      await waitForLogs(provider, 0);

      expect(provider.logs, isEmpty);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('gameLogs'), '[]');
    });
  });
}
