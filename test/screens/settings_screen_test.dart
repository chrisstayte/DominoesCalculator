import 'package:dominoes/enum/app_accent_color.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/screens/settings_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      expect(find.text('VIBRATION'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('sound stays available on hardware without haptics', (
      tester,
    ) async {
      useLargeDisplay(tester);
      final settings = await createReadySettingsProvider();
      for (final size in [const Size(1024, 768), const Size(430, 932)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          buildProviderHarness(
            settingsProvider: settings,
            supportsHaptics: false,
            child: const SettingsScreen(),
          ),
        );
        expect(find.text('SOUND_EFFECTS'), findsOneWidget);
        expect(find.text('VIBRATION'), findsNothing);
      }
    });

    testWidgets(
      'updates the device sound notice while sound effects are enabled',
      (tester) async {
        useLargeDisplay(tester);
        late MockStreamHandlerEventSink system;
        tester.binding.defaultBinaryMessenger.setMockStreamHandler(
          const EventChannel('dominoes/systemSound'),
          MockStreamHandler.inline(
            onListen: (_, events) {
              system = events;
              events.success('normal');
            },
          ),
        );
        final settings = await createReadySettingsProvider();
        settings.setSoundEffects(true);
        await tester.pumpWidget(
          buildProviderHarness(
            settingsProvider: settings,
            child: const SettingsScreen(),
          ),
        );
        await tester.pumpAndSettle();
        final isApple = defaultTargetPlatform == TargetPlatform.iOS;
        final warning = isApple
            ? 'Output volume is at zero.'
            : 'Your device is set to vibrate.';
        system.success(isApple ? 'zeroVolume' : 'vibrate');
        await tester.pumpAndSettle();
        expect(find.text(warning), findsOneWidget);
        system.success('normal');
        await tester.pumpAndSettle();
        expect(find.text(warning), findsNothing);
        final hint = find.text('Sound effects follow Silent Mode.');
        expect(hint, isApple ? findsOneWidget : findsNothing);
        settings.setSoundEffects(false);
        await tester.pumpAndSettle();
        expect(hint, findsNothing);
        expect(find.byIcon(Icons.volume_off_outlined), findsNothing);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.iOS,
        TargetPlatform.android,
      }),
    );

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
