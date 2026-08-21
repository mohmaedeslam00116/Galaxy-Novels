import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/ads/application/full_screen_ad_repository.dart';
import 'package:galaxy_novels_app/features/ads/presentation/app_open_ad_host.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets(
    'cold start uses the resolved regular account and removes cover',
    (tester) async {
      final ads = _TestFullScreenAds();
      await tester.pumpWidget(
        MaterialApp(
          home: AppOpenAdHost(
            authRepository: FakeAuthRepository(),
            ads: ads,
            child: const SizedBox(key: ValueKey('app-content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(ads.coldStartCalls, 1);
      expect(ads.lastCanShow, isTrue);
      expect(find.byKey(const ValueKey('app-content')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('app-open-loading-cover')),
        findsNothing,
      );
    },
  );

  testWidgets('cold start passes a disabled decision for an active VIP', (
    tester,
  ) async {
    final ads = _TestFullScreenAds();
    await tester.pumpWidget(
      MaterialApp(
        home: AppOpenAdHost(
          authRepository: FakeAuthRepository(
            initialState: const AuthSessionState.authenticated(_vipUser),
          ),
          ads: ads,
          child: const SizedBox(key: ValueKey('app-content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(ads.coldStartCalls, 1);
    expect(ads.lastCanShow, isFalse);
  });

  testWidgets('first onboarding session suppresses only the cold-start ad', (
    tester,
  ) async {
    final ads = _TestFullScreenAds();
    await tester.pumpWidget(
      MaterialApp(
        home: AppOpenAdHost(
          authRepository: FakeAuthRepository(),
          ads: ads,
          suppressColdStartAd: true,
          child: const SizedBox(key: ValueKey('app-content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(ads.coldStartCalls, 1);
    expect(ads.lastCanShow, isFalse);
    expect(find.byKey(const ValueKey('app-content')), findsOneWidget);
  });
}

class _TestFullScreenAds implements FullScreenAdRepository {
  int coldStartCalls = 0;
  bool? lastCanShow;

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> showAppOpenOnColdStart({required bool canShow}) async {
    coldStartCalls += 1;
    lastCanShow = canShow;
    return false;
  }

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

const _vipUser = AuthUser(
  id: 2,
  displayName: 'VIP',
  avatar: null,
  vip: AuthVip(active: true, tier: 'vip1', label: 'VIP 1', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 0, display: ''),
  ),
);
