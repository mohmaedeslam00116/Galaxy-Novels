import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/account_reading_stats.dart';

void main() {
  testWidgets('renders four reading values as one continuous table', (
    tester,
  ) async {
    await tester.pumpWidget(_statsApp(textScale: 1));

    expect(find.byKey(const ValueKey('account-reading-stats')), findsOneWidget);
    for (final key in const [
      'account-stat-total-xp',
      'account-stat-today-xp',
      'account-stat-chapters',
      'account-stat-time',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
    expect(find.text('120'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2س 1د'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reading table grows at 320 and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_statsApp(textScale: 2));

    expect(tester.takeException(), isNull);
    for (final label in const [
      'نقاط XP',
      'XP اليوم',
      'الفصول المقروءة',
      'وقت القراءة',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });
}

const _statsUser = AuthUser(
  id: 7,
  displayName: 'قارئ الاختبار',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 120,
    today: 10,
    secondsTotal: 7260,
    chaptersTotal: 4,
    rank: AuthRank(level: 3, display: 'قارئ مجري'),
  ),
);

Widget _statsApp({required double textScale}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: AccountReadingStats(user: _statsUser)),
      ),
    ),
  );
}
