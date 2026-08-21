import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/account_action_list.dart';

void main() {
  testWidgets('renders account destinations as one ordered vertical list', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      _actionsApp(
        onFavorites: () => opened.add('favorites'),
        onHistory: () => opened.add('history'),
        onSettings: () => opened.add('settings'),
      ),
    );

    final favorites = find.byKey(const ValueKey('account-action-favorites'));
    final history = find.byKey(const ValueKey('account-action-history'));
    final settings = find.byKey(const ValueKey('account-action-settings'));
    expect(
      tester.getTopLeft(history).dy,
      greaterThan(tester.getTopLeft(favorites).dy),
    );
    expect(
      tester.getTopLeft(settings).dy,
      greaterThan(tester.getTopLeft(history).dy),
    );

    await tester.tap(favorites);
    await tester.tap(history);
    await tester.tap(settings);
    expect(opened, ['favorites', 'history', 'settings']);
  });

  testWidgets('account actions remain readable at 200 percent text', (
    tester,
  ) async {
    await tester.pumpWidget(_actionsApp(textScale: 2));
    expect(tester.takeException(), isNull);
    expect(find.text('الروايات المحفوظة'), findsOneWidget);
    expect(find.text('متابعة القراءة'), findsOneWidget);
    expect(find.text('المظهر وإعدادات القراءة'), findsOneWidget);
  });
}

Widget _actionsApp({
  double textScale = 1,
  VoidCallback? onFavorites,
  VoidCallback? onHistory,
  VoidCallback? onSettings,
}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: AccountActionList(
            onOpenFavorites: onFavorites,
            onOpenHistory: onHistory,
            onOpenReaderSettings: onSettings,
          ),
        ),
      ),
    ),
  );
}
