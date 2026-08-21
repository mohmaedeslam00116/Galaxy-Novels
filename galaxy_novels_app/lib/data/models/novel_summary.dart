class NovelSummary {
  const NovelSummary({
    required this.id,
    required this.title,
    required this.url,
    required this.coverThumbnail,
    this.coverMedium = '',
    this.coverLarge = '',
    required this.statusLabel,
    required this.genres,
    required this.chaptersCount,
    required this.manifest,
  });

  factory NovelSummary.fromJson(Map<String, dynamic> json) {
    final cover = json['cover'];
    final status = json['status'];
    final genres = json['genres'];

    return NovelSummary(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      url: _asString(json['url']),
      coverThumbnail: cover is Map<String, dynamic>
          ? _asString(cover['thumbnail'])
          : _asString(json['cover_thumbnail'] ?? json['c']),
      coverMedium: cover is Map<String, dynamic>
          ? _asString(cover['medium'])
          : _asString(json['cover_medium'] ?? json['coverMedium']),
      coverLarge: cover is Map<String, dynamic>
          ? _asString(cover['large'])
          : _asString(json['cover_large'] ?? json['coverLarge']),
      statusLabel: status is Map<String, dynamic>
          ? _asString(status['label'])
          : _asString(json['status_label'] ?? json['st']),
      genres: genres is List
          ? genres
                .map((genre) {
                  if (genre is Map<String, dynamic>) {
                    return _asString(genre['name']);
                  }
                  return _asString(genre);
                })
                .where((genre) => genre.isNotEmpty)
                .toList(growable: false)
          : const [],
      chaptersCount: _asInt(json['chapters_count'] ?? json['n']),
      manifest: _asString(json['manifest']),
    );
  }

  final int id;
  final String title;
  final String url;
  final String coverThumbnail;
  final String coverMedium;
  final String coverLarge;
  final String statusLabel;
  final List<String> genres;
  final int chaptersCount;
  final String manifest;

  String get bestCover => coverLarge.isNotEmpty
      ? coverLarge
      : coverMedium.isNotEmpty
      ? coverMedium
      : coverThumbnail;
}

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

String _asString(Object? value) => value?.toString() ?? '';
