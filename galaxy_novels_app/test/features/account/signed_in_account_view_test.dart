import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/signed_in_account_view.dart';

void main() {
  testWidgets('shows active VIP status with expiry date', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SignedInAccountView(
              user: _user.copyWith(
                vip: AuthVip(
                  active: true,
                  tier: 'gold',
                  label: 'VIP ذهبي',
                  expiresAt: DateTime.utc(2026, 12, 31),
                ),
              ),
              isSigningOut: false,
              onLogout: () async {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('VIP ذهبي'), findsOneWidget);
    expect(find.textContaining('ينتهي'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
  });
}

const _user = _TestAuthUser(
  id: 7,
  displayName: 'قارئ الاختبار',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 120,
    today: 10,
    secondsTotal: 0,
    chaptersTotal: 4,
    rank: AuthRank(level: 1, display: 'قارئ جديد'),
  ),
);

class _TestAuthUser extends AuthUser {
  const _TestAuthUser({
    required super.id,
    required super.displayName,
    required super.avatar,
    required super.vip,
    required super.xp,
  });

  AuthUser copyWith({AuthVip? vip}) {
    return AuthUser(
      id: id,
      displayName: displayName,
      avatar: avatar,
      vip: vip ?? this.vip,
      xp: xp,
    );
  }
}
