class DownloadedChapter {
  const DownloadedChapter({
    required this.novelId,
    required this.novelTitle,
    required this.novelCover,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterLabel,
    required this.chapterPosition,
    required this.chaptersTotal,
    required this.contentApi,
    required this.contentHtml,
    required this.plainTextPreview,
    required this.downloadedAt,
    required this.lastOpenedAt,
    this.contentByteSize = 0,
  });

  factory DownloadedChapter.fromJson(Map<String, dynamic> json) {
    return DownloadedChapter(
      novelId: _asInt(json['novelId']),
      novelTitle: _asString(json['novelTitle']),
      novelCover: _asString(json['novelCover']),
      chapterId: _asInt(json['chapterId']),
      chapterTitle: _asString(json['chapterTitle']),
      chapterLabel: _asString(json['chapterLabel']),
      chapterPosition: _asInt(json['chapterPosition']),
      chaptersTotal: _asInt(json['chaptersTotal']),
      contentApi: _asString(json['contentApi']),
      contentHtml: _asString(json['contentHtml']),
      plainTextPreview: _asString(json['plainTextPreview']),
      contentByteSize: _asInt(json['contentByteSize']),
      downloadedAt:
          DateTime.tryParse(_asString(json['downloadedAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastOpenedAt: _asDateTime(json['lastOpenedAt']),
    );
  }

  final int novelId;
  final String novelTitle;
  final String novelCover;
  final int chapterId;
  final String chapterTitle;
  final String chapterLabel;
  final int chapterPosition;
  final int chaptersTotal;
  final String contentApi;
  final String contentHtml;
  final String plainTextPreview;
  final int contentByteSize;
  final DateTime downloadedAt;
  final DateTime? lastOpenedAt;

  Map<String, dynamic> toJson() {
    return {
      'novelId': novelId,
      'novelTitle': novelTitle,
      'novelCover': novelCover,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'chapterLabel': chapterLabel,
      'chapterPosition': chapterPosition,
      'chaptersTotal': chaptersTotal,
      'contentApi': contentApi,
      'contentHtml': contentHtml,
      'plainTextPreview': plainTextPreview,
      'contentByteSize': contentByteSize,
      'downloadedAt': downloadedAt.toIso8601String(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
    };
  }

  DownloadedChapter copyWith({DateTime? lastOpenedAt, String? contentHtml}) {
    return DownloadedChapter(
      novelId: novelId,
      novelTitle: novelTitle,
      novelCover: novelCover,
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      chapterLabel: chapterLabel,
      chapterPosition: chapterPosition,
      chaptersTotal: chaptersTotal,
      contentApi: contentApi,
      contentHtml: contentHtml ?? this.contentHtml,
      plainTextPreview: plainTextPreview,
      contentByteSize: contentByteSize,
      downloadedAt: downloadedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }
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

DateTime? _asDateTime(Object? value) {
  final text = _asString(value);
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}
