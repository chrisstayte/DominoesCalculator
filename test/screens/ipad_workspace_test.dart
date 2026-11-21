import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:dominoes/providers/game_log_provider.dart';
import 'package:dominoes/screens/calc_screen.dart';
import 'package:dominoes/screens/logs_screen.dart';
import 'package:dominoes/screens/settings_screen.dart';
import 'package:dominoes/widgets/domino_pip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('iPad switches screens from the title bar', (tester) async {
    useLargeDisplay(tester);
    tester.view.physicalSize = const Size(1194, 834);
    await tester.pumpWidget(
      buildAppHarness(settingsProvider: await createReadySettingsProvider()),
    );
    await tester.pumpAndSettle();
    final logs = find.descendant(
      of: find.byType(AppBar),
      matching: find.byTooltip('Logs'),
    );
    expect(
      tester.getCenter(logs).dx,
      greaterThan(tester.getCenter(find.text('DOMINO_CALC')).dx),
    );
    expect(find.byTooltip('Camera'), findsNothing);
    await tester.tap(logs);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('ABOUT'), findsOneWidget);
    await tester.tap(find.byTooltip('Calculator'));
    await tester.pumpAndSettle();
    expect(find.text('CURRENT_SCORE'), findsOneWidget);
  });

  testWidgets('keeps one tally through rotation and narrow window resizing', (
    tester,
  ) async {
    useLargeDisplay(tester);
    tester.view.physicalSize = const Size(1194, 834);
    final settings = await createReadySettingsProvider();
    final calculator = CalculatorProvider();
    await tester.pumpWidget(
      buildProviderHarness(
        settingsProvider: settings,
        calculatorProvider: calculator,
        child: const HomeScreen(),
      ),
    );
    final tile = find.byWidgetPredicate(
      (w) => w is DominoPip && w.pip == DominoPips.p9,
    );
    await tester.tap(tile);
    for (final size in [
      const Size(1194, 834),
      const Size(744, 1133),
      const Size(602, 744),
      const Size(430, 932),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
      expect(
        find.text('PIP_HISTORY'),
        size.width >= 700 ? findsOneWidget : findsNothing,
      );
      expect(calculator.selectedPips, [DominoPips.p9]);
      expect(tile.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('deleting a selected game keeps the remaining detail open', (
    tester,
  ) async {
    useLargeDisplay(tester);
    tester.view.physicalSize = const Size(1024, 768);
    final settings = await createReadySettingsProvider();
    final logs = GameLogProvider();
    await logs.isReady;
    logs.saveGame(CalculatorProvider()..addPip(DominoPips.p6), 50);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    logs.saveGame(CalculatorProvider()..addPip(DominoPips.p9), 50);
    await tester.pumpWidget(
      buildProviderHarness(
        settingsProvider: settings,
        gameLogProvider: logs,
        child: const HistoryScreen(),
      ),
    );
    await tester.tap(find.text('6'));
    await tester.pump();
    expect(find.text('TOTAL: 6'), findsOneWidget);
    await tester.tap(find.text('DELETE'));
    await tester.pump();
    expect(find.text('TOTAL: 9'), findsOneWidget);
    expect(logs.logs.length, 1);
  });

  testWidgets('all settings groups fit the iPad mini portrait window', (
    tester,
  ) async {
    useLargeDisplay(tester);
    tester.view.physicalSize = const Size(744, 1133);
    await tester.pumpWidget(
      buildProviderHarness(
        settingsProvider: await createReadySettingsProvider(),
        child: const SettingsScreen(),
      ),
    );
    expect(find.text('ABOUT').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
