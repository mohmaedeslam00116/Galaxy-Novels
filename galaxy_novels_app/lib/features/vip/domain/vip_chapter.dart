class VipChapter {
  const VipChapter({
    required this.id,
    required this.number,
    required this.position,
    required this.order,
    required this.title,
    required this.url,
    required this.publicAt,
    required this.views,
    required this.comments,
    this.contentApi = '',
  });

  factory VipChapter.fromJson(Map<String, dynamic> json) {
    final contentApi = _asString(json['content_api']);
    return VipChapter(
      id: _asInt(json['id']),
      number: _asString(json['number']),
      position: _asInt(json['position']),
      order: _asString(json['order']),
      title: _asString(json['title']),
      url: _asString(json['url']),
      publicAt: _asString(json['public_at']),
      views: _asInt(json['views']),
      comments: _asInt(json['comments']),
      contentApi: contentApi.isNotEmpty ? contentApi : _asString(json['api']),
    );
  }

  final int id;
  final String number;
  final int position;
  final String order;
  final String title;
  final String url;
  final String publicAt;
  final int views;
  final int comments;
  final String contentApi;

  String get displayLabel {
    if (number.isNotEmpty) {
      return 'الفصل $number';
    }
    if (position > 0) {
      return 'الفصل $position';
    }
    return 'فصل VIP';
  }
}

class VipChapterPage {
  const VipChapterPage({
    required this.items,
    required this.hasMore,
    required this.nextCursorOrder,
    required this.nextCursorId,
    required this.totalAvailable,
  });

  factory VipChapterPage.fromJson(Map<String, dynamic> json) {
    final cursor = _asMap(json['next_cursor']);
    return VipChapterPage(
      items: _asList(json['items'])
          .map((item) => VipChapter.fromJson(_asMap(item)))
          .where((chapter) => chapter.id > 0)
          .toList(growable: false),
      hasMore: json['has_more'] == true,
      nextCursorOrder: _asString(cursor['order']),
      nextCursorId: _asInt(cursor['id']),
      totalAvailable: _asInt(json['total_available']),
    );
  }

  final List<VipChapter> items;
  final bool hasMore;
  final String nextCursorOrder;
  final int nextCursorId;
  final int totalAvailable;
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

String _asString(Object? value) => value?.toString().trim() ?? '';

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
