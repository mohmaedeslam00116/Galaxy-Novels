import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/models/search_index_data.dart';
import 'package:galaxy_novels_app/features/home/domain/home_recommendations.dart';

void main() {
  test('uses the latest history novel that exists in the search index', () {
    final result = buildHomeRecommendations(
      history: [_progress(99, daysAgo: 0), _progress(1, daysAgo: 1)],
      index: SearchIndex(
        items: [
          _novel(1, genres: const ['خيال', 'أكشن']),
          _novel(2, genres: const ['خيال']),
        ],
      ),
      excludedNovelIds: const {},
      limit: 12,
    );

    expect(result?.anchorNovel.id, 1);
    expect(result?.items.single.novel.id, 2);
    expect(result?.strongestGenre, 'خيال');
  });

  test('ranks by shared genres then views then title', () {
    final result = buildHomeRecommendations(
      history: [_progress(1)],
      index: SearchIndex(
        items: [
          _novel(1, genres: const ['خيال', 'أكشن']),
          _novel(2, genres: const ['خيال'], views: 900),
          _novel(3, genres: const ['خيال', 'أكشن'], views: 20),
          _novel(4, genres: const ['خيال'], views: 100),
        ],
      ),
      excludedNovelIds: const {},
      limit: 12,
    );

    expect(result?.items.map((item) => item.novel.id), [3, 2, 4]);
    expect(result?.items.first.sharedGenres, ['خيال', 'أكشن']);
  });

  test('excludes read and hidden novels and caps results at twelve', () {
    final catalog = [
      _novel(1, genres: const ['خيال']),
      _novel(2, genres: const ['خيال']),
      for (var id = 3; id <= 20; id++)
        _novel(id, genres: const ['خيال'], views: 100 - id),
    ];

    final result = buildHomeRecommendations(
      history: [_progress(1), _progress(2, daysAgo: 1)],
      index: SearchIndex(items: catalog),
      excludedNovelIds: const {3},
      limit: 50,
    );

    expect(result?.items, hasLength(12));
    expect(result?.items.map((item) => item.novel.id), isNot(contains(2)));
    expect(result?.items.map((item) => item.novel.id), isNot(contains(3)));
  });

  test('returns no section without history or matching genres', () {
    final index = SearchIndex(
      items: [
        _novel(1, genres: const ['خيال']),
        _novel(2, genres: const ['رومانسية']),
      ],
    );

    expect(
      buildHomeRecommendations(
        history: const [],
        index: index,
        excludedNovelIds: const {},
        limit: 8,
      ),
      isNull,
    );
    expect(
      buildHomeRecommendations(
        history: [_progress(1)],
        index: index,
        excludedNovelIds: const {},
        limit: 8,
      ),
      isNull,
    );
  });
}

ReadingProgress _progress(int novelId, {int daysAgo = 0}) {
  return ReadingProgress(
    novelId: novelId,
    novelTitle: 'رواية $novelId',
    chapterId: novelId * 10,
    chapterTitle: 'الفصل 1',
    contentApi: '/chapters/$novelId',
    updatedAt: DateTime.utc(2026, 8, 6).subtract(Duration(days: daysAgo)),
  );
}

SearchIndexItem _novel(int id, {required List<String> genres, int views = 0}) {
  return SearchIndexItem(
    id: id,
    title: 'رواية $id',
    originalTitle: '',
    url: '/novels/$id',
    cover: '/covers/$id.jpg',
    genres: genres,
    chaptersCount: 40,
    statusLabel: 'مستمرة',
    views: views,
    normalizedSearch: 'رواية $id',
    manifest: '/manifests/$id.json',
  );
}
