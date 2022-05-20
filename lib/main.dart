import 'package:dominoes/global/global.dart';
import 'package:dominoes/providers/settings_provider.dart';
import 'package:dominoes/screens/home_screen.dart';
import 'package:dominoes/screens/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:page_transition/page_transition.dart';
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
      debugShowCheckedModeBanner: false,
      title: 'Domino Counter',
      themeMode: context.watch<SettingsProvider>().isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,
      theme: ThemeData.light().copyWith(
        // textTheme: GoogleFonts.quicksandTextTheme(),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          color: Color(0XFFF3F4F8),
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
          titleTextStyle: TextStyle(
            color: Colors.black,
          ),
          toolbarTextStyle: TextStyle(
            color: context.watch<SettingsProvider>().appAccentColor,
          ),
        ),
        scaffoldBackgroundColor: Color(0XFFF3F4F8),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: context.watch<SettingsProvider>().appAccentColor,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.all(
            context.watch<SettingsProvider>().appAccentColor,
          ),
          trackColor: MaterialStateProperty.resolveWith(
            (states) {
              if (states.contains(MaterialState.selected)) {
                return HSLColor.fromColor(
                        context.watch<SettingsProvider>().appAccentColor)
                    .withLightness(.5)
                    .toColor();
              }
              return CupertinoColors.tertiarySystemFill;
            },
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: HSLColor.fromColor(
                  context.watch<SettingsProvider>().appAccentColor)
              .withLightness(.6)
              .toColor(),
          inactiveTrackColor: HSLColor.fromColor(
                  context.watch<SettingsProvider>().appAccentColor)
              .withLightness(.7)
              .toColor(),
          thumbColor: context.watch<SettingsProvider>().appAccentColor,
          overlayColor:
              context.watch<SettingsProvider>().appAccentColor.withOpacity(.5),
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
          trackColor: MaterialStateProperty.resolveWith(
            (states) {
              if (states.contains(MaterialState.selected)) {
                return HSLColor.fromColor(
                        context.watch<SettingsProvider>().appAccentColor)
                    .withLightness(.5)
                    .toColor();
              }
              return CupertinoColors.inactiveGray;
            },
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: HSLColor.fromColor(
                  context.watch<SettingsProvider>().appAccentColor)
              .withLightness(.6)
              .toColor(),
          inactiveTrackColor: HSLColor.fromColor(
                  context.watch<SettingsProvider>().appAccentColor)
              .withLightness(.7)
              .toColor(),
          thumbColor: context.watch<SettingsProvider>().appAccentColor,
          overlayColor:
              context.watch<SettingsProvider>().appAccentColor.withOpacity(.5),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return PageTransition(
              child: HomeScreen(),
              type: PageTransitionType.rightToLeft,
            );

          case '/settings':
            return PageTransition(
              child: SettingsScreen(),
              type: PageTransitionType.bottomToTop,
            );
        }
      },
    );
  }
}
