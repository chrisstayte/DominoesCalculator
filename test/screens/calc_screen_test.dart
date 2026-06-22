import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/models/local_settings.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:dominoes/providers/game_log_provider.dart';
import 'package:dominoes/screens/calc_screen.dart';
import 'package:dominoes/widgets/domino_pip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Finder domino(DominoPips pip) {
    return find.byWidgetPredicate(
      (widget) => widget is DominoPip && widget.pip == pip,
    );
  }

  group('HomeScreen', () {
    testWidgets('starts on zero and updates the total as pips are tapped', (
      tester,
    ) async {
      useLargeDisplay(tester);
      final settings = await createReadySettingsProvider(
        settings: LocalSettings(numberStyle: NumberStyle.numbers),
      );

      await tester.pumpWidget(
        buildProviderHarness(
          settingsProvider: settings,
          child: const HomeScreen(),
        ),
      );

      expect(find.text('CURRENT_SCORE'), findsOneWidget);
      expect(find.text('0'), findsWidgets);

      await tester.tap(domino(DominoPips.p5));
      await tester.pump();
      await tester.tap(domino(DominoPips.p15));
      await tester.pump();

      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('blank pip uses the configured free point value', (
      tester,
    ) async {
      useLargeDisplay(tester);
      final settings = await createReadySettingsProvider(
        settings: LocalSettings(
          numberStyle: NumberStyle.numbers,
          freePointValue: 25,
        ),
      );

      await tester.pumpWidget(
        buildProviderHarness(
          settingsProvider: settings,
          child: const HomeScreen(),
        ),
      );

      await tester.tap(domino(DominoPips.p0));
      await tester.pump();

      expect(find.text('CURRENT_SCORE'), findsOneWidget);
      expect(find.text('25'), findsWidgets);
    });

    testWidgets('backspace removes the last selected pip', (tester) async {
      useLargeDisplay(tester);
      final settings = await createReadySettingsProvider(
        settings: LocalSettings(numberStyle: NumberStyle.numbers),
      );

      await tester.pumpWidget(
        buildProviderHarness(
          settingsProvider: settings,
          child: const HomeScreen(),
        ),
      );

      await tester.tap(domino(DominoPips.p8));
      await tester.pump();
      await tester.tap(domino(DominoPips.p9));
      await tester.pump();
      expect(find.text('17'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      expect(find.text('8'), findsWidgets);
      expect(find.text('17'), findsNothing);
    });

    testWidgets(
      'save with no pips shows a SnackBar and does not create a log',
      (tester) async {
        useLargeDisplay(tester);
        final settings = await createReadySettingsProvider();
        final gameLogs = GameLogProvider();

        await tester.pumpWidget(
          buildProviderHarness(
            settingsProvider: settings,
            gameLogProvider: gameLogs,
            child: const HomeScreen(),
          ),
        );

        await tester.tap(find.byIcon(Icons.save_outlined));
        await tester.pump();

        expect(find.text('No pips to save'), findsOneWidget);
        expect(gameLogs.logs, isEmpty);
      },
    );

    testWidgets('save records a game log and clears the calculator', (
      tester,
    ) async {
      useLargeDisplay(tester);
      final settings = await createReadySettingsProvider(
        settings: LocalSettings(numberStyle: NumberStyle.numbers),
      );
      final calculator = CalculatorProvider();
      final gameLogs = GameLogProvider();

      await tester.pumpWidget(
        buildProviderHarness(
          settingsProvider: settings,
          calculatorProvider: calculator,
          gameLogProvider: gameLogs,
          child: const HomeScreen(),
        ),
      );

      await tester.tap(domino(DominoPips.p6));
      await tester.pump();
      await tester.tap(domino(DominoPips.p7));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.save_outlined));
      await tester.pump();

      expect(gameLogs.logs, hasLength(1));
      expect(gameLogs.logs.first.pips, [6, 7]);
      expect(gameLogs.logs.first.total, 13);
      expect(calculator.selectedPips, isEmpty);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('history dialog lists selected pips and can remove an entry', (
      tester,
    ) async {
      useLargeDisplay(tester);
      final settings = await createReadySettingsProvider(
        settings: LocalSettings(numberStyle: NumberStyle.numbers),
      );
      final calculator = CalculatorProvider()
        ..addPip(DominoPips.p4)
        ..addPip(DominoPips.p5);

      await tester.pumpWidget(
        buildProviderHarness(
          settingsProvider: settings,
          calculatorProvider: calculator,
          child: const HomeScreen(),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.text('PIP_HISTORY'), findsOneWidget);
      expect(find.text('4 pts'), findsOneWidget);
      expect(find.text('5 pts'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();

      expect(calculator.selectedPips, [DominoPips.p4]);
      expect(find.text('5 pts'), findsNothing);
    });
  });
}
