import 'dart:convert';

import 'package:dominoes/models/local_settings.dart';
import 'package:dominoes/providers/game_log_provider.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalSettingsProvider', () {
    test(
      'falls back to defaults when persisted settings are invalid',
      () async {
        SharedPreferences.setMockInitialValues({
          'localSettings': '{not valid json',
        });

        final provider = LocalSettingsProvider();
        await provider.isReady.timeout(const Duration(seconds: 1));

        expect(
          provider.localSettings.freePointValue,
          LocalSettings().freePointValue,
        );

        final preferences = await SharedPreferences.getInstance();
        expect(preferences.getString('localSettings'), isNull);
      },
    );

    test(
      'falls back to defaults when persisted settings have the wrong shape',
      () async {
        SharedPreferences.setMockInitialValues({
          'localSettings': jsonEncode(['not', 'a', 'settings', 'object']),
        });

        final provider = LocalSettingsProvider();
        await provider.isReady.timeout(const Duration(seconds: 1));

        expect(provider.localSettings.numberStyle, LocalSettings().numberStyle);

        final preferences = await SharedPreferences.getInstance();
        expect(preferences.getString('localSettings'), isNull);
      },
    );
  });

  group('GameLogProvider', () {
    test('clears game logs when persisted logs are invalid JSON', () async {
      SharedPreferences.setMockInitialValues({'gameLogs': '[not valid json'});

      final provider = GameLogProvider();
      await provider.isReady.timeout(const Duration(seconds: 1));

      expect(provider.logs, isEmpty);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('gameLogs'), isNull);
    });

    test('drops malformed game logs and preserves valid logs', () async {
      final validLog = {
        'id': 'log-1',
        'timestamp': DateTime(2026, 6, 21).millisecondsSinceEpoch,
        'pips': [5, 10],
        'freePointValue': 50,
        'total': 15,
      };

      SharedPreferences.setMockInitialValues({
        'gameLogs': jsonEncode([
          validLog,
          {'id': 'missing required fields'},
        ]),
      });

      final provider = GameLogProvider();
      await provider.isReady.timeout(const Duration(seconds: 1));

      expect(provider.logs, hasLength(1));
      expect(provider.logs.single.id, 'log-1');

      final preferences = await SharedPreferences.getInstance();
      final savedLogs =
          jsonDecode(preferences.getString('gameLogs')!) as List<dynamic>;
      expect(savedLogs, hasLength(1));
    });
  });
}
