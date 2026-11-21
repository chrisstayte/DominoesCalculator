import 'dart:convert';

import 'package:dominoes/main.dart';
import 'package:dominoes/models/local_settings.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:dominoes/providers/camera_provider.dart';
import 'package:dominoes/providers/game_log_provider.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:dominoes/services/sfx_service.dart';
import 'package:dominoes/services/vibration_service.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoopCameraProvider extends CameraProvider {
  @override
  Future<void> initializeCamera() async {}

  @override
  void pausePreview() {}

  @override
  Future<void> requestPermissionAgain() async {}

  @override
  void resumePreview() {}
}

void useLargeDisplay(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 932);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<LocalSettingsProvider> createReadySettingsProvider({
  LocalSettings? settings,
}) async {
  final initialSettings = settings ?? LocalSettings();
  initialSettings.soundEffects = false;
  initialSettings.vibration = false;
  initialSettings.showSplashScreen = false;

  SharedPreferences.setMockInitialValues({
    'localSettings': jsonEncode(initialSettings.toJson()),
  });

  final provider = LocalSettingsProvider();
  await provider.isReady;
  return provider;
}

Widget buildProviderHarness({
  required Widget child,
  LocalSettingsProvider? settingsProvider,
  CalculatorProvider? calculatorProvider,
  GameLogProvider? gameLogProvider,
  CameraProvider? cameraProvider,
}) {
  GoogleFonts.config.allowRuntimeFetching = false;

  final settings = settingsProvider ?? LocalSettingsProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LocalSettingsProvider>.value(value: settings),
      ChangeNotifierProvider<CalculatorProvider>.value(
        value: calculatorProvider ?? CalculatorProvider(),
      ),
      ChangeNotifierProvider<GameLogProvider>.value(
        value: gameLogProvider ?? GameLogProvider(),
      ),
      ChangeNotifierProvider<CameraProvider>.value(
        value: cameraProvider ?? NoopCameraProvider(),
      ),
      Provider<SfxService>.value(value: SfxService(settings)),
      Provider<VibrationService>.value(value: VibrationService(settings)),
    ],
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: false,
        splashFactory: NoSplash.splashFactory,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        textTheme: GoogleFonts.bricolageGrotesqueTextTheme(),
        extensions: [NeoBrutalistTheme.light()],
      ),
      darkTheme: ThemeData(
        useMaterial3: false,
        splashFactory: NoSplash.splashFactory,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.bricolageGrotesqueTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        extensions: [NeoBrutalistTheme.dark()],
      ),
      home: child,
    ),
  );
}

Widget buildAppHarness({
  LocalSettingsProvider? settingsProvider,
  CalculatorProvider? calculatorProvider,
  GameLogProvider? gameLogProvider,
  CameraProvider? cameraProvider,
}) {
  GoogleFonts.config.allowRuntimeFetching = false;

  final settings = settingsProvider ?? LocalSettingsProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LocalSettingsProvider>.value(value: settings),
      ChangeNotifierProvider<CalculatorProvider>.value(
        value: calculatorProvider ?? CalculatorProvider(),
      ),
      ChangeNotifierProvider<GameLogProvider>.value(
        value: gameLogProvider ?? GameLogProvider(),
      ),
      ChangeNotifierProvider<CameraProvider>.value(
        value: cameraProvider ?? NoopCameraProvider(),
      ),
      Provider<SfxService>.value(value: SfxService(settings)),
      Provider<VibrationService>.value(value: VibrationService(settings)),
    ],
    child: const MyApp(),
  );
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 10,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}
