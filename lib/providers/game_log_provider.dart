import 'dart:convert';

import 'package:dominoes/models/game_log.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameLogProvider extends ChangeNotifier {
  List<GameLog> _logs = [];

  List<GameLog> get logs => List.unmodifiable(_logs);

  GameLogProvider() {
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final preferences = await SharedPreferences.getInstance();
    final json = preferences.getString('gameLogs');
    if (json != null) {
      final List<dynamic> decoded = jsonDecode(json);
      _logs = decoded
          .map((e) => GameLog.fromJson(e as Map<String, dynamic>))
          .toList();
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
