import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/ads/application/standard_ad_visibility_policy.dart';

void main() {
  test('ordinary ads are visible to guests and regular users', () {
    expect(
      StandardAdVisibilityPolicy.canShow(const AuthSessionState.guest()),
      isTrue,
    );
    expect(
      StandardAdVisibilityPolicy.canShow(
        AuthSessionState.authenticated(_user(activeVip: false)),
      ),
      isTrue,
    );
  });

  for (final tier in ['vip1', 'vip2', 'vip3', 'vipmax']) {
    test('ordinary ads are hidden from active $tier users', () {
      expect(
        StandardAdVisibilityPolicy.canShow(
          AuthSessionState.authenticated(_user(activeVip: true, tier: tier)),
        ),
        isFalse,
      );
    });
  }

  test('ordinary ads stay hidden while the session is unresolved', () {
    expect(
      StandardAdVisibilityPolicy.canShow(const AuthSessionState.idle()),
      isFalse,
    );
    expect(
      StandardAdVisibilityPolicy.canShow(const AuthSessionState.restoring()),
      isFalse,
    );
    expect(
      StandardAdVisibilityPolicy.canShow(
        const AuthSessionState.authenticating(),
      ),
      isFalse,
    );
  });
}

AuthUser _user({required bool activeVip, String tier = ''}) {
  return AuthUser(
    id: 1,
    displayName: 'قارئ',
    avatar: null,
    vip: AuthVip(
      active: activeVip,
      tier: tier,
      label: activeVip ? tier : '',
      expiresAt: null,
    ),
    xp: const AuthXp(
      total: 0,
      today: 0,
      secondsTotal: 0,
      chaptersTotal: 0,
      rank: AuthRank(level: 0, display: ''),
    ),
  );
}
