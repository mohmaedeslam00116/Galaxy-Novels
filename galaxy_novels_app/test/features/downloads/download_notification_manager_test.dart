import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/repositories/downloads_repository.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_manager.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_progress_notifier.dart';

void main() {
  test('publishes foreground notification progress during a batch', () async {
    final repository = _ControlledDownloadsRepository();
    final notifier = _FakeDownloadProgressNotifier();
    final manager = DownloadManager(
      repository: repository,
      progressNotifier: notifier,
    );
    addTearDown(manager.dispose);

    final completion = manager.startBatch([_request(1), _request(2)]);
    await _flushAsync();

    expect(notifier.events, ['running:0/2:false']);

    repository.emit(_progress(total: 2, completed: 1, failed: 0));
    await _flushAsync();
    expect(notifier.events.last, 'running:1/2:false');

    repository.emit(_progress(total: 2, completed: 2, failed: 0));
    await repository.closeProgress();
    await completion;
    await _flushAsync();

    expect(notifier.events.last, 'completed:2/2');
  });

  test('updates the notification when a batch is paused and resumed', () async {
    final repository = _ControlledDownloadsRepository();
    final notifier = _FakeDownloadProgressNotifier();
    final manager = DownloadManager(
      repository: repository,
      progressNotifier: notifier,
    );
    addTearDown(manager.dispose);

    unawaited(manager.startBatch([_request(1)]));
    await _flushAsync();

    manager.pause();
    await _flushAsync();
    expect(notifier.events.last, 'running:0/1:true');

    manager.resume();
    await _flushAsync();
    expect(notifier.events.last, 'running:0/1:false');

    await manager.cancel();
  });
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
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
  required int total,
  required int completed,
  required int failed,
}) {
  return DownloadBatchProgress(
    novelTitle: 'رواية الاختبار',
    novelCover: '/cover.jpg',
    total: total,
    completed: completed,
    failed: failed,
    isComplete: completed + failed >= total,
  );
}

class _FakeDownloadProgressNotifier implements DownloadProgressNotifier {
  final List<String> events = [];

  @override
  Future<void> clear() async {
    events.add('clear');
  }

  @override
  Future<void> showCompleted(DownloadBatchProgress progress) async {
    events.add('completed:${progress.completed}/${progress.total}');
  }

  @override
  Future<void> showFailed({
    required DownloadBatchProgress? progress,
    required String message,
  }) async {
    events.add('failed:${progress?.completed ?? 0}:${progress?.failed ?? 0}');
  }

  @override
  Future<void> showRunning(
    DownloadBatchProgress progress, {
    required bool isPaused,
  }) async {
    events.add(
      'running:${progress.completed + progress.failed}/${progress.total}:$isPaused',
    );
  }
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
