class CatalogManifest {
  const CatalogManifest({
    required this.version,
    required this.count,
    required this.partSize,
    required this.packs,
  });

  factory CatalogManifest.fromJson(Map<String, dynamic> json) {
    return CatalogManifest(
      version: _asString(json['version']),
      count: _asInt(json['count']),
      partSize: _asInt(json['part_size']),
      packs: _asStringList(json['packs']),
    );
  }

  final String version;
  final int count;
  final int partSize;
  final List<String> packs;
}

class CatalogPack {
  const CatalogPack({
    required this.part,
    required this.totalParts,
    required this.items,
  });

  factory CatalogPack.fromJson(Map<String, dynamic> json) {
    return CatalogPack(
      part: _asInt(json['part']),
      totalParts: _asInt(json['total_parts']),
      items: _asList(json['items'])
          .map((item) => CatalogNovel.fromJson(_asMap(item)))
          .toList(growable: false),
    );
  }

  final int part;
  final int totalParts;
  final List<CatalogNovel> items;
}

class CatalogNovel {
  const CatalogNovel({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.url,
    required this.coverThumbnail,
    required this.coverMedium,
    required this.statusKey,
    required this.statusLabel,
    required this.genres,
    required this.chaptersCount,
    required this.ratingAverage,
    required this.ratingCount,
    required this.views,
    required this.updatedAt,
    required this.manifest,
  });

  factory CatalogNovel.fromJson(Map<String, dynamic> json) {
    final cover = _asMap(json['cover']);
    final status = _asMap(json['status']);
    final rating = _asMap(json['rating']);
    final stats = _asMap(json['stats']);

    return CatalogNovel(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      originalTitle: _asString(json['original_title']),
      url: _asString(json['url']),
      coverThumbnail: _asString(cover['thumbnail']),
      coverMedium: _asString(cover['medium']),
      statusKey: _asString(status['key']),
      statusLabel: _asString(status['label']),
      genres: _asList(json['genres'])
          .map((genre) => CatalogGenre.fromJson(_asMap(genre)))
          .where((genre) => genre.name.isNotEmpty)
          .toList(growable: false),
      chaptersCount: _asInt(json['chapters_count']),
      ratingAverage: _asDouble(rating['average']),
      ratingCount: _asInt(rating['count']),
      views: _asInt(stats['views']),
      updatedAt: _asDateTime(json['updated_at']),
      manifest: _asString(json['manifest']),
    );
  }

  final int id;
  final String title;
  final String originalTitle;
  final String url;
  final String coverThumbnail;
  final String coverMedium;
  final String statusKey;
  final String statusLabel;
  final List<CatalogGenre> genres;
  final int chaptersCount;
  final double ratingAverage;
  final int ratingCount;
  final int views;
  final DateTime? updatedAt;
  final String manifest;
}

class CatalogGenre {
  const CatalogGenre({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory CatalogGenre.fromJson(Map<String, dynamic> json) {
    return CatalogGenre(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
    );
  }

  final int id;
  final String name;
  final String slug;
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

double _asDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

DateTime? _asDateTime(Object? value) {
  final text = _asString(value);
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}
