import '../../../data/models/reading_progress.dart';

List<ReadingProgress> mergeReadingHistory(
  List<ReadingProgress> localHistory,
  List<ReadingProgress> remoteHistory,
) {
  final mergedByNovel = {
    for (final localProgress in localHistory)
      localProgress.novelId: localProgress,
  };
  for (final remoteProgress in remoteHistory) {
    final localProgress = mergedByNovel[remoteProgress.novelId];
    mergedByNovel[remoteProgress.novelId] = localProgress == null
        ? remoteProgress
        : _newestProgress(localProgress, remoteProgress);
  }
  final merged = mergedByNovel.values.toList(growable: false)
    ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
  return List.unmodifiable(merged);
}

ReadingProgress _newestProgress(
  ReadingProgress localProgress,
  ReadingProgress remoteProgress,
) {
  final remoteIsNewer = remoteProgress.updatedAt.isAfter(
    localProgress.updatedAt,
  );
  final newest = remoteIsNewer ? remoteProgress : localProgress;
  final other = remoteIsNewer ? localProgress : remoteProgress;
  if (newest.chapterId != other.chapterId) {
    return newest.copyWith(
      novelTitle: newest.novelTitle.isEmpty
          ? other.novelTitle
          : newest.novelTitle,
    );
  }
  return newest.copyWith(
    novelTitle: newest.novelTitle.isEmpty
        ? other.novelTitle
        : newest.novelTitle,
    chapterTitle: newest.chapterTitle.isEmpty
        ? other.chapterTitle
        : newest.chapterTitle,
    contentApi: newest.contentApi.isEmpty
        ? other.contentApi
        : newest.contentApi,
    chapterPosition: newest.chapterPosition > 0
        ? newest.chapterPosition
        : other.chapterPosition,
    chaptersTotal: newest.chaptersTotal > 0
        ? newest.chaptersTotal
        : other.chaptersTotal,
  );
}
