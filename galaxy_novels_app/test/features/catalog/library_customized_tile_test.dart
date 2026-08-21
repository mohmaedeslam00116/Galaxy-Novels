import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/features/catalog/domain/library_customization.dart';
import 'package:galaxy_novels_app/features/catalog/presentation/widgets/catalog_novel_tile.dart';

void main() {
  final templates = <LibraryCustomization>[
    LibraryCustomization.defaults.copyWith(
      layout: LibraryLayout.grid,
      gridTemplate: LibraryGridTemplate.calmPoster,
    ),
    LibraryCustomization.defaults.copyWith(
      layout: LibraryLayout.grid,
      gridTemplate: LibraryGridTemplate.coverOnly,
    ),
    LibraryCustomization.defaults.copyWith(
      layout: LibraryLayout.list,
      listTemplate: LibraryListTemplate.detailed,
    ),
    LibraryCustomization.defaults.copyWith(
      layout: LibraryLayout.list,
      listTemplate: LibraryListTemplate.compact,
    ),
  ];

  for (
    var templateIndex = 0;
    templateIndex < templates.length;
    templateIndex++
  ) {
    for (final size in LibraryCardSize.values) {
      for (final cover in LibraryCoverPresentation.values) {
        testWidgets(
          'customized tile renders template $templateIndex, ${size.name}, ${cover.name}',
          (tester) async {
            final customization = templates[templateIndex].copyWith(
              cardSize: size,
              coverPresentation: cover,
              cardSurface: LibraryCardSurface
                  .values[templateIndex % LibraryCardSurface.values.length],
              cardCorner: LibraryCardCorner
                  .values[templateIndex % LibraryCardCorner.values.length],
              visibleFields: LibraryCardField.values.toSet(),
            );

            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: customization.layout == LibraryLayout.grid
                          ? 180
                          : 320,
                      height: customization.layout == LibraryLayout.grid
                          ? 360
                          : 260,
                      child: CatalogNovelTile(
                        novel: _novel,
                        customization: customization,
                      ),
                    ),
                  ),
                ),
              ),
            );

            expect(find.text(_novel.title), findsOneWidget);
            expect(
              find.byKey(const ValueKey('catalog-tile-cover')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('cover and title remain when every optional field is hidden', (
    tester,
  ) async {
    final customization = LibraryCustomization.defaults.copyWith(
      visibleFields: const {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 170,
            height: 330,
            child: CatalogNovelTile(
              novel: _novel,
              customization: customization,
            ),
          ),
        ),
      ),
    );

    expect(find.text(_novel.title), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-tile-cover')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-tile-status')), findsNothing);
    expect(find.byKey(const ValueKey('catalog-tile-chapters')), findsNothing);
    expect(find.byKey(const ValueKey('catalog-tile-rating')), findsNothing);
    expect(find.byKey(const ValueKey('catalog-tile-genre')), findsNothing);
  });

  testWidgets(
    'balanced grid applies the surface to the poster, not its caption',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 360,
              child: CatalogNovelTile(novel: _novel),
            ),
          ),
        ),
      );

      final coverSurface = find.byKey(
        const ValueKey('catalog-editorial-cover-surface'),
      );
      expect(coverSurface, findsOneWidget);
      expect(
        find.descendant(of: coverSurface, matching: find.text(_novel.title)),
        findsNothing,
      );
      expect(find.text(_novel.title), findsOneWidget);
    },
  );
}

const _novel = CatalogNovel(
  id: 71,
  title: 'رواية مخصصة للاختبار',
  originalTitle: '',
  url: '',
  coverThumbnail: '',
  coverMedium: '',
  statusKey: 'ongoing',
  statusLabel: 'مستمرة',
  genres: [CatalogGenre(id: 4, name: 'خيال', slug: 'fantasy')],
  chaptersCount: 144,
  ratingAverage: 4.6,
  ratingCount: 35,
  views: 800,
  updatedAt: null,
  manifest: '',
);
