import 'package:dominoes/constants.dart';
import 'package:dominoes/screens/camera_screen.dart';
import 'package:dominoes/screens/logs_screen.dart';
import 'package:dominoes/screens/calc_screen.dart';
import 'package:dominoes/screens/settings_screen.dart';
import 'package:dominoes/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _calcNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'calc');
final _historyNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'history');
final _cameraNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'camera');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/${AppRoutes.calc}',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _calcNavigatorKey,
            routes: [
              GoRoute(
                name: AppRoutes.calc,
                path: '/${AppRoutes.calc}',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _historyNavigatorKey,
            routes: [
              GoRoute(
                name: AppRoutes.logs,
                path: '/${AppRoutes.logs}',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _cameraNavigatorKey,
            routes: [
              GoRoute(
                name: AppRoutes.camera,
                path: '/${AppRoutes.camera}',
                builder: (context, state) => const CameraScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                name: AppRoutes.settings,
                path: '/${AppRoutes.settings}',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
