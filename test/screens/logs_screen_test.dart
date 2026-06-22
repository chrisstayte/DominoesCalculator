import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:dominoes/providers/game_log_provider.dart';
import 'package:dominoes/screens/logs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HistoryScreen', () {
    testWidgets('shows an empty state when there are no logs', (tester) async {
      useLargeDisplay(tester);
      final settings = await createReadySettingsProvider();
      final gameLogs = GameLogProvider();
      await gameLogs.isReady;

      await tester.pumpWidget(
        buildProviderHarness(
          settingsProvider: settings,
          gameLogProvider: gameLogs,
          child: const HistoryScreen(),
        ),
      );

      expect(find.text('GAME_LOGS'), findsOneWidget);
      expect(find.text('NO LOGS YET'), findsOneWidget);
    });

    testWidgets('lists saved games and deletes one from the detail dialog', (
      tester,
    ) async {
      useLargeDisplay(tester);
      final settings = await createReadySettingsProvider();
      final gameLogs = GameLogProvider();
      await gameLogs.isReady;
      final calculator = CalculatorProvider()
        ..addPip(DominoPips.p6)
        ..addPip(DominoPips.p7);
      gameLogs.saveGame(calculator, 50);

      await tester.pumpWidget(
        buildProviderHarness(
          settingsProvider: settings,
          gameLogProvider: gameLogs,
          child: const HistoryScreen(),
        ),
      );

      expect(find.text('2 pips'), findsOneWidget);
      expect(find.text('13'), findsOneWidget);

      await tester.tap(find.text('13'));
      await tester.pumpAndSettle();

      expect(find.text('GAME_LOG'), findsOneWidget);
      expect(find.text('TOTAL: 13'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(gameLogs.logs, isEmpty);
      expect(find.text('NO LOGS YET'), findsOneWidget);
    });
  });
}
