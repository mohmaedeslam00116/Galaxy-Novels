import 'package:flutter/foundation.dart';

import '../models/downloaded_chapter.dart';
import '../models/reader_content_data.dart';
import 'downloads_repository.dart';

class FakeDownloadsRepository implements DownloadsRepository {
  FakeDownloadsRepository({List<DownloadedChapter> chapters = const []})
    : _state = ValueNotifier<DownloadsState>(
        DownloadsState(chapters: chapters),
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
  Future<void> downloadChapter(ChapterDownloadRequest request) async {}

  @override
  Stream<DownloadBatchProgress> downloadChaptersBatch(
    List<ChapterDownloadRequest> requests,
  ) async* {}

  @override
  Future<void> deleteChapter(String contentApi) async {}

  @override
  Future<void> deleteNovelDownloads(int novelId) async {}

  @override
  Future<void> markOpened(String contentApi) async {}
}
