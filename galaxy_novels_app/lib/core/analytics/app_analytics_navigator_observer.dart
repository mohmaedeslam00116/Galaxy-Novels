import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_analytics.dart';
import 'app_screen_names.dart';

class AppAnalyticsNavigatorObserver extends NavigatorObserver {
  AppAnalyticsNavigatorObserver({required AppAnalytics analytics})
    : _analytics = analytics;

  final AppAnalytics _analytics;

  void _report(Route<dynamic>? route) {
    if (route is! PageRoute<dynamic>) return;
    final name = route.settings.name;
    if (!AppScreenNames.contains(name)) return;
    unawaited(_analytics.logScreenView(name!));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _report(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _report(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute<dynamic>) _report(previousRoute);
  }
}
