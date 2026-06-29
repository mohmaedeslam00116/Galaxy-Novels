import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/features/catalog/presentation/widgets/catalog_novel_tile.dart';

void main() {
  testWidgets('catalog tile stats keep compact numbers visible', (
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

    final viewsText = tester.widget<Text>(find.text('1.0M'));

    expect(viewsText.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
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
