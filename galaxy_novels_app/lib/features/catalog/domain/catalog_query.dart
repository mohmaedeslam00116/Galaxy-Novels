import '../../../data/models/catalog_data.dart';

enum CatalogSort {
  latest('آخر تحديث'),
  views('الأكثر مشاهدة'),
  rating('الأعلى تقييمًا'),
  chapters('عدد الفصول'),
  title('العنوان');

  const CatalogSort(this.label);

  final String label;
}

class CatalogQuery {
  const CatalogQuery({
    this.searchText = '',
    this.statusLabel,
    this.genreName,
    this.sort = CatalogSort.latest,
  });

  final String searchText;
  final String? statusLabel;
  final String? genreName;
  final CatalogSort sort;

  bool get hasActiveFilters =>
      searchText.trim().isNotEmpty || statusLabel != null || genreName != null;

  CatalogQuery copyWith({
    String? searchText,
    String? statusLabel,
    String? genreName,
    CatalogSort? sort,
    bool clearStatus = false,
    bool clearGenre = false,
  }) {
    return CatalogQuery(
      searchText: searchText ?? this.searchText,
      statusLabel: clearStatus ? null : statusLabel ?? this.statusLabel,
      genreName: clearGenre ? null : genreName ?? this.genreName,
      sort: sort ?? this.sort,
    );
  }
}

class CatalogQueryResult {
  const CatalogQueryResult({
    required this.items,
    required this.availableStatuses,
    required this.availableGenres,
  });

  final List<CatalogNovel> items;
  final List<String> availableStatuses;
  final List<String> availableGenres;
}

CatalogQueryResult applyCatalogQuery(
  List<CatalogNovel> source,
  CatalogQuery query,
) {
  final availableStatuses = _unique(
    source.map((novel) => novel.statusLabel).where((value) => value.isNotEmpty),
  );
  final availableGenres = _unique(
    source.expand((novel) => novel.genres.map((genre) => genre.name)),
  );
  final normalizedSearch = normalizeArabicSearch(query.searchText);

  final filtered = source.where((novel) {
    if (query.statusLabel != null && novel.statusLabel != query.statusLabel) {
      return false;
    }
    if (query.genreName != null &&
        !novel.genres.any((genre) => genre.name == query.genreName)) {
      return false;
    }
    if (normalizedSearch.isEmpty) {
      return true;
    }

    final haystack = normalizeArabicSearch(
      [
        novel.title,
        novel.originalTitle,
        ...novel.genres.map((genre) => genre.name),
      ].join(' '),
    );

    return haystack.contains(normalizedSearch);
  }).toList();

  filtered.sort((a, b) => _compareNovels(a, b, query.sort));

  return CatalogQueryResult(
    items: List.unmodifiable(filtered),
    availableStatuses: availableStatuses,
    availableGenres: availableGenres,
  );
}

String normalizeArabicSearch(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll(RegExp('[ىئ]'), 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('ـ', '')
      .replaceAll(RegExp(r'[^0-9A-Za-z\u0621-\u064A\u0660-\u0669]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

int _compareNovels(CatalogNovel a, CatalogNovel b, CatalogSort sort) {
  final comparison = switch (sort) {
    CatalogSort.latest => _compareNullableDatesDesc(a.updatedAt, b.updatedAt),
    CatalogSort.views => b.views.compareTo(a.views),
    CatalogSort.rating => b.ratingAverage.compareTo(a.ratingAverage),
    CatalogSort.chapters => b.chaptersCount.compareTo(a.chaptersCount),
    CatalogSort.title => a.title.compareTo(b.title),
  };

  if (comparison != 0) {
    return comparison;
  }

  return a.title.compareTo(b.title);
}

int _compareNullableDatesDesc(DateTime? a, DateTime? b) {
  if (a == null && b == null) {
    return 0;
  }
  if (a == null) {
    return 1;
  }
  if (b == null) {
    return -1;
  }
  return b.compareTo(a);
}

List<String> _unique(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    if (value.isNotEmpty && seen.add(value)) {
      result.add(value);
    }
  }
  return result;
}
