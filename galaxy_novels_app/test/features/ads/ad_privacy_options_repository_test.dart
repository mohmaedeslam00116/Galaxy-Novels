import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/application/ad_privacy_options_repository.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_ad_privacy_options_repository.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_initialization_coordinator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  test('maps the required UMP state and presents privacy options', () async {
    var formPresentations = 0;
    final repository = AdMobAdPrivacyOptionsRepository(
      coordinator: _readyCoordinator(),
      statusLoader: () async => PrivacyOptionsRequirementStatus.required,
      formPresenter: () async => formPresentations += 1,
    );

    expect(await repository.loadStatus(), AdPrivacyOptionsStatus.required);
    expect(await repository.show(), AdPrivacyOptionsOutcome.shown);
    expect(formPresentations, 1);
  });

  test('maps not-required and unknown UMP states safely', () async {
    final notRequired = AdMobAdPrivacyOptionsRepository(
      coordinator: _readyCoordinator(),
      statusLoader: () async => PrivacyOptionsRequirementStatus.notRequired,
      formPresenter: () async {},
    );
    final unknown = AdMobAdPrivacyOptionsRepository(
      coordinator: _readyCoordinator(),
      statusLoader: () async => PrivacyOptionsRequirementStatus.unknown,
      formPresenter: () async {},
    );

    expect(await notRequired.loadStatus(), AdPrivacyOptionsStatus.notRequired);
    expect(await unknown.loadStatus(), AdPrivacyOptionsStatus.unavailable);
  });

  test('stays unavailable outside Android and never invokes UMP', () async {
    var statusLoads = 0;
    final repository = AdMobAdPrivacyOptionsRepository(
      coordinator: AdMobInitializationCoordinator(isAndroid: () => false),
      statusLoader: () async {
        statusLoads += 1;
        return PrivacyOptionsRequirementStatus.required;
      },
      formPresenter: () async {},
    );

    expect(await repository.loadStatus(), AdPrivacyOptionsStatus.unavailable);
    expect(await repository.show(), AdPrivacyOptionsOutcome.unavailable);
    expect(statusLoads, 0);
  });
}

AdMobInitializationCoordinator _readyCoordinator() {
  return AdMobInitializationCoordinator(
    isAndroid: () => true,
    updateConsentInfo: () async {},
    showConsentFormIfRequired: () async {},
    canRequestAds: () async => true,
    initializeMobileAds: () async {},
  );
}
