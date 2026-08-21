import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/domain/reader_interstitial_policy.dart';

void main() {
  test(
    'reader interstitial defaults use the approved five to twenty range',
    () {
      expect(ReaderInterstitialPolicy.defaults.enabled, isTrue);
      expect(ReaderInterstitialPolicy.defaults.minimumChapters, 5);
      expect(ReaderInterstitialPolicy.defaults.maximumChapters, 20);
    },
  );

  test('valid remote values produce a reader interstitial policy', () {
    final policy = ReaderInterstitialPolicy.tryFromMap({
      ReaderInterstitialPolicy.enabledKey: false,
      ReaderInterstitialPolicy.minimumChaptersKey: 8,
      ReaderInterstitialPolicy.maximumChaptersKey: 30,
    });

    expect(
      policy,
      const ReaderInterstitialPolicy(
        enabled: false,
        minimumChapters: 8,
        maximumChapters: 30,
      ),
    );
  });

  test('invalid remote ranges are rejected', () {
    expect(
      ReaderInterstitialPolicy.tryFromMap({
        ReaderInterstitialPolicy.enabledKey: true,
        ReaderInterstitialPolicy.minimumChaptersKey: 4,
        ReaderInterstitialPolicy.maximumChaptersKey: 20,
      }),
      isNull,
    );
    expect(
      ReaderInterstitialPolicy.tryFromMap({
        ReaderInterstitialPolicy.enabledKey: true,
        ReaderInterstitialPolicy.minimumChaptersKey: 21,
        ReaderInterstitialPolicy.maximumChaptersKey: 20,
      }),
      isNull,
    );
    expect(
      ReaderInterstitialPolicy.tryFromMap({
        ReaderInterstitialPolicy.enabledKey: true,
        ReaderInterstitialPolicy.minimumChaptersKey: 5,
        ReaderInterstitialPolicy.maximumChaptersKey: 101,
      }),
      isNull,
    );
  });
}
