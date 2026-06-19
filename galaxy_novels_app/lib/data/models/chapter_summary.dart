class ChapterSummary {
  const ChapterSummary({
    required this.id,
    required this.novelId,
    required this.novelTitle,
    required this.label,
    required this.title,
    required this.dateLabel,
    required this.url,
    this.chapters = const [],
  });

  factory ChapterSummary.fromJson(Map<String, dynamic> json) {
    final chapters = json['chapters'];
    final chapterItems = chapters is List
        ? chapters
              .whereType<Map<String, dynamic>>()
              .map(ChapterSummaryItem.fromJson)
              .toList(growable: false)
        : const <ChapterSummaryItem>[];
    final firstChapter = chapterItems.isNotEmpty ? chapterItems.first : null;

    return ChapterSummary(
      id: firstChapter?.id ?? _asInt(json['id']),
      novelId: _asInt(json['novel_id']),
      novelTitle: _asString(json['novel_title']),
      label: firstChapter?.label ?? _asString(json['label']),
      title: firstChapter?.title ?? _asString(json['title']),
      dateLabel:
          firstChapter?.dateLabel ??
          _asString(json['date'] ?? json['latest_date']),
      url: firstChapter?.url ?? _asString(json['url']),
      chapters: chapterItems,
    );
  }

  final int id;
  final int novelId;
  final String novelTitle;
  final String label;
  final String title;
  final String dateLabel;
  final String url;
  final List<ChapterSummaryItem> chapters;

  List<ChapterSummaryItem> get visibleChapters {
    if (chapters.isNotEmpty) {
      return chapters;
    }

    return [
      ChapterSummaryItem(
        id: id,
        label: label,
        title: title,
        dateLabel: dateLabel,
        url: url,
      ),
    ];
  }
}

class ChapterSummaryItem {
  const ChapterSummaryItem({
    required this.id,
    required this.label,
    required this.title,
    required this.dateLabel,
    required this.url,
  });

  factory ChapterSummaryItem.fromJson(Map<String, dynamic> json) {
    return ChapterSummaryItem(
      id: _asInt(json['id']),
      label: _asString(json['label']),
      title: _asString(json['title']),
      dateLabel: _asString(json['date']),
      url: _asString(json['url']),
    );
  }

  final int id;
  final String label;
  final String title;
  final String dateLabel;
  final String url;
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
