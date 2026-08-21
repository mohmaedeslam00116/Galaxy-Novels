import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/presentation/adaptive_banner_frame.dart';
import 'package:galaxy_novels_app/features/ads/presentation/admob_adaptive_banner.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  group('AdaptiveBannerFrame', () {
    testWidgets('collapses when the banner is not loaded', (tester) async {
      await _pumpFrame(tester, isLoaded: false, size: const Size(320, 50));

      expect(tester.getSize(find.byKey(_frameKey)), Size.zero);
      expect(find.byKey(_fakeChildKey), findsNothing);
    });

    testWidgets('collapses when a loaded banner has no usable size', (
      tester,
    ) async {
      const failedSizes = <Size?>[
        null,
        Size.zero,
        Size(320, 0),
        Size(double.infinity, 50),
        Size(320, double.nan),
      ];

      for (final size in failedSizes) {
        await _pumpFrame(tester, isLoaded: true, size: size);

        expect(
          tester.getSize(find.byKey(_frameKey)),
          Size.zero,
          reason: 'Expected $size to collapse',
        );
        expect(find.byKey(_fakeChildKey), findsNothing);
      }
    });

    testWidgets('uses the supplied dimensions and child when loaded', (
      tester,
    ) async {
      await _pumpFrame(tester, isLoaded: true, size: const Size(320, 50));

      expect(tester.getSize(find.byKey(_frameKey)), const Size(320, 50));
      expect(find.byKey(_fakeChildKey), findsOneWidget);
    });
  });

  testWidgets('collapses while ad readiness is pending and when it is false', (
    tester,
  ) async {
    final readiness = Completer<bool>();
    const bannerKey = Key('admob-banner');
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: AdMobAdaptiveBanner(
            key: bannerKey,
            adUnitId: 'test-unit',
            readiness: readiness.future,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AdWidget), findsNothing);
    expect(tester.getSize(find.byKey(bannerKey)).height, 0);

    readiness.complete(false);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AdWidget), findsNothing);
    expect(tester.getSize(find.byKey(bannerKey)).height, 0);
  });

  testWidgets('collapses when the adaptive SDK size lookup throws', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      instanceManager.channel,
      (call) async {
        if (call.method == 'AdSize#getLargeAnchoredAdaptiveBannerAdSize') {
          throw PlatformException(code: 'sdk-unavailable');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        instanceManager.channel,
        null,
      ),
    );

    const bannerKey = Key('admob-sdk-failure-banner');
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: AdMobAdaptiveBanner(
              key: bannerKey,
              adUnitId: 'test-unit',
              readiness: Future<bool>.value(true),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AdWidget), findsNothing);
    expect(tester.getSize(find.byKey(bannerKey)).height, 0);
  });
}

const _frameKey = Key('adaptive-banner-frame');
const _fakeChildKey = Key('fake-banner-child');

Future<void> _pumpFrame(
  WidgetTester tester, {
  required bool isLoaded,
  required Size? size,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: AdaptiveBannerFrame(
          key: _frameKey,
          isLoaded: isLoaded,
          size: size,
          child: const ColoredBox(key: _fakeChildKey, color: Colors.purple),
        ),
      ),
    ),
  );
}
