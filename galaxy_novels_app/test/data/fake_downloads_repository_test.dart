import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/repositories/downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/stored_downloads_repository.dart';

void main() {
  test('downloads, opens, and deletes chapters in memory', () async {
    final repository = FakeDownloadsRepository(maxChapters: 7);

    await repository.downloadChapter(_request(1));
    await repository.downloadChapter(_request(1));
    await repository.downloadChapter(_request(0, contentApi: ''));

    expect(repository.state.value.downloadedCount, 1);
    expect(repository.state.value.maxChapters, 7);
    expect(repository.state.value.contains('/chapters/1'), isTrue);

    final content = await repository.findReaderContent('/chapters/1');
    expect(content?.contentHtml, '<p>Chapter 1</p>');

    await repository.markOpened('/chapters/1');
    expect(
      (await repository.findChapter('/chapters/1'))?.lastOpenedAt,
      isNotNull,
    );

    await repository.deleteChapter('/chapters/1');

    expect(repository.state.value.downloadedCount, 0);
    expect(await repository.findReaderContent('/chapters/1'), isNull);
  });

  test('batch download filters invalid requests and emits progress', () async {
    final repository = FakeDownloadsRepository();

    final progress = await repository.downloadChaptersBatch([
      _request(1),
      _request(1),
      _request(2),
      _request(0, contentApi: ''),
    ]).toList();

    expect(progress, hasLength(2));
    expect(progress.first.completed, 1);
    expect(progress.first.isComplete, isFalse);
    expect(progress.last.total, 2);
    expect(progress.last.completed, 2);
    expect(progress.last.failed, 0);
    expect(progress.last.isComplete, isTrue);
    expect(repository.state.value.downloadedCount, 2);
  });

  test('downloadChapter throws when maxChapters is exceeded', () async {
    final repository = FakeDownloadsRepository(maxChapters: 1);

    await repository.downloadChapter(_request(1));

    expect(
      () => repository.downloadChapter(_request(2)),
      throwsA(isA<DownloadLimitExceededException>()),
    );
    expect(repository.state.value.downloadedCount, 1);
    expect(repository.state.value.contains('/chapters/1'), isTrue);
    expect(repository.state.value.contains('/chapters/2'), isFalse);
  });

  test(
    'batch download throws before partial state changes when over limit',
    () {
      final repository = FakeDownloadsRepository(maxChapters: 1);

      expect(
        () => repository.downloadChaptersBatch([
          _request(1),
          _request(2),
        ]).toList(),
        throwsA(isA<DownloadLimitExceededException>()),
      );
      expect(repository.state.value.downloadedCount, 0);
    },
  );

  test('batch download emits complete progress for empty requests', () async {
    final repository = FakeDownloadsRepository();

    final progress = await repository.downloadChaptersBatch(const []).toList();

    expect(progress, hasLength(1));
    expect(progress.single.total, 0);
    expect(progress.single.completed, 0);
    expect(progress.single.failed, 0);
    expect(progress.single.isComplete, isTrue);
  });
}

ChapterDownloadRequest _request(int id, {String? contentApi}) {
  return ChapterDownloadRequest(
    novelId: 10,
    novelTitle: 'Test Novel',
    novelCover: '/cover.jpg',
    chapter: NovelChapter(
      id: id,
      position: id,
      number: '$id',
      label: 'Chapter $id',
      title: 'Chapter $id',
      url: '/novel/test/chapter-$id',
      contentApi: contentApi ?? '/chapters/$id',
      dateLabel: '',
      dateIso: null,
      views: 0,
      comments: 0,
      search: '',
    ),
  );
}
