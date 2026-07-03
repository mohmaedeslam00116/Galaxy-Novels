class ReadingProgress {
  const ReadingProgress({
    required this.novelId,
    required this.novelTitle,
    required this.chapterId,
    required this.chapterTitle,
    required this.contentApi,
    required this.updatedAt,
    this.coverUrl = '',
    this.chapterPosition = 0,
    this.chaptersTotal = 0,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      novelId: _asInt(json['novelId']),
      novelTitle: _asString(json['novelTitle']),
      chapterId: _asInt(json['chapterId']),
      chapterTitle: _asString(json['chapterTitle']),
      contentApi: _asString(json['contentApi']),
      coverUrl: _bestCoverFromJson(json),
      chapterPosition: _asInt(json['chapterPosition']),
      chaptersTotal: _asInt(json['chaptersTotal']),
      updatedAt:
          DateTime.tryParse(_asString(json['updatedAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final int novelId;
  final String novelTitle;
  final int chapterId;
  final String chapterTitle;
  final String contentApi;
  final String coverUrl;
  final DateTime updatedAt;
  final int chapterPosition;
  final int chaptersTotal;

  ReadingProgress copyWith({
    String? novelTitle,
    String? chapterTitle,
    String? contentApi,
    String? coverUrl,
    DateTime? updatedAt,
    int? chapterPosition,
    int? chaptersTotal,
  }) {
    return ReadingProgress(
      novelId: novelId,
      novelTitle: novelTitle ?? this.novelTitle,
      chapterId: chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      contentApi: contentApi ?? this.contentApi,
      coverUrl: coverUrl ?? this.coverUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      chapterPosition: chapterPosition ?? this.chapterPosition,
      chaptersTotal: chaptersTotal ?? this.chaptersTotal,
    );
  }

  double? get completionFraction {
    if (chapterPosition <= 0 || chaptersTotal <= 0) {
      return null;
    }
    final bounded = (chapterPosition / chaptersTotal).clamp(0.0, 1.0);
    return bounded.toDouble();
  }

  int? get completionPercent {
    final fraction = completionFraction;
    if (fraction == null) {
      return null;
    }
    final percent = (fraction * 100).round().clamp(1, 100);
    return percent.toInt();
  }

  Map<String, dynamic> toJson() {
    return {
      'novelId': novelId,
      'novelTitle': novelTitle,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'contentApi': contentApi,
      'coverUrl': coverUrl,
      'chapterPosition': chapterPosition,
      'chaptersTotal': chaptersTotal,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  String get displayNovelTitle =>
      novelTitle.isNotEmpty ? novelTitle : 'رواية #$novelId';

  String get displayChapterTitle =>
      chapterTitle.isNotEmpty ? chapterTitle : 'الفصل $chapterId';
}

String _asString(Object? value) => value?.toString() ?? '';

String _bestCoverFromJson(Map<String, dynamic> json) {
  final cover = json['cover'];
  if (cover is Map) {
    final map = cover.map((key, value) => MapEntry(key.toString(), value));
    return _firstNonEmptyString([
      map['medium'],
      map['large'],
      map['thumbnail'],
      map['url'],
    ]);
  }

  return _firstNonEmptyString([
    json['coverUrl'],
    json['cover_url'],
    json['coverMedium'],
    json['cover_medium'],
    json['coverThumbnail'],
    json['cover_thumbnail'],
  ]);
}

String _firstNonEmptyString(List<Object?> values) {
  for (final value in values) {
    final text = _asString(value);
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
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
