import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/features/catalog/domain/catalog_query.dart';

void main() {
  test('normalizes Arabic search text', () {
    expect(normalizeArabicSearch('أبطالُ السَّماء ــ ١'), 'ابطال السماء ١');
    expect(normalizeArabicSearch('رواية نهاية'), 'روايه نهايه');
  });

  test('filters by normalized search text', () {
    final result = applyCatalogQuery([
      _novel(title: 'أبطال السماء'),
      _novel(title: 'بوابة الشمال'),
    ], const CatalogQuery(searchText: 'ابطال'));

    expect(result.items.map((novel) => novel.title), ['أبطال السماء']);
  });

  test('filters by status and genre', () {
    final result = applyCatalogQuery([
      _novel(title: 'أ', status: 'مستمرة', genres: ['أكشن']),
      _novel(title: 'ب', status: 'مكتملة', genres: ['دراما']),
    ], const CatalogQuery(statusLabel: 'مستمرة', genreName: 'أكشن'));

    expect(result.items.map((novel) => novel.title), ['أ']);
  });

  test('sorts by latest update by default', () {
    final result = applyCatalogQuery([
      _novel(title: 'قديم', updatedAt: DateTime.parse('2026-06-01T00:00:00Z')),
      _novel(title: 'حديث', updatedAt: DateTime.parse('2026-06-19T00:00:00Z')),
    ], const CatalogQuery());

    expect(result.items.map((novel) => novel.title), ['حديث', 'قديم']);
  });

  test('builds available statuses and genres from loaded items', () {
    final result = applyCatalogQuery([
      _novel(title: 'أ', status: 'مستمرة', genres: ['أكشن', 'خيال']),
      _novel(title: 'ب', status: 'مكتملة', genres: ['أكشن']),
    ], const CatalogQuery());

    expect(result.availableStatuses, ['مستمرة', 'مكتملة']);
    expect(result.availableGenres, ['أكشن', 'خيال']);
  });
}

CatalogNovel _novel({
  required String title,
  String status = '',
  List<String> genres = const [],
  DateTime? updatedAt,
  int views = 0,
  double rating = 0,
  int chapters = 0,
}) {
  return CatalogNovel(
    id: title.hashCode,
    title: title,
    originalTitle: '',
    url: '',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: '',
    statusLabel: status,
    genres: [
      for (var index = 0; index < genres.length; index += 1)
        CatalogGenre(id: index + 1, name: genres[index], slug: genres[index]),
    ],
    chaptersCount: chapters,
    ratingAverage: rating,
    ratingCount: rating > 0 ? 1 : 0,
    views: views,
    updatedAt: updatedAt,
    manifest: '',
  );
}
