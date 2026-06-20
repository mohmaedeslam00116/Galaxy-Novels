class NovelDetails {
  const NovelDetails({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.url,
    required this.coverThumbnail,
    required this.coverMedium,
    required this.coverLarge,
    required this.statusKey,
    required this.statusLabel,
    required this.country,
    required this.author,
    required this.translator,
    required this.genres,
    required this.chaptersCount,
    required this.firstChapterId,
    required this.firstChapterUrl,
    required this.ratingAverage,
    required this.ratingCount,
    required this.views,
    required this.updatedAt,
    required this.summary,
    required this.chaptersManifest,
    required this.vipScheduleManifest,
    required this.manifest,
  });

  factory NovelDetails.fromJson(Map<String, dynamic> json) {
    final cover = _asMap(json['cover']);
    final status = _asMap(json['status']);
    final rating = _asMap(json['rating']);
    final stats = _asMap(json['stats']);
    final links = _asMap(json['links']);

    return NovelDetails(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      originalTitle: _asString(json['original_title']),
      url: _asString(json['url']),
      coverThumbnail: _asString(cover['thumbnail']),
      coverMedium: _asString(cover['medium']),
      coverLarge: _asString(cover['large']),
      statusKey: _asString(status['key']),
      statusLabel: _asString(status['label']),
      country: _asString(json['country']),
      author: _asString(json['author']),
      translator: _asString(json['translator']),
      genres: _asList(json['genres'])
          .map((genre) => NovelGenre.fromJson(_asMap(genre)))
          .where((genre) => genre.name.isNotEmpty)
          .toList(growable: false),
      chaptersCount: _asInt(json['chapters_count']),
      firstChapterId: _asInt(json['first_chapter_id']),
      firstChapterUrl: _asString(json['first_chapter_url']),
      ratingAverage: _asDouble(rating['average']),
      ratingCount: _asInt(rating['count']),
      views: _asInt(stats['views']),
      updatedAt: _asDateTime(json['updated_at']),
      summary: _asString(json['summary']),
      chaptersManifest: _asString(links['chapters_manifest']),
      vipScheduleManifest: _asString(links['vip_schedule_manifest']),
      manifest: _asString(json['manifest']),
    );
  }

  final int id;
  final String title;
  final String originalTitle;
  final String url;
  final String coverThumbnail;
  final String coverMedium;
  final String coverLarge;
  final String statusKey;
  final String statusLabel;
  final String country;
  final String author;
  final String translator;
  final List<NovelGenre> genres;
  final int chaptersCount;
  final int firstChapterId;
  final String firstChapterUrl;
  final double ratingAverage;
  final int ratingCount;
  final int views;
  final DateTime? updatedAt;
  final String summary;
  final String chaptersManifest;
  final String vipScheduleManifest;
  final String manifest;

  String get bestCover => coverLarge.isNotEmpty
      ? coverLarge
      : coverMedium.isNotEmpty
      ? coverMedium
      : coverThumbnail;
}

class NovelGenre {
  const NovelGenre({required this.id, required this.name, required this.slug});

  factory NovelGenre.fromJson(Map<String, dynamic> json) {
    return NovelGenre(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
    );
  }

  final int id;
  final String name;
  final String slug;
}

class ChapterManifest {
  const ChapterManifest({
    required this.novelId,
    required this.total,
    required this.latestId,
    required this.latestNumber,
    required this.packUrl,
  });

  factory ChapterManifest.fromJson(Map<String, dynamic> json) {
    final packUrl = _asString(json['pack_url']);
    final pack = _asString(json['pack']);

    return ChapterManifest(
      novelId: _asInt(json['novel_id']),
      total: _asInt(json['total']),
      latestId: _asInt(json['latest_id']),
      latestNumber: _asString(json['latest_number']),
      packUrl: packUrl.isNotEmpty ? packUrl : pack,
    );
  }

  final int novelId;
  final int total;
  final int latestId;
  final String latestNumber;
  final String packUrl;
}

class ChapterPack {
  const ChapterPack({required this.total, required this.chapters});

  factory ChapterPack.fromJsonValue(Object? value) {
    if (value is List) {
      final chapters = value
          .map((item) => NovelChapter.fromJson(_asMap(item)))
          .where((chapter) => chapter.id != 0 || chapter.url.isNotEmpty)
          .toList(growable: false);
      return ChapterPack(total: chapters.length, chapters: chapters);
    }

    final json = _asMap(value);
    final chapters = _asList(json['chapters'])
        .map((item) => NovelChapter.fromJson(_asMap(item)))
        .where((chapter) => chapter.id != 0 || chapter.url.isNotEmpty)
        .toList(growable: false);

    return ChapterPack(total: _asInt(json['total']), chapters: chapters);
  }

  final int total;
  final List<NovelChapter> chapters;
}

class NovelChapter {
  const NovelChapter({
    required this.id,
    required this.position,
    required this.number,
    required this.label,
    required this.title,
    required this.url,
    required this.contentApi,
    required this.dateLabel,
    required this.dateIso,
    required this.views,
    required this.comments,
    required this.search,
  });

  factory NovelChapter.fromJson(Map<String, dynamic> json) {
    return NovelChapter(
      id: _asInt(json['id']),
      position: _asInt(json['position']),
      number: _asString(json['number']),
      label: _asString(json['label']),
      title: _asString(json['title']),
      url: _asString(json['url']),
      contentApi: _asString(json['content_api']),
      dateLabel: _asString(json['date']),
      dateIso: _asDateTime(json['date_iso']),
      views: _asInt(json['views']),
      comments: _asInt(json['comments']),
      search: _asString(json['search']),
    );
  }

  final int id;
  final int position;
  final String number;
  final String label;
  final String title;
  final String url;
  final String contentApi;
  final String dateLabel;
  final DateTime? dateIso;
  final int views;
  final int comments;
  final String search;

  String get displayTitle => title.isNotEmpty
      ? title
      : _titleFromSearch(search: search, label: label, number: number);

  String get effectiveContentApi {
    if (contentApi.isNotEmpty) {
      return contentApi;
    }
    if (id == 0) {
      return '';
    }
    return '/wp-json/wor-reader-app/v1/chapters/$id';
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

String _titleFromSearch({
  required String search,
  required String label,
  required String number,
}) {
  var text = search.trim();
  if (text.isEmpty) {
    return '';
  }

  if (number.isNotEmpty && text.startsWith(number)) {
    text = text.substring(number.length).trim();
  }
  if (label.isNotEmpty && text.startsWith(label)) {
    text = text.substring(label.length).trim();
  }

  return text;
}
