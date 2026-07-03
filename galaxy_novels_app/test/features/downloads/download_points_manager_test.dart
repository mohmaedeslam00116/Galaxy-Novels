import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/repositories/downloads_repository.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_manager.dart';
import 'package:galaxy_novels_app/features/rewards/data/stored_reader_rewards_repository.dart';

void main() {
  test('spends one local point for each new requested chapter', () async {
    final repository = _ControlledDownloadsRepository();
    final rewards = StoredReaderRewardsRepository.memory(initialPoints: 5);
    final manager = DownloadManager(
      repository: repository,
      rewardsRepository: rewards,
    );
    addTearDown(manager.dispose);

    final completion = manager.startBatch([_request(1), _request(2)]);

    expect(rewards.state.value.points, 3);

    repository.emit(_progress(total: 2, completed: 2, failed: 0));
    await repository.closeProgress();
    await completion;
  });

  test('does not start a download when points are insufficient', () {
    final repository = _ControlledDownloadsRepository();
    final rewards = StoredReaderRewardsRepository.memory(initialPoints: 1);
    final manager = DownloadManager(
      repository: repository,
      rewardsRepository: rewards,
    );
    addTearDown(manager.dispose);

    expect(
      () => manager.startBatch([_request(1), _request(2)]),
      throwsA(isA<InsufficientDownloadPointsException>()),
    );
    expect(repository.listenCount, 0);
    expect(rewards.state.value.points, 1);
  });

  test('refunds points for failed chapters in a batch', () async {
    final repository = _ControlledDownloadsRepository();
    final rewards = StoredReaderRewardsRepository.memory(initialPoints: 5);
    final manager = DownloadManager(
      repository: repository,
      rewardsRepository: rewards,
    );
    addTearDown(manager.dispose);

    final completion = manager.startBatch([_request(1), _request(2)]);

    repository.emit(_progress(total: 2, completed: 1, failed: 1));
    await repository.closeProgress();
    await completion;

    expect(rewards.state.value.points, 4);
  });

  test('does not spend points for chapters already downloaded locally', () async {
    final repository = _ControlledDownloadsRepository(
      chapters: [_downloadedChapter(1)],
    );
    final rewards = StoredReaderRewardsRepository.memory(initialPoints: 1);
    final manager = DownloadManager(
      repository: repository,
      rewardsRepository: rewards,
    );
    addTearDown(manager.dispose);

    final completion = manager.startBatch([_request(1), _request(2)]);

    expect(rewards.state.value.points, 0);

    repository.emit(_progress(total: 2, completed: 2, failed: 0));
    await repository.closeProgress();
    await completion;
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

DownloadedChapter _downloadedChapter(int id) {
  return DownloadedChapter(
    novelId: 10,
    novelTitle: 'رواية الاختبار',
    novelCover: '',
    chapterId: id,
    chapterTitle: 'الفصل $id',
    chapterLabel: 'الفصل $id',
    chapterPosition: id,
    chaptersTotal: 2,
    contentApi: '/chapters/$id',
    contentHtml: '<p>الفصل $id</p>',
    plainTextPreview: 'الفصل $id',
    contentByteSize: 100,
    downloadedAt: DateTime.utc(2026, 7, 3),
    lastOpenedAt: null,
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

class _ControlledDownloadsRepository implements DownloadsRepository {
  _ControlledDownloadsRepository({List<DownloadedChapter> chapters = const []})
    : _state = ValueNotifier(DownloadsState(chapters: chapters));

  final ValueNotifier<DownloadsState> _state;
  final StreamController<DownloadBatchProgress> _progressController =
      StreamController();
  int listenCount = 0;

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
    listenCount++;
    return _progressController.stream;
  }

  @override
  Future<void> deleteChapter(String contentApi) async {}

  @override
  Future<void> deleteNovelDownloads(int novelId) async {}

  @override
  Future<void> downloadChapter(ChapterDownloadRequest request) async {}

  @override
  Future<DownloadedChapter?> findChapter(String contentApi) async {
    return _state.value.findByContentApi(contentApi);
  }

  @override
  Future<ReaderChapterContent?> findReaderContent(String contentApi) async {
    return null;
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> markOpened(String contentApi) async {}
}
