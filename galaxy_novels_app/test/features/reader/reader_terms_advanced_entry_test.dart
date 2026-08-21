import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_advanced_terminology.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_terms_settings_panel.dart';

void main() {
  testWidgets('advanced entry stays hidden until access is unlocked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _surface(
        ReaderTermsSettingsPanel(
          replacements: const [],
          novelId: 0,
          highlightEnabled: false,
          onHighlightChanged: (_) {},
          onEdit: null,
          onDelete: null,
          advancedState: ReaderAdvancedTerminologyState.defaults,
          onOpenAdvanced: () {},
        ),
      ),
    );

    expect(find.text('أدوات المصطلحات المتقدمة'), findsNothing);
  });

  testWidgets('unlocked entry reports pack state and opens management', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      _surface(
        ReaderTermsSettingsPanel(
          replacements: const [],
          novelId: 0,
          highlightEnabled: false,
          onHighlightChanged: (_) {},
          onEdit: null,
          onDelete: null,
          advancedState: ReaderAdvancedTerminologyState.defaults.copyWith(
            accessUnlocked: true,
          ),
          onOpenAdvanced: () => opened = true,
        ),
      ),
    );

    expect(find.text('أدوات المصطلحات المتقدمة'), findsOneWidget);
    expect(find.text('لا توجد حزمة مستوردة'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reader-advanced-terms-entry')));
    expect(opened, isTrue);
  });
}

Widget _surface(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}
