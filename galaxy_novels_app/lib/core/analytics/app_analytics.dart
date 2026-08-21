abstract interface class AppAnalytics {
  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  Future<void> logScreenView(String screenName);
}

class NoopAppAnalytics implements AppAnalytics {
  const NoopAppAnalytics();

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> logScreenView(String screenName) async {}
}
