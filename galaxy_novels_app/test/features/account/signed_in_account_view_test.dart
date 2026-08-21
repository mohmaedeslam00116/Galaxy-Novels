import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/signed_in_account_view.dart';

void main() {
  testWidgets('unifies identity membership level and refresh in one header', (
    tester,
  ) async {
    var refreshCalls = 0;
    await _pumpSignedIn(
      tester,
      user: _user.copyWith(
        vip: AuthVip(
          active: true,
          tier: 'gold',
          label: 'VIP ذهبي',
          expiresAt: DateTime.utc(2026, 12, 31),
        ),
      ),
      onRefreshProfile: () async => refreshCalls += 1,
    );

    expect(
      find.byKey(const ValueKey('account-profile-header')),
      findsOneWidget,
    );
    expect(find.text('قارئ الاختبار'), findsOneWidget);
    expect(find.text('قارئ جديد'), findsOneWidget);
    expect(find.text('المستوى 1'), findsOneWidget);
    expect(find.text('VIP ذهبي'), findsOneWidget);
    expect(find.textContaining('ينتهي'), findsOneWidget);
    expect(find.text('حالة العضوية'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('account-refresh-profile')));
    await tester.pump();
    expect(refreshCalls, 1);
  });

  testWidgets('profile refresh prevents duplicate requests', (tester) async {
    final refresh = Completer<void>();
    var refreshCalls = 0;
    await _pumpSignedIn(
      tester,
      user: _user,
      onRefreshProfile: () {
        refreshCalls += 1;
        return refresh.future;
      },
    );

    final action = find.byKey(const ValueKey('account-refresh-profile'));
    await tester.tap(action);
    await tester.pump();
    await tester.tap(action);
    await tester.pump();
    expect(refreshCalls, 1);

    refresh.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('account logout is a compact actionable row', (tester) async {
    var logoutCalls = 0;
    await _pumpSignedIn(
      tester,
      user: _user,
      onLogout: () async => logoutCalls += 1,
    );

    final logout = find.byKey(const ValueKey('account-logout'));
    await tester.ensureVisible(logout);
    await tester.pumpAndSettle();
    expect(logout, findsOneWidget);
    await tester.tap(logout);
    await tester.pump();
    expect(logoutCalls, 1);
  });

  testWidgets('shows a reader dashboard from authenticated profile data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SignedInAccountView(
              user: _user.copyWith(
                xp: const AuthXp(
                  total: 120,
                  today: 10,
                  secondsTotal: 7260,
                  chaptersTotal: 4,
                  rank: AuthRank(level: 3, display: 'قارئ مجري'),
                ),
              ),
              isSigningOut: false,
              onLogout: () async {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('نشاط القراءة'), findsOneWidget);
    expect(find.text('قارئ الاختبار'), findsOneWidget);
    expect(find.text('قارئ مجري'), findsOneWidget);
    expect(find.text('المستوى 3'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2س 1د'), findsOneWidget);
    expect(find.text('حالة العضوية'), findsNothing);
    expect(find.text('حساب عادي'), findsOneWidget);
    expect(find.textContaining('الفصول العامة'), findsNothing);
    expect(find.text('المفضلة'), findsOneWidget);
    expect(find.text('السجل'), findsOneWidget);
    expect(find.text('التنزيلات'), findsNothing);
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('إعدادات القراءة'), findsNothing);
  });

  testWidgets('opens account destinations from the unified list', (
    tester,
  ) async {
    final opened = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SignedInAccountView(
              user: _user,
              isSigningOut: false,
              onLogout: () async {},
              onOpenFavorites: () => opened.add('favorites'),
              onOpenHistory: () => opened.add('history'),
              onOpenReaderSettings: () => opened.add('settings'),
            ),
          ),
        ),
      ),
    );

    for (final key in const [
      'account-action-favorites',
      'account-action-history',
      'account-action-settings',
    ]) {
      final action = find.byKey(ValueKey(key));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
    }

    expect(opened, ['favorites', 'history', 'settings']);
  });

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
    expect(find.text('حالة العضوية'), findsNothing);
    expect(find.text('VIP مفعل'), findsNothing);
    expect(find.textContaining('ينتهي'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
  });

  testWidgets('offers a profile refresh action backed by the account API', (
    tester,
  ) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SignedInAccountView(
              user: _user,
              isSigningOut: false,
              onLogout: () async {},
              onRefreshProfile: () async => refreshCount += 1,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('account-refresh-profile')));
    await tester.pump();

    expect(refreshCount, 1);
  });
}

Future<void> _pumpSignedIn(
  WidgetTester tester, {
  required AuthUser user,
  Future<void> Function()? onRefreshProfile,
  Future<void> Function()? onLogout,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SignedInAccountView(
            user: user,
            isSigningOut: false,
            onLogout: onLogout ?? () async {},
            onRefreshProfile: onRefreshProfile,
          ),
        ),
      ),
    ),
  );
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

  AuthUser copyWith({AuthVip? vip, AuthXp? xp}) {
    return AuthUser(
      id: id,
      displayName: displayName,
      avatar: avatar,
      vip: vip ?? this.vip,
      xp: xp ?? this.xp,
    );
  }
}
