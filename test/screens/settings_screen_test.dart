import 'package:dominoes/enum/app_accent_color.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsScreen', () {
    testWidgets('renders the main settings sections', (tester) async {
      useLargeDisplay(tester);
      final settings = await createReadySettingsProvider();

      await tester.pumpWidget(
        buildProviderHarness(
          settingsProvider: settings,
          child: const SettingsScreen(),
        ),
      );

      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('GAMEPLAY'), findsOneWidget);
      expect(find.text('FEEDBACK'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets(
      'updates theme, gameplay, and feedback settings from controls',
      (tester) async {
        useLargeDisplay(tester);
        final settings = await createReadySettingsProvider();

        await tester.pumpWidget(
          buildProviderHarness(
            settingsProvider: settings,
            child: const SettingsScreen(),
          ),
        );

        await tester.tap(find.text('DARK'));
        await tester.pump();
        await tester.tap(find.text('25'));
        await tester.pump();
        await tester.tap(find.text('NUMBERS'));
        await tester.pump();
        await tester.tap(find.text('COLORED'));
        await tester.pump();
        await tester.tap(find.text('OFF').first);
        await tester.pump();

        expect(settings.localSettings.themeMode, ThemeMode.dark);
        expect(settings.localSettings.freePointValue, 25);
        expect(settings.localSettings.numberStyle, NumberStyle.numbers);
        expect(settings.localSettings.coloredPips, isTrue);
        expect(settings.localSettings.showSplashScreen, isFalse);
      },
    );

    testWidgets('accent swatches update the selected app accent color', (
      tester,
    ) async {
      useLargeDisplay(tester);
      final settings = await createReadySettingsProvider();

      await tester.pumpWidget(
        buildProviderHarness(
          settingsProvider: settings,
          child: const SettingsScreen(),
        ),
      );

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).color ==
                  AppAccentColor.coral.color,
        ),
      );
      await tester.pump();

      expect(settings.localSettings.appAccentColor, AppAccentColor.coral);
    });
  });
}
