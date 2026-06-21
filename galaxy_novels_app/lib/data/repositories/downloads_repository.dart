import 'package:flutter/foundation.dart';

import '../models/downloaded_chapter.dart';
import '../models/novel_details_data.dart';
import '../models/reader_content_data.dart';

class DownloadLimitExceededException implements Exception {
  const DownloadLimitExceededException({
    required this.maxChapters,
    required this.currentCount,
    required this.requestedCount,
  });

  final int maxChapters;
  final int currentCount;
  final int requestedCount;

  @override
  String toString() {
    return 'DownloadLimitExceededException: requested $requestedCount with '
        '$currentCount of $maxChapters chapters already downloaded';
  }
}

class DownloadLimitPolicy {
  const DownloadLimitPolicy({this.maxChapters = defaultMaxChapters});

  static const defaultMaxChapters = 100;

  final int maxChapters;

  int remainingSlots({required int currentCount}) {
    final remaining = maxChapters - currentCount;
    return remaining < 0 ? 0 : remaining;
  }

  bool canDownload({required int currentCount, required int requestedCount}) {
    return requestedCount <= remainingSlots(currentCount: currentCount);
  }
}

class DownloadsState {
  DownloadsState({
    List<DownloadedChapter> chapters = const [],
    this.maxChapters = DownloadLimitPolicy.defaultMaxChapters,
  }) : chapters = List.unmodifiable(chapters);

  final List<DownloadedChapter> chapters;
  final int maxChapters;

  int get downloadedCount => chapters.length;

  int get remainingSlots => DownloadLimitPolicy(
    maxChapters: maxChapters,
  ).remainingSlots(currentCount: downloadedCount);

  bool get isFull => remainingSlots == 0;

  bool contains(String contentApi) {
    return chapters.any((chapter) => chapter.contentApi == contentApi);
  }

  DownloadedChapter? findByContentApi(String contentApi) {
    for (final chapter in chapters) {
      if (chapter.contentApi == contentApi) {
        return chapter;
      }
    }
    return null;
  }
}

class ChapterDownloadRequest {
  const ChapterDownloadRequest({
    required this.novelId,
    required this.novelTitle,
    required this.novelCover,
    required this.chapter,
  });

  final int novelId;
  final String novelTitle;
  final String novelCover;
  final NovelChapter chapter;
}

class DownloadBatchProgress {
  const DownloadBatchProgress({
    required this.novelTitle,
    required this.novelCover,
    required this.total,
    required this.completed,
    required this.failed,
    required this.isComplete,
  });

  final String novelTitle;
  final String novelCover;
  final int total;
  final int completed;
  final int failed;
  final bool isComplete;

  double get fraction => total <= 0 ? 0 : (completed + failed) / total;
}

abstract class DownloadsRepository {
  const DownloadsRepository();

  ValueListenable<DownloadsState> get state;

  Future<void> load();

  Future<DownloadedChapter?> findChapter(String contentApi);

  Future<ReaderChapterContent?> findReaderContent(String contentApi);

  Future<void> downloadChapter(ChapterDownloadRequest request);

  Stream<DownloadBatchProgress> downloadChaptersBatch(
    List<ChapterDownloadRequest> requests,
  );

  Future<void> deleteChapter(String contentApi);

  Future<void> deleteNovelDownloads(int novelId);

  Future<void> markOpened(String contentApi);
}
