import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/downloaded_chapter.dart';
import '../models/reader_content_data.dart';
import 'downloads_repository.dart';
import 'local_download_store.dart';
import 'reader_repository.dart';

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
  Future<void> _mutationQueue = Future.value();
  Future<void>? _loadFuture;
  bool _loaded = false;

  @override
  ValueListenable<DownloadsState> get state => _state;

  @override
  Future<void> load() async {
    if (_loaded) {
      return;
    }
    final pendingLoad = _loadFuture;
    if (pendingLoad != null) {
      return pendingLoad;
    }

    final loadFuture = _loadFromStore();
    _loadFuture = loadFuture;
    try {
      await loadFuture;
    } finally {
      _loadFuture = null;
    }
  }

  Future<void> _loadFromStore() async {
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

    final contentHtml = await _readContent(chapter);
    if (contentHtml == null) {
      return null;
    }
    final navigation = _localNavigationFor(chapter);
    return ReaderChapterContent(
      id: chapter.chapterId,
      novelId: chapter.novelId,
      label: chapter.chapterLabel,
      title: chapter.chapterTitle,
      displayTitle: chapter.chapterTitle,
      position: chapter.chapterPosition,
      total: chapter.chaptersTotal,
      contentHtml: contentHtml,
      navigation: navigation,
    );
  }

  @override
  Future<void> downloadChapter(ChapterDownloadRequest request) async {
    await _ensureLoaded();
    await _serializeMutation(() => _downloadChapter(request));
  }

  @override
  Stream<DownloadBatchProgress> downloadChaptersBatch(
    List<ChapterDownloadRequest> requests,
  ) async* {
    await _ensureLoaded();
    final pending = <ChapterDownloadRequest>[];
    final seenContentApis = <String>{};
    for (final request in requests) {
      final contentApi = request.chapter.effectiveContentApi;
      if (contentApi.isEmpty ||
          _findChapter(contentApi) != null ||
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
    await _serializeMutation(() async {
      final next = _chapters
          .where((chapter) => chapter.contentApi != contentApi)
          .toList(growable: false);
      await _replaceChapters(next);
    });
  }

  @override
  Future<void> deleteNovelDownloads(int novelId) async {
    await _ensureLoaded();
    await _serializeMutation(() async {
      final next = _chapters
          .where((chapter) => chapter.novelId != novelId)
          .toList(growable: false);
      await _replaceChapters(next);
    });
  }

  @override
  Future<void> markOpened(String contentApi) async {
    await _ensureLoaded();
    await _serializeMutation(() async {
      final openedAt = DateTime.now().toUtc();
      final next = _chapters
          .map(
            (chapter) => chapter.contentApi == contentApi
                ? chapter.copyWith(lastOpenedAt: openedAt)
                : chapter,
          )
          .toList(growable: false);
      await _replaceChapters(next);
    });
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

  Future<void> _downloadChapter(ChapterDownloadRequest request) async {
    final contentApi = request.chapter.effectiveContentApi;
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
      contentByteSize: utf8.encode(content.contentHtml).length,
      downloadedAt: DateTime.now().toUtc(),
      lastOpenedAt: null,
    );

    await _replaceChapters([..._chapters, chapter]);
  }

  Future<T> _serializeMutation<T>(Future<T> Function() mutation) {
    final result = _mutationQueue.then((_) => mutation());
    _mutationQueue = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  Future<void> _replaceChapters(List<DownloadedChapter> chapters) async {
    final next = List<DownloadedChapter>.unmodifiable(chapters);
    await _store.writeChapters(next);
    _chapters = _store is DownloadContentStore
        ? List.unmodifiable(
            next.map((chapter) => chapter.copyWith(contentHtml: '')),
          )
        : next;
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

  ReaderChapterNavigation _localNavigationFor(DownloadedChapter chapter) {
    final siblings =
        _chapters
            .where((candidate) => candidate.novelId == chapter.novelId)
            .toList(growable: false)
          ..sort((a, b) => a.chapterPosition.compareTo(b.chapterPosition));
    final index = siblings.indexWhere(
      (candidate) => candidate.contentApi == chapter.contentApi,
    );
    if (index < 0) {
      return const ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      );
    }

    final previous = index > 0 ? siblings[index - 1] : null;
    final next = index + 1 < siblings.length ? siblings[index + 1] : null;
    return ReaderChapterNavigation(
      previousApi: previous?.contentApi ?? '',
      nextApi: next?.contentApi ?? '',
      previousId: previous?.chapterId ?? 0,
      nextId: next?.chapterId ?? 0,
    );
  }

  Future<String?> _readContent(DownloadedChapter chapter) {
    if (_store case final DownloadContentStore contentStore) {
      return contentStore.readChapterContent(chapter);
    }
    return Future.value(chapter.contentHtml);
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
  final plainText = html
      .replaceAll(RegExp('<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  const maxCharacters = 240;
  final characters = plainText.runes;
  if (characters.length <= maxCharacters) {
    return plainText;
  }
  return String.fromCharCodes(characters.take(maxCharacters));
}
