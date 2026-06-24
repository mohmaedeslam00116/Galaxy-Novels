import '../../core/text/arabic_search_normalizer.dart';
import 'catalog_data.dart';

class SearchManifest {
  const SearchManifest({
    required this.version,
    required this.generated,
    required this.count,
    required this.index,
  });

  factory SearchManifest.fromJson(Map<String, dynamic> json) {
    return SearchManifest(
      version: _asString(json['version']),
      generated: _asInt(json['generated']),
      count: _asInt(json['count']),
      index: _asString(json['index']),
    );
  }

  final String version;
  final int generated;
  final int count;
  final String index;
}

class SearchIndex {
  const SearchIndex({required this.items});

  factory SearchIndex.fromJson(Map<String, dynamic> json) {
    return SearchIndex(
      items: _asList(json['items'])
          .map((item) => SearchIndexItem.fromJson(_asMap(item)))
          .where((item) => item.title.isNotEmpty)
          .toList(growable: false),
    );
  }

  final List<SearchIndexItem> items;

  List<SearchIndexItem> search(String query) {
    final normalizedQuery = normalizeArabicSearch(query);
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    return items
        .where((item) => item.normalizedSearch.contains(normalizedQuery))
        .toList(growable: false);
  }
}

class SearchIndexItem {
  const SearchIndexItem({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.url,
    required this.cover,
    required this.genres,
    required this.chaptersCount,
    required this.statusLabel,
    required this.views,
    required this.normalizedSearch,
    required this.manifest,
  });

  factory SearchIndexItem.fromJson(Map<String, dynamic> json) {
    final title = _asString(json['t']);
    final originalTitle = _asString(json['o']);
    final genres = _asStringList(json['g']);
    final explicitSearch = _asString(json['s']);

    return SearchIndexItem(
      id: _asInt(json['id']),
      title: title,
      originalTitle: originalTitle,
      url: _asString(json['u']),
      cover: _asString(json['c']),
      genres: genres,
      chaptersCount: _asInt(json['n']),
      statusLabel: _asString(json['st']),
      views: _asInt(json['r']),
      normalizedSearch: explicitSearch.isNotEmpty
          ? normalizeArabicSearch(explicitSearch)
          : normalizeArabicSearch([title, originalTitle, ...genres].join(' ')),
      manifest: _asString(json['manifest']),
    );
  }

  final int id;
  final String title;
  final String originalTitle;
  final String url;
  final String cover;
  final List<String> genres;
  final int chaptersCount;
  final String statusLabel;
  final int views;
  final String normalizedSearch;
  final String manifest;

  CatalogNovel toCatalogNovel() {
    return CatalogNovel(
      id: id,
      title: title,
      originalTitle: originalTitle,
      url: url,
      coverThumbnail: cover,
      coverMedium: cover,
      statusKey: '',
      statusLabel: statusLabel,
      genres: [
        for (var index = 0; index < genres.length; index += 1)
          CatalogGenre(id: index + 1, name: genres[index], slug: genres[index]),
      ],
      chaptersCount: chaptersCount,
      ratingAverage: 0,
      ratingCount: 0,
      views: views,
      updatedAt: null,
      manifest: manifest.isNotEmpty
          ? manifest
          : '/wp-content/uploads/wor-reader-cache/app/manifest/novel-$id.json',
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> _asList(Object? value) {
  if (value is List) {
    return value.cast<Object?>();
  }
  return const [];
}

List<String> _asStringList(Object? value) {
  return _asList(
    value,
  ).map(_asString).where((item) => item.isNotEmpty).toList(growable: false);
}

String _asString(Object? value) => value?.toString() ?? '';

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
