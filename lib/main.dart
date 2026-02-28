import 'package:dominoes/constants.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:dominoes/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider<LocalSettingsProvider>(
      create: (context) => LocalSettingsProvider(),
      lazy: false,
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
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
      ),
    );
  }
}
