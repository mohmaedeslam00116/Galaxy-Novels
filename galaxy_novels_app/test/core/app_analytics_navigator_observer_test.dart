import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics_navigator_observer.dart';
import 'package:galaxy_novels_app/core/analytics/app_screen_names.dart';

void main() {
  test('named page routes report stable screen views', () async {
    final analytics = _RecordingAppAnalytics();
    final observer = AppAnalyticsNavigatorObserver(analytics: analytics);
    final route = MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppScreenNames.novelDetails),
      builder: (_) => const SizedBox(),
    );

    observer.didPush(route, null);
    await Future<void>.delayed(Duration.zero);

    expect(analytics.screens, [AppScreenNames.novelDetails]);
  });

  test('unnamed pages and modal routes are not reported as screens', () async {
    final analytics = _RecordingAppAnalytics();
    final observer = AppAnalyticsNavigatorObserver(analytics: analytics);
    final unnamed = MaterialPageRoute<void>(builder: (_) => const SizedBox());
    final dialog = _TestPopupRoute();

    observer.didPush(unnamed, null);
    observer.didPush(dialog, unnamed);
    await Future<void>.delayed(Duration.zero);

    expect(analytics.screens, isEmpty);
  });

  test('popping a named page restores the previous named screen', () async {
    final analytics = _RecordingAppAnalytics();
    final observer = AppAnalyticsNavigatorObserver(analytics: analytics);
    final home = MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppScreenNames.home),
      builder: (_) => const SizedBox(),
    );
    final details = MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppScreenNames.novelDetails),
      builder: (_) => const SizedBox(),
    );

    observer.didPush(home, null);
    observer.didPush(details, home);
    observer.didPop(details, home);
    await Future<void>.delayed(Duration.zero);

    expect(analytics.screens, [
      AppScreenNames.home,
      AppScreenNames.novelDetails,
      AppScreenNames.home,
    ]);
  });

  test('screen names are unique and Firebase-safe', () {
    expect(
      AppScreenNames.values.toSet(),
      hasLength(AppScreenNames.values.length),
    );
    for (final name in AppScreenNames.values) {
      expect(name, matches(RegExp(r'^[a-z][a-z0-9_]{0,39}$')));
    }
  });
}

class _RecordingAppAnalytics implements AppAnalytics {
  final List<String> screens = [];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> logScreenView(String screenName) async {
    screens.add(screenName);
  }
}

class _TestPopupRoute extends PopupRoute<void> {
  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'test';

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => const SizedBox();
}
