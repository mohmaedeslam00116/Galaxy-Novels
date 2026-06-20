# Galaxy Novels Downloads Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build offline chapter downloads for Galaxy Novels with a 100-chapter device limit, individual and batch downloads, a downloads tab, a floating progress overlay, and native reader local-first loading.

**Architecture:** Add a focused downloads data layer beside the existing repositories. The downloads feature stores chapter content locally through a small store, exposes operations through `DownloadsRepository`, and lets UI widgets observe `ValueListenable<DownloadsState>` without introducing a new state package.

**Tech Stack:** Flutter, Dart, Material 3, `shared_preferences`, existing `ReaderRepository`, existing `AppDependencies`, widget/unit tests with `flutter_test`.

---

## Spec Source

Read this first:

- `docs/superpowers/specs/2026-06-20-galaxy-novels-downloads-design.md`

The implementation must preserve these fixed decisions:

- The limit is `100` downloaded chapters total on the device.
- Points and ads are not implemented in this phase.
- The reader remains native.
- Batch download starts from a sheet in novel details.
- A small floating progress overlay appears after batch download starts.
- Downloads get their own bottom navigation tab.

## File Structure

Create:

- `lib/data/models/downloaded_chapter.dart`  
  Owns the persisted downloaded chapter shape and JSON conversion.

- `lib/data/repositories/downloads_repository.dart`  
  Public interface, state object, batch progress objects, and limit policy.

- `lib/data/repositories/stored_downloads_repository.dart`  
  Implements downloads using `ReaderRepository` and `LocalDownloadStore`.

- `lib/data/repositories/local_download_store.dart`  
  Abstract local storage contract.

- `lib/data/repositories/shared_preferences_download_store.dart`  
  Stores downloaded chapters as JSON in `SharedPreferences`.

- `lib/data/repositories/fake_downloads_repository.dart`  
  Test/dummy implementation.

- `lib/features/downloads/presentation/downloads_screen.dart`  
  Bottom navigation screen for offline downloads.

- `lib/features/downloads/presentation/download_chapters_sheet.dart`  
  Large bottom sheet for selecting chapters.

- `lib/features/downloads/presentation/download_progress_overlay.dart`  
  Center overlay showing cover, title, progress, and result actions.

- `lib/features/downloads/presentation/chapter_download_button.dart`  
  Small reusable chapter download state button.

- `test/data/downloaded_chapter_test.dart`
- `test/data/stored_downloads_repository_test.dart`
- `test/features/downloads/downloads_screen_test.dart`
- `test/features/downloads/download_chapters_sheet_test.dart`
- `test/features/downloads/download_progress_overlay_test.dart`

Modify:

- `lib/app/app_dependencies.dart`
- `lib/app/galaxy_novels_app.dart`
- `lib/features/shell/presentation/app_shell.dart`
- `lib/features/novel_details/presentation/widgets/novel_chapter_tile.dart`
- `lib/features/novel_details/presentation/novel_details_screen.dart`
- `lib/features/reader/presentation/reader_screen.dart`
- Existing tests that construct `AppDependencies`

Do not modify:

- Public cache loading behavior.
- Search implementation.
- Ranking implementation.
- Reader HTML parsing logic except where local-first loading needs to call the same rendering path.

---

## Task 1: Download Model And Limit Policy

**Files:**

- Create: `lib/data/models/downloaded_chapter.dart`
- Create: `lib/data/repositories/downloads_repository.dart`
- Test: `test/data/downloaded_chapter_test.dart`

- [ ] **Step 1: Write the failing model and policy tests**

Create `test/data/downloaded_chapter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/data/repositories/downloads_repository.dart';

void main() {
  test('downloaded chapter serializes and restores from json', () {
    final downloadedAt = DateTime.utc(2026, 6, 20, 12);
    final chapter = DownloadedChapter(
      novelId: 10,
      novelTitle: 'رواية الاختبار',
      novelCover: '/cover.jpg',
      chapterId: 55,
      chapterTitle: 'البداية',
      chapterLabel: 'الفصل 1',
      chapterPosition: 1,
      chaptersTotal: 120,
      contentApi: '/wp-json/wor-reader-app/v1/chapters/55',
      contentHtml: '<p>نص الفصل</p>',
      plainTextPreview: 'نص الفصل',
      downloadedAt: downloadedAt,
      lastOpenedAt: null,
    );

    final restored = DownloadedChapter.fromJson(chapter.toJson());

    expect(restored.novelId, 10);
    expect(restored.novelTitle, 'رواية الاختبار');
    expect(restored.chapterId, 55);
    expect(restored.contentApi, '/wp-json/wor-reader-app/v1/chapters/55');
    expect(restored.contentHtml, '<p>نص الفصل</p>');
    expect(restored.downloadedAt, downloadedAt);
    expect(restored.lastOpenedAt, isNull);
  });

  test('download state exposes total and remaining slots', () {
    final chapters = List.generate(
      3,
      (index) => DownloadedChapter(
        novelId: 1,
        novelTitle: 'رواية',
        novelCover: '',
        chapterId: index + 1,
        chapterTitle: 'الفصل ${index + 1}',
        chapterLabel: 'الفصل ${index + 1}',
        chapterPosition: index + 1,
        chaptersTotal: 10,
        contentApi: '/chapters/${index + 1}',
        contentHtml: '<p>الفصل</p>',
        plainTextPreview: 'الفصل',
        downloadedAt: DateTime.utc(2026, 6, 20),
        lastOpenedAt: null,
      ),
    );

    final state = DownloadsState(chapters: chapters);

    expect(state.downloadedCount, 3);
    expect(state.remainingSlots, 97);
    expect(state.isFull, isFalse);
  });

  test('download limit policy blocks requests above remaining slots', () {
    const policy = DownloadLimitPolicy(maxChapters: 100);

    expect(policy.canDownload(currentCount: 99, requestedCount: 1), isTrue);
    expect(policy.canDownload(currentCount: 99, requestedCount: 2), isFalse);
    expect(policy.remainingSlots(currentCount: 101), 0);
  });
}
```

- [ ] **Step 2: Run model tests and verify failure**

Run:

```powershell
flutter test test\data\downloaded_chapter_test.dart
```

Expected: fails because `DownloadedChapter`, `DownloadsState`, and `DownloadLimitPolicy` do not exist.

- [ ] **Step 3: Add `DownloadedChapter`**

Create `lib/data/models/downloaded_chapter.dart`:

```dart
class DownloadedChapter {
  const DownloadedChapter({
    required this.novelId,
    required this.novelTitle,
    required this.novelCover,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterLabel,
    required this.chapterPosition,
    required this.chaptersTotal,
    required this.contentApi,
    required this.contentHtml,
    required this.plainTextPreview,
    required this.downloadedAt,
    required this.lastOpenedAt,
  });

  factory DownloadedChapter.fromJson(Map<String, dynamic> json) {
    return DownloadedChapter(
      novelId: _asInt(json['novelId']),
      novelTitle: _asString(json['novelTitle']),
      novelCover: _asString(json['novelCover']),
      chapterId: _asInt(json['chapterId']),
      chapterTitle: _asString(json['chapterTitle']),
      chapterLabel: _asString(json['chapterLabel']),
      chapterPosition: _asInt(json['chapterPosition']),
      chaptersTotal: _asInt(json['chaptersTotal']),
      contentApi: _asString(json['contentApi']),
      contentHtml: _asString(json['contentHtml']),
      plainTextPreview: _asString(json['plainTextPreview']),
      downloadedAt:
          DateTime.tryParse(_asString(json['downloadedAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastOpenedAt: _asDateTime(json['lastOpenedAt']),
    );
  }

  final int novelId;
  final String novelTitle;
  final String novelCover;
  final int chapterId;
  final String chapterTitle;
  final String chapterLabel;
  final int chapterPosition;
  final int chaptersTotal;
  final String contentApi;
  final String contentHtml;
  final String plainTextPreview;
  final DateTime downloadedAt;
  final DateTime? lastOpenedAt;

  Map<String, dynamic> toJson() {
    return {
      'novelId': novelId,
      'novelTitle': novelTitle,
      'novelCover': novelCover,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'chapterLabel': chapterLabel,
      'chapterPosition': chapterPosition,
      'chaptersTotal': chaptersTotal,
      'contentApi': contentApi,
      'contentHtml': contentHtml,
      'plainTextPreview': plainTextPreview,
      'downloadedAt': downloadedAt.toIso8601String(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
    };
  }

  DownloadedChapter copyWith({DateTime? lastOpenedAt}) {
    return DownloadedChapter(
      novelId: novelId,
      novelTitle: novelTitle,
      novelCover: novelCover,
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      chapterLabel: chapterLabel,
      chapterPosition: chapterPosition,
      chaptersTotal: chaptersTotal,
      contentApi: contentApi,
      contentHtml: contentHtml,
      plainTextPreview: plainTextPreview,
      downloadedAt: downloadedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }
}

String _asString(Object? value) => value?.toString() ?? '';

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

DateTime? _asDateTime(Object? value) {
  final text = _asString(value);
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}
```

- [ ] **Step 4: Add repository contract, state, and policy**

Create `lib/data/repositories/downloads_repository.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../models/downloaded_chapter.dart';
import '../models/novel_details_data.dart';
import '../models/reader_content_data.dart';

class DownloadLimitPolicy {
  const DownloadLimitPolicy({this.maxChapters = 100});

  final int maxChapters;

  int remainingSlots({required int currentCount}) {
    final remaining = maxChapters - currentCount;
    return remaining < 0 ? 0 : remaining;
  }

  bool canDownload({
    required int currentCount,
    required int requestedCount,
  }) {
    return requestedCount <= remainingSlots(currentCount: currentCount);
  }
}

class DownloadsState {
  const DownloadsState({this.chapters = const []});

  final List<DownloadedChapter> chapters;

  int get downloadedCount => chapters.length;

  int get remainingSlots =>
      const DownloadLimitPolicy().remainingSlots(currentCount: downloadedCount);

  bool get isFull => remainingSlots == 0;

  bool contains(String contentApi) {
    return chapters.any((chapter) => chapter.contentApi == contentApi);
  }

  DownloadedChapter? findByContentApi(String contentApi) {
    for (final chapter in chapters) {
      if (chapter.contentApi == contentApi) {
        return chapter;
      }
    }
    return null;
  }
}

class ChapterDownloadRequest {
  const ChapterDownloadRequest({
    required this.novelId,
    required this.novelTitle,
    required this.novelCover,
    required this.chapter,
  });

  final int novelId;
  final String novelTitle;
  final String novelCover;
  final NovelChapter chapter;
}

class DownloadBatchProgress {
  const DownloadBatchProgress({
    required this.novelTitle,
    required this.novelCover,
    required this.total,
    required this.completed,
    required this.failed,
    required this.isComplete,
  });

  final String novelTitle;
  final String novelCover;
  final int total;
  final int completed;
  final int failed;
  final bool isComplete;

  double get fraction => total <= 0 ? 0 : (completed + failed) / total;
}

abstract class DownloadsRepository {
  const DownloadsRepository();

  ValueListenable<DownloadsState> get state;

  Future<void> load();

  Future<DownloadedChapter?> findChapter(String contentApi);

  Future<ReaderChapterContent?> findReaderContent(String contentApi);

  Future<void> downloadChapter(ChapterDownloadRequest request);

  Stream<DownloadBatchProgress> downloadChaptersBatch(
    List<ChapterDownloadRequest> requests,
  );

  Future<void> deleteChapter(String contentApi);

  Future<void> deleteNovelDownloads(int novelId);

  Future<void> markOpened(String contentApi);
}
```

- [ ] **Step 5: Run model tests and verify pass**

Run:

```powershell
flutter test test\data\downloaded_chapter_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit Task 1**

Run:

```powershell
git add lib/data/models/downloaded_chapter.dart lib/data/repositories/downloads_repository.dart test/data/downloaded_chapter_test.dart
git commit -m "feat: add download models and limit policy"
```

---

## Task 2: Local Store And Stored Downloads Repository

**Files:**

- Create: `lib/data/repositories/local_download_store.dart`
- Create: `lib/data/repositories/shared_preferences_download_store.dart`
- Create: `lib/data/repositories/stored_downloads_repository.dart`
- Test: `test/data/stored_downloads_repository_test.dart`

- [ ] **Step 1: Write failing repository tests**

Create `test/data/stored_downloads_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/repositories/local_download_store.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/stored_downloads_repository.dart';

void main() {
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

    final content = await repository.findReaderContent('/chapters/1');
    expect(content?.contentHtml, '<p>الفصل 1</p>');
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

  test('batch download continues when one chapter fails', () async {
    final store = _MemoryDownloadStore();
    final reader = _ReaderRepository(failingApi: '/chapters/2');
    final repository = StoredDownloadsRepository(
      store: store,
      readerRepository: reader,
    );

    await repository.load();
    final progress = await repository
        .downloadChaptersBatch([_request(1), _request(2), _request(3)])
        .toList();

    expect(progress.last.completed, 2);
    expect(progress.last.failed, 1);
    expect(progress.last.isComplete, isTrue);
    expect(repository.state.value.downloadedCount, 2);
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
      url: '/novel/test/chapter-$id',
      contentApi: '/chapters/$id',
      dateLabel: '',
      dateIso: null,
      views: 0,
      comments: 0,
      search: '',
    ),
  );
}

DownloadedChapter _downloaded(int id) {
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
    contentHtml: '<p>الفصل $id</p>',
    plainTextPreview: 'الفصل $id',
    downloadedAt: DateTime.utc(2026, 6, 20),
    lastOpenedAt: null,
  );
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

class _ReaderRepository implements ReaderRepository {
  const _ReaderRepository({this.failingApi});

  final String? failingApi;

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
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
      contentHtml: '<p>الفصل $id</p>',
      navigation: const ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }
}
```

- [ ] **Step 2: Run repository tests and verify failure**

Run:

```powershell
flutter test test\data\stored_downloads_repository_test.dart
```

Expected: fails because store and repository files do not exist.

- [ ] **Step 3: Add local store contract**

Create `lib/data/repositories/local_download_store.dart`:

```dart
import '../models/downloaded_chapter.dart';

abstract class LocalDownloadStore {
  const LocalDownloadStore();

  Future<List<DownloadedChapter>> readChapters();

  Future<void> writeChapters(List<DownloadedChapter> chapters);
}
```

- [ ] **Step 4: Add SharedPreferences store**

Create `lib/data/repositories/shared_preferences_download_store.dart`:

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/downloaded_chapter.dart';
import 'local_download_store.dart';

class SharedPreferencesDownloadStore implements LocalDownloadStore {
  const SharedPreferencesDownloadStore();

  static const key = 'downloads.v1';

  @override
  Future<List<DownloadedChapter>> readChapters() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((item) => DownloadedChapter.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .toList(growable: false);
  }

  @override
  Future<void> writeChapters(List<DownloadedChapter> chapters) async {
    final preferences = await SharedPreferences.getInstance();
    final value = jsonEncode(
      chapters.map((chapter) => chapter.toJson()).toList(growable: false),
    );
    await preferences.setString(key, value);
  }
}
```

- [ ] **Step 5: Add stored repository**

Create `lib/data/repositories/stored_downloads_repository.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../models/downloaded_chapter.dart';
import '../models/reader_content_data.dart';
import 'downloads_repository.dart';
import 'local_download_store.dart';
import 'reader_repository.dart';

class DownloadLimitExceededException implements Exception {
  const DownloadLimitExceededException(this.remainingSlots);

  final int remainingSlots;

  @override
  String toString() {
    return 'DownloadLimitExceededException: remainingSlots=$remainingSlots';
  }
}

class StoredDownloadsRepository implements DownloadsRepository {
  StoredDownloadsRepository({
    required LocalDownloadStore store,
    required ReaderRepository readerRepository,
    DownloadLimitPolicy limitPolicy = const DownloadLimitPolicy(),
  })  : _store = store,
        _readerRepository = readerRepository,
        _limitPolicy = limitPolicy;

  final LocalDownloadStore _store;
  final ReaderRepository _readerRepository;
  final DownloadLimitPolicy _limitPolicy;
  final ValueNotifier<DownloadsState> _state =
      ValueNotifier<DownloadsState>(const DownloadsState());

  @override
  ValueListenable<DownloadsState> get state => _state;

  @override
  Future<void> load() async {
    _state.value = DownloadsState(chapters: await _store.readChapters());
  }

  @override
  Future<DownloadedChapter?> findChapter(String contentApi) async {
    await _ensureLoaded();
    return _state.value.findByContentApi(contentApi);
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
    final contentApi = request.chapter.effectiveContentApi;
    if (contentApi.isEmpty || _state.value.contains(contentApi)) {
      return;
    }

    final currentCount = _state.value.downloadedCount;
    if (!_limitPolicy.canDownload(
      currentCount: currentCount,
      requestedCount: 1,
    )) {
      throw DownloadLimitExceededException(
        _limitPolicy.remainingSlots(currentCount: currentCount),
      );
    }

    final content = await _readerRepository.loadChapter(contentApi);
    final downloaded = DownloadedChapter(
      novelId: request.novelId,
      novelTitle: request.novelTitle,
      novelCover: request.novelCover,
      chapterId: content.id,
      chapterTitle: content.effectiveTitle,
      chapterLabel: content.label,
      chapterPosition: content.position,
      chaptersTotal: content.total,
      contentApi: contentApi,
      contentHtml: content.contentHtml,
      plainTextPreview: _preview(content.contentHtml),
      downloadedAt: DateTime.now().toUtc(),
      lastOpenedAt: null,
    );
    await _replace([..._state.value.chapters, downloaded]);
  }

  @override
  Stream<DownloadBatchProgress> downloadChaptersBatch(
    List<ChapterDownloadRequest> requests,
  ) async* {
    await _ensureLoaded();
    final uniqueRequests = requests
        .where((request) => request.chapter.effectiveContentApi.isNotEmpty)
        .where((request) => !_state.value.contains(
              request.chapter.effectiveContentApi,
            ))
        .toList(growable: false);

    if (!_limitPolicy.canDownload(
      currentCount: _state.value.downloadedCount,
      requestedCount: uniqueRequests.length,
    )) {
      throw DownloadLimitExceededException(_state.value.remainingSlots);
    }

    var completed = 0;
    var failed = 0;
    final novelTitle =
        uniqueRequests.isEmpty ? '' : uniqueRequests.first.novelTitle;
    final novelCover =
        uniqueRequests.isEmpty ? '' : uniqueRequests.first.novelCover;

    for (final request in uniqueRequests) {
      try {
        await downloadChapter(request);
        completed += 1;
      } catch (_) {
        failed += 1;
      }
      yield DownloadBatchProgress(
        novelTitle: novelTitle,
        novelCover: novelCover,
        total: uniqueRequests.length,
        completed: completed,
        failed: failed,
        isComplete: completed + failed == uniqueRequests.length,
      );
    }

    if (uniqueRequests.isEmpty) {
      yield DownloadBatchProgress(
        novelTitle: '',
        novelCover: '',
        total: 0,
        completed: 0,
        failed: 0,
        isComplete: true,
      );
    }
  }

  @override
  Future<void> deleteChapter(String contentApi) async {
    await _ensureLoaded();
    await _replace(
      _state.value.chapters
          .where((chapter) => chapter.contentApi != contentApi)
          .toList(growable: false),
    );
  }

  @override
  Future<void> deleteNovelDownloads(int novelId) async {
    await _ensureLoaded();
    await _replace(
      _state.value.chapters
          .where((chapter) => chapter.novelId != novelId)
          .toList(growable: false),
    );
  }

  @override
  Future<void> markOpened(String contentApi) async {
    await _ensureLoaded();
    await _replace(
      _state.value.chapters.map((chapter) {
        if (chapter.contentApi != contentApi) {
          return chapter;
        }
        return chapter.copyWith(lastOpenedAt: DateTime.now().toUtc());
      }).toList(growable: false),
    );
  }

  Future<void> _ensureLoaded() async {
    if (_state.value.chapters.isEmpty) {
      await load();
    }
  }

  Future<void> _replace(List<DownloadedChapter> chapters) async {
    _state.value = DownloadsState(chapters: chapters);
    await _store.writeChapters(chapters);
  }
}

String _preview(String html) {
  final text = html.replaceAll(RegExp('<[^>]+>'), ' ').trim();
  return text.length <= 90 ? text : text.substring(0, 90);
}
```

- [ ] **Step 6: Run repository tests and verify pass**

Run:

```powershell
flutter test test\data\stored_downloads_repository_test.dart
```

Expected: all tests pass.

- [ ] **Step 7: Commit Task 2**

Run:

```powershell
git add lib/data/repositories/local_download_store.dart lib/data/repositories/shared_preferences_download_store.dart lib/data/repositories/stored_downloads_repository.dart test/data/stored_downloads_repository_test.dart
git commit -m "feat: persist downloaded chapters"
```

---

## Task 3: Dependency Injection And Fake Repository

**Files:**

- Create: `lib/data/repositories/fake_downloads_repository.dart`
- Modify: `lib/app/app_dependencies.dart`
- Modify: `lib/app/galaxy_novels_app.dart`
- Modify tests that construct `AppDependencies`

- [ ] **Step 1: Add fake repository**

Create `lib/data/repositories/fake_downloads_repository.dart`:

```dart
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
```

- [ ] **Step 2: Modify `AppDependencies`**

Add import:

```dart
import '../data/repositories/downloads_repository.dart';
```

Add constructor parameter and field:

```dart
required this.downloadsRepository,
```

```dart
final DownloadsRepository downloadsRepository;
```

Add to `updateShouldNotify`:

```dart
downloadsRepository != oldWidget.downloadsRepository ||
```

- [ ] **Step 3: Modify `GalaxyNovelsApp`**

Add imports:

```dart
import '../data/repositories/downloads_repository.dart';
import '../data/repositories/shared_preferences_download_store.dart';
import '../data/repositories/stored_downloads_repository.dart';
```

Add optional field:

```dart
this.downloadsRepository,
```

```dart
final DownloadsRepository? downloadsRepository;
```

Create effective repository after `effectiveReaderRepository`:

```dart
final effectiveDownloadsRepository =
    downloadsRepository ??
    StoredDownloadsRepository(
      store: const SharedPreferencesDownloadStore(),
      readerRepository: effectiveReaderRepository,
    );
```

Pass to `AppDependencies`:

```dart
downloadsRepository: effectiveDownloadsRepository,
```

- [ ] **Step 4: Update tests that manually create `AppDependencies`**

For every `AppDependencies(` in tests, add:

```dart
downloadsRepository: FakeDownloadsRepository(),
```

and import:

```dart
import 'package:galaxy_novels_app/data/repositories/fake_downloads_repository.dart';
```

Use:

```powershell
rg -n "AppDependencies\\(" test lib
```

Expected after edits: all manual test wrappers include `downloadsRepository`.

- [ ] **Step 5: Run focused compile checks**

Run:

```powershell
flutter test test\features\history\history_screen_test.dart test\features\reader\reader_screen_test.dart
```

Expected: passes.

- [ ] **Step 6: Commit Task 3**

Run:

```powershell
git add lib/app/app_dependencies.dart lib/app/galaxy_novels_app.dart lib/data/repositories/fake_downloads_repository.dart test
git commit -m "feat: wire downloads repository"
```

---

## Task 4: Downloads Tab And Screen

**Files:**

- Create: `lib/features/downloads/presentation/downloads_screen.dart`
- Modify: `lib/features/shell/presentation/app_shell.dart`
- Test: `test/features/downloads/downloads_screen_test.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write failing downloads screen test**

Create `test/features/downloads/downloads_screen_test.dart` with a wrapper using fake repositories and one downloaded chapter. Assert:

```dart
expect(find.text('التنزيلات'), findsWidgets);
expect(find.text('1 / 100 فصل محمل'), findsOneWidget);
expect(find.text('رواية الاختبار'), findsOneWidget);
expect(find.text('الفصل 1'), findsOneWidget);
```

- [ ] **Step 2: Add `DownloadsScreen`**

Create a screen that:

- Uses `AppDependencies.of(context).downloadsRepository`.
- Calls `load()` once in `didChangeDependencies`.
- Uses `ValueListenableBuilder<DownloadsState>`.
- Shows empty state when no chapters exist.
- Groups chapters by `novelId`.
- Shows count as `X / 100 فصل محمل`.

Core grouping code:

```dart
Map<int, List<DownloadedChapter>> _groupByNovel(
  List<DownloadedChapter> chapters,
) {
  final grouped = <int, List<DownloadedChapter>>{};
  for (final chapter in chapters) {
    grouped.putIfAbsent(chapter.novelId, () => []).add(chapter);
  }
  return grouped;
}
```

- [ ] **Step 3: Add tab to `AppShell`**

Import:

```dart
import '../../downloads/presentation/downloads_screen.dart';
```

Update screens:

```dart
static const _screens = [
  HomeScreen(),
  CatalogScreen(),
  DownloadsScreen(),
  HistoryScreen(),
  RankingsScreen(),
];
```

Update titles:

```dart
static const _titles = ['الرئيسية', 'المكتبة', 'التنزيلات', 'السجل', 'الترتيب'];
```

Add navigation destination between library and history:

```dart
NavigationDestination(
  icon: Icon(Icons.download_outlined),
  selectedIcon: Icon(Icons.download),
  label: 'التنزيلات',
),
```

- [ ] **Step 4: Update shell/widget tests**

In `test/widget_test.dart`, add expectation for bottom navigation:

```dart
expect(find.text('التنزيلات'), findsOneWidget);
```

If existing tests tap by index, update indexes after inserting the new tab.

- [ ] **Step 5: Run screen tests**

Run:

```powershell
flutter test test\features\downloads\downloads_screen_test.dart test\widget_test.dart --plain-name "shows Galaxy Novels Arabic shell"
```

Expected: passes.

- [ ] **Step 6: Commit Task 4**

Run:

```powershell
git add lib/features/downloads/presentation/downloads_screen.dart lib/features/shell/presentation/app_shell.dart test/features/downloads/downloads_screen_test.dart test/widget_test.dart
git commit -m "feat: add downloads tab"
```

---

## Task 5: Individual Chapter Download Button

**Files:**

- Create: `lib/features/downloads/presentation/chapter_download_button.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_chapter_tile.dart`
- Modify: `lib/features/novel_details/presentation/novel_details_screen.dart`
- Test: `test/features/novel_details/novel_details_widgets_test.dart`

- [ ] **Step 1: Extend `NovelChapterTile` API**

Add optional parameter:

```dart
final Widget? trailingAction;
```

Constructor:

```dart
this.trailingAction,
```

Render before chevron:

```dart
if (trailingAction != null) ...[
  trailingAction!,
  const SizedBox(width: 8),
],
```

- [ ] **Step 2: Create `ChapterDownloadButton`**

The button accepts:

```dart
const ChapterDownloadButton({
  required this.isDownloaded,
  required this.isEnabled,
  required this.onPressed,
  super.key,
});
```

Use icons:

- downloaded: `Icons.download_done`
- enabled: `Icons.download_outlined`
- disabled: `Icons.block`

Tooltips:

- `محمل`
- `تحميل الفصل`
- `غير متاح للتحميل`

- [ ] **Step 3: Wire individual downloads in details**

In `_ChaptersSection`, read `downloadsRepository` and pass a trailing button to each `NovelChapterTile`.

The button calls:

```dart
downloadsRepository.downloadChapter(
  ChapterDownloadRequest(
    novelId: result.details.id,
    novelTitle: result.details.title,
    novelCover: result.details.bestCover,
    chapter: chapter,
  ),
);
```

If `DownloadLimitExceededException` is thrown, show:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('وصلت إلى حد 100 فصل محمل')),
);
```

- [ ] **Step 4: Add widget test**

Update `test/features/novel_details/novel_details_widgets_test.dart` with:

```dart
testWidgets('chapter tile can show a download action', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: NovelChapterTile(
            chapter: _chapter,
            onTap: () {},
            trailingAction: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined),
            ),
          ),
        ),
      ),
    ),
  );

  expect(find.byIcon(Icons.download_outlined), findsOneWidget);
});
```

- [ ] **Step 5: Run tests**

Run:

```powershell
flutter test test\features\novel_details\novel_details_widgets_test.dart
```

Expected: passes.

- [ ] **Step 6: Commit Task 5**

Run:

```powershell
git add lib/features/downloads/presentation/chapter_download_button.dart lib/features/novel_details/presentation/widgets/novel_chapter_tile.dart lib/features/novel_details/presentation/novel_details_screen.dart test/features/novel_details/novel_details_widgets_test.dart
git commit -m "feat: add chapter download action"
```

---

## Task 6: Batch Download Selection Sheet

**Files:**

- Create: `lib/features/downloads/presentation/download_chapters_sheet.dart`
- Modify: `lib/features/novel_details/presentation/novel_details_screen.dart`
- Test: `test/features/downloads/download_chapters_sheet_test.dart`

- [ ] **Step 1: Write failing sheet tests**

Test that the sheet:

- Shows novel title.
- Shows `0 محدد`.
- Has buttons `آخر 10 فصول`, `غير المحمل`, `إلغاء التحديد`, `تحميل`.
- Disables `تحميل` when selection is empty.
- Shows remaining limit text.

- [ ] **Step 2: Create `DownloadChaptersSheet`**

Constructor:

```dart
const DownloadChaptersSheet({
  required this.details,
  required this.chapters,
  required this.downloadsState,
  required this.onStart,
  super.key,
});
```

Callback:

```dart
final ValueChanged<List<NovelChapter>> onStart;
```

Selection rules:

- Tapping an unloaded chapter toggles selection.
- Downloaded chapters are disabled.
- `آخر 10 فصول` selects the first 10 unloaded items from the displayed latest list.
- `غير المحمل` selects unloaded chapters up to remaining slots.
- If selected count exceeds remaining slots, show warning and disable `تحميل`.

- [ ] **Step 3: Add button to details page**

In `_ChaptersSection`, add a small action to `SectionTitle`:

```dart
FilledButton.tonalIcon(
  onPressed: chapters.isEmpty ? null : () => _openDownloadSheet(context),
  icon: const Icon(Icons.download_outlined),
  label: const Text('تحميل الفصول'),
)
```

`_openDownloadSheet` calls `showModalBottomSheet` with:

```dart
isScrollControlled: true,
useSafeArea: true,
```

- [ ] **Step 4: Start batch callback**

When the sheet returns selected chapters, convert to requests:

```dart
final requests = selected.map((chapter) {
  return ChapterDownloadRequest(
    novelId: details.id,
    novelTitle: details.title,
    novelCover: details.bestCover,
    chapter: chapter,
  );
}).toList(growable: false);
```

Pass those requests to the progress overlay in Task 7.

- [ ] **Step 5: Run sheet tests**

Run:

```powershell
flutter test test\features\downloads\download_chapters_sheet_test.dart
```

Expected: passes.

- [ ] **Step 6: Commit Task 6**

Run:

```powershell
git add lib/features/downloads/presentation/download_chapters_sheet.dart lib/features/novel_details/presentation/novel_details_screen.dart test/features/downloads/download_chapters_sheet_test.dart
git commit -m "feat: add batch download picker"
```

---

## Task 7: Floating Download Progress Overlay

**Files:**

- Create: `lib/features/downloads/presentation/download_progress_overlay.dart`
- Modify: `lib/features/novel_details/presentation/novel_details_screen.dart`
- Test: `test/features/downloads/download_progress_overlay_test.dart`

- [ ] **Step 1: Write failing overlay tests**

Assert:

```dart
expect(find.text('جاري تحميل 2 من 5'), findsOneWidget);
expect(find.byType(LinearProgressIndicator), findsOneWidget);
expect(find.text('رواية الاختبار'), findsOneWidget);
```

For complete state:

```dart
expect(find.text('اكتمل تحميل 5 فصل'), findsOneWidget);
expect(find.text('فتح التنزيلات'), findsOneWidget);
```

- [ ] **Step 2: Create `DownloadProgressOverlay`**

Constructor:

```dart
const DownloadProgressOverlay({
  required this.progress,
  required this.onDismiss,
  required this.onOpenDownloads,
  super.key,
});
```

Display:

- Cover thumbnail if `progress.novelCover.isNotEmpty`.
- Novel title.
- `LinearProgressIndicator(value: progress.fraction)`.
- State text:
  - active: `جاري تحميل ${progress.completed + progress.failed} من ${progress.total}`
  - complete success: `اكتمل تحميل ${progress.completed} فصل`
  - complete partial failure: `تم تحميل ${progress.completed} فصل، فشل ${progress.failed}`

- [ ] **Step 3: Host overlay from details**

In `NovelDetailsScreen`, add state:

```dart
DownloadBatchProgress? _downloadProgress;
StreamSubscription<DownloadBatchProgress>? _downloadSubscription;
```

Start batch:

```dart
void _startBatchDownload(List<ChapterDownloadRequest> requests) {
  _downloadSubscription?.cancel();
  final repository = AppDependencies.of(context).downloadsRepository;
  _downloadSubscription = repository.downloadChaptersBatch(requests).listen(
    (progress) {
      setState(() => _downloadProgress = progress);
    },
    onError: (Object error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر بدء التحميل')),
      );
    },
  );
}
```

Dispose:

```dart
@override
void dispose() {
  _downloadSubscription?.cancel();
  super.dispose();
}
```

Render overlay in the details `Stack` when `_downloadProgress != null`.

- [ ] **Step 4: Add open downloads behavior**

For this phase, `فتح التنزيلات` can pop the details page and let the user tap the downloads tab manually only if cross-tab control is not available. Prefer this simple behavior:

```dart
Navigator.of(context).pop();
```

Do not introduce a global navigation controller in this task.

- [ ] **Step 5: Run overlay tests**

Run:

```powershell
flutter test test\features\downloads\download_progress_overlay_test.dart
```

Expected: passes.

- [ ] **Step 6: Commit Task 7**

Run:

```powershell
git add lib/features/downloads/presentation/download_progress_overlay.dart lib/features/novel_details/presentation/novel_details_screen.dart test/features/downloads/download_progress_overlay_test.dart
git commit -m "feat: show batch download progress"
```

---

## Task 8: Reader Local-First Loading

**Files:**

- Modify: `lib/features/reader/presentation/reader_screen.dart`
- Test: `test/features/reader/reader_screen_test.dart`

- [ ] **Step 1: Write failing reader test**

Add a test that provides `FakeDownloadsRepository` with one chapter and a `ReaderRepository` that throws. Open `ReaderScreen(contentApi: '/chapters/1')`.

Expected:

```dart
expect(find.textContaining('نص محلي'), findsOneWidget);
```

The throwing network reader proves the content came from downloads.

- [ ] **Step 2: Modify reader loading order**

In `_load`, before network call:

```dart
final downloadsRepository = AppDependencies.of(context).downloadsRepository;
final downloadedContent =
    await downloadsRepository.findReaderContent(widget.contentApi);
if (downloadedContent != null) {
  await downloadsRepository.markOpened(widget.contentApi);
  _setLoadedContent(downloadedContent);
  return;
}
```

Keep the existing `ReaderRepository` path after that.

Extract the existing success state assignment into:

```dart
void _setLoadedContent(ReaderChapterContent content) {
  if (!mounted) {
    return;
  }
  setState(() {
    _content = content;
    _chapterTitle = content.effectiveTitle;
    _error = null;
  });
}
```

- [ ] **Step 3: Preserve reading history**

After local content loads, keep recording reading progress through existing `ReadingHistoryRepository.record`. This ensures local reading still updates history.

- [ ] **Step 4: Run reader tests**

Run:

```powershell
flutter test test\features\reader\reader_screen_test.dart
```

Expected: passes.

- [ ] **Step 5: Commit Task 8**

Run:

```powershell
git add lib/features/reader/presentation/reader_screen.dart test/features/reader/reader_screen_test.dart
git commit -m "feat: read downloaded chapters offline"
```

---

## Task 9: Full Verification And Polish

**Files:**

- Modify only files required by failing tests or analyzer.

- [ ] **Step 1: Run formatter**

Run:

```powershell
dart format lib test
```

Expected: completes without errors.

- [ ] **Step 2: Run analyzer**

Run:

```powershell
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 3: Run all tests**

Run:

```powershell
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Build debug APK**

Run:

```powershell
flutter build apk --debug
```

Expected:

```text
√ Built build\app\outputs\flutter-apk\app-debug.apk
```

- [ ] **Step 5: Manual phone QA**

Install the APK and verify:

1. Open a novel details page.
2. Download one chapter using the small button.
3. Open `التنزيلات` and confirm the novel appears.
4. Open the downloaded chapter.
5. Turn off internet.
6. Open the same chapter again.
7. Confirm the reader still displays native content.
8. Start a batch download.
9. Confirm the center progress overlay shows cover, title, and progress.
10. Try selecting more chapters than remaining slots and confirm the app blocks it.

- [ ] **Step 6: Commit final verification fixes**

If formatting or polish changed files:

```powershell
git add lib test
git commit -m "test: verify downloads workflow"
```

If there are no additional changes, do not create an empty commit.

---

## Self-Review Notes

- Spec coverage: individual downloads, batch sheet, 100 limit, downloads tab, floating progress overlay, and local-first reader are each mapped to tasks.
- Scope kept focused: no points, ads, login, sync, or background downloads.
- Storage choice: `SharedPreferences` is acceptable for the phase because the temporary limit is 100 chapters and the app already uses this dependency.
- Risk: storing many large chapters in `SharedPreferences` may become heavy later. The plan keeps `LocalDownloadStore` abstract so the store can move to files or SQLite without changing UI code.
- Test strategy: unit tests cover limit and persistence; widget tests cover screen/sheet/overlay; reader test proves offline local-first behavior.
