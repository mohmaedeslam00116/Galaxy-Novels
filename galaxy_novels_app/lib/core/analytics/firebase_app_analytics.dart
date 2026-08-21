import 'package:firebase_analytics/firebase_analytics.dart';

import 'app_analytics.dart';

class FirebaseAppAnalytics implements AppAnalytics {
  FirebaseAppAnalytics({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } on Exception {
      // Measurement must never interrupt application behavior.
    }
  }

  @override
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
    } on Exception {
      // Measurement must never interrupt navigation.
    }
  }
}
