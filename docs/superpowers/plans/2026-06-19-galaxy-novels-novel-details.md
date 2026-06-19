# Galaxy Novels Novel Details Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the public novel details screen with real manifest-backed novel data, public chapter index loading, and navigation from home/catalog without implementing the WebView reader.

**Architecture:** Add focused novel details models and a `NovelRepository` that loads a novel manifest/pack and then attempts to load the public chapter manifest/pack. Inject the repository through `AppDependencies`, keep UI state local to `NovelDetailsScreen`, and add lightweight navigation callbacks to existing home/catalog tiles. Keep reader opening as a non-WebView placeholder action in this phase.

**Tech Stack:** Flutter, Dart, Material 3, existing `PublicCacheClient`, existing `BootstrapRepository` patterns, Flutter unit/widget tests.

---

## File Structure

- Modify: `galaxy_novels_app/lib/core/network/public_cache_client.dart`
- Create: `galaxy_novels_app/lib/data/models/novel_details_data.dart`
- Create: `galaxy_novels_app/lib/data/repositories/novel_repository.dart`
- Create: `galaxy_novels_app/lib/data/repositories/fake_novel_repository.dart`
- Create: `galaxy_novels_app/lib/data/repositories/public_novel_repository.dart`
- Modify: `galaxy_novels_app/lib/app/app_dependencies.dart`
- Modify: `galaxy_novels_app/lib/app/galaxy_novels_app.dart`
- Create: `galaxy_novels_app/lib/features/novel_details/presentation/novel_details_screen.dart`
- Create: `galaxy_novels_app/lib/features/novel_details/presentation/widgets/novel_details_header.dart`
- Create: `galaxy_novels_app/lib/features/novel_details/presentation/widgets/novel_chapter_tile.dart`
- Modify: `galaxy_novels_app/lib/features/catalog/presentation/widgets/catalog_novel_tile.dart`
- Modify: `galaxy_novels_app/lib/features/catalog/presentation/catalog_screen.dart`
- Modify: `galaxy_novels_app/lib/features/home/presentation/home_screen.dart`
- Test: `galaxy_novels_app/test/data/novel_details_data_test.dart`
- Test: `galaxy_novels_app/test/data/public_novel_repository_test.dart`
- Modify/Test: `galaxy_novels_app/test/widget_test.dart`

---

### Task 1: JSON Value Support For Chapter Packs

**Files:**
- Modify: `galaxy_novels_app/lib/core/network/public_cache_client.dart`
- Test: `galaxy_novels_app/test/core/public_cache_client_test.dart`

- [ ] **Step 1: Add tests for loading top-level JSON arrays**

Append this test to `galaxy_novels_app/test/core/public_cache_client_test.dart`:

```dart
test('loadJsonValue supports top-level arrays', () async {
  final client = PublicCacheClient(
    config: const AppConfig(siteBaseUrl: 'https://example.com/'),
    jsonGet: (uri, headers) async {
      expect(uri.toString(), 'https://example.com/chapters.json');
      expect(headers['Accept'], 'application/json');
      return [
        {'id': 1, 'label': 'الفصل 1'},
      ];
    },
  );

  final value = await client.loadJsonValue('/chapters.json');

  expect(value, isA<List<Object?>>());
  expect((value as List).single, isA<Map<String, dynamic>>());
});
```

- [ ] **Step 2: Run the focused test and confirm failure**

Run:

```powershell
Set-Location .\galaxy_novels_app
flutter test test/core/public_cache_client_test.dart
```

Expected: fails because `loadJsonValue` does not exist and `JsonGet` currently only models map responses.

- [ ] **Step 3: Extend `PublicCacheClient` without breaking `loadJson`**

Update `galaxy_novels_app/lib/core/network/public_cache_client.dart` so the public API contains:

```dart
typedef JsonGet =
    Future<Object?> Function(Uri uri, Map<String, String> headers);

class PublicCacheClient {
  PublicCacheClient({required this.config, JsonGet? jsonGet})
    : _jsonGet = jsonGet ?? _defaultJsonGet;

  final AppConfig config;
  final JsonGet _jsonGet;

  Map<String, String> get publicJsonHeaders => {
    'Accept': 'application/json',
    'User-Agent': config.userAgent,
  };

  Future<Object?> loadJsonValue(String urlOrPath) {
    return _jsonGet(config.resolve(urlOrPath), publicJsonHeaders);
  }

  Future<Map<String, dynamic>> loadJson(String urlOrPath) async {
    final value = await loadJsonValue(urlOrPath);
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    throw PublicCacheException(
      'GET ${config.resolve(urlOrPath)} did not return a JSON object.',
    );
  }

  Future<Map<String, dynamic>> loadPackFromManifest(String manifestPath) async {
    final manifest = await loadJson(manifestPath);
    final packPath = _readPackPath(manifest);
    return loadJson(packPath);
  }

  static Future<Object?> _defaultJsonGet(
    Uri uri,
    Map<String, String> headers,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers.forEach(request.headers.set);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PublicCacheException(
          'GET $uri failed with HTTP ${response.statusCode}.',
        );
      }

      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }
}
```

Keep the existing `_readPackPath` and `PublicCacheException` logic. Do not change existing method names used by home/catalog.

- [ ] **Step 4: Run the focused test**

Run:

```powershell
flutter test test/core/public_cache_client_test.dart
```

Expected: all public cache client tests pass.

- [ ] **Step 5: Commit**

```powershell
git add galaxy_novels_app/lib/core/network/public_cache_client.dart galaxy_novels_app/test/core/public_cache_client_test.dart
git commit -m "feat: support public JSON array payloads"
```

---

### Task 2: Novel Details Models

**Files:**
- Create: `galaxy_novels_app/lib/data/models/novel_details_data.dart`
- Test: `galaxy_novels_app/test/data/novel_details_data_test.dart`

- [ ] **Step 1: Write model tests**

Create `galaxy_novels_app/test/data/novel_details_data_test.dart` with tests for:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';

void main() {
  test('parses novel details data from pack data', () {
    final details = NovelDetails.fromJson({
      'id': 120429,
      'title': 'إمبراطوريتي البريطانية',
      'original_title': 'My British Empire',
      'url': '/novel/my-british-empire/',
      'cover': {
        'thumbnail': '/thumb.webp',
        'medium': '/medium.webp',
        'large': '/large.webp',
      },
      'status': {'key': 'ongoing', 'label': 'مستمرة'},
      'country': 'cn',
      'author': 'Fei Tian Lan Che',
      'translator': 'ISRAWATAN',
      'genres': [
        {'id': 8, 'name': 'تاريخي', 'slug': 'history'},
      ],
      'chapters_count': 127,
      'first_chapter_id': 122597,
      'first_chapter_url': '/chapter-1/',
      'rating': {'average': 4.5, 'count': 12},
      'stats': {'views': 525},
      'updated_at': '2026-06-16T12:12:29+03:00',
      'summary': 'ملخص طويل للرواية',
      'links': {
        'chapters_manifest': '/chapters/manifest.json',
        'vip_schedule_manifest': '/vip/manifest.json',
      },
      'manifest': '/novel-manifest.json',
    });

    expect(details.id, 120429);
    expect(details.title, 'إمبراطوريتي البريطانية');
    expect(details.originalTitle, 'My British Empire');
    expect(details.coverLarge, '/large.webp');
    expect(details.statusLabel, 'مستمرة');
    expect(details.author, 'Fei Tian Lan Che');
    expect(details.translator, 'ISRAWATAN');
    expect(details.genres.single.name, 'تاريخي');
    expect(details.chaptersCount, 127);
    expect(details.firstChapterUrl, '/chapter-1/');
    expect(details.ratingAverage, 4.5);
    expect(details.ratingCount, 12);
    expect(details.views, 525);
    expect(details.summary, 'ملخص طويل للرواية');
    expect(details.chaptersManifest, '/chapters/manifest.json');
  });

  test('parses chapter manifest pack url', () {
    final manifest = ChapterManifest.fromJson({
      'novel_id': 120429,
      'total': 127,
      'latest_id': 122723,
      'latest_number': '127',
      'pack_url': 'https://example.com/chapters.json',
    });

    expect(manifest.novelId, 120429);
    expect(manifest.total, 127);
    expect(manifest.latestNumber, '127');
    expect(manifest.packUrl, 'https://example.com/chapters.json');
  });

  test('parses chapter pack object with chapters field', () {
    final pack = ChapterPack.fromJsonValue({
      'total': 2,
      'chapters': [
        {
          'id': 1,
          'position': 1,
          'number': '1',
          'label': 'الفصل 1',
          'title': 'البداية',
          'url': 'https://example.com/chapter-1/',
          'date': 'يونيو 17, 2026',
          'date_iso': '2026-06-18T00:14:09+03:00',
          'views': 7,
          'comments': 2,
          'search': '1 الفصل 1 البداية',
        },
      ],
    });

    expect(pack.total, 2);
    expect(pack.chapters.single.id, 1);
    expect(pack.chapters.single.displayTitle, 'البداية');
    expect(pack.chapters.single.dateLabel, 'يونيو 17, 2026');
  });

  test('parses chapter pack top-level array', () {
    final pack = ChapterPack.fromJsonValue([
      {'id': 5, 'position': 5, 'label': 'الفصل 5', 'url': '/chapter-5/'},
    ]);

    expect(pack.total, 1);
    expect(pack.chapters.single.position, 5);
    expect(pack.chapters.single.label, 'الفصل 5');
  });

  test('uses safe defaults for missing fields', () {
    final details = NovelDetails.fromJson({'id': 7, 'title': 'ناقصة'});
    final chapter = NovelChapter.fromJson({'id': 1});

    expect(details.title, 'ناقصة');
    expect(details.coverLarge, '');
    expect(details.genres, isEmpty);
    expect(details.chaptersManifest, '');
    expect(chapter.label, '');
    expect(chapter.displayTitle, '');
    expect(chapter.url, '');
  });
}
```

- [ ] **Step 2: Run failing model tests**

Run:

```powershell
flutter test test/data/novel_details_data_test.dart
```

Expected: fails because the model file does not exist.

- [ ] **Step 3: Implement model classes**

Create `galaxy_novels_app/lib/data/models/novel_details_data.dart` with:

```dart
class NovelDetails {
  const NovelDetails({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.url,
    required this.coverThumbnail,
    required this.coverMedium,
    required this.coverLarge,
    required this.statusKey,
    required this.statusLabel,
    required this.country,
    required this.author,
    required this.translator,
    required this.genres,
    required this.chaptersCount,
    required this.firstChapterId,
    required this.firstChapterUrl,
    required this.ratingAverage,
    required this.ratingCount,
    required this.views,
    required this.updatedAt,
    required this.summary,
    required this.chaptersManifest,
    required this.vipScheduleManifest,
    required this.manifest,
  });

  factory NovelDetails.fromJson(Map<String, dynamic> json) {
    final cover = _asMap(json['cover']);
    final status = _asMap(json['status']);
    final rating = _asMap(json['rating']);
    final stats = _asMap(json['stats']);
    final links = _asMap(json['links']);

    return NovelDetails(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      originalTitle: _asString(json['original_title']),
      url: _asString(json['url']),
      coverThumbnail: _asString(cover['thumbnail']),
      coverMedium: _asString(cover['medium']),
      coverLarge: _asString(cover['large']),
      statusKey: _asString(status['key']),
      statusLabel: _asString(status['label']),
      country: _asString(json['country']),
      author: _asString(json['author']),
      translator: _asString(json['translator']),
      genres: _asList(json['genres'])
          .map((genre) => NovelGenre.fromJson(_asMap(genre)))
          .where((genre) => genre.name.isNotEmpty)
          .toList(growable: false),
      chaptersCount: _asInt(json['chapters_count']),
      firstChapterId: _asInt(json['first_chapter_id']),
      firstChapterUrl: _asString(json['first_chapter_url']),
      ratingAverage: _asDouble(rating['average']),
      ratingCount: _asInt(rating['count']),
      views: _asInt(stats['views']),
      updatedAt: _asDateTime(json['updated_at']),
      summary: _asString(json['summary']),
      chaptersManifest: _asString(links['chapters_manifest']),
      vipScheduleManifest: _asString(links['vip_schedule_manifest']),
      manifest: _asString(json['manifest']),
    );
  }

  final int id;
  final String title;
  final String originalTitle;
  final String url;
  final String coverThumbnail;
  final String coverMedium;
  final String coverLarge;
  final String statusKey;
  final String statusLabel;
  final String country;
  final String author;
  final String translator;
  final List<NovelGenre> genres;
  final int chaptersCount;
  final int firstChapterId;
  final String firstChapterUrl;
  final double ratingAverage;
  final int ratingCount;
  final int views;
  final DateTime? updatedAt;
  final String summary;
  final String chaptersManifest;
  final String vipScheduleManifest;
  final String manifest;

  String get bestCover =>
      coverLarge.isNotEmpty ? coverLarge : coverMedium.isNotEmpty ? coverMedium : coverThumbnail;
}

class NovelGenre {
  const NovelGenre({required this.id, required this.name, required this.slug});

  factory NovelGenre.fromJson(Map<String, dynamic> json) {
    return NovelGenre(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
    );
  }

  final int id;
  final String name;
  final String slug;
}

class ChapterManifest {
  const ChapterManifest({
    required this.novelId,
    required this.total,
    required this.latestId,
    required this.latestNumber,
    required this.packUrl,
  });

  factory ChapterManifest.fromJson(Map<String, dynamic> json) {
    final packUrl = _asString(json['pack_url']);
    final pack = _asString(json['pack']);
    return ChapterManifest(
      novelId: _asInt(json['novel_id']),
      total: _asInt(json['total']),
      latestId: _asInt(json['latest_id']),
      latestNumber: _asString(json['latest_number']),
      packUrl: packUrl.isNotEmpty ? packUrl : pack,
    );
  }

  final int novelId;
  final int total;
  final int latestId;
  final String latestNumber;
  final String packUrl;
}

class ChapterPack {
  const ChapterPack({required this.total, required this.chapters});

  factory ChapterPack.fromJsonValue(Object? value) {
    if (value is List) {
      final chapters = value
          .map((item) => NovelChapter.fromJson(_asMap(item)))
          .where((chapter) => chapter.id != 0 || chapter.url.isNotEmpty)
          .toList(growable: false);
      return ChapterPack(total: chapters.length, chapters: chapters);
    }

    final json = _asMap(value);
    final chapters = _asList(json['chapters'])
        .map((item) => NovelChapter.fromJson(_asMap(item)))
        .where((chapter) => chapter.id != 0 || chapter.url.isNotEmpty)
        .toList(growable: false);

    return ChapterPack(total: _asInt(json['total']), chapters: chapters);
  }

  final int total;
  final List<NovelChapter> chapters;
}

class NovelChapter {
  const NovelChapter({
    required this.id,
    required this.position,
    required this.number,
    required this.label,
    required this.title,
    required this.url,
    required this.dateLabel,
    required this.dateIso,
    required this.views,
    required this.comments,
    required this.search,
  });

  factory NovelChapter.fromJson(Map<String, dynamic> json) {
    return NovelChapter(
      id: _asInt(json['id']),
      position: _asInt(json['position']),
      number: _asString(json['number']),
      label: _asString(json['label']),
      title: _asString(json['title']),
      url: _asString(json['url']),
      dateLabel: _asString(json['date']),
      dateIso: _asDateTime(json['date_iso']),
      views: _asInt(json['views']),
      comments: _asInt(json['comments']),
      search: _asString(json['search']),
    );
  }

  final int id;
  final int position;
  final String number;
  final String label;
  final String title;
  final String url;
  final String dateLabel;
  final DateTime? dateIso;
  final int views;
  final int comments;
  final String search;

  String get displayTitle => title.isNotEmpty ? title : _titleFromSearch(search, label);
}
```

Add helpers in the same file: `_asMap`, `_asList`, `_asString`, `_asInt`, `_asDouble`, `_asDateTime`, and `_titleFromSearch`. Use the same defensive parsing pattern as `catalog_data.dart`.

- [ ] **Step 4: Fix formatting issues in the model implementation**

Run:

```powershell
dart format lib/data/models/novel_details_data.dart test/data/novel_details_data_test.dart
```

Expected: formatter completes.

- [ ] **Step 5: Run model tests**

Run:

```powershell
flutter test test/data/novel_details_data_test.dart
```

Expected: all model tests pass.

- [ ] **Step 6: Commit**

```powershell
git add galaxy_novels_app/lib/data/models/novel_details_data.dart galaxy_novels_app/test/data/novel_details_data_test.dart
git commit -m "feat: add novel details data models"
```

---

### Task 3: Novel Repository

**Files:**
- Create: `galaxy_novels_app/lib/data/repositories/novel_repository.dart`
- Create: `galaxy_novels_app/lib/data/repositories/public_novel_repository.dart`
- Create: `galaxy_novels_app/lib/data/repositories/fake_novel_repository.dart`
- Test: `galaxy_novels_app/test/data/public_novel_repository_test.dart`

- [ ] **Step 1: Write repository tests**

Create `galaxy_novels_app/test/data/public_novel_repository_test.dart` with tests that fake `PublicCacheClient`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/public_cache_client.dart';
import 'package:galaxy_novels_app/data/repositories/public_novel_repository.dart';

void main() {
  test('loads novel details then chapter pack', () async {
    final client = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        if (uri.path.endsWith('/novel-1.json')) {
          return {'pack': '/packs/novel-1-pack.json', 'novel_id': 1};
        }
        if (uri.path.endsWith('/packs/novel-1-pack.json')) {
          return {
            'data': {
              'id': 1,
              'title': 'رواية كاملة',
              'summary': 'ملخص',
              'first_chapter_url': '/chapter-1/',
              'links': {'chapters_manifest': '/chapters/manifest-1.json'},
            },
          };
        }
        if (uri.path.endsWith('/chapters/manifest-1.json')) {
          return {'total': 1, 'pack_url': 'https://example.com/chapters/pack-1.json'};
        }
        if (uri.path.endsWith('/chapters/pack-1.json')) {
          return {
            'total': 1,
            'chapters': [
              {'id': 10, 'position': 1, 'label': 'الفصل 1', 'url': '/chapter-1/'},
            ],
          };
        }
        throw PublicCacheException('Unexpected $uri');
      },
    );

    final repository = PublicNovelRepository(cacheClient: client);
    final result = await repository.loadNovel('/novel-1.json');

    expect(result.details.title, 'رواية كاملة');
    expect(result.chapters, hasLength(1));
    expect(result.chaptersError, isNull);
  });

  test('keeps details visible when chapter loading fails', () async {
    final client = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        if (uri.path.endsWith('/novel-1.json')) {
          return {'pack': '/novel-pack.json'};
        }
        if (uri.path.endsWith('/novel-pack.json')) {
          return {
            'data': {
              'id': 1,
              'title': 'رواية بدون فصول',
              'links': {'chapters_manifest': '/chapters.json'},
            },
          };
        }
        throw const PublicCacheException('chapters failed');
      },
    );

    final repository = PublicNovelRepository(cacheClient: client);
    final result = await repository.loadNovel('/novel-1.json');

    expect(result.details.title, 'رواية بدون فصول');
    expect(result.chapters, isEmpty);
    expect(result.chaptersError, contains('chapters failed'));
  });

  test('returns empty chapters when no chapters manifest exists', () async {
    final client = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        if (uri.path.endsWith('/novel-1.json')) {
          return {'pack': '/novel-pack.json'};
        }
        return {
          'data': {'id': 1, 'title': 'رواية جديدة'},
        };
      },
    );

    final repository = PublicNovelRepository(cacheClient: client);
    final result = await repository.loadNovel('/novel-1.json');

    expect(result.details.title, 'رواية جديدة');
    expect(result.chapters, isEmpty);
    expect(result.chaptersError, isNull);
  });
}
```

- [ ] **Step 2: Run failing repository tests**

Run:

```powershell
flutter test test/data/public_novel_repository_test.dart
```

Expected: fails because repository files do not exist.

- [ ] **Step 3: Create repository contracts**

Create `galaxy_novels_app/lib/data/repositories/novel_repository.dart`:

```dart
import '../models/novel_details_data.dart';

abstract interface class NovelRepository {
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath);
}

class NovelDetailsLoadResult {
  const NovelDetailsLoadResult({
    required this.details,
    required this.chapters,
    this.chaptersError,
  });

  final NovelDetails details;
  final List<NovelChapter> chapters;
  final String? chaptersError;

  bool get hasReadableChapter =>
      chapters.isNotEmpty || details.firstChapterUrl.isNotEmpty;
}
```

- [ ] **Step 4: Implement public repository**

Create `galaxy_novels_app/lib/data/repositories/public_novel_repository.dart`:

```dart
import '../../core/network/public_cache_client.dart';
import '../models/novel_details_data.dart';
import 'novel_repository.dart';

class PublicNovelRepository implements NovelRepository {
  const PublicNovelRepository({required PublicCacheClient cacheClient})
    : _cacheClient = cacheClient;

  final PublicCacheClient _cacheClient;

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    if (manifestPath.isEmpty) {
      throw const PublicCacheException('Novel manifest path is empty.');
    }

    final novelPack = await _cacheClient.loadPackFromManifest(manifestPath);
    final details = NovelDetails.fromJson(_asMap(novelPack['data']));

    if (details.chaptersManifest.isEmpty) {
      return NovelDetailsLoadResult(details: details, chapters: const []);
    }

    try {
      final chapterManifestJson = await _cacheClient.loadJson(
        details.chaptersManifest,
      );
      final chapterManifest = ChapterManifest.fromJson(chapterManifestJson);
      if (chapterManifest.packUrl.isEmpty) {
        return NovelDetailsLoadResult(details: details, chapters: const []);
      }

      final chapterPackValue = await _cacheClient.loadJsonValue(
        chapterManifest.packUrl,
      );
      final chapterPack = ChapterPack.fromJsonValue(chapterPackValue);
      return NovelDetailsLoadResult(
        details: details,
        chapters: chapterPack.chapters,
      );
    } on Object catch (error) {
      return NovelDetailsLoadResult(
        details: details,
        chapters: const [],
        chaptersError: error.toString(),
      );
    }
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}
```

- [ ] **Step 5: Create fake repository**

Create `galaxy_novels_app/lib/data/repositories/fake_novel_repository.dart`:

```dart
import '../models/novel_details_data.dart';
import 'novel_repository.dart';

class FakeNovelRepository implements NovelRepository {
  const FakeNovelRepository({required this.result, this.error});

  final NovelDetailsLoadResult? result;
  final Object? error;

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    final thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    return result ??
        const NovelDetailsLoadResult(
          details: NovelDetails(
            id: 0,
            title: 'رواية تجريبية',
            originalTitle: '',
            url: '',
            coverThumbnail: '',
            coverMedium: '',
            coverLarge: '',
            statusKey: '',
            statusLabel: '',
            country: '',
            author: '',
            translator: '',
            genres: [],
            chaptersCount: 0,
            firstChapterId: 0,
            firstChapterUrl: '',
            ratingAverage: 0,
            ratingCount: 0,
            views: 0,
            updatedAt: null,
            summary: '',
            chaptersManifest: '',
            vipScheduleManifest: '',
            manifest: '',
          ),
          chapters: [],
        );
  }
}
```

- [ ] **Step 6: Run repository tests**

Run:

```powershell
flutter test test/data/public_novel_repository_test.dart
```

Expected: all repository tests pass.

- [ ] **Step 7: Commit**

```powershell
git add galaxy_novels_app/lib/data/repositories/novel_repository.dart galaxy_novels_app/lib/data/repositories/public_novel_repository.dart galaxy_novels_app/lib/data/repositories/fake_novel_repository.dart galaxy_novels_app/test/data/public_novel_repository_test.dart
git commit -m "feat: add novel details repository"
```

---

### Task 4: Dependency Injection

**Files:**
- Modify: `galaxy_novels_app/lib/app/app_dependencies.dart`
- Modify: `galaxy_novels_app/lib/app/galaxy_novels_app.dart`
- Modify/Test: `galaxy_novels_app/test/widget_test.dart`

- [ ] **Step 1: Update app constructor usage in tests**

In `test/widget_test.dart`, add `novelRepository: const _TestNovelRepository(),` to each `GalaxyNovelsApp(...)` pump. Add imports:

```dart
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';
```

Add test fake:

```dart
class _TestNovelRepository implements NovelRepository {
  const _TestNovelRepository();

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    return const NovelDetailsLoadResult(
      details: NovelDetails(
        id: 99,
        title: 'تفاصيل الاختبار',
        originalTitle: 'Test Details',
        url: '/novel/details-test/',
        coverThumbnail: '',
        coverMedium: '',
        coverLarge: '',
        statusKey: 'ongoing',
        statusLabel: 'مستمرة',
        country: 'cn',
        author: 'كاتب الاختبار',
        translator: '',
        genres: [NovelGenre(id: 1, name: 'أكشن', slug: 'action')],
        chaptersCount: 2,
        firstChapterId: 1,
        firstChapterUrl: '/chapter-1/',
        ratingAverage: 4.2,
        ratingCount: 5,
        views: 120,
        updatedAt: null,
        summary: 'هذه نبذة تفاصيل الاختبار.',
        chaptersManifest: '/chapters.json',
        vipScheduleManifest: '',
        manifest: '/novel-test.json',
      ),
      chapters: [
        NovelChapter(
          id: 1,
          position: 1,
          number: '1',
          label: 'الفصل 1',
          title: 'البداية',
          url: '/chapter-1/',
          dateLabel: 'اليوم',
          dateIso: null,
          views: 0,
          comments: 0,
          search: '',
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Run widget tests and confirm failure**

Run:

```powershell
flutter test test/widget_test.dart
```

Expected: fails because `GalaxyNovelsApp` and `AppDependencies` do not accept `NovelRepository`.

- [ ] **Step 3: Inject `NovelRepository`**

Update `app_dependencies.dart`:

```dart
import '../data/repositories/novel_repository.dart';

class AppDependencies extends InheritedWidget {
  const AppDependencies({
    required this.config,
    required this.homeRepository,
    required this.catalogRepository,
    required this.novelRepository,
    required super.child,
    super.key,
  });

  final AppConfig config;
  final HomeRepository homeRepository;
  final CatalogRepository catalogRepository;
  final NovelRepository novelRepository;

  @override
  bool updateShouldNotify(AppDependencies oldWidget) {
    return config != oldWidget.config ||
        homeRepository != oldWidget.homeRepository ||
        catalogRepository != oldWidget.catalogRepository ||
        novelRepository != oldWidget.novelRepository;
  }
}
```

Update `galaxy_novels_app.dart`:

```dart
import '../data/repositories/novel_repository.dart';
import '../data/repositories/public_novel_repository.dart';

class GalaxyNovelsApp extends StatelessWidget {
  const GalaxyNovelsApp({
    AppConfig? config,
    this.homeRepository,
    this.catalogRepository,
    this.novelRepository,
    super.key,
  }) : config = config ?? const AppConfig();

  final NovelRepository? novelRepository;
}
```

Inside `build`, create:

```dart
final effectiveNovelRepository =
    novelRepository ?? PublicNovelRepository(cacheClient: cacheClient);
```

Pass `novelRepository: effectiveNovelRepository` into `AppDependencies`.

- [ ] **Step 4: Run widget tests**

Run:

```powershell
flutter test test/widget_test.dart
```

Expected: existing widget tests pass with injected fake novel repository.

- [ ] **Step 5: Commit**

```powershell
git add galaxy_novels_app/lib/app/app_dependencies.dart galaxy_novels_app/lib/app/galaxy_novels_app.dart galaxy_novels_app/test/widget_test.dart
git commit -m "feat: inject novel details repository"
```

---

### Task 5: Details UI Components

**Files:**
- Create: `galaxy_novels_app/lib/features/novel_details/presentation/widgets/novel_details_header.dart`
- Create: `galaxy_novels_app/lib/features/novel_details/presentation/widgets/novel_chapter_tile.dart`

- [ ] **Step 1: Create header widget**

Create `novel_details_header.dart` with:

```dart
import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../data/models/novel_details_data.dart';

class NovelDetailsHeader extends StatelessWidget {
  const NovelDetailsHeader({required this.details, super.key});

  final NovelDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      if (details.author.isNotEmpty) 'المؤلف: ${details.author}',
      if (details.translator.isNotEmpty) 'المترجم: ${details.translator}',
      if (details.statusLabel.isNotEmpty) details.statusLabel,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          SizedBox(
            width: 150,
            height: 224,
            child: _NovelCover(title: details.title, url: details.bestCover),
          ),
          const SizedBox(height: 16),
          Text(
            details.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          if (details.originalTitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              details.originalTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              meta,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _StatsRow(details: details),
        ],
      ),
    );
  }
}
```

Add `_StatsRow`, `_StatItem`, `_NovelCover`, `_CoverFallback`, and `_resolveImageUrl` in the same file. Use fixed stat item height `72`, border radius `8`, and `theme.dividerColor` for borders.

- [ ] **Step 2: Create chapter tile**

Create `novel_chapter_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../data/models/novel_details_data.dart';

class NovelChapterTile extends StatelessWidget {
  const NovelChapterTile({required this.chapter, required this.onTap, super.key});

  final NovelChapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: SizedBox(
            minHeight: 64,
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Text(
                    chapter.number.isNotEmpty ? chapter.number : '${chapter.position}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.label.isNotEmpty ? chapter.label : 'فصل',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (chapter.displayTitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            chapter.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        if (chapter.dateLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            chapter.dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_left, size: 22),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Format component files**

Run:

```powershell
dart format lib/features/novel_details/presentation/widgets
```

Expected: formatter completes.

- [ ] **Step 4: Commit**

```powershell
git add galaxy_novels_app/lib/features/novel_details/presentation/widgets/novel_details_header.dart galaxy_novels_app/lib/features/novel_details/presentation/widgets/novel_chapter_tile.dart
git commit -m "feat: add novel details UI components"
```

---

### Task 6: Details Screen

**Files:**
- Create: `galaxy_novels_app/lib/features/novel_details/presentation/novel_details_screen.dart`
- Modify/Test: `galaxy_novels_app/test/widget_test.dart`

- [ ] **Step 1: Add widget tests for details screen states**

Add tests to `test/widget_test.dart`:

```dart
testWidgets('novel details screen renders details and chapters', (tester) async {
  await tester.pumpWidget(
    GalaxyNovelsApp(
      homeRepository: _TestHomeRepository(_homeData),
      catalogRepository: const _TestCatalogRepository(),
      novelRepository: const _TestNovelRepository(),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('المكتبة'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('مكتبة الاختبار'));
  await tester.pumpAndSettle();

  expect(find.text('تفاصيل الاختبار'), findsOneWidget);
  expect(find.text('هذه نبذة تفاصيل الاختبار.'), findsOneWidget);
  expect(find.text('الفصل 1'), findsOneWidget);
  expect(find.text('ابدأ القراءة'), findsOneWidget);
});

testWidgets('novel details screen shows empty chapters state', (tester) async {
  await tester.pumpWidget(
    GalaxyNovelsApp(
      homeRepository: _TestHomeRepository(_homeData),
      catalogRepository: const _TestCatalogRepository(),
      novelRepository: const _EmptyNovelRepository(),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('المكتبة'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('مكتبة الاختبار'));
  await tester.pumpAndSettle();

  expect(find.text('لا توجد فصول متاحة للعرض الآن'), findsOneWidget);
  expect(find.text('ابدأ القراءة'), findsNothing);
});
```

Add `_EmptyNovelRepository` with details title `تفاصيل بلا فصول`, `chaptersCount: 10`, empty `firstChapterUrl`, and empty `chapters`.

- [ ] **Step 2: Create screen implementation**

Create `novel_details_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/novel_details_data.dart';
import '../../../data/repositories/novel_repository.dart';
import 'widgets/novel_chapter_tile.dart';
import 'widgets/novel_details_header.dart';

class NovelDetailsScreen extends StatefulWidget {
  const NovelDetailsScreen({required this.manifestPath, super.key});

  final String manifestPath;

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  Future<NovelDetailsLoadResult>? _future;
  NovelRepository? _repository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppDependencies.of(context).novelRepository;
    if (_repository != repository) {
      _repository = repository;
      _future = repository.loadNovel(widget.manifestPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الرواية')),
      body: FutureBuilder<NovelDetailsLoadResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _NovelDetailsSkeleton();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _DetailsMessage(
              title: 'تعذر تحميل تفاصيل الرواية الآن',
              actionLabel: 'إعادة المحاولة',
              onAction: _retry,
            );
          }

          return _NovelDetailsContent(
            result: snapshot.data!,
            onRead: _showReaderPlaceholder,
          );
        },
      ),
    );
  }

  void _retry() {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    setState(() {
      _future = repository.loadNovel(widget.manifestPath);
    });
  }

  void _showReaderPlaceholder(String chapterUrl) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('القارئ سيكون في المرحلة التالية')),
    );
  }
}
```

Add `_NovelDetailsContent`, `_SummarySection`, `_GenresSection`, `_ChaptersSection`, `_NovelDetailsSkeleton`, and `_DetailsMessage` in the same file. Keep content in a vertical `ListView`, use `NovelDetailsHeader`, use `NovelChapterTile`, and show `لا توجد فصول متاحة للعرض الآن` when `result.chapters.isEmpty`.

- [ ] **Step 3: Implement summary expansion**

Inside `_SummarySection`, use a local `StatefulWidget` with `maxLines: expanded ? null : 5` and a `TextButton` labeled `عرض المزيد` / `عرض أقل` only when `summary.length > 220`.

- [ ] **Step 4: Implement read action availability**

In `_NovelDetailsContent`, compute:

```dart
final firstReadableUrl = result.chapters.isNotEmpty
    ? result.chapters.first.url
    : result.details.firstChapterUrl;
```

Show `FilledButton.icon` with label `ابدأ القراءة` only when `firstReadableUrl.isNotEmpty`.

- [ ] **Step 5: Run focused widget tests**

Run:

```powershell
flutter test test/widget_test.dart
```

Expected: details tests may still fail until navigation callbacks are added in Task 7.

- [ ] **Step 6: Commit screen file without navigation if component tests pass independently**

If direct screen tests are added and pass, commit:

```powershell
git add galaxy_novels_app/lib/features/novel_details/presentation/novel_details_screen.dart galaxy_novels_app/test/widget_test.dart
git commit -m "feat: add novel details screen"
```

If navigation tests fail because taps are not wired yet, defer the commit to Task 7.

---

### Task 7: Navigation From Catalog And Home

**Files:**
- Modify: `galaxy_novels_app/lib/features/catalog/presentation/widgets/catalog_novel_tile.dart`
- Modify: `galaxy_novels_app/lib/features/catalog/presentation/catalog_screen.dart`
- Modify: `galaxy_novels_app/lib/features/home/presentation/home_screen.dart`
- Modify/Test: `galaxy_novels_app/test/widget_test.dart`

- [ ] **Step 1: Add `onTap` to catalog tile**

Update `CatalogNovelTile` constructor:

```dart
const CatalogNovelTile({required this.novel, this.onTap, super.key});

final VoidCallback? onTap;
```

Use:

```dart
onTap: onTap,
```

instead of the current empty callback.

- [ ] **Step 2: Navigate from catalog screen**

Import:

```dart
import '../../novel_details/presentation/novel_details_screen.dart';
```

When creating `CatalogNovelTile`, pass:

```dart
onTap: result.items[itemIndex].manifest.isEmpty
    ? null
    : () => _openNovelDetails(result.items[itemIndex].manifest),
```

Add:

```dart
void _openNovelDetails(String manifestPath) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => NovelDetailsScreen(manifestPath: manifestPath),
    ),
  );
}
```

- [ ] **Step 3: Navigate from home shelves**

In `home_screen.dart`, import `NovelDetailsScreen`. Add a local helper in `_HomeScreenState`:

```dart
void _openNovelDetails(String manifestPath) {
  if (manifestPath.isEmpty) {
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => NovelDetailsScreen(manifestPath: manifestPath),
    ),
  );
}
```

Pass `onNovelTap: _openNovelDetails` into `_FeaturedNovelsShelf` and `_RecentNovelsStrip`. Add `ValueChanged<String> onNovelTap` to those widgets and pass it to `_NovelCoverCell`. Add `onTap` to `_NovelCoverCell` and use it in `InkWell`.

- [ ] **Step 4: Make test data navigable**

Update `_homeData.recentNovels.single.manifest` to `/novel-home-test.json`. Update `_TestCatalogRepository` first item manifest to `/novel-catalog-test.json`.

- [ ] **Step 5: Run widget tests**

Run:

```powershell
flutter test test/widget_test.dart
```

Expected: all widget tests pass, including details navigation.

- [ ] **Step 6: Commit**

```powershell
git add galaxy_novels_app/lib/features/catalog/presentation/widgets/catalog_novel_tile.dart galaxy_novels_app/lib/features/catalog/presentation/catalog_screen.dart galaxy_novels_app/lib/features/home/presentation/home_screen.dart galaxy_novels_app/lib/features/novel_details/presentation/novel_details_screen.dart galaxy_novels_app/test/widget_test.dart
git commit -m "feat: navigate to novel details"
```

---

### Task 8: Final Verification

**Files:**
- All files touched by Tasks 1-7.

- [ ] **Step 1: Format**

Run:

```powershell
Set-Location .\galaxy_novels_app
dart format lib test
```

Expected: formatter completes without errors.

- [ ] **Step 2: Analyze**

Run:

```powershell
dart analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 3: Run focused tests**

Run:

```powershell
flutter test test/core/public_cache_client_test.dart test/data/novel_details_data_test.dart test/data/public_novel_repository_test.dart test/widget_test.dart
```

Expected: all focused tests pass.

- [ ] **Step 4: Run the full test suite**

Run:

```powershell
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Build debug APK**

Run:

```powershell
flutter build apk --debug
```

Expected: debug APK builds successfully.

- [ ] **Step 6: Review git status**

Run:

```powershell
git status --short
```

Expected: only unrelated pre-existing files remain untracked:

```text
?? _tmp_xapk_extract/
?? docs/superpowers/plans/2026-06-18-galaxy-novels-data-layer.md
?? wor-reader-v2470-app-cache-api.zip
```

- [ ] **Step 7: Commit final formatting if needed**

If formatting changed files after prior commits:

```powershell
git add galaxy_novels_app/lib galaxy_novels_app/test
git commit -m "chore: format novel details implementation"
```

If no files changed, skip this commit.

---

## Self-Review

- Spec coverage: The plan implements public novel manifest loading, chapter manifest/pack loading, object and array chapter pack parsing, empty chapter states, lightweight RTL details layout, navigation from catalog/home, and keeps WebView reader outside scope.
- Placeholder scan: The plan has no placeholder markers and no unspecified endpoints. Steps identify exact files, commands, expected results, and commit boundaries.
- Type consistency: `NovelDetails`, `NovelGenre`, `ChapterManifest`, `ChapterPack`, `NovelChapter`, `NovelRepository`, and `NovelDetailsLoadResult` are used consistently.
- Scope check: Auth, favorites sync, ratings, comments, VIP private chapters, WebView reader, and reading XP sync remain outside this phase.
