import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/repositories/downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/local_download_store.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/shared_preferences_download_store.dart';
import 'package:galaxy_novels_app/data/repositories/stored_downloads_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('downloads a chapter and exposes it in state', () async {
    final store = _MemoryDownloadStore();
    final reader = _ReaderRepository();
    final repository = StoredDownloadsRepository(
      store: store,
      readerRepository: reader,
    );

    await repository.load();
    await repository.downloadChapter(_request(1));

    expect(repository.state.value.downloadedCount, 1);
    expect(repository.state.value.contains('/chapters/1'), isTrue);
    expect(store.chapters.single.contentHtml, '<p>الفصل 1</p>');

    final content = await repository.findReaderContent('/chapters/1');
    expect(content?.contentHtml, '<p>الفصل 1</p>');
  });

  test('keeps only a short plain text preview in metadata', () async {
    final store = _MemoryDownloadStore();
    final repository = StoredDownloadsRepository(
      store: store,
      readerRepository: _ReaderRepository(
        contentHtml: '<p>${List.filled(400, 'ن').join()}</p>',
      ),
    );

    await repository.downloadChapter(_request(1));

    expect(store.chapters.single.plainTextPreview.runes.length, 240);
  });

  test('serializes concurrent chapter downloads without losing data', () async {
    final store = _MemoryDownloadStore();
    final repository = StoredDownloadsRepository(
      store: store,
      readerRepository: _ReaderRepository(),
    );

    await Future.wait([
      repository.downloadChapter(_request(1)),
      repository.downloadChapter(_request(2)),
    ]);

    expect(repository.state.value.downloadedCount, 2);
    expect(repository.state.value.contains('/chapters/1'), isTrue);
    expect(repository.state.value.contains('/chapters/2'), isTrue);
  });

  test('builds offline navigation from downloaded sibling chapters', () async {
    final store = _MemoryDownloadStore();
    final repository = StoredDownloadsRepository(
      store: store,
      readerRepository: _ReaderRepository(),
    );
    await store.writeChapters([_downloaded(1), _downloaded(2), _downloaded(3)]);
    await repository.load();

    final content = await repository.findReaderContent('/chapters/2');

    expect(content?.navigation.previousApi, '/chapters/1');
    expect(content?.navigation.previousId, 1);
    expect(content?.navigation.nextApi, '/chapters/3');
    expect(content?.navigation.nextId, 3);
  });

  test('does not download above the 100 chapter limit', () async {
    final store = _MemoryDownloadStore();
    final reader = _ReaderRepository();
    final repository = StoredDownloadsRepository(
      store: store,
      readerRepository: reader,
    );

    await store.writeChapters(
      List.generate(100, (index) => _downloaded(index + 1)),
    );
    await repository.load();

    expect(
      () => repository.downloadChapter(_request(101)),
      throwsA(isA<DownloadLimitExceededException>()),
    );
  });

  test(
    'does not download a chapter with an empty effective content api',
    () async {
      final reader = _ReaderRepository();
      final repository = StoredDownloadsRepository(
        store: _MemoryDownloadStore(),
        readerRepository: reader,
      );

      await repository.downloadChapter(_request(0, contentApi: ''));

      expect(repository.state.value.downloadedCount, 0);
      expect(reader.loadCalls, isEmpty);
    },
  );

  test('batch download continues when one chapter fails', () async {
    final store = _MemoryDownloadStore();
    final reader = _ReaderRepository(failingApi: '/chapters/2');
    final repository = StoredDownloadsRepository(
      store: store,
      readerRepository: reader,
    );

    await repository.load();
    final progress = await repository.downloadChaptersBatch([
      _request(1),
      _request(2),
      _request(3),
    ]).toList();

    expect(progress.last.completed, 2);
    expect(progress.last.failed, 1);
    expect(progress.last.isComplete, isTrue);
    expect(repository.state.value.downloadedCount, 2);
  });

  test('batch download emits complete progress for empty requests', () async {
    final repository = StoredDownloadsRepository(
      store: _MemoryDownloadStore(),
      readerRepository: _ReaderRepository(),
    );

    final progress = await repository.downloadChaptersBatch(const []).toList();

    expect(progress, hasLength(1));
    expect(progress.single.total, 0);
    expect(progress.single.completed, 0);
    expect(progress.single.failed, 0);
    expect(progress.single.isComplete, isTrue);
  });

  test('batch download counts duplicate chapter APIs once', () async {
    final repository = StoredDownloadsRepository(
      store: _MemoryDownloadStore(),
      readerRepository: _ReaderRepository(),
      limitPolicy: const DownloadLimitPolicy(maxChapters: 1),
    );

    await repository.load();
    final progress = await repository.downloadChaptersBatch([
      _request(1),
      _request(1),
    ]).toList();

    expect(progress, hasLength(1));
    expect(progress.single.total, 1);
    expect(progress.single.completed, 1);
    expect(progress.single.failed, 0);
    expect(progress.single.isComplete, isTrue);
    expect(repository.state.value.downloadedCount, 1);
  });

  test('batch download enforces total limit before starting', () async {
    final store = _MemoryDownloadStore();
    final reader = _ReaderRepository();
    final repository = StoredDownloadsRepository(
      store: store,
      readerRepository: reader,
      limitPolicy: const DownloadLimitPolicy(maxChapters: 2),
    );

    await repository.load();

    expect(
      () => repository.downloadChaptersBatch([
        _request(1),
        _request(2),
        _request(3),
      ]).toList(),
      throwsA(isA<DownloadLimitExceededException>()),
    );
    expect(reader.loadCalls, isEmpty);
  });

  test('delete chapter lowers the count', () async {
    final store = _MemoryDownloadStore();
    final reader = _ReaderRepository();
    final repository = StoredDownloadsRepository(
      store: store,
      readerRepository: reader,
    );

    await repository.load();
    await repository.downloadChapter(_request(1));
    await repository.deleteChapter('/chapters/1');

    expect(repository.state.value.downloadedCount, 0);
  });

  test('delete novel downloads removes all matching novel chapters', () async {
    final store = _MemoryDownloadStore();
    final repository = StoredDownloadsRepository(
      store: store,
      readerRepository: _ReaderRepository(),
    );

    await store.writeChapters([
      _downloaded(1),
      _downloaded(2),
      _downloaded(3, novelId: 11),
    ]);
    await repository.load();
    await repository.deleteNovelDownloads(10);

    expect(repository.state.value.downloadedCount, 1);
    expect(repository.state.value.contains('/chapters/3'), isTrue);
  });

  test('mark opened updates last opened timestamp', () async {
    final store = _MemoryDownloadStore();
    final repository = StoredDownloadsRepository(
      store: store,
      readerRepository: _ReaderRepository(),
    );

    await store.writeChapters([_downloaded(1)]);
    await repository.load();
    await repository.markOpened('/chapters/1');

    final chapter = await repository.findChapter('/chapters/1');
    expect(chapter?.lastOpenedAt, isNotNull);
    expect(store.chapters.single.lastOpenedAt, isNotNull);
  });

  test('repository state uses injected limit policy', () async {
    final repository = StoredDownloadsRepository(
      store: _MemoryDownloadStore(),
      readerRepository: _ReaderRepository(),
      limitPolicy: const DownloadLimitPolicy(maxChapters: 2),
    );

    await repository.load();
    await repository.downloadChapter(_request(1));

    expect(repository.state.value.maxChapters, 2);
    expect(repository.state.value.remainingSlots, 1);
  });

  test('store failure does not mutate state or future reads', () async {
    final repository = StoredDownloadsRepository(
      store: _FailingDownloadStore(),
      readerRepository: _ReaderRepository(),
    );

    await repository.load();

    await expectLater(
      repository.downloadChapter(_request(1)),
      throwsA(isA<Exception>()),
    );

    expect(repository.state.value.downloadedCount, 0);
    expect(await repository.findChapter('/chapters/1'), isNull);
  });

  test('shared preferences store reads missing data as empty', () async {
    final store = _testSharedPreferencesStore();

    expect(await store.readChapters(), isEmpty);
  });

  test('shared preferences store writes and restores chapters', () async {
    final store = _testSharedPreferencesStore();

    await store.writeChapters([_downloaded(1)]);
    final chapters = await store.readChapters();

    expect(chapters, hasLength(1));
    expect(chapters.single.contentApi, '/chapters/1');
  });
}

ChapterDownloadRequest _request(int id, {String? contentApi}) {
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

DownloadedChapter _downloaded(int id, {int novelId = 10}) {
  return DownloadedChapter(
    novelId: novelId,
    novelTitle: 'رواية الاختبار',
    novelCover: '/cover.jpg',
    chapterId: id,
    chapterTitle: 'الفصل $id',
    chapterLabel: 'الفصل $id',
    chapterPosition: id,
    chaptersTotal: 100,
    contentApi: '/chapters/$id',
    contentHtml: '<p>الفصل $id</p>',
    plainTextPreview: 'الفصل $id',
    downloadedAt: DateTime.utc(2026, 6, 20),
    lastOpenedAt: null,
  );
}

SharedPreferencesDownloadStore _testSharedPreferencesStore() {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferencesDownloadStore();
}

class _MemoryDownloadStore implements LocalDownloadStore {
  List<DownloadedChapter> chapters = [];

  @override
  Future<List<DownloadedChapter>> readChapters() async => chapters;

  @override
  Future<void> writeChapters(List<DownloadedChapter> value) async {
    chapters = value;
  }
}

class _FailingDownloadStore implements LocalDownloadStore {
  @override
  Future<List<DownloadedChapter>> readChapters() async => const [];

  @override
  Future<void> writeChapters(List<DownloadedChapter> chapters) async {
    throw Exception('failed to persist downloads');
  }
}

class _ReaderRepository implements ReaderRepository {
  _ReaderRepository({this.failingApi, this.contentHtml});

  final String? failingApi;
  final String? contentHtml;
  final List<String> loadCalls = [];

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    loadCalls.add(contentApi);
    if (contentApi == failingApi) {
      throw Exception('failed');
    }
    final id = int.parse(contentApi.split('/').last);
    return ReaderChapterContent(
      id: id,
      novelId: 10,
      label: 'الفصل $id',
      title: 'الفصل $id',
      displayTitle: 'الفصل $id',
      position: id,
      total: 100,
      contentHtml: contentHtml ?? '<p>الفصل $id</p>',
      navigation: const ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }
}
