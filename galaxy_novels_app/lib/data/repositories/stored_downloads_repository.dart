import 'package:flutter/foundation.dart';

import '../models/downloaded_chapter.dart';
import '../models/reader_content_data.dart';
import 'downloads_repository.dart';
import 'local_download_store.dart';
import 'reader_repository.dart';

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

class StoredDownloadsRepository implements DownloadsRepository {
  StoredDownloadsRepository({
    required LocalDownloadStore store,
    required ReaderRepository readerRepository,
    DownloadLimitPolicy limitPolicy = const DownloadLimitPolicy(),
  }) : _store = store,
       _readerRepository = readerRepository,
       _limitPolicy = limitPolicy,
       _state = ValueNotifier<DownloadsState>(
         DownloadsState(maxChapters: limitPolicy.maxChapters),
       );

  final LocalDownloadStore _store;
  final ReaderRepository _readerRepository;
  final DownloadLimitPolicy _limitPolicy;
  final ValueNotifier<DownloadsState> _state;

  List<DownloadedChapter> _chapters = const [];
  bool _loaded = false;

  @override
  ValueListenable<DownloadsState> get state => _state;

  @override
  Future<void> load() async {
    _chapters = List.unmodifiable(await _store.readChapters());
    _loaded = true;
    _emit();
  }

  @override
  Future<DownloadedChapter?> findChapter(String contentApi) async {
    await _ensureLoaded();
    return _findChapter(contentApi);
  }

  @override
  Future<ReaderChapterContent?> findReaderContent(String contentApi) async {
    final chapter = await findChapter(contentApi);
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
    await _ensureLoaded();
    final contentApi = request.chapter.contentApi;
    if (contentApi.isEmpty || _findChapter(contentApi) != null) {
      return;
    }

    _ensureWithinLimit(1);

    final content = await _readerRepository.loadChapter(contentApi);
    final chapter = DownloadedChapter(
      novelId: request.novelId,
      novelTitle: request.novelTitle,
      novelCover: request.novelCover,
      chapterId: request.chapter.id,
      chapterTitle: _chapterTitle(request, content),
      chapterLabel: request.chapter.label,
      chapterPosition: request.chapter.position,
      chaptersTotal: content.total,
      contentApi: contentApi,
      contentHtml: content.contentHtml,
      plainTextPreview: _plainTextPreview(content.contentHtml),
      downloadedAt: DateTime.now().toUtc(),
      lastOpenedAt: null,
    );

    await _replaceChapters([..._chapters, chapter]);
  }

  @override
  Stream<DownloadBatchProgress> downloadChaptersBatch(
    List<ChapterDownloadRequest> requests,
  ) async* {
    await _ensureLoaded();
    final pending = requests
        .where((request) {
          final contentApi = request.chapter.contentApi;
          return contentApi.isNotEmpty && _findChapter(contentApi) == null;
        })
        .toList(growable: false);

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
    var failed = 0;
    for (final request in pending) {
      try {
        await downloadChapter(request);
        completed++;
      } catch (_) {
        failed++;
      }

      yield DownloadBatchProgress(
        novelTitle: request.novelTitle,
        novelCover: request.novelCover,
        total: pending.length,
        completed: completed,
        failed: failed,
        isComplete: completed + failed == pending.length,
      );
    }
  }

  @override
  Future<void> deleteChapter(String contentApi) async {
    await _ensureLoaded();
    final next = _chapters
        .where((chapter) => chapter.contentApi != contentApi)
        .toList(growable: false);
    await _replaceChapters(next);
  }

  @override
  Future<void> deleteNovelDownloads(int novelId) async {
    await _ensureLoaded();
    final next = _chapters
        .where((chapter) => chapter.novelId != novelId)
        .toList(growable: false);
    await _replaceChapters(next);
  }

  @override
  Future<void> markOpened(String contentApi) async {
    await _ensureLoaded();
    final openedAt = DateTime.now().toUtc();
    final next = _chapters
        .map(
          (chapter) => chapter.contentApi == contentApi
              ? chapter.copyWith(lastOpenedAt: openedAt)
              : chapter,
        )
        .toList(growable: false);
    await _replaceChapters(next);
  }

  Future<void> _ensureLoaded() async {
    if (!_loaded) {
      await load();
    }
  }

  void _ensureWithinLimit(int requestedCount) {
    if (!_limitPolicy.canDownload(
      currentCount: _chapters.length,
      requestedCount: requestedCount,
    )) {
      throw DownloadLimitExceededException(
        maxChapters: _limitPolicy.maxChapters,
        currentCount: _chapters.length,
        requestedCount: requestedCount,
      );
    }
  }

  Future<void> _replaceChapters(List<DownloadedChapter> chapters) async {
    _chapters = List.unmodifiable(chapters);
    await _store.writeChapters(_chapters);
    _emit();
  }

  void _emit() {
    _state.value = DownloadsState(
      chapters: _chapters,
      maxChapters: _limitPolicy.maxChapters,
    );
  }

  DownloadedChapter? _findChapter(String contentApi) {
    for (final chapter in _chapters) {
      if (chapter.contentApi == contentApi) {
        return chapter;
      }
    }
    return null;
  }
}

String _chapterTitle(
  ChapterDownloadRequest request,
  ReaderChapterContent content,
) {
  final requestTitle = request.chapter.displayTitle;
  if (requestTitle.isNotEmpty) {
    return requestTitle;
  }
  return content.effectiveTitle;
}

String _plainTextPreview(String html) {
  return html
      .replaceAll(RegExp('<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
