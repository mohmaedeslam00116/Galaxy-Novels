import 'package:flutter/foundation.dart';

class AdMobAdUnits {
  const AdMobAdUnits._();

  static const androidTestAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const androidHomeNativeTest = 'ca-app-pub-3940256099942544/2247696110';
  static const androidNativeTest = 'ca-app-pub-3940256099942544/2247696110';
  static const androidInterstitialTest =
      'ca-app-pub-3940256099942544/1033173712';
  static const androidAppOpenTest = 'ca-app-pub-3940256099942544/9257395921';
  static const androidDownloadRewardedTest =
      'ca-app-pub-3940256099942544/5224354917';
  static const androidDownloadRewardedProduction =
      'ca-app-pub-4720168413129669/1421531485';
  static const androidHomeNativeProduction =
      'ca-app-pub-4720168413129669/1233525308';
  static const androidAppOpenProduction =
      'ca-app-pub-4720168413129669/4558114101';
  static const androidNovelDetailsNativeProduction =
      'ca-app-pub-4720168413129669/7625206084';
  static const androidLibraryNativeProduction =
      'ca-app-pub-4720168413129669/8938287750';
  static const androidRankingsNativeProduction =
      'ca-app-pub-4720168413129669/7210273119';
  static const androidReaderJourneyNativeProduction =
      'ca-app-pub-4720168413129669/4999042740';
  static const androidBrowseInterstitialProduction =
      'ca-app-pub-4720168413129669/5705619755';
  static const androidReaderInterstitialProduction =
      'ca-app-pub-4720168413129669/6736464540';

  static const current = AdMobAdConfig(
    isRelease: kReleaseMode,
    androidHomeNativeId: String.fromEnvironment('ADMOB_ANDROID_HOME_NATIVE_ID'),
    androidAppOpenId: String.fromEnvironment('ADMOB_ANDROID_APP_OPEN_ID'),
    androidDownloadRewardedId: String.fromEnvironment(
      'ADMOB_ANDROID_DOWNLOAD_REWARDED_ID',
    ),
    androidNovelDetailsNativeId: String.fromEnvironment(
      'ADMOB_ANDROID_NOVEL_DETAILS_NATIVE_ID',
    ),
    androidLibraryNativeId: String.fromEnvironment(
      'ADMOB_ANDROID_LIBRARY_NATIVE_ID',
    ),
    androidRankingsNativeId: String.fromEnvironment(
      'ADMOB_ANDROID_RANKINGS_NATIVE_ID',
    ),
    androidReaderJourneyNativeId: String.fromEnvironment(
      'ADMOB_ANDROID_READER_JOURNEY_NATIVE_ID',
    ),
    androidBrowseInterstitialId: String.fromEnvironment(
      'ADMOB_ANDROID_BROWSE_INTERSTITIAL_ID',
    ),
    androidReaderInterstitialId: String.fromEnvironment(
      'ADMOB_ANDROID_READER_INTERSTITIAL_ID',
    ),
  );
}

class AdMobAdConfig {
  const AdMobAdConfig({
    required this.isRelease,
    String androidHomeNativeId = '',
    String androidAppOpenId = '',
    String androidDownloadRewardedId = '',
    String androidNovelDetailsNativeId = '',
    String androidLibraryNativeId = '',
    String androidRankingsNativeId = '',
    String androidReaderJourneyNativeId = '',
    String androidBrowseInterstitialId = '',
    String androidReaderInterstitialId = '',
  }) : _androidHomeNativeId = androidHomeNativeId,
       _androidAppOpenId = androidAppOpenId,
       _androidDownloadRewardedId = androidDownloadRewardedId,
       _androidNovelDetailsNativeId = androidNovelDetailsNativeId,
       _androidLibraryNativeId = androidLibraryNativeId,
       _androidRankingsNativeId = androidRankingsNativeId,
       _androidReaderJourneyNativeId = androidReaderJourneyNativeId,
       _androidBrowseInterstitialId = androidBrowseInterstitialId,
       _androidReaderInterstitialId = androidReaderInterstitialId;

  final bool isRelease;
  final String _androidHomeNativeId;
  final String _androidAppOpenId;
  final String _androidDownloadRewardedId;
  final String _androidNovelDetailsNativeId;
  final String _androidLibraryNativeId;
  final String _androidRankingsNativeId;
  final String _androidReaderJourneyNativeId;
  final String _androidBrowseInterstitialId;
  final String _androidReaderInterstitialId;

  String get androidDownloadRewardedId => _adUnitId(
    value: _androidDownloadRewardedId,
    testValue: AdMobAdUnits.androidDownloadRewardedTest,
    defineName: 'ADMOB_ANDROID_DOWNLOAD_REWARDED_ID',
  );

  String get androidHomeNativeId => _adUnitId(
    value: _androidHomeNativeId,
    testValue: AdMobAdUnits.androidHomeNativeTest,
    defineName: 'ADMOB_ANDROID_HOME_NATIVE_ID',
  );

  String get androidAppOpenId => _adUnitId(
    value: _androidAppOpenId,
    testValue: AdMobAdUnits.androidAppOpenTest,
    defineName: 'ADMOB_ANDROID_APP_OPEN_ID',
  );

  String get androidNovelDetailsNativeId => _adUnitId(
    value: _androidNovelDetailsNativeId,
    testValue: AdMobAdUnits.androidNativeTest,
    defineName: 'ADMOB_ANDROID_NOVEL_DETAILS_NATIVE_ID',
  );

  String get androidLibraryNativeId => _adUnitId(
    value: _androidLibraryNativeId,
    testValue: AdMobAdUnits.androidNativeTest,
    defineName: 'ADMOB_ANDROID_LIBRARY_NATIVE_ID',
  );

  String get androidRankingsNativeId => _adUnitId(
    value: _androidRankingsNativeId,
    testValue: AdMobAdUnits.androidNativeTest,
    defineName: 'ADMOB_ANDROID_RANKINGS_NATIVE_ID',
  );

  String get androidReaderJourneyNativeId => _adUnitId(
    value: _androidReaderJourneyNativeId,
    testValue: AdMobAdUnits.androidNativeTest,
    defineName: 'ADMOB_ANDROID_READER_JOURNEY_NATIVE_ID',
  );

  String get androidBrowseInterstitialId => _adUnitId(
    value: _androidBrowseInterstitialId,
    testValue: AdMobAdUnits.androidInterstitialTest,
    defineName: 'ADMOB_ANDROID_BROWSE_INTERSTITIAL_ID',
  );

  String get androidReaderInterstitialId => _adUnitId(
    value: _androidReaderInterstitialId,
    testValue: AdMobAdUnits.androidInterstitialTest,
    defineName: 'ADMOB_ANDROID_READER_INTERSTITIAL_ID',
  );

  String _adUnitId({
    required String value,
    required String testValue,
    required String defineName,
  }) {
    final trimmedValue = value.trim();
    if (trimmedValue.isNotEmpty) {
      return trimmedValue;
    }
    if (!isRelease) {
      return testValue;
    }
    return switch (defineName) {
      'ADMOB_ANDROID_HOME_NATIVE_ID' =>
        AdMobAdUnits.androidHomeNativeProduction,
      'ADMOB_ANDROID_APP_OPEN_ID' => AdMobAdUnits.androidAppOpenProduction,
      'ADMOB_ANDROID_DOWNLOAD_REWARDED_ID' =>
        AdMobAdUnits.androidDownloadRewardedProduction,
      'ADMOB_ANDROID_NOVEL_DETAILS_NATIVE_ID' =>
        AdMobAdUnits.androidNovelDetailsNativeProduction,
      'ADMOB_ANDROID_LIBRARY_NATIVE_ID' =>
        AdMobAdUnits.androidLibraryNativeProduction,
      'ADMOB_ANDROID_RANKINGS_NATIVE_ID' =>
        AdMobAdUnits.androidRankingsNativeProduction,
      'ADMOB_ANDROID_READER_JOURNEY_NATIVE_ID' =>
        AdMobAdUnits.androidReaderJourneyNativeProduction,
      'ADMOB_ANDROID_BROWSE_INTERSTITIAL_ID' =>
        AdMobAdUnits.androidBrowseInterstitialProduction,
      'ADMOB_ANDROID_READER_INTERSTITIAL_ID' =>
        AdMobAdUnits.androidReaderInterstitialProduction,
      _ => throw AdMobConfigurationException(
        'Missing $defineName. Production builds must pass real AdMob unit ids '
        'with --dart-define.',
      ),
    };
  }
}

class AdMobConfigurationException implements Exception {
  const AdMobConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'AdMobConfigurationException: $message';
}
