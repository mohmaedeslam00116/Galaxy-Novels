import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/repositories/downloads_repository.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_manager.dart';

void main() {
  test('owns batch progress until the repository stream completes', () async {
    final repository = _ControlledDownloadsRepository();
    final manager = DownloadManager(repository: repository);
    addTearDown(manager.dispose);

    final completion = manager.startBatch([_request(1)]);
    expect(manager.state.value.status, DownloadJobStatus.running);
    expect(manager.state.value.isOverlayVisible, isTrue);

    repository.emit(_progress(completed: 1, isComplete: true));
    await repository.closeProgress();
    await completion;

    expect(manager.state.value.status, DownloadJobStatus.completed);
    expect(manager.state.value.progress?.completed, 1);
  });

  test('pauses and resumes the active repository subscription', () async {
    final repository = _ControlledDownloadsRepository();
    final manager = DownloadManager(repository: repository);
    addTearDown(manager.dispose);
    unawaited(manager.startBatch([_request(1)]));

    manager.pause();
    expect(manager.state.value.status, DownloadJobStatus.paused);

    manager.resume();
    expect(manager.state.value.status, DownloadJobStatus.running);

    repository.emit(_progress(completed: 1, isComplete: true));
    await repository.closeProgress();
  });

  test('rejects a second job while a download is active', () async {
    final repository = _ControlledDownloadsRepository();
    final manager = DownloadManager(repository: repository);
    addTearDown(manager.dispose);
    unawaited(manager.startBatch([_request(1)]));

    expect(
      () => manager.startBatch([_request(2)]),
      throwsA(isA<DownloadJobInProgressException>()),
    );

    await manager.cancel();
    expect(manager.state.value.status, DownloadJobStatus.cancelled);
  });

  test('can hide progress without cancelling the active job', () async {
    final repository = _ControlledDownloadsRepository();
    final manager = DownloadManager(repository: repository);
    addTearDown(manager.dispose);
    unawaited(manager.startBatch([_request(1)]));

    manager.dismissOverlay();

    expect(manager.state.value.isOverlayVisible, isFalse);
    expect(manager.state.value.isActive, isTrue);
    await manager.cancel();
  });
}

ChapterDownloadRequest _request(int id) {
  return ChapterDownloadRequest(
    novelId: 10,
    novelTitle: 'رواية الاختبار',
    novelCover: '/cover.jpg',
    chapter: NovelChapter(
      id: id,
      position: id,
      number: '$id',
      label: 'الفصل $id',
      title: 'الفصل $id',
      url: '/chapter-$id',
      contentApi: '/chapters/$id',
      dateLabel: '',
      dateIso: null,
      views: 0,
      comments: 0,
      search: '',
    ),
  );
}

DownloadBatchProgress _progress({
  required int completed,
  required bool isComplete,
}) {
  return DownloadBatchProgress(
    novelTitle: 'رواية الاختبار',
    novelCover: '/cover.jpg',
    total: 1,
    completed: completed,
    failed: 0,
    isComplete: isComplete,
  );
}

class _ControlledDownloadsRepository implements DownloadsRepository {
  final ValueNotifier<DownloadsState> _state = ValueNotifier(DownloadsState());
  final StreamController<DownloadBatchProgress> _progressController =
      StreamController();

  @override
  ValueListenable<DownloadsState> get state => _state;

  void emit(DownloadBatchProgress progress) {
    _progressController.add(progress);
  }

  Future<void> closeProgress() => _progressController.close();

  @override
  Stream<DownloadBatchProgress> downloadChaptersBatch(
    List<ChapterDownloadRequest> requests,
  ) {
    return _progressController.stream;
  }

  @override
  Future<void> deleteChapter(String contentApi) async {}

  @override
  Future<void> deleteNovelDownloads(int novelId) async {}

  @override
  Future<void> downloadChapter(ChapterDownloadRequest request) async {}

  @override
  Future<DownloadedChapter?> findChapter(String contentApi) async => null;

  @override
  Future<ReaderChapterContent?> findReaderContent(String contentApi) async {
    return null;
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> markOpened(String contentApi) async {}
}
