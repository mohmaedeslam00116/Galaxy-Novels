import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/application/full_screen_ad_cadence.dart';
import 'package:galaxy_novels_app/features/ads/data/shared_preferences_full_screen_ad_cadence_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('old cadence payloads restore with an untouched reader cycle', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          SharedPreferencesFullScreenAdCadenceStore.key: jsonEncode({
            'app_launches': 4,
            'novel_detail_opens_since_browse_ad': 3,
          }),
        });
    final store = SharedPreferencesFullScreenAdCadenceStore(
      preferences: SharedPreferencesAsync(),
    );

    final state = await store.read();

    expect(state.appLaunches, 4);
    expect(state.novelDetailOpensSinceBrowseAd, 3);
    expect(state.readerForwardTransitionsSinceInterstitial, 0);
    expect(state.readerInterstitialTarget, 0);
    expect(state.readerInterstitialRetryAtTransition, 0);
  });

  test('reader cadence survives a storage round trip', () async {
    final store = SharedPreferencesFullScreenAdCadenceStore(
      preferences: SharedPreferencesAsync(),
    );
    const expected = FullScreenAdCadenceState(
      appLaunches: 8,
      novelDetailOpensSinceBrowseAd: 2,
      readerForwardTransitionsSinceInterstitial: 9,
      readerInterstitialTarget: 14,
      readerInterstitialRetryAtTransition: 0,
    );

    await store.write(expected);
    final restored = await store.read();

    expect(restored.appLaunches, 8);
    expect(restored.novelDetailOpensSinceBrowseAd, 2);
    expect(restored.readerForwardTransitionsSinceInterstitial, 9);
    expect(restored.readerInterstitialTarget, 14);
    expect(restored.readerInterstitialRetryAtTransition, 0);
  });
}
