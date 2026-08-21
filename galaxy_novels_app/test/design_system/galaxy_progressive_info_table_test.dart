import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/design_system/patterns/galaxy_progressive_info_table.dart';

void main() {
  testWidgets('reveals secondary information inside the table', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: GalaxyProgressiveInfoTable(
            primaryItems: [
              GalaxyInfoItem(
                key: ValueKey('author'),
                icon: Icons.person_outline_rounded,
                label: 'الكاتب',
                value: 'كاتب الرواية',
              ),
              GalaxyInfoItem(
                icon: Icons.translate_rounded,
                label: 'المترجم',
                value: 'فريق الترجمة',
              ),
            ],
            secondaryItems: [
              GalaxyInfoItem(
                key: ValueKey('country'),
                icon: Icons.public_rounded,
                label: 'البلد',
                value: 'الصين',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('author')), findsOneWidget);
    expect(find.byKey(const ValueKey('country')), findsNothing);
    await tester.tap(find.text('عرض كل البيانات'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('country')), findsOneWidget);
    expect(find.text('عرض أقل'), findsOneWidget);
  });
}
