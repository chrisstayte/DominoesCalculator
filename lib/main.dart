import 'package:dominoes/constants.dart';
import 'package:dominoes/providers/calculator_provider.dart';
import 'package:dominoes/providers/game_log_provider.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:dominoes/router.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localSettingsProvider = LocalSettingsProvider();
  await localSettingsProvider.isReady;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalSettingsProvider>.value(
          value: localSettingsProvider,
        ),
        ChangeNotifierProvider<CalculatorProvider>(
          create: (context) => CalculatorProvider(),
        ),
        ChangeNotifierProvider<GameLogProvider>(
          create: (context) => GameLogProvider(),
          lazy: false,
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<LocalSettingsProvider>(
      context,
    ).localSettings.themeMode;

    return MaterialApp.router(
      routerConfig: _router,
      title: 'Dominoes',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        textTheme: GoogleFonts.bricolageGrotesqueTextTheme(),
        extensions: [NeoBrutalistTheme.light()],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.bricolageGrotesqueTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        extensions: [NeoBrutalistTheme.dark()],
      ),
    );
  }
}
