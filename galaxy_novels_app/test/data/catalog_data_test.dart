import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';

void main() {
  test('parses catalog manifest packs and metadata', () {
    final manifest = CatalogManifest.fromJson({
      'schema': 1,
      'generated': 1718780000,
      'version': 'catalog-hash',
      'count': 1200,
      'part_size': 500,
      'packs': [
        '/wp-content/uploads/wor-reader-cache/app/packs/catalog-1.json',
        '/wp-content/uploads/wor-reader-cache/app/packs/catalog-2.json',
      ],
    });

    expect(manifest.version, 'catalog-hash');
    expect(manifest.count, 1200);
    expect(manifest.partSize, 500);
    expect(manifest.packs, [
      '/wp-content/uploads/wor-reader-cache/app/packs/catalog-1.json',
      '/wp-content/uploads/wor-reader-cache/app/packs/catalog-2.json',
    ]);
  });

  test('parses catalog pack items with nested fields', () {
    final pack = CatalogPack.fromJson({
      'schema': 1,
      'generated': 1718780000,
      'part': 1,
      'total_parts': 3,
      'items': [
        {
          'id': 10,
          'title': 'نجوم الاختبار',
          'original_title': 'Test Stars',
          'url': '/novel/test-stars/',
          'cover': {
            'thumbnail': '/uploads/thumb.jpg',
            'medium': '/uploads/medium.jpg',
            'large': '/uploads/large.jpg',
          },
          'status': {'key': 'ongoing', 'label': 'مستمرة'},
          'genres': [
            {'id': 1, 'name': 'أكشن', 'slug': 'action'},
            {'id': 2, 'name': 'خيال', 'slug': 'fantasy'},
          ],
          'chapters_count': 120,
          'rating': {'average': 4.5, 'count': 30},
          'stats': {'views': 10000},
          'updated_at': '2026-06-18T10:00:00+00:00',
          'manifest': '/manifest/novel-10.json',
        },
      ],
    });

    final novel = pack.items.single;

    expect(pack.part, 1);
    expect(pack.totalParts, 3);
    expect(novel.id, 10);
    expect(novel.title, 'نجوم الاختبار');
    expect(novel.originalTitle, 'Test Stars');
    expect(novel.url, '/novel/test-stars/');
    expect(novel.coverThumbnail, '/uploads/thumb.jpg');
    expect(novel.coverMedium, '/uploads/medium.jpg');
    expect(novel.coverLarge, '/uploads/large.jpg');
    expect(novel.bestCover, '/uploads/large.jpg');
    expect(novel.statusKey, 'ongoing');
    expect(novel.statusLabel, 'مستمرة');
    expect(novel.genres.map((genre) => genre.name), ['أكشن', 'خيال']);
    expect(novel.genres.map((genre) => genre.slug), ['action', 'fantasy']);
    expect(novel.chaptersCount, 120);
    expect(novel.ratingAverage, 4.5);
    expect(novel.ratingCount, 30);
    expect(novel.views, 10000);
    expect(novel.updatedAt, DateTime.parse('2026-06-18T10:00:00+00:00'));
    expect(novel.manifest, '/manifest/novel-10.json');
  });

  test('uses safe defaults for missing optional fields', () {
    final novel = CatalogNovel.fromJson({'id': 7, 'title': 'رواية ناقصة'});

    expect(novel.id, 7);
    expect(novel.title, 'رواية ناقصة');
    expect(novel.originalTitle, '');
    expect(novel.url, '');
    expect(novel.coverThumbnail, '');
    expect(novel.coverMedium, '');
    expect(novel.coverLarge, '');
    expect(novel.bestCover, '');
    expect(novel.statusKey, '');
    expect(novel.statusLabel, '');
    expect(novel.genres, isEmpty);
    expect(novel.chaptersCount, 0);
    expect(novel.ratingAverage, 0);
    expect(novel.ratingCount, 0);
    expect(novel.views, 0);
    expect(novel.updatedAt, isNull);
    expect(novel.manifest, '');
  });
}
