import 'package:dominoes/constants.dart';
import 'package:dominoes/screens/calc_screen.dart';
import 'package:dominoes/screens/detect_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets(
    'closing detection settings dismisses the root dialog, not the camera branch',
    (tester) async {
      useLargeDisplay(tester);
      final camera = NoopCameraProvider();
      await tester.pumpWidget(
        buildAppHarness(
          settingsProvider: await createReadySettingsProvider(),
          cameraProvider: camera,
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      GoRouter.of(
        tester.element(find.byType(HomeScreen)),
      ).goNamed(AppRoutes.camera);
      await tester.pump(const Duration(milliseconds: 250));
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.tap(find.byType(IconButton).last);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('DETECT_SETTINGS'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('DETECT_SETTINGS'), findsNothing);
        expect(find.byType(CameraScreen), findsOneWidget);
        expect(
          GoRouter.of(tester.element(find.byType(CameraScreen))).state.uri.path,
          '/camera',
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
