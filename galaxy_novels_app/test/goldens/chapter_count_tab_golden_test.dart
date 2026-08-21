import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/home/domain/home_customization.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_poster_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Future.wait([
      (FontLoader(
        'Readex Pro',
      )..addFont(rootBundle.load('assets/fonts/ReadexPro.ttf'))).load(),
      (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load(),
    ]);
  });

  for (final brightness in Brightness.values) {
    testWidgets('chapter count bookmark tab in ${brightness.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.dark
              ? AppTheme.dark()
              : AppTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 136,
                  child: HomePosterCard(
                    section: HomeSectionId.updatedNovels,
                    customization: HomeCustomization.defaults,
                    content: const HomePosterContent(
                      title: 'حارس النجوم',
                      imageUrl: '',
                      badge: '1324',
                      metadata: 'خيال وأكشن',
                    ),
                    onTap: null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(HomePosterCard),
        matchesGoldenFile('goldens/chapter_count_tab_${brightness.name}.png'),
      );
    });
  }
}
