import 'chapter_summary.dart';
import 'novel_summary.dart';

class HomeData {
  const HomeData({
    required this.continueReading,
    required this.latestChapters,
    required this.recentNovels,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return HomeData(
      continueReading: data['continue_reading'] is Map<String, dynamic>
          ? ReadingProgress.fromJson(
              data['continue_reading'] as Map<String, dynamic>,
            )
          : null,
      latestChapters: _asList(
        data['latest_chapters'],
      ).map(ChapterSummary.fromJson).toList(growable: false),
      recentNovels: _asList(
        data['recent_novels'],
      ).map(NovelSummary.fromJson).toList(growable: false),
    );
  }

  final ReadingProgress? continueReading;
  final List<ChapterSummary> latestChapters;
  final List<NovelSummary> recentNovels;

  bool get isEmpty =>
      continueReading == null && latestChapters.isEmpty && recentNovels.isEmpty;
}

class ReadingProgress {
  const ReadingProgress({
    required this.novelTitle,
    required this.chapterLabel,
    required this.progress,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      novelTitle: _asString(json['novel_title']),
      chapterLabel: _asString(json['chapter_label']),
      progress: _asInt(json['progress']).clamp(0, 100),
    );
  }

  final String novelTitle;
  final String chapterLabel;
  final int progress;
}

List<Map<String, dynamic>> _asList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.whereType<Map<String, dynamic>>().toList(growable: false);
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
