import 'package:firebase_analytics/firebase_analytics.dart';

import '../application/download_analytics.dart';

class FirebaseDownloadAnalytics implements DownloadAnalytics {
  FirebaseDownloadAnalytics({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> record(DownloadAnalyticsEvent event) async {
    try {
      await _analytics.logEvent(name: event.name, parameters: event.parameters);
    } catch (_) {
      // القياس لا يجب أن يوقف التنزيل أو يحجب المكافأة عند تعطل SDK.
    }
  }
}
