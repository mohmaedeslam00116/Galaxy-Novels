import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/design_system/gallery/galaxy_design_system_gallery.dart';
import 'package:galaxy_novels_app/design_system/novel/galaxy_novel_card.dart';

void main() {
  testWidgets('gallery renders local fixtures without network images', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const GalaxyDesignSystemGallery(),
      ),
    );

    expect(find.text('Galaxy Design System'), findsOneWidget);
    expect(find.byType(GalaxyNovelCard), findsWidgets);
    expect(
      find.byKey(const ValueKey('galaxy-cinematic-cover')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('galaxy-editorial-caption')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('galaxy-stats-rail')), findsOneWidget);
    expect(find.bySemanticsLabel('أوامر المكتبة'), findsOneWidget);
    expect(find.byKey(const ValueKey('galaxy-gallery-states')), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('معاينة starlightPaper'));
    await tester.pump();
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );
    expect(scaffold.backgroundColor, isNull);
  });
}
