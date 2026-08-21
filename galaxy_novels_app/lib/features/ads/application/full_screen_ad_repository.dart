abstract class FullScreenAdRepository {
  bool get isSupported;

  Future<void> initialize();

  Future<bool> showAppOpenOnColdStart({required bool canShow});

  Future<bool> showAppOpenOnForeground({required bool canShow});

  Future<bool> showBrowseInterstitial({required bool canShow}) async => false;

  Future<bool> showReaderInterstitialIfDue({required bool canShow}) async =>
      false;

  void dispose();
}

class NoopFullScreenAdRepository implements FullScreenAdRepository {
  const NoopFullScreenAdRepository();

  @override
  bool get isSupported => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> showAppOpenOnColdStart({required bool canShow}) async => false;

  @override
  Future<bool> showAppOpenOnForeground({required bool canShow}) async => false;

  @override
  Future<bool> showBrowseInterstitial({required bool canShow}) async => false;

  @override
  Future<bool> showReaderInterstitialIfDue({required bool canShow}) async =>
      false;

  @override
  void dispose() {}
}
