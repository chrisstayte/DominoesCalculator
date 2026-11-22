import 'package:dominoes/screens/detect_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CameraScreen', () {
    testWidgets('opens detect settings and updates local preferences', (
      tester,
    ) async {
      useLargeDisplay(tester);
      final settings = await createReadySettingsProvider();

      await tester.pumpWidget(
        buildProviderHarness(
          settingsProvider: settings,
          child: const CameraScreen(),
        ),
      );

      await tester.tap(find.byType(IconButton).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('DETECT_SETTINGS'), findsOneWidget);

      await tester.tap(find.text('ON').first);
      await tester.pump();
      await tester.tap(find.text('OFF').last);
      await tester.pump();

      expect(settings.localSettings.showConfidence, isTrue);
      expect(settings.localSettings.showScanLine, isFalse);
    });
  });
}
