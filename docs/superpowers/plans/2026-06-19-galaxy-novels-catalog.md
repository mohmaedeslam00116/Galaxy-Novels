# Galaxy Novels Catalog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the real `المكتبة` tab as a progressive, repository-backed Arabic catalog list using `public.catalog_manifest`.

**Architecture:** Add pure Dart catalog models and a `CatalogRepository` stream that yields after the first pack, then continues loading remaining packs in the background. Keep search, sorting, and filters as pure functions so the UI stays light and testable. Inject the catalog repository through `AppDependencies`, matching the existing home repository pattern.

**Tech Stack:** Flutter, Dart, Material 3, existing `PublicCacheClient`, existing `BootstrapRepository`, Flutter unit/widget tests.

---

## File Structure

- Create: `galaxy_novels_app/lib/data/models/catalog_data.dart`
- Create: `galaxy_novels_app/lib/data/repositories/catalog_repository.dart`
- Create: `galaxy_novels_app/lib/data/repositories/fake_catalog_repository.dart`
- Create: `galaxy_novels_app/lib/data/repositories/public_catalog_repository.dart`
- Create: `galaxy_novels_app/lib/features/catalog/domain/catalog_query.dart`
- Create: `galaxy_novels_app/lib/features/catalog/presentation/widgets/catalog_novel_tile.dart`
- Modify: `galaxy_novels_app/lib/app/app_dependencies.dart`
- Modify: `galaxy_novels_app/lib/app/galaxy_novels_app.dart`
- Replace: `galaxy_novels_app/lib/features/catalog/presentation/catalog_screen.dart`
- Test: `galaxy_novels_app/test/data/catalog_data_test.dart`
- Test: `galaxy_novels_app/test/data/public_catalog_repository_test.dart`
- Test: `galaxy_novels_app/test/features/catalog/catalog_query_test.dart`
- Modify/Test: `galaxy_novels_app/test/widget_test.dart`

---

### Task 1: Catalog Models

**Files:**
- Create: `galaxy_novels_app/lib/data/models/catalog_data.dart`
- Test: `galaxy_novels_app/test/data/catalog_data_test.dart`

- [ ] **Step 1: Write model parsing tests**

Create `galaxy_novels_app/test/data/catalog_data_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';

void main() {
  test('parses catalog manifest packs and metadata', () {
    final manifest = CatalogManifest.fromJson({
      'schema': 1,
      'generated': 1718780000,
      'version': 'catalog-hash',
      'count': 1200,
      'part_size': 500,
      'packs': [
        '/wp-content/uploads/wor-reader-cache/app/packs/catalog-1.json',
        '/wp-content/uploads/wor-reader-cache/app/packs/catalog-2.json',
      ],
    });

    expect(manifest.version, 'catalog-hash');
    expect(manifest.count, 1200);
    expect(manifest.partSize, 500);
    expect(manifest.packs, hasLength(2));
  });

  test('parses catalog pack items with nested fields', () {
    final pack = CatalogPack.fromJson({
      'schema': 1,
      'generated': 1718780000,
      'part': 1,
      'total_parts': 3,
      'items': [
        {
          'id': 10,
          'title': 'نجوم الاختبار',
          'original_title': 'Test Stars',
          'url': '/novel/test-stars/',
          'cover': {
            'thumbnail': '/uploads/thumb.jpg',
            'medium': '/uploads/medium.jpg',
          },
          'status': {'key': 'ongoing', 'label': 'مستمرة'},
          'genres': [
            {'id': 1, 'name': 'أكشن', 'slug': 'action'},
            {'id': 2, 'name': 'خيال', 'slug': 'fantasy'},
          ],
          'chapters_count': 120,
          'rating': {'average': 4.5, 'count': 30},
          'stats': {'views': 10000},
          'updated_at': '2026-06-18T10:00:00+00:00',
          'manifest': '/manifest/novel-10.json',
        },
      ],
    });

    expect(pack.part, 1);
    expect(pack.totalParts, 3);
    expect(pack.items.single.id, 10);
    expect(pack.items.single.title, 'نجوم الاختبار');
    expect(pack.items.single.coverThumbnail, '/uploads/thumb.jpg');
    expect(pack.items.single.statusLabel, 'مستمرة');
    expect(pack.items.single.genres.map((genre) => genre.name), [
      'أكشن',
      'خيال',
    ]);
    expect(pack.items.single.chaptersCount, 120);
    expect(pack.items.single.ratingAverage, 4.5);
    expect(pack.items.single.views, 10000);
    expect(pack.items.single.updatedAt, DateTime.parse('2026-06-18T10:00:00+00:00'));
    expect(pack.items.single.manifest, '/manifest/novel-10.json');
  });

  test('uses safe defaults for missing optional fields', () {
    final novel = CatalogNovel.fromJson({
      'id': 7,
      'title': 'رواية ناقصة',
    });

    expect(novel.id, 7);
    expect(novel.title, 'رواية ناقصة');
    expect(novel.originalTitle, '');
    expect(novel.coverThumbnail, '');
    expect(novel.statusLabel, '');
    expect(novel.genres, isEmpty);
    expect(novel.chaptersCount, 0);
    expect(novel.ratingAverage, 0);
    expect(novel.views, 0);
    expect(novel.updatedAt, isNull);
  });
}
```

- [ ] **Step 2: Run the failing model tests**

Run:

```powershell
flutter test test/data/catalog_data_test.dart
```

Expected: fails because `CatalogManifest`, `CatalogPack`, and `CatalogNovel` do not exist.

- [ ] **Step 3: Implement catalog models**

Create `galaxy_novels_app/lib/data/models/catalog_data.dart`:

```dart
class CatalogManifest {
  const CatalogManifest({
    required this.version,
    required this.count,
    required this.partSize,
    required this.packs,
  });

  factory CatalogManifest.fromJson(Map<String, dynamic> json) {
    return CatalogManifest(
      version: _asString(json['version']),
      count: _asInt(json['count']),
      partSize: _asInt(json['part_size']),
      packs: _asStringList(json['packs']),
    );
  }

  final String version;
  final int count;
  final int partSize;
  final List<String> packs;
}

class CatalogPack {
  const CatalogPack({
    required this.part,
    required this.totalParts,
    required this.items,
  });

  factory CatalogPack.fromJson(Map<String, dynamic> json) {
    return CatalogPack(
      part: _asInt(json['part']),
      totalParts: _asInt(json['total_parts']),
      items: _asList(json['items'])
          .map((item) => CatalogNovel.fromJson(_asMap(item)))
          .toList(),
    );
  }

  final int part;
  final int totalParts;
  final List<CatalogNovel> items;
}

class CatalogNovel {
  const CatalogNovel({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.url,
    required this.coverThumbnail,
    required this.coverMedium,
    required this.statusKey,
    required this.statusLabel,
    required this.genres,
    required this.chaptersCount,
    required this.ratingAverage,
    required this.ratingCount,
    required this.views,
    required this.updatedAt,
    required this.manifest,
  });

  factory CatalogNovel.fromJson(Map<String, dynamic> json) {
    final cover = _asMap(json['cover']);
    final status = _asMap(json['status']);
    final rating = _asMap(json['rating']);
    final stats = _asMap(json['stats']);

    return CatalogNovel(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      originalTitle: _asString(json['original_title']),
      url: _asString(json['url']),
      coverThumbnail: _asString(cover['thumbnail']),
      coverMedium: _asString(cover['medium']),
      statusKey: _asString(status['key']),
      statusLabel: _asString(status['label']),
      genres: _asList(json['genres'])
          .map((genre) => CatalogGenre.fromJson(_asMap(genre)))
          .where((genre) => genre.name.isNotEmpty)
          .toList(),
      chaptersCount: _asInt(json['chapters_count']),
      ratingAverage: _asDouble(rating['average']),
      ratingCount: _asInt(rating['count']),
      views: _asInt(stats['views']),
      updatedAt: _asDateTime(json['updated_at']),
      manifest: _asString(json['manifest']),
    );
  }

  final int id;
  final String title;
  final String originalTitle;
  final String url;
  final String coverThumbnail;
  final String coverMedium;
  final String statusKey;
  final String statusLabel;
  final List<CatalogGenre> genres;
  final int chaptersCount;
  final double ratingAverage;
  final int ratingCount;
  final int views;
  final DateTime? updatedAt;
  final String manifest;
}

class CatalogGenre {
  const CatalogGenre({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory CatalogGenre.fromJson(Map<String, dynamic> json) {
    return CatalogGenre(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
    );
  }

  final int id;
  final String name;
  final String slug;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return const {};
}

List<Object?> _asList(Object? value) {
  if (value is List) {
    return value.cast<Object?>();
  }
  return const [];
}

List<String> _asStringList(Object? value) {
  return _asList(value)
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

String _asString(Object? value) => value?.toString() ?? '';

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_asString(value)) ?? 0;
}

double _asDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(_asString(value)) ?? 0;
}

DateTime? _asDateTime(Object? value) {
  final text = _asString(value);
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}
```

- [ ] **Step 4: Run model tests**

Run:

```powershell
flutter test test/data/catalog_data_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```powershell
git add galaxy_novels_app/lib/data/models/catalog_data.dart galaxy_novels_app/test/data/catalog_data_test.dart
git commit -m "feat: add catalog data models"
```

---

### Task 2: Progressive Catalog Repository

**Files:**
- Create: `galaxy_novels_app/lib/data/repositories/catalog_repository.dart`
- Create: `galaxy_novels_app/lib/data/repositories/fake_catalog_repository.dart`
- Create: `galaxy_novels_app/lib/data/repositories/public_catalog_repository.dart`
- Test: `galaxy_novels_app/test/data/public_catalog_repository_test.dart`

- [ ] **Step 1: Write repository tests**

Create `galaxy_novels_app/test/data/public_catalog_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/public_cache_client.dart';
import 'package:galaxy_novels_app/data/repositories/bootstrap_repository.dart';
import 'package:galaxy_novels_app/data/repositories/public_catalog_repository.dart';

void main() {
  test('emits after the first catalog pack then after remaining packs', () async {
    final requests = <Uri>[];
    final cacheClient = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        requests.add(uri);
        if (uri.path.endsWith('/manifest/bootstrap.json')) {
          return {
            'pack': '/wp-content/uploads/wor-reader-cache/app/packs/bootstrap.json',
          };
        }
        if (uri.path.endsWith('/packs/bootstrap.json')) {
          return {
            'data': {
              'site': {'name': 'Galaxy', 'url': 'https://example.com/'},
              'api': {},
              'public': {
                'catalog_manifest':
                    '/wp-content/uploads/wor-reader-cache/app/manifest/catalog.json',
              },
              'features': {},
            },
          };
        }
        if (uri.path.endsWith('/manifest/catalog.json')) {
          return {
            'version': 'catalog-v1',
            'count': 2,
            'part_size': 1,
            'packs': ['/packs/catalog-1.json', '/packs/catalog-2.json'],
          };
        }
        if (uri.path.endsWith('/packs/catalog-1.json')) {
          return {
            'part': 1,
            'total_parts': 2,
            'items': [
              {'id': 1, 'title': 'الأولى', 'updated_at': '2026-06-18T10:00:00Z'},
            ],
          };
        }
        return {
          'part': 2,
          'total_parts': 2,
          'items': [
            {'id': 2, 'title': 'الثانية', 'updated_at': '2026-06-19T10:00:00Z'},
          ],
        };
      },
    );

    final repository = PublicCatalogRepository(
      bootstrapRepository: BootstrapRepository(cacheClient),
      cacheClient: cacheClient,
    );

    final states = await repository.watchCatalog().toList();

    expect(states, hasLength(2));
    expect(states.first.items.map((novel) => novel.title), ['الأولى']);
    expect(states.first.isLoadingMore, isTrue);
    expect(states.last.items.map((novel) => novel.title), ['الأولى', 'الثانية']);
    expect(states.last.isLoadingMore, isFalse);
    expect(states.last.loadedParts, 2);
    expect(states.last.totalParts, 2);
    expect(requests.any((uri) => uri.path.endsWith('/manifest/catalog.json')), isTrue);
  });

  test('keeps loaded items when a later pack fails', () async {
    final cacheClient = PublicCacheClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      jsonGet: (uri, headers) async {
        if (uri.path.endsWith('/manifest/bootstrap.json')) {
          return {'pack': '/bootstrap.json'};
        }
        if (uri.path.endsWith('/bootstrap.json')) {
          return {
            'data': {
              'site': {},
              'api': {},
              'public': {'catalog_manifest': '/catalog.json'},
              'features': {},
            },
          };
        }
        if (uri.path.endsWith('/catalog.json')) {
          return {
            'packs': ['/catalog-1.json', '/catalog-2.json'],
          };
        }
        if (uri.path.endsWith('/catalog-1.json')) {
          return {
            'part': 1,
            'total_parts': 2,
            'items': [
              {'id': 1, 'title': 'المحفوظة'},
            ],
          };
        }
        throw const PublicCacheException('Second pack failed.');
      },
    );

    final repository = PublicCatalogRepository(
      bootstrapRepository: BootstrapRepository(cacheClient),
      cacheClient: cacheClient,
    );

    final states = await repository.watchCatalog().toList();

    expect(states, hasLength(2));
    expect(states.last.items.map((novel) => novel.title), ['المحفوظة']);
    expect(states.last.backgroundError, contains('Second pack failed'));
    expect(states.last.isLoadingMore, isFalse);
  });
}
```

- [ ] **Step 2: Run failing repository tests**

Run:

```powershell
flutter test test/data/public_catalog_repository_test.dart
```

Expected: fails because repository files do not exist.

- [ ] **Step 3: Add repository boundary and state**

Create `galaxy_novels_app/lib/data/repositories/catalog_repository.dart`:

```dart
import '../models/catalog_data.dart';

abstract class CatalogRepository {
  Stream<CatalogLoadState> watchCatalog();
}

class CatalogLoadState {
  const CatalogLoadState({
    required this.items,
    required this.loadedParts,
    required this.totalParts,
    required this.isLoadingMore,
    this.backgroundError,
  });

  final List<CatalogNovel> items;
  final int loadedParts;
  final int totalParts;
  final bool isLoadingMore;
  final String? backgroundError;

  CatalogLoadState copyWith({
    List<CatalogNovel>? items,
    int? loadedParts,
    int? totalParts,
    bool? isLoadingMore,
    String? backgroundError,
  }) {
    return CatalogLoadState(
      items: items ?? this.items,
      loadedParts: loadedParts ?? this.loadedParts,
      totalParts: totalParts ?? this.totalParts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      backgroundError: backgroundError ?? this.backgroundError,
    );
  }
}
```

- [ ] **Step 4: Add fake catalog repository**

Create `galaxy_novels_app/lib/data/repositories/fake_catalog_repository.dart`:

```dart
import '../models/catalog_data.dart';
import 'catalog_repository.dart';

class FakeCatalogRepository implements CatalogRepository {
  const FakeCatalogRepository([this.items = _defaultItems]);

  final List<CatalogNovel> items;

  @override
  Stream<CatalogLoadState> watchCatalog() async* {
    yield CatalogLoadState(
      items: items,
      loadedParts: 1,
      totalParts: 1,
      isLoadingMore: false,
    );
  }
}

const _defaultItems = [
  CatalogNovel(
    id: 1,
    title: 'حارس النجوم',
    originalTitle: '',
    url: '/novel/star-guard/',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: 'ongoing',
    statusLabel: 'مستمرة',
    genres: [CatalogGenre(id: 1, name: 'أكشن', slug: 'action')],
    chaptersCount: 82,
    ratingAverage: 4.4,
    ratingCount: 20,
    views: 14000,
    updatedAt: null,
    manifest: '',
  ),
  CatalogNovel(
    id: 2,
    title: 'بوابة الشمال',
    originalTitle: '',
    url: '/novel/north-gate/',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: 'completed',
    statusLabel: 'مكتملة',
    genres: [CatalogGenre(id: 2, name: 'فانتازيا', slug: 'fantasy')],
    chaptersCount: 126,
    ratingAverage: 4.8,
    ratingCount: 45,
    views: 25000,
    updatedAt: null,
    manifest: '',
  ),
];
```

- [ ] **Step 5: Add public catalog repository**

Create `galaxy_novels_app/lib/data/repositories/public_catalog_repository.dart`:

```dart
import '../../core/network/public_cache_client.dart';
import '../models/catalog_data.dart';
import 'bootstrap_repository.dart';
import 'catalog_repository.dart';

class PublicCatalogRepository implements CatalogRepository {
  const PublicCatalogRepository({
    required BootstrapRepository bootstrapRepository,
    required PublicCacheClient cacheClient,
  }) : _bootstrapRepository = bootstrapRepository,
       _cacheClient = cacheClient;

  final BootstrapRepository _bootstrapRepository;
  final PublicCacheClient _cacheClient;

  @override
  Stream<CatalogLoadState> watchCatalog() async* {
    final bootstrap = await _bootstrapRepository.loadBootstrap();
    final manifestPath = bootstrap.publicManifests.catalog;
    if (manifestPath.isEmpty) {
      throw const PublicCacheException('Bootstrap does not contain catalog manifest.');
    }

    final manifest = CatalogManifest.fromJson(
      await _cacheClient.loadJson(manifestPath),
    );
    if (manifest.packs.isEmpty) {
      yield const CatalogLoadState(
        items: [],
        loadedParts: 0,
        totalParts: 0,
        isLoadingMore: false,
      );
      return;
    }

    final items = <CatalogNovel>[];
    final totalParts = manifest.packs.length;

    for (var index = 0; index < manifest.packs.length; index += 1) {
      final packPath = manifest.packs[index];
      try {
        final pack = CatalogPack.fromJson(await _cacheClient.loadJson(packPath));
        items.addAll(pack.items);
        yield CatalogLoadState(
          items: List.unmodifiable(items),
          loadedParts: index + 1,
          totalParts: totalParts,
          isLoadingMore: index + 1 < totalParts,
        );
      } on Object catch (error) {
        if (items.isEmpty) {
          rethrow;
        }
        yield CatalogLoadState(
          items: List.unmodifiable(items),
          loadedParts: index,
          totalParts: totalParts,
          isLoadingMore: false,
          backgroundError: error.toString(),
        );
        return;
      }
    }
  }
}
```

- [ ] **Step 6: Run repository tests**

Run:

```powershell
flutter test test/data/public_catalog_repository_test.dart
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```powershell
git add galaxy_novels_app/lib/data/repositories/catalog_repository.dart galaxy_novels_app/lib/data/repositories/fake_catalog_repository.dart galaxy_novels_app/lib/data/repositories/public_catalog_repository.dart galaxy_novels_app/test/data/public_catalog_repository_test.dart
git commit -m "feat: add progressive catalog repository"
```

---

### Task 3: Local Search, Sorting, and Filters

**Files:**
- Create: `galaxy_novels_app/lib/features/catalog/domain/catalog_query.dart`
- Test: `galaxy_novels_app/test/features/catalog/catalog_query_test.dart`

- [ ] **Step 1: Write query tests**

Create `galaxy_novels_app/test/features/catalog/catalog_query_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/features/catalog/domain/catalog_query.dart';

void main() {
  test('normalizes Arabic search text', () {
    expect(normalizeArabicSearch('أبطالُ السَّماء ــ ١'), 'ابطال السماء ١');
    expect(normalizeArabicSearch('رواية نهاية'), 'روايه نهايه');
  });

  test('filters by normalized search text', () {
    final result = applyCatalogQuery(
      [_novel(title: 'أبطال السماء'), _novel(title: 'بوابة الشمال')],
      const CatalogQuery(searchText: 'ابطال'),
    );

    expect(result.items.map((novel) => novel.title), ['أبطال السماء']);
  });

  test('filters by status and genre', () {
    final result = applyCatalogQuery(
      [
        _novel(title: 'أ', status: 'مستمرة', genres: ['أكشن']),
        _novel(title: 'ب', status: 'مكتملة', genres: ['دراما']),
      ],
      const CatalogQuery(statusLabel: 'مستمرة', genreName: 'أكشن'),
    );

    expect(result.items.map((novel) => novel.title), ['أ']);
  });

  test('sorts by latest update by default', () {
    final result = applyCatalogQuery([
      _novel(title: 'قديم', updatedAt: DateTime.parse('2026-06-01T00:00:00Z')),
      _novel(title: 'حديث', updatedAt: DateTime.parse('2026-06-19T00:00:00Z')),
    ], const CatalogQuery());

    expect(result.items.map((novel) => novel.title), ['حديث', 'قديم']);
  });

  test('builds available statuses and genres from loaded items', () {
    final result = applyCatalogQuery([
      _novel(title: 'أ', status: 'مستمرة', genres: ['أكشن', 'خيال']),
      _novel(title: 'ب', status: 'مكتملة', genres: ['أكشن']),
    ], const CatalogQuery());

    expect(result.availableStatuses, ['مستمرة', 'مكتملة']);
    expect(result.availableGenres, ['أكشن', 'خيال']);
  });
}

CatalogNovel _novel({
  required String title,
  String status = '',
  List<String> genres = const [],
  DateTime? updatedAt,
  int views = 0,
  double rating = 0,
  int chapters = 0,
}) {
  return CatalogNovel(
    id: title.hashCode,
    title: title,
    originalTitle: '',
    url: '',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: '',
    statusLabel: status,
    genres: [
      for (var index = 0; index < genres.length; index += 1)
        CatalogGenre(id: index + 1, name: genres[index], slug: genres[index]),
    ],
    chaptersCount: chapters,
    ratingAverage: rating,
    ratingCount: rating > 0 ? 1 : 0,
    views: views,
    updatedAt: updatedAt,
    manifest: '',
  );
}
```

- [ ] **Step 2: Run failing query tests**

Run:

```powershell
flutter test test/features/catalog/catalog_query_test.dart
```

Expected: fails because `catalog_query.dart` does not exist.

- [ ] **Step 3: Implement query logic**

Create `galaxy_novels_app/lib/features/catalog/domain/catalog_query.dart`:

```dart
import '../../../data/models/catalog_data.dart';

enum CatalogSort {
  latest('آخر تحديث'),
  views('الأكثر مشاهدة'),
  rating('الأعلى تقييمًا'),
  chapters('عدد الفصول'),
  title('العنوان');

  const CatalogSort(this.label);

  final String label;
}

class CatalogQuery {
  const CatalogQuery({
    this.searchText = '',
    this.statusLabel,
    this.genreName,
    this.sort = CatalogSort.latest,
  });

  final String searchText;
  final String? statusLabel;
  final String? genreName;
  final CatalogSort sort;

  bool get hasActiveFilters =>
      searchText.trim().isNotEmpty || statusLabel != null || genreName != null;

  CatalogQuery copyWith({
    String? searchText,
    String? statusLabel,
    String? genreName,
    CatalogSort? sort,
    bool clearStatus = false,
    bool clearGenre = false,
  }) {
    return CatalogQuery(
      searchText: searchText ?? this.searchText,
      statusLabel: clearStatus ? null : statusLabel ?? this.statusLabel,
      genreName: clearGenre ? null : genreName ?? this.genreName,
      sort: sort ?? this.sort,
    );
  }
}

class CatalogQueryResult {
  const CatalogQueryResult({
    required this.items,
    required this.availableStatuses,
    required this.availableGenres,
  });

  final List<CatalogNovel> items;
  final List<String> availableStatuses;
  final List<String> availableGenres;
}

CatalogQueryResult applyCatalogQuery(
  List<CatalogNovel> source,
  CatalogQuery query,
) {
  final availableStatuses = _unique(
    source.map((novel) => novel.statusLabel).where((value) => value.isNotEmpty),
  );
  final availableGenres = _unique(
    source.expand((novel) => novel.genres.map((genre) => genre.name)),
  );
  final normalizedSearch = normalizeArabicSearch(query.searchText);

  final filtered = source.where((novel) {
    if (query.statusLabel != null && novel.statusLabel != query.statusLabel) {
      return false;
    }
    if (query.genreName != null &&
        !novel.genres.any((genre) => genre.name == query.genreName)) {
      return false;
    }
    if (normalizedSearch.isEmpty) {
      return true;
    }

    final haystack = normalizeArabicSearch([
      novel.title,
      novel.originalTitle,
      ...novel.genres.map((genre) => genre.name),
    ].join(' '));

    return haystack.contains(normalizedSearch);
  }).toList();

  filtered.sort((a, b) => _compareNovels(a, b, query.sort));

  return CatalogQueryResult(
    items: List.unmodifiable(filtered),
    availableStatuses: availableStatuses,
    availableGenres: availableGenres,
  );
}

String normalizeArabicSearch(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll(RegExp('[ىئ]'), 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('ـ', '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

int _compareNovels(CatalogNovel a, CatalogNovel b, CatalogSort sort) {
  final comparison = switch (sort) {
    CatalogSort.latest => _compareNullableDatesDesc(a.updatedAt, b.updatedAt),
    CatalogSort.views => b.views.compareTo(a.views),
    CatalogSort.rating => b.ratingAverage.compareTo(a.ratingAverage),
    CatalogSort.chapters => b.chaptersCount.compareTo(a.chaptersCount),
    CatalogSort.title => a.title.compareTo(b.title),
  };

  if (comparison != 0) {
    return comparison;
  }

  return a.title.compareTo(b.title);
}

int _compareNullableDatesDesc(DateTime? a, DateTime? b) {
  if (a == null && b == null) {
    return 0;
  }
  if (a == null) {
    return 1;
  }
  if (b == null) {
    return -1;
  }
  return b.compareTo(a);
}

List<String> _unique(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    if (value.isNotEmpty && seen.add(value)) {
      result.add(value);
    }
  }
  return result;
}
```

- [ ] **Step 4: Run query tests**

Run:

```powershell
flutter test test/features/catalog/catalog_query_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```powershell
git add galaxy_novels_app/lib/features/catalog/domain/catalog_query.dart galaxy_novels_app/test/features/catalog/catalog_query_test.dart
git commit -m "feat: add catalog search and filtering logic"
```

---

### Task 4: Dependency Injection

**Files:**
- Modify: `galaxy_novels_app/lib/app/app_dependencies.dart`
- Modify: `galaxy_novels_app/lib/app/galaxy_novels_app.dart`
- Modify: `galaxy_novels_app/test/widget_test.dart`

- [ ] **Step 1: Update app dependency tests expectations**

In `galaxy_novels_app/test/widget_test.dart`, add catalog imports:

```dart
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/data/repositories/catalog_repository.dart';
```

Update every `GalaxyNovelsApp(...)` test call to pass both repositories:

```dart
GalaxyNovelsApp(
  homeRepository: _TestHomeRepository(_homeData),
  catalogRepository: const _TestCatalogRepository(),
)
```

Add this fake repository at the bottom of the file:

```dart
class _TestCatalogRepository implements CatalogRepository {
  const _TestCatalogRepository();

  @override
  Stream<CatalogLoadState> watchCatalog() async* {
    yield const CatalogLoadState(
      items: [
        CatalogNovel(
          id: 99,
          title: 'مكتبة الاختبار',
          originalTitle: '',
          url: '/novel/catalog-test/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'ongoing',
          statusLabel: 'مستمرة',
          genres: [CatalogGenre(id: 1, name: 'أكشن', slug: 'action')],
          chaptersCount: 10,
          ratingAverage: 4.2,
          ratingCount: 5,
          views: 100,
          updatedAt: null,
          manifest: '',
        ),
      ],
      loadedParts: 1,
      totalParts: 1,
      isLoadingMore: false,
    );
  }
}
```

- [ ] **Step 2: Run widget tests and confirm compile failure**

Run:

```powershell
flutter test test/widget_test.dart
```

Expected: fails because `GalaxyNovelsApp` and `AppDependencies` do not accept `catalogRepository` yet.

- [ ] **Step 3: Add catalog repository to AppDependencies**

Modify `galaxy_novels_app/lib/app/app_dependencies.dart`:

```dart
import 'package:flutter/widgets.dart';

import '../core/config/app_config.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/home_repository.dart';

class AppDependencies extends InheritedWidget {
  const AppDependencies({
    required this.config,
    required this.homeRepository,
    required this.catalogRepository,
    required super.child,
    super.key,
  });

  final AppConfig config;
  final HomeRepository homeRepository;
  final CatalogRepository catalogRepository;

  static AppDependencies of(BuildContext context) {
    final dependencies = context
        .dependOnInheritedWidgetOfExactType<AppDependencies>();

    assert(dependencies != null, 'AppDependencies was not found in context.');
    return dependencies!;
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) {
    return config != oldWidget.config ||
        homeRepository != oldWidget.homeRepository ||
        catalogRepository != oldWidget.catalogRepository;
  }
}
```

- [ ] **Step 4: Wire catalog repository in GalaxyNovelsApp**

Modify `galaxy_novels_app/lib/app/galaxy_novels_app.dart` imports:

```dart
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/public_catalog_repository.dart';
```

Update constructor and field:

```dart
const GalaxyNovelsApp({
  AppConfig? config,
  this.homeRepository,
  this.catalogRepository,
  super.key,
}) : config = config ?? const AppConfig();

final AppConfig config;
final HomeRepository? homeRepository;
final CatalogRepository? catalogRepository;
```

Inside `build`, create one bootstrap repository and both effective repositories:

```dart
final cacheClient = PublicCacheClient(config: config);
final bootstrapRepository = BootstrapRepository(cacheClient);
final effectiveHomeRepository =
    homeRepository ??
    PublicHomeRepository(
      bootstrapRepository: bootstrapRepository,
      cacheClient: cacheClient,
    );
final effectiveCatalogRepository =
    catalogRepository ??
    PublicCatalogRepository(
      bootstrapRepository: bootstrapRepository,
      cacheClient: cacheClient,
    );
```

Pass it to `AppDependencies`:

```dart
home: AppDependencies(
  config: config,
  homeRepository: effectiveHomeRepository,
  catalogRepository: effectiveCatalogRepository,
  child: const Directionality(
    textDirection: TextDirection.rtl,
    child: AppShell(),
  ),
),
```

- [ ] **Step 5: Run widget tests**

Run:

```powershell
flutter test test/widget_test.dart
```

Expected: tests compile and existing home/shell tests pass.

- [ ] **Step 6: Commit**

```powershell
git add galaxy_novels_app/lib/app/app_dependencies.dart galaxy_novels_app/lib/app/galaxy_novels_app.dart galaxy_novels_app/test/widget_test.dart
git commit -m "feat: inject catalog repository"
```

---

### Task 5: Catalog List UI

**Files:**
- Create: `galaxy_novels_app/lib/features/catalog/presentation/widgets/catalog_novel_tile.dart`
- Replace: `galaxy_novels_app/lib/features/catalog/presentation/catalog_screen.dart`
- Modify/Test: `galaxy_novels_app/test/widget_test.dart`

- [ ] **Step 1: Add widget tests for the catalog tab**

Append tests to `galaxy_novels_app/test/widget_test.dart`:

```dart
testWidgets('catalog tab renders repository-provided novels', (tester) async {
  await tester.pumpWidget(
    GalaxyNovelsApp(
      homeRepository: _TestHomeRepository(_homeData),
      catalogRepository: const _TestCatalogRepository(),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('المكتبة'));
  await tester.pumpAndSettle();

  expect(find.text('مكتبة الاختبار'), findsOneWidget);
  expect(find.textContaining('10 فصل'), findsOneWidget);
  expect(find.text('آخر تحديث'), findsOneWidget);
});

testWidgets('catalog search filters results locally', (tester) async {
  await tester.pumpWidget(
    GalaxyNovelsApp(
      homeRepository: _TestHomeRepository(_homeData),
      catalogRepository: const _TestCatalogRepository(),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('المكتبة'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField), 'غير موجود');
  await tester.pump(const Duration(milliseconds: 350));

  expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);

  await tester.tap(find.text('مسح البحث والفلاتر'));
  await tester.pumpAndSettle();

  expect(find.text('مكتبة الاختبار'), findsOneWidget);
});
```

- [ ] **Step 2: Run failing catalog widget tests**

Run:

```powershell
flutter test test/widget_test.dart
```

Expected: fails because current catalog screen still shows static temporary content.

- [ ] **Step 3: Create catalog novel tile**

Create `galaxy_novels_app/lib/features/catalog/presentation/widgets/catalog_novel_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../data/models/catalog_data.dart';

class CatalogNovelTile extends StatelessWidget {
  const CatalogNovelTile({required this.novel, super.key});

  final CatalogNovel novel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _buildMeta(novel);
    final genres = novel.genres.take(2).map((genre) => genre.name).join('، ');

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 76,
              child: _CatalogCover(
                title: novel.title,
                url: novel.coverThumbnail.isNotEmpty
                    ? novel.coverThumbnail
                    : novel.coverMedium,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (genres.isNotEmpty)
                    Text(
                      genres,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogCover extends StatelessWidget {
  const _CatalogCover({required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedUrl = _resolveImageUrl(context, url);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: resolvedUrl == null
          ? ColoredBox(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              child: Center(
                child: Text(
                  'غلاف',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          : Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Center(
                  child: Text(
                    title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

String _buildMeta(CatalogNovel novel) {
  final parts = <String>[
    if (novel.chaptersCount > 0) '${novel.chaptersCount} فصل',
    if (novel.statusLabel.isNotEmpty) novel.statusLabel,
    if (novel.updatedAt != null) _dateLabel(novel.updatedAt!),
  ];

  return parts.join(' • ');
}

String _dateLabel(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String? _resolveImageUrl(BuildContext context, String url) {
  if (url.isEmpty) {
    return null;
  }

  try {
    return AppDependencies.of(context).config.resolve(url).toString();
  } on Object {
    return null;
  }
}
```

- [ ] **Step 4: Replace CatalogScreen**

Replace `galaxy_novels_app/lib/features/catalog/presentation/catalog_screen.dart` with:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../domain/catalog_query.dart';
import 'widgets/catalog_novel_tile.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  CatalogRepository? _repository;
  Stream<CatalogLoadState>? _catalogStream;
  CatalogQuery _query = const CatalogQuery();
  Timer? _searchDebounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppDependencies.of(context).catalogRepository;
    if (_repository != repository) {
      _repository = repository;
      _catalogStream = repository.watchCatalog();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CatalogLoadState>(
      stream: _catalogStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _CatalogSkeleton();
        }

        if (snapshot.hasError && !snapshot.hasData) {
          return _CatalogMessage(
            title: 'تعذر تحميل المكتبة الآن',
            actionLabel: 'إعادة المحاولة',
            onAction: _retryCatalog,
          );
        }

        final state = snapshot.data;
        final items = state?.items ?? const [];
        if (items.isEmpty) {
          return const _CatalogMessage(title: 'لا توجد روايات في المكتبة الآن');
        }

        final result = applyCatalogQuery(items, _query);

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: result.items.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _CatalogControls(
                query: _query,
                resultCount: result.items.length,
                availableStatuses: result.availableStatuses,
                availableGenres: result.availableGenres,
                onSearchChanged: _onSearchChanged,
                onSortChanged: (sort) {
                  setState(() => _query = _query.copyWith(sort: sort));
                },
                onFiltersChanged: (status, genre) {
                  setState(() {
                    _query = _query.copyWith(
                      statusLabel: status,
                      genreName: genre,
                      clearStatus: status == null,
                      clearGenre: genre == null,
                    );
                  });
                },
                onClear: _clearQuery,
              );
            }

            if (result.items.isEmpty && index == 1) {
              return _CatalogMessage(
                title: 'لا توجد نتائج مطابقة',
                actionLabel: 'مسح البحث والفلاتر',
                onAction: _clearQuery,
              );
            }

            final itemIndex = index - 1;
            if (itemIndex < result.items.length) {
              return CatalogNovelTile(novel: result.items[itemIndex]);
            }

            return _CatalogLoadingMore(state: state);
          },
        );
      },
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      setState(() => _query = _query.copyWith(searchText: value));
    });
  }

  void _clearQuery() {
    setState(() => _query = const CatalogQuery());
  }

  void _retryCatalog() {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    setState(() {
      _catalogStream = repository.watchCatalog();
    });
  }
}

class _CatalogControls extends StatelessWidget {
  const _CatalogControls({
    required this.query,
    required this.resultCount,
    required this.availableStatuses,
    required this.availableGenres,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onFiltersChanged,
    required this.onClear,
  });

  final CatalogQuery query;
  final int resultCount;
  final List<String> availableStatuses;
  final List<String> availableGenres;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CatalogSort> onSortChanged;
  final void Function(String? status, String? genre) onFiltersChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'ابحث في المكتبة',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              DropdownButton<CatalogSort>(
                value: query.sort,
                items: [
                  for (final sort in CatalogSort.values)
                    DropdownMenuItem(value: sort, child: Text(sort.label)),
                ],
                onChanged: (sort) {
                  if (sort != null) {
                    onSortChanged(sort);
                  }
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showFilters(context),
                icon: const Icon(Icons.tune),
                label: const Text('فلاتر'),
              ),
              const Spacer(),
              if (query.hasActiveFilters)
                TextButton(onPressed: onClear, child: const Text('مسح')),
            ],
          ),
          if (query.hasActiveFilters)
            Text(
              '$resultCount نتيجة',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    final result = await showModalBottomSheet<_FilterSelection>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _CatalogFiltersSheet(
          selectedStatus: query.statusLabel,
          selectedGenre: query.genreName,
          availableStatuses: availableStatuses,
          availableGenres: availableGenres,
        );
      },
    );

    if (result != null) {
      onFiltersChanged(result.status, result.genre);
    }
  }
}

class _CatalogFiltersSheet extends StatefulWidget {
  const _CatalogFiltersSheet({
    required this.selectedStatus,
    required this.selectedGenre,
    required this.availableStatuses,
    required this.availableGenres,
  });

  final String? selectedStatus;
  final String? selectedGenre;
  final List<String> availableStatuses;
  final List<String> availableGenres;

  @override
  State<_CatalogFiltersSheet> createState() => _CatalogFiltersSheetState();
}

class _CatalogFiltersSheetState extends State<_CatalogFiltersSheet> {
  String? _status;
  String? _genre;

  @override
  void initState() {
    super.initState();
    _status = widget.selectedStatus;
    _genre = widget.selectedGenre;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.availableStatuses.length > 1) ...[
              Text('الحالة', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final status in widget.availableStatuses)
                    FilterChip(
                      label: Text(status),
                      selected: _status == status,
                      onSelected: (selected) {
                        setState(() => _status = selected ? status : null);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (widget.availableGenres.isNotEmpty) ...[
              Text('التصنيفات', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final genre in widget.availableGenres)
                    FilterChip(
                      label: Text(genre),
                      selected: _genre == genre,
                      onSelected: (selected) {
                        setState(() => _genre = selected ? genre : null);
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        _FilterSelection(status: _status, genre: _genre),
                      );
                    },
                    child: const Text('تطبيق'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(const _FilterSelection());
                  },
                  child: const Text('مسح'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSelection {
  const _FilterSelection({this.status, this.genre});

  final String? status;
  final String? genre;
}

class _CatalogLoadingMore extends StatelessWidget {
  const _CatalogLoadingMore({required this.state});

  final CatalogLoadState? state;

  @override
  Widget build(BuildContext context) {
    if (state == null || !state!.isLoadingMore) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        'جار تحديث المكتبة...',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(width: 54, height: 76, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 160, color: color),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 120, color: color),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 90, color: color),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run widget tests**

Run:

```powershell
flutter test test/widget_test.dart
```

Expected: catalog tab tests pass with existing shell/home tests.

- [ ] **Step 6: Commit**

```powershell
git add galaxy_novels_app/lib/features/catalog/presentation/catalog_screen.dart galaxy_novels_app/lib/features/catalog/presentation/widgets/catalog_novel_tile.dart galaxy_novels_app/test/widget_test.dart
git commit -m "feat: render progressive catalog screen"
```

---

### Task 6: Final Verification

**Files:**
- All files touched by Tasks 1-5.

- [ ] **Step 1: Format**

Run:

```powershell
dart format lib test
```

Expected: completes without errors.

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
flutter test test/data/catalog_data_test.dart test/data/public_catalog_repository_test.dart test/features/catalog/catalog_query_test.dart test/widget_test.dart
```

Expected: all tests pass.

- [ ] **Step 4: Build debug APK**

Run:

```powershell
flutter build apk --debug
```

Expected: debug APK builds successfully.

- [ ] **Step 5: Review git status**

Run:

```powershell
git status --short
```

Expected: only intended source/test files are modified or staged. Existing QA screenshots and APK/XAPK inspection files remain untracked and outside commits.

- [ ] **Step 6: Commit any final polish**

If formatting changed files after the prior commits:

```powershell
git add galaxy_novels_app/lib galaxy_novels_app/test
git commit -m "chore: format catalog implementation"
```

If no files changed, skip this commit.

---

## Self-Review

- Spec coverage: The plan implements progressive catalog loading, dense list UI, visible search/sort, bottom-sheet filters, dynamic filter values, local search/sort/filter, and loading/error/empty states.
- Completeness scan: No TBD markers or incomplete implementation notes are included. The only future-facing items are explicitly outside scope.
- Type consistency: `CatalogManifest`, `CatalogPack`, `CatalogNovel`, `CatalogRepository`, `CatalogLoadState`, `CatalogQuery`, and `CatalogSort` are named consistently across tasks.
- Scope check: Page details, reader, offline cache, REST auth, and grid view stay outside this plan.
