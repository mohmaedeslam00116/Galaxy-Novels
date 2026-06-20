class ReaderChapterContent {
  const ReaderChapterContent({
    required this.id,
    required this.novelId,
    required this.label,
    required this.title,
    required this.displayTitle,
    required this.position,
    required this.total,
    required this.contentHtml,
    required this.navigation,
  });

  factory ReaderChapterContent.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final source = data.isNotEmpty ? data : json;

    return ReaderChapterContent(
      id: _asInt(source['id']),
      novelId: _asInt(source['novel_id']),
      label: _asString(source['label']),
      title: _asString(source['title']),
      displayTitle: _asString(source['display_title']),
      position: _asInt(source['position']),
      total: _asInt(source['total']),
      contentHtml: _asString(source['content_html']),
      navigation: ReaderChapterNavigation.fromJson(
        _asMap(source['navigation']),
      ),
    );
  }

  final int id;
  final int novelId;
  final String label;
  final String title;
  final String displayTitle;
  final int position;
  final int total;
  final String contentHtml;
  final ReaderChapterNavigation navigation;

  String get effectiveTitle => displayTitle.isNotEmpty
      ? displayTitle
      : title.isNotEmpty
      ? title
      : label;
}

class ReaderChapterNavigation {
  const ReaderChapterNavigation({
    required this.previousApi,
    required this.nextApi,
    required this.previousId,
    required this.nextId,
  });

  factory ReaderChapterNavigation.fromJson(Map<String, dynamic> json) {
    return ReaderChapterNavigation(
      previousApi: _asString(json['previous_api']),
      nextApi: _asString(json['next_api']),
      previousId: _asInt(json['previous_id']),
      nextId: _asInt(json['next_id']),
    );
  }

  final String previousApi;
  final String nextApi;
  final int previousId;
  final int nextId;
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
