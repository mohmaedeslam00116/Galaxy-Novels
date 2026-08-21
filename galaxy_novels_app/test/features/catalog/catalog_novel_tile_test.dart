import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/features/catalog/presentation/widgets/catalog_novel_tile.dart';
import 'package:galaxy_novels_app/shared/widgets/novel_cover.dart';

void main() {
  testWidgets('catalog tile shows only approved compact metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 104,
                height: 230,
                child: CatalogNovelTile(novel: _narrowStatsNovel),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(_narrowStatsNovel.title), findsOneWidget);
    expect(find.text('مستمرة'), findsOneWidget);
    expect(find.text('999 فصل'), findsOneWidget);
    expect(find.textContaining('مشاهدة'), findsNothing);
    expect(find.byKey(const ValueKey('catalog-tile-cover')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-tile-status')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-tile-chapters')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'catalog tile uses the medium cover with finite decode dimensions',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 140,
                height: 300,
                child: CatalogNovelTile(novel: _sizedCoverNovel),
              ),
            ),
          ),
        ),
      );

      final cover = tester.widget<NovelCover>(find.byType(NovelCover));

      expect(cover.imageUrl, '/medium.jpg');
      expect(cover.width.isFinite, isTrue);
      expect(cover.height.isFinite, isTrue);
      expect(cover.width, tester.getSize(find.byType(NovelCover)).width);
      expect(cover.height, tester.getSize(find.byType(NovelCover)).height);
    },
  );

  for (final (description, novel, expectedCover) in [
    ('thumbnail fallback', _thumbnailCoverNovel, '/thumb.jpg'),
    ('large fallback', _largeCoverNovel, '/large.jpg'),
  ]) {
    testWidgets('catalog tile uses the $description cover', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 140,
              height: 300,
              child: CatalogNovelTile(novel: novel),
            ),
          ),
        ),
      );

      expect(
        tester.widget<NovelCover>(find.byType(NovelCover)).imageUrl,
        expectedCover,
      );
    });
  }

  testWidgets('catalog tile fills its grid cell with a finite cover', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 156,
              height: 320,
              child: CatalogNovelTile(novel: _sizedCoverNovel),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(CatalogNovelTile)), const Size(156, 320));
    final cover = tester.widget<NovelCover>(find.byType(NovelCover));
    expect(cover.width.isFinite, isTrue);
    expect(cover.height.isFinite, isTrue);
    expect(cover.width, 156);
  });

  testWidgets('catalog tile exposes title semantics and maps tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 140,
            height: 300,
            child: CatalogNovelTile(
              key: const ValueKey('catalog-tile'),
              novel: _sizedCoverNovel,
              onTap: () => taps += 1,
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel(_sizedCoverNovel.title), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('catalog-tile')));
    expect(taps, 1);
  });
}

const _narrowStatsNovel = CatalogNovel(
  id: 1,
  title: 'رواية اختبار طويلة',
  originalTitle: '',
  url: '/novel/test/',
  coverThumbnail: '',
  coverMedium: '',
  statusKey: 'ongoing',
  statusLabel: 'مستمرة',
  genres: [CatalogGenre(id: 1, name: 'أكشن', slug: 'action')],
  chaptersCount: 999,
  ratingAverage: 4.5,
  ratingCount: 20,
  views: 1000000,
  updatedAt: null,
  manifest: '/manifest/test.json',
);

const _sizedCoverNovel = CatalogNovel(
  id: 2,
  title: 'رواية الغلاف',
  originalTitle: '',
  url: '/novel/cover/',
  coverThumbnail: '/thumb.jpg',
  coverMedium: '/medium.jpg',
  coverLarge: '/large.jpg',
  statusKey: 'ongoing',
  statusLabel: 'مستمرة',
  genres: [],
  chaptersCount: 12,
  ratingAverage: 4.5,
  ratingCount: 20,
  views: 1000,
  updatedAt: null,
  manifest: '/manifest/cover.json',
);

const _thumbnailCoverNovel = CatalogNovel(
  id: 3,
  title: 'غلاف مصغر',
  originalTitle: '',
  url: '/novel/thumbnail-cover/',
  coverThumbnail: '/thumb.jpg',
  coverMedium: '',
  coverLarge: '/large.jpg',
  statusKey: 'ongoing',
  statusLabel: 'مستمرة',
  genres: [],
  chaptersCount: 5,
  ratingAverage: 0,
  ratingCount: 0,
  views: 10,
  updatedAt: null,
  manifest: '',
);

const _largeCoverNovel = CatalogNovel(
  id: 4,
  title: 'غلاف كبير',
  originalTitle: '',
  url: '/novel/large-cover/',
  coverThumbnail: '',
  coverMedium: '',
  coverLarge: '/large.jpg',
  statusKey: 'completed',
  statusLabel: 'مكتملة',
  genres: [],
  chaptersCount: 8,
  ratingAverage: 0,
  ratingCount: 0,
  views: 20,
  updatedAt: null,
  manifest: '',
);
