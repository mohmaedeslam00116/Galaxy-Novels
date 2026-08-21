import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_action.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_overlay.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_search_field.dart';

void main() {
  testWidgets('GalaxyButton variants keep a 48dp target and invoke once', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      GalaxyButton(
        label: 'متابعة القراءة',
        icon: Icons.play_arrow_rounded,
        onPressed: () => taps += 1,
      ),
    );

    expect(tester.getSize(find.byType(GalaxyButton)).height, 48);
    await tester.tap(find.text('متابعة القراءة'));
    expect(taps, 1);
  });

  testWidgets('GalaxyIconAction exposes tooltip and a 48dp target', (
    tester,
  ) async {
    await _pump(
      tester,
      GalaxyIconAction(
        icon: Icons.favorite_border_rounded,
        tooltip: 'إضافة إلى المفضلة',
        onPressed: () {},
      ),
    );

    expect(tester.getSize(find.byType(GalaxyIconAction)), const Size(48, 48));
    expect(find.byTooltip('إضافة إلى المفضلة'), findsOneWidget);
  });

  testWidgets(
    'GalaxySearchField sends query changes without owning data state',
    (tester) async {
      var query = '';
      await _pump(
        tester,
        GalaxySearchField(
          hintText: 'ابحث عن رواية',
          onChanged: (nextQuery) => query = nextQuery,
        ),
      );

      await tester.enterText(find.byType(TextField), 'المجنون');
      expect(query, 'المجنون');
    },
  );

  testWidgets(
    'GalaxyDialog and GalaxyBottomSheet use shared overlay geometry',
    (tester) async {
      await _pump(
        tester,
        const Column(
          children: [
            GalaxyDialog(title: 'تأكيد', content: Text('هل تريد المتابعة؟')),
            GalaxyBottomSheet(title: 'إعدادات العرض', content: Text('المحتوى')),
          ],
        ),
      );

      expect(find.text('تأكيد'), findsOneWidget);
      expect(find.text('إعدادات العرض'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
