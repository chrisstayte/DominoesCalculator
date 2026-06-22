import 'dart:convert';

import 'package:dominoes/models/game_log.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameLogProvider extends ChangeNotifier {
  List<GameLog> _logs = [];
  late final Future<void> _loadFuture;

  List<GameLog> get logs => List.unmodifiable(_logs);
  Future<void> get isReady => _loadFuture;

  GameLogProvider() {
    _loadFuture = _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final json = preferences.getString('gameLogs');
      if (json != null) {
        final decoded = jsonDecode(json);
        if (decoded is! List<dynamic>) {
          throw FormatException('Expected gameLogs to be a JSON array');
        }

        final logs = <GameLog>[];
        var removedMalformedLogs = false;

        for (final entry in decoded) {
          try {
            if (entry is! Map<String, dynamic>) {
              throw FormatException('Expected game log to be a JSON object');
            }
            logs.add(GameLog.fromJson(entry));
          } catch (_) {
            removedMalformedLogs = true;
          }
        }

        _logs = logs;
        if (removedMalformedLogs) {
          try {
            await _saveLogs();
          } catch (_) {
            // Loading should not fail just because cleanup could not be saved.
          }
        }
        notifyListeners();
      }
    } catch (_) {
      _logs = [];
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove('gameLogs');
      } catch (_) {
        // Keep startup moving even if the preferences store cannot be repaired.
      }
      notifyListeners();
    }
  }

  Future<void> _saveLogs() async {
    final preferences = await SharedPreferences.getInstance();
    final json = jsonEncode(_logs.map((e) => e.toJson()).toList());
    await preferences.setString('gameLogs', json);
  }

  void saveGame(CalculatorProvider calculator, int freePointValue) {
    final now = DateTime.now();
    final pips = calculator.selectedPips.map((p) => p.value).toList();
    final total = calculator.total(freePointValue: freePointValue);

    final log = GameLog(
      id: now.millisecondsSinceEpoch.toString(),
      timestamp: now,
      pips: pips,
      freePointValue: freePointValue,
      total: total,
    );

    _logs.insert(0, log);
    _saveLogs();
    notifyListeners();
  }

  void deleteLog(String id) {
    _logs.removeWhere((log) => log.id == id);
    _saveLogs();
    notifyListeners();
  }
}
