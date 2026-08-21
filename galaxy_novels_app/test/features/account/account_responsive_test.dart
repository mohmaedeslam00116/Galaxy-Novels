import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/guest_account_view.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/signed_in_account_view.dart';

void main() {
  for (final viewport in const [
    _Viewport(Size(320, 720), 1),
    _Viewport(Size(600, 800), 1),
    _Viewport(Size(840, 900), 1),
    _Viewport(Size(840, 360), 1),
    _Viewport(Size(320, 1100), 2),
  ]) {
    testWidgets('signed account remains usable at ${viewport.size} '
        'and ${viewport.textScale}x text', (tester) async {
      await _configureViewport(tester, viewport);
      await tester.pumpWidget(_signedAccount(viewport));

      final logout = find.byKey(const ValueKey('account-logout'));
      await tester.ensureVisible(logout);
      await tester.pumpAndSettle();

      expect(logout.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('guest account remains usable at ${viewport.size} '
        'and ${viewport.textScale}x text', (tester) async {
      await _configureViewport(tester, viewport);
      await tester.pumpWidget(_guestAccount(viewport));

      final register = find.byKey(const ValueKey('auth-show-register'));
      await tester.ensureVisible(register);
      await tester.pumpAndSettle();

      expect(register.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _configureViewport(WidgetTester tester, _Viewport viewport) async {
  tester.view.physicalSize = viewport.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _signedAccount(_Viewport viewport) {
  return _testApp(
    viewport,
    SignedInAccountView(
      user: _user,
      isSigningOut: false,
      onLogout: () async {},
      onRefreshProfile: () async {},
    ),
  );
}

Widget _guestAccount(_Viewport viewport) {
  return _testApp(
    viewport,
    GuestAccountView(onShowLogin: () {}, onShowRegister: () {}),
  );
}

Widget _testApp(_Viewport viewport, Widget body) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(
        size: viewport.size,
        textScaler: TextScaler.linear(viewport.textScale),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: body),
      ),
    ),
  );
}

class _Viewport {
  const _Viewport(this.size, this.textScale);

  final Size size;
  final double textScale;
}

const _user = AuthUser(
  id: 7,
  displayName: 'قارئ الاختبار ذو الاسم الطويل',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 12345,
    today: 100,
    secondsTotal: 7260,
    chaptersTotal: 432,
    rank: AuthRank(level: 12, display: 'قارئ مجري متقدم'),
  ),
);
