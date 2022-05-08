import 'package:dominoes/global/global.dart';
import 'package:dominoes/providers/settings_provider.dart';
import 'package:dominoes/screens/home_screen.dart';
import 'package:dominoes/screens/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(), lazy: false),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domino Counter',
      themeMode: context.watch<SettingsProvider>().isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,
      theme: ThemeData.light().copyWith(
        appBarTheme: AppBarTheme(
          centerTitle: false,
          color: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
          titleTextStyle: Theme.of(context).textTheme.headline5?.copyWith(
                color: Colors.black,
              ),
          toolbarTextStyle: TextStyle(
            color: context.watch<SettingsProvider>().appAccentColor,
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: context.watch<SettingsProvider>().appAccentColor,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.all(
            context.watch<SettingsProvider>().appAccentColor,
          ),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return HSLColor.fromColor(
                      context.watch<SettingsProvider>().appAccentColor)
                  .withLightness(.5)
                  .toColor();
            }
            return CupertinoColors.tertiarySystemFill;
          }),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(
          centerTitle: false,
          color: Global.colors.darkThemeColor,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          titleTextStyle: Theme.of(context).textTheme.headline5?.copyWith(
                color: Colors.white,
              ),
        ),
        scaffoldBackgroundColor: Global.colors.darkThemeColor,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: context.watch<SettingsProvider>().appAccentColor,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.all(
            context.watch<SettingsProvider>().appAccentColor,
          ),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return HSLColor.fromColor(
                      context.watch<SettingsProvider>().appAccentColor)
                  .withLightness(.5)
                  .toColor();
            }
            return CupertinoColors.inactiveGray;
          }),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialWithModalsPageRoute(
              builder: (context) => HomeScreen(),
            );
          // case '/settings':
          //   showCupertinoDialog(

          //     context: context,
          //     builder: (context) => SettingsScreen(),
          //   );
          //   break;
        }
      },
    );
  }
}
