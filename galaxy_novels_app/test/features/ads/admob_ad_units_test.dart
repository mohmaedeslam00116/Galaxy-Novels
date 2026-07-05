import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_ad_units.dart';

void main() {
  test('debug ad config falls back to Google test unit ids', () {
    const config = AdMobAdConfig(
      isRelease: false,
      androidReaderBannerId: '',
      androidRewardedId: '',
    );

    expect(config.androidReaderBannerId, AdMobAdUnits.androidReaderBannerTest);
    expect(config.androidRewardedId, AdMobAdUnits.androidRewardedTest);
  });

  test('release ad config rejects missing production unit ids', () {
    const config = AdMobAdConfig(
      isRelease: true,
      androidReaderBannerId: '',
      androidRewardedId: '',
    );

    expect(
      () => config.androidReaderBannerId,
      throwsA(isA<AdMobConfigurationException>()),
    );
    expect(
      () => config.androidRewardedId,
      throwsA(isA<AdMobConfigurationException>()),
    );
  });

  test('release ad config uses supplied production unit ids', () {
    const config = AdMobAdConfig(
      isRelease: true,
      androidReaderBannerId: 'ca-app-pub-123/reader',
      androidRewardedId: 'ca-app-pub-123/rewarded',
    );

    expect(config.androidReaderBannerId, 'ca-app-pub-123/reader');
    expect(config.androidRewardedId, 'ca-app-pub-123/rewarded');
  });
}
