import 'package:dominoes/constants.dart';
import 'package:dominoes/screens/home_screen.dart';
import 'package:dominoes/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

late GoRouter globalRouter;

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _settingNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>();

Page getPage({required Widget child, required GoRouterState state}) {
  return MaterialPage(key: state.pageKey, child: child);
}

GoRouter createRouter(BuildContext context) {
  return GoRouter(
    initialLocation: '/${AppRoutes.home}',
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        name: AppRoutes.home,
        path: '/${AppRoutes.home}',
        pageBuilder: (context, state) =>
            getPage(child: HomeScreen(), state: state),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        name: AppRoutes.settings,
        path: '/${AppRoutes.settings}',
        pageBuilder: (context, state) =>
            getPage(child: SettingsScreen(), state: state),
      ),
    ],
  );
}
