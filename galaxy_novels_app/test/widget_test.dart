import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/galaxy_novels_app.dart';

void main() {
  testWidgets('shows Galaxy Novels Arabic shell', (tester) async {
    await tester.pumpWidget(const GalaxyNovelsApp());

    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('المكتبة'), findsOneWidget);
    expect(find.text('السجل'), findsOneWidget);
    expect(find.text('الترتيب'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('حسابي'),
      ),
      findsNothing,
    );
  });

  testWidgets('opens account screen from the drawer', (tester) async {
    await tester.pumpWidget(const GalaxyNovelsApp());

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('حسابي'), findsOneWidget);

    await tester.tap(find.text('حسابي'));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(
      find.text('سجّل الدخول لمزامنة القراءة والمفضلة و XP.'),
      findsOneWidget,
    );
  });
}
