import 'package:flutter/foundation.dart';

import '../models/downloaded_chapter.dart';
import '../models/reader_content_data.dart';
import 'downloads_repository.dart';
import 'stored_downloads_repository.dart';

class FakeDownloadsRepository implements DownloadsRepository {
  FakeDownloadsRepository({
    List<DownloadedChapter> chapters = const [],
    int maxChapters = DownloadLimitPolicy.defaultMaxChapters,
  }) : _state = ValueNotifier<DownloadsState>(
         DownloadsState(chapters: chapters, maxChapters: maxChapters),
       );

  final ValueNotifier<DownloadsState> _state;

  @override
  ValueListenable<DownloadsState> get state => _state;

  @override
  Future<void> load() async {}

  @override
  Future<DownloadedChapter?> findChapter(String contentApi) async {
    return _state.value.findByContentApi(contentApi);
  }

  @override
  Future<ReaderChapterContent?> findReaderContent(String contentApi) async {
    final chapter = _state.value.findByContentApi(contentApi);
    if (chapter == null) {
      return null;
    }
    return ReaderChapterContent(
      id: chapter.chapterId,
      novelId: chapter.novelId,
      label: chapter.chapterLabel,
      title: chapter.chapterTitle,
      displayTitle: chapter.chapterTitle,
      position: chapter.chapterPosition,
      total: chapter.chaptersTotal,
      contentHtml: chapter.contentHtml,
      navigation: const ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }

  @override
  Future<void> downloadChapter(ChapterDownloadRequest request) async {
    final contentApi = request.chapter.effectiveContentApi;
    if (contentApi.isEmpty || _state.value.contains(contentApi)) {
      return;
    }

    _ensureWithinLimit(1);

    final title = _chapterTitle(request);
    final contentHtml = '<p>$title</p>';
    final chapter = DownloadedChapter(
      novelId: request.novelId,
      novelTitle: request.novelTitle,
      novelCover: request.novelCover,
      chapterId: request.chapter.id,
      chapterTitle: title,
      chapterLabel: request.chapter.label,
      chapterPosition: request.chapter.position,
      chaptersTotal: request.chapter.position,
      contentApi: contentApi,
      contentHtml: contentHtml,
      plainTextPreview: title,
      downloadedAt: DateTime.now().toUtc(),
      lastOpenedAt: null,
    );

    _replaceChapters([..._state.value.chapters, chapter]);
  }

  @override
  Stream<DownloadBatchProgress> downloadChaptersBatch(
    List<ChapterDownloadRequest> requests,
  ) async* {
    final pending = <ChapterDownloadRequest>[];
    final seenContentApis = <String>{};
    for (final request in requests) {
      final contentApi = request.chapter.effectiveContentApi;
      if (contentApi.isEmpty ||
          _state.value.contains(contentApi) ||
          !seenContentApis.add(contentApi)) {
        continue;
      }
      pending.add(request);
    }

    if (pending.isEmpty) {
      yield const DownloadBatchProgress(
        novelTitle: '',
        novelCover: '',
        total: 0,
        completed: 0,
        failed: 0,
        isComplete: true,
      );
      return;
    }

    _ensureWithinLimit(pending.length);

    var completed = 0;
    for (final request in pending) {
      await downloadChapter(request);
      completed++;

      yield DownloadBatchProgress(
        novelTitle: request.novelTitle,
        novelCover: request.novelCover,
        total: pending.length,
        completed: completed,
        failed: 0,
        isComplete: completed == pending.length,
      );
    }
  }

  @override
  Future<void> deleteChapter(String contentApi) async {
    _replaceChapters(
      _state.value.chapters
          .where((chapter) => chapter.contentApi != contentApi)
          .toList(growable: false),
    );
  }

  @override
  Future<void> deleteNovelDownloads(int novelId) async {
    _replaceChapters(
      _state.value.chapters
          .where((chapter) => chapter.novelId != novelId)
          .toList(growable: false),
    );
  }

  @override
  Future<void> markOpened(String contentApi) async {
    final openedAt = DateTime.now().toUtc();
    _replaceChapters(
      _state.value.chapters
          .map(
            (chapter) => chapter.contentApi == contentApi
                ? chapter.copyWith(lastOpenedAt: openedAt)
                : chapter,
          )
          .toList(growable: false),
    );
  }

  void _replaceChapters(List<DownloadedChapter> chapters) {
    _state.value = DownloadsState(
      chapters: chapters,
      maxChapters: _state.value.maxChapters,
    );
  }

  void _ensureWithinLimit(int requestedCount) {
    final state = _state.value;
    final limitPolicy = DownloadLimitPolicy(maxChapters: state.maxChapters);
    if (!limitPolicy.canDownload(
      currentCount: state.chapters.length,
      requestedCount: requestedCount,
    )) {
      throw DownloadLimitExceededException(
        maxChapters: state.maxChapters,
        currentCount: state.chapters.length,
        requestedCount: requestedCount,
      );
    }
  }
}

String _chapterTitle(ChapterDownloadRequest request) {
  final displayTitle = request.chapter.displayTitle;
  if (displayTitle.isNotEmpty) {
    return displayTitle;
  }
  if (request.chapter.label.isNotEmpty) {
    return request.chapter.label;
  }
  return 'Chapter ${request.chapter.id}';
}
