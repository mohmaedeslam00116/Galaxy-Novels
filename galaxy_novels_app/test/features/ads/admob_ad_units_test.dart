import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_ad_units.dart';

void main() {
  test('debug ad config falls back to Google test unit ids', () {
    const config = AdMobAdConfig(isRelease: false);

    expect(config.androidHomeNativeId, AdMobAdUnits.androidHomeNativeTest);
    expect(config.androidAppOpenId, AdMobAdUnits.androidAppOpenTest);
    expect(config.androidNovelDetailsNativeId, AdMobAdUnits.androidNativeTest);
    expect(config.androidLibraryNativeId, AdMobAdUnits.androidNativeTest);
    expect(config.androidRankingsNativeId, AdMobAdUnits.androidNativeTest);
    expect(config.androidReaderJourneyNativeId, AdMobAdUnits.androidNativeTest);
    expect(
      config.androidBrowseInterstitialId,
      AdMobAdUnits.androidInterstitialTest,
    );
    expect(
      config.androidReaderInterstitialId,
      AdMobAdUnits.androidInterstitialTest,
    );
    expect(
      config.androidDownloadRewardedId,
      AdMobAdUnits.androidDownloadRewardedTest,
    );
  });

  test('release ad config falls back to bundled production unit ids', () {
    const config = AdMobAdConfig(isRelease: true);

    expect(
      config.androidDownloadRewardedId,
      'ca-app-pub-4720168413129669/1421531485',
    );
    expect(
      config.androidHomeNativeId,
      'ca-app-pub-4720168413129669/1233525308',
    );
    expect(config.androidAppOpenId, 'ca-app-pub-4720168413129669/4558114101');
    expect(
      config.androidNovelDetailsNativeId,
      'ca-app-pub-4720168413129669/7625206084',
    );
    expect(
      config.androidLibraryNativeId,
      'ca-app-pub-4720168413129669/8938287750',
    );
    expect(
      config.androidRankingsNativeId,
      'ca-app-pub-4720168413129669/7210273119',
    );
    expect(
      config.androidReaderJourneyNativeId,
      'ca-app-pub-4720168413129669/4999042740',
    );
    expect(
      config.androidBrowseInterstitialId,
      'ca-app-pub-4720168413129669/5705619755',
    );
    expect(
      config.androidReaderInterstitialId,
      'ca-app-pub-4720168413129669/6736464540',
    );
  });

  test('release ad config uses supplied production unit ids', () {
    const config = AdMobAdConfig(
      isRelease: true,
      androidHomeNativeId: 'ca-app-pub-123/home',
      androidAppOpenId: 'ca-app-pub-123/open',
      androidDownloadRewardedId: 'ca-app-pub-123/download',
      androidNovelDetailsNativeId: 'ca-app-pub-123/details',
      androidLibraryNativeId: 'ca-app-pub-123/library',
      androidRankingsNativeId: 'ca-app-pub-123/rankings',
      androidReaderJourneyNativeId: 'ca-app-pub-123/journey',
      androidBrowseInterstitialId: 'ca-app-pub-123/browse',
      androidReaderInterstitialId: 'ca-app-pub-123/reader',
    );

    expect(config.androidHomeNativeId, 'ca-app-pub-123/home');
    expect(config.androidAppOpenId, 'ca-app-pub-123/open');
    expect(config.androidDownloadRewardedId, 'ca-app-pub-123/download');
    expect(config.androidNovelDetailsNativeId, 'ca-app-pub-123/details');
    expect(config.androidLibraryNativeId, 'ca-app-pub-123/library');
    expect(config.androidRankingsNativeId, 'ca-app-pub-123/rankings');
    expect(config.androidReaderJourneyNativeId, 'ca-app-pub-123/journey');
    expect(config.androidBrowseInterstitialId, 'ca-app-pub-123/browse');
    expect(config.androidReaderInterstitialId, 'ca-app-pub-123/reader');
  });

  test('release download rewarded unit has a bundled production fallback', () {
    const config = AdMobAdConfig(isRelease: true);

    expect(
      config.androidDownloadRewardedId,
      AdMobAdUnits.androidDownloadRewardedProduction,
    );
  });
}
