import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/search_index_data.dart';

void main() {
  test('parses search manifest and index items', () {
    final manifest = SearchManifest.fromJson({
      'version': 'search-v1',
      'generated': 1710000000,
      'count': 1,
      'index': '/wp-content/uploads/wor-reader-cache/search/novels-v1.json',
    });

    expect(manifest.version, 'search-v1');
    expect(manifest.count, 1);
    expect(
      manifest.index,
      '/wp-content/uploads/wor-reader-cache/search/novels-v1.json',
    );

    final index = SearchIndex.fromJson({
      'v': 1,
      'items': [
        {
          'id': 42,
          't': 'أبطال السماء',
          'o': 'Sky Heroes',
          'u': '/novel/sky-heroes/',
          'c': '/cover.jpg',
          'g': ['أكشن', 'خيال'],
          'n': 120,
          'st': 'مستمرة',
          'r': 15000,
          's': 'ابطال السماء sky heroes اكشن خيال',
          'manifest':
              '/wp-content/uploads/wor-reader-cache/app/manifest/novel-42.json',
        },
      ],
    });

    expect(index.items.single.id, 42);
    expect(index.items.single.title, 'أبطال السماء');
    expect(index.items.single.genres, ['أكشن', 'خيال']);
    expect(index.items.single.chaptersCount, 120);
    expect(index.items.single.views, 15000);
  });

  test('filters search index with normalized Arabic text', () {
    final index = SearchIndex.fromJson({
      'items': [
        {'id': 1, 't': 'أبطال السماء', 's': 'ابطال السماء'},
        {'id': 2, 't': 'بوابة الشمال', 's': 'بوابه الشمال'},
      ],
    });

    expect(index.search('أبطال').map((item) => item.title), ['أبطال السماء']);
    expect(index.search('بوابة').map((item) => item.title), ['بوابة الشمال']);
  });

  test('converts search result to a catalog novel for UI reuse', () {
    final item = SearchIndexItem.fromJson({
      'id': 42,
      't': 'أبطال السماء',
      'u': '/novel/sky-heroes/',
      'c': '/cover.jpg',
      'g': ['أكشن'],
      'n': 120,
      'st': 'مستمرة',
      'r': 15000,
    });

    final novel = item.toCatalogNovel();

    expect(novel.title, 'أبطال السماء');
    expect(novel.coverThumbnail, '/cover.jpg');
    expect(novel.statusLabel, 'مستمرة');
    expect(novel.genres.single.name, 'أكشن');
    expect(novel.chaptersCount, 120);
    expect(novel.views, 15000);
    expect(
      novel.manifest,
      '/wp-content/uploads/wor-reader-cache/app/manifest/novel-42.json',
    );
  });
}
