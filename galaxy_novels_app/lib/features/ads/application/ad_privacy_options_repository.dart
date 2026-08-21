enum AdPrivacyOptionsStatus { required, notRequired, unavailable }

enum AdPrivacyOptionsOutcome { shown, unavailable }

abstract interface class AdPrivacyOptionsRepository {
  Future<AdPrivacyOptionsStatus> loadStatus();

  Future<AdPrivacyOptionsOutcome> show();
}

class NoopAdPrivacyOptionsRepository implements AdPrivacyOptionsRepository {
  const NoopAdPrivacyOptionsRepository();

  @override
  Future<AdPrivacyOptionsStatus> loadStatus() async {
    return AdPrivacyOptionsStatus.unavailable;
  }

  @override
  Future<AdPrivacyOptionsOutcome> show() async {
    return AdPrivacyOptionsOutcome.unavailable;
  }
}
