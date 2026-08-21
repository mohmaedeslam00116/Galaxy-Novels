import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/design_system/foundation/galaxy_component_variants.dart';
import 'package:galaxy_novels_app/design_system/novel/galaxy_chapter_count_tab.dart';
import 'package:galaxy_novels_app/features/home/domain/home_customization.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_poster_card.dart';

void main() {
  testWidgets('numeric cover badge uses the chapter count bookmark tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      _PosterHarness(
        content: const HomePosterContent(
          title: 'رواية اختبار',
          imageUrl: '',
          badge: '1324',
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('home-poster-chapter-count-tab-updatedNovels')),
      findsOneWidget,
    );
    expect(find.text('1324'), findsOneWidget);
    expect(find.text('فصل'), findsOneWidget);
  });

  testWidgets('text cover badge keeps the standard status treatment', (
    tester,
  ) async {
    await tester.pumpWidget(
      _PosterHarness(
        content: const HomePosterContent(
          title: 'رواية اختبار',
          imageUrl: '',
          badge: 'مستمرة',
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('home-poster-badge-updatedNovels')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-poster-chapter-count-tab-updatedNovels')),
      findsNothing,
    );
  });

  testWidgets('bookmark tab fits four digits at 200 percent text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GalaxyChapterCountTab(
                  chapterCount: '1324',
                  size: GalaxyComponentSize.small,
                ),
                GalaxyChapterCountTab(chapterCount: '1324'),
                GalaxyChapterCountTab(
                  chapterCount: '1324',
                  size: GalaxyComponentSize.large,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('1324 فصلًا'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}

class _PosterHarness extends StatelessWidget {
  const _PosterHarness({required this.content});

  final HomePosterContent content;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 136,
            child: HomePosterCard(
              section: HomeSectionId.updatedNovels,
              customization: HomeCustomization.defaults,
              content: content,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
  }
}
