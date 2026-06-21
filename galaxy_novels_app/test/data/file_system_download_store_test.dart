import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/data/repositories/file_system_download_store.dart';
import 'package:galaxy_novels_app/data/repositories/local_download_store.dart';

void main() {
  test('stores chapter content outside the metadata index', () async {
    final directory = await _temporaryDirectory();
    final store = FileSystemDownloadStore(rootDirectory: directory);
    final chapter = _downloaded(1, contentHtml: '<p>محتوى كبير</p>');

    await store.writeChapters([chapter]);

    final index = await File(
      '${directory.path}${Platform.pathSeparator}index.json',
    ).readAsString();
    final restored = await store.readChapters();

    expect(index, isNot(contains('محتوى كبير')));
    expect(jsonDecode(index), isA<Map<String, dynamic>>());
    expect(restored.single.contentHtml, isEmpty);
    expect(
      await store.readChapterContent(restored.single),
      '<p>محتوى كبير</p>',
    );
  });

  test('removes content files after their chapter is deleted', () async {
    final directory = await _temporaryDirectory();
    final store = FileSystemDownloadStore(rootDirectory: directory);

    await store.writeChapters([_downloaded(1), _downloaded(2)]);
    await store.writeChapters([_downloaded(2)]);

    final contentFiles = await directory
        .list()
        .where((entity) => entity.path.endsWith('.html'))
        .toList();
    expect(contentFiles, hasLength(1));
    expect((await store.readChapters()).single.chapterId, 2);
  });

  test('migrates the legacy store once and clears it', () async {
    final directory = await _temporaryDirectory();
    final legacyStore = _MemoryDownloadStore([_downloaded(3)]);
    final store = FileSystemDownloadStore(
      rootDirectory: directory,
      legacyStore: legacyStore,
    );

    final firstRead = await store.readChapters();
    final secondRead = await store.readChapters();

    expect(firstRead.single.chapterId, 3);
    expect(secondRead.single.chapterId, 3);
    expect(legacyStore.chapters, isEmpty);
    expect(legacyStore.readCount, 1);
  });

  test('ignores an index entry when its content file is missing', () async {
    final directory = await _temporaryDirectory();
    final store = FileSystemDownloadStore(rootDirectory: directory);
    await store.writeChapters([_downloaded(1)]);

    final contentFile = await directory
        .list()
        .where((entity) => entity.path.endsWith('.html'))
        .single;
    await contentFile.delete();

    expect(await store.readChapters(), isEmpty);
  });
}

Future<Directory> _temporaryDirectory() async {
  final directory = await Directory.systemTemp.createTemp(
    'galaxy_download_store_',
  );
  addTearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });
  return directory;
}

DownloadedChapter _downloaded(int id, {String? contentHtml}) {
  return DownloadedChapter(
    novelId: 10,
    novelTitle: 'رواية الاختبار',
    novelCover: '/cover.jpg',
    chapterId: id,
    chapterTitle: 'الفصل $id',
    chapterLabel: 'الفصل $id',
    chapterPosition: id,
    chaptersTotal: 100,
    contentApi: '/chapters/$id',
    contentHtml: contentHtml ?? '<p>الفصل $id</p>',
    plainTextPreview: 'الفصل $id',
    downloadedAt: DateTime.utc(2026, 6, 21),
    lastOpenedAt: null,
  );
}

class _MemoryDownloadStore implements LocalDownloadStore {
  _MemoryDownloadStore(this.chapters);

  List<DownloadedChapter> chapters;
  int readCount = 0;

  @override
  Future<List<DownloadedChapter>> readChapters() async {
    readCount++;
    return chapters;
  }

  @override
  Future<void> writeChapters(List<DownloadedChapter> chapters) async {
    this.chapters = chapters;
  }
}
