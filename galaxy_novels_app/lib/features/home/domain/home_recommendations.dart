import '../../../data/models/catalog_data.dart';
import '../../../data/models/reading_progress.dart';
import '../../../data/models/search_index_data.dart';

class HomeRecommendation {
  const HomeRecommendation({required this.novel, required this.sharedGenres});

  final CatalogNovel novel;
  final List<String> sharedGenres;

  String get reasonLabel => 'مشترك في: ${sharedGenres.join(' و')}';
}

class HomeRecommendationResult {
  const HomeRecommendationResult({
    required this.anchorNovel,
    required this.strongestGenre,
    required this.items,
  });

  final SearchIndexItem anchorNovel;
  final String strongestGenre;
  final List<HomeRecommendation> items;
}

HomeRecommendationResult? buildHomeRecommendations({
  required List<ReadingProgress> history,
  required SearchIndex index,
  required Set<int> excludedNovelIds,
  required int limit,
}) {
  final novelsById = {for (final novel in index.items) novel.id: novel};
  final anchor = _latestIndexedNovel(history, novelsById);
  if (anchor == null || anchor.genres.isEmpty) {
    return null;
  }

  final readIds = history.map((progress) => progress.novelId).toSet();
  final candidates = <_RecommendationCandidate>[];
  for (final novel in index.items) {
    if (readIds.contains(novel.id) || excludedNovelIds.contains(novel.id)) {
      continue;
    }
    final sharedGenres = [
      for (final genre in anchor.genres)
        if (novel.genres.contains(genre)) genre,
    ];
    if (sharedGenres.isNotEmpty) {
      candidates.add((novel: novel, sharedGenres: sharedGenres));
    }
  }
  if (candidates.isEmpty) {
    return null;
  }

  candidates.sort(_compareCandidates);
  final cappedLimit = limit.clamp(1, 12);
  final selected = candidates.take(cappedLimit).toList(growable: false);
  return HomeRecommendationResult(
    anchorNovel: anchor,
    strongestGenre: _strongestGenre(anchor.genres, candidates),
    items: List.unmodifiable(
      selected.map(
        (candidate) => HomeRecommendation(
          novel: candidate.novel.toCatalogNovel(),
          sharedGenres: List.unmodifiable(candidate.sharedGenres),
        ),
      ),
    ),
  );
}

typedef _RecommendationCandidate = ({
  SearchIndexItem novel,
  List<String> sharedGenres,
});

SearchIndexItem? _latestIndexedNovel(
  List<ReadingProgress> history,
  Map<int, SearchIndexItem> novelsById,
) {
  final indexedHistory =
      history
          .where((progress) => novelsById.containsKey(progress.novelId))
          .toList(growable: false)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return indexedHistory.isEmpty
      ? null
      : novelsById[indexedHistory.first.novelId];
}

int _compareCandidates(
  _RecommendationCandidate first,
  _RecommendationCandidate second,
) {
  final sharedComparison = second.sharedGenres.length.compareTo(
    first.sharedGenres.length,
  );
  if (sharedComparison != 0) return sharedComparison;
  final viewsComparison = second.novel.views.compareTo(first.novel.views);
  if (viewsComparison != 0) return viewsComparison;
  return first.novel.title.compareTo(second.novel.title);
}

String _strongestGenre(
  List<String> anchorGenres,
  List<_RecommendationCandidate> candidates,
) {
  var strongest = anchorGenres.first;
  var strongestCount = -1;
  for (final genre in anchorGenres) {
    final count = candidates
        .where((candidate) => candidate.sharedGenres.contains(genre))
        .length;
    if (count > strongestCount) {
      strongest = genre;
      strongestCount = count;
    }
  }
  return strongest;
}
