class ReadingProgress {
  const ReadingProgress({
    required this.novelId,
    required this.novelTitle,
    required this.chapterId,
    required this.chapterTitle,
    required this.contentApi,
    required this.updatedAt,
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
  final DateTime updatedAt;
  final int chapterPosition;
  final int chaptersTotal;

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
