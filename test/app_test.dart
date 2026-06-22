import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/models/local_settings.dart';
import 'package:dominoes/widgets/domino_pip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MyApp pumps with its root providers and opens calculator tab', (
    tester,
  ) async {
    useLargeDisplay(tester);
    final settings = await createReadySettingsProvider(
      settings: LocalSettings(numberStyle: NumberStyle.numbers),
    );

    await tester.pumpWidget(buildAppHarness(settingsProvider: settings));
    await tester.pumpAndSettle();

    expect(find.text('DOMINO_CALC'), findsOneWidget);
    expect(find.text('CURRENT_SCORE'), findsOneWidget);
    expect(find.byType(DominoPip), findsNWidgets(16));
  });

  testWidgets('calculator flow works through the real router shell', (
    tester,
  ) async {
    useLargeDisplay(tester);
    final settings = await createReadySettingsProvider(
      settings: LocalSettings(numberStyle: NumberStyle.numbers),
    );

    await tester.pumpWidget(buildAppHarness(settingsProvider: settings));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is DominoPip && widget.pip == DominoPips.p10,
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is DominoPip && widget.pip == DominoPips.p15,
      ),
    );
    await tester.pump();

    expect(find.text('25'), findsOneWidget);
  });
}
