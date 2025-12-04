import 'package:dominoes/constants.dart';
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
    routes: [GoRoute(name: AppRoutes.home, path: '/${AppRoutes.home}')],
  );
}
