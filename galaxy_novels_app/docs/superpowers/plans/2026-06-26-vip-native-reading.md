# VIP Native Reading Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add read-only VIP support to the Flutter app: account/details VIP state, private VIP chapter listing, and native-reader access without payment or downloads.

**Architecture:** Add a focused VIP feature boundary with domain models, a private repository over `PrivateApiClient`, and a VIP-aware reader adapter that keeps `ReaderScreen` using the existing `ReaderRepository` contract. Novel details get a third tab for VIP chapters, while downloads remain limited to public chapters.

**Tech Stack:** Flutter/Dart, `ChangeNotifier`/`ValueListenableBuilder`, existing `PrivateApiClient`, existing `ReaderRepository`, `flutter_test`.

## Execution Status

- [x] Task 0: Confirm required VIP content contract.
- [x] Task 1: Add VIP chapter domain and list repository.
- [x] Task 2: Add VIP-aware native reader routing.
- [x] Task 3: Wire VIP dependencies without breaking tests.
- [x] Task 4: Add VIP chapters tab to novel details.
- [x] Task 5: Show VIP expiry in account.
- [x] Task 6: Final docs, validation, and manual-device notes.

**Current blocker:** production still needs `GET /wp-json/wor-reader-app/v1/vip/chapter?chapter_id=ID`. Until that endpoint exists, the app lists VIP chapters but shows a clear server-route message instead of opening the first VIP chapter.

**Validation completed:** `flutter analyze`, full `flutter test`, and `flutter build apk --debug` all passed after implementation.

## Global Constraints

- No purchase, checkout, PayPal, subscription activation, or Store screen work in this implementation.
- VIP content must open in the existing native Flutter reader, not WebView.
- VIP chapter content must not be written to public cache, downloads storage, SharedPreferences, or files.
- All private requests must use `Authorization: Bearer ACCESS_TOKEN`, `X-Wor-App-Token: ACCESS_TOKEN`, and `User-Agent: WorReaderApp/1.0 Android`.
- Do not send WordPress cookies or `X-WP-Nonce` from app private requests.
- `GET /vip/chapters` and `GET /vip/continuous-next` exist on production and return `401` without auth.
- Direct first-chapter VIP reading requires a private content route. On 2026-06-26, `GET /wp-json/wor-reader-app/v1/vip/chapter?chapter_id=1` returned `rest_no_route`; execution must treat that as an API contract blocker for direct first-chapter opening.

---

## File Structure

- Create `lib/features/vip/domain/vip_chapter.dart`: VIP list models and parse helpers.
- Create `lib/features/vip/application/vip_repository.dart`: app-facing VIP repository interface and request helpers.
- Create `lib/features/vip/data/private_vip_repository.dart`: authenticated REST implementation for VIP lists and content.
- Create `lib/features/vip/data/vip_reader_request.dart`: stable internal `vip:` reader path parser/builder.
- Create `lib/features/vip/data/vip_aware_reader_repository.dart`: `ReaderRepository` wrapper that routes public paths to public reading and VIP paths to `PrivateVipRepository`.
- Create `lib/features/vip/application/vip_chapters_controller.dart`: state holder for the novel details VIP tab.
- Create `lib/features/vip/presentation/vip_chapters_section.dart`: VIP tab UI.
- Modify `lib/app/app_dependencies.dart`: expose `VipRepository`.
- Modify `lib/app/galaxy_novels_app.dart`: wire `PrivateVipRepository` and `VipAwareReaderRepository`.
- Modify `lib/features/novel_details/presentation/novel_details_screen.dart`: pass VIP repository into content callbacks.
- Modify `lib/features/novel_details/presentation/widgets/novel_details_content.dart`: add VIP tab.
- Modify `lib/features/account/presentation/widgets/signed_in_account_view.dart`: show VIP expiry text when present.
- Add tests under `test/features/vip/`.
- Extend relevant widget tests for novel details and account display.
- Update `docs/app_api_gap_audit.md` after implementation.

---

### Task 0: Confirm The Required VIP Content Contract

**Files:**
- Read: `docs/superpowers/specs/2026-06-26-vip-native-reading-design.md`
- No app files changed in this task.

**Interfaces:**
- Consumes: production API availability.
- Produces: a go/no-go decision for direct first VIP chapter reading.

- [ ] **Step 1: Confirm list route exists**

Run:

```powershell
curl.exe -s -i -H "User-Agent: WorReaderApp/1.0 Android" -H "Accept: application/json" "https://galaxynovels.com/wp-json/wor-reader-app/v1/vip/chapters?novel_id=1&limit=1"
```

Expected: `401 Unauthorized` with JSON code `wor_reader_app_login_required`, not `rest_no_route`.

- [ ] **Step 2: Confirm next route exists**

Run:

```powershell
curl.exe -s -i -H "User-Agent: WorReaderApp/1.0 Android" -H "Accept: application/json" "https://galaxynovels.com/wp-json/wor-reader-app/v1/vip/continuous-next?chapter_id=1"
```

Expected: `401 Unauthorized` with JSON code `wor_reader_app_login_required`, not `rest_no_route`.

- [ ] **Step 3: Confirm direct content route before enabling opening a VIP row**

Run:

```powershell
curl.exe -s -i -H "User-Agent: WorReaderApp/1.0 Android" -H "Accept: application/json" "https://galaxynovels.com/wp-json/wor-reader-app/v1/vip/chapter?chapter_id=1"
```

Expected for full implementation: `401 Unauthorized` or `403 Forbidden`, not `rest_no_route`.

If it returns:

```json
{"code":"rest_no_route","data":{"status":404}}
```

then keep Task 1 and Task 4 list/status work executable, but do not enable row taps that promise direct VIP reading. Ask the template owner to add this app route:

```php
register_rest_route(WOR_READER_APP_API_NAMESPACE, '/vip/chapter', array(
    'methods' => WP_REST_Server::READABLE,
    'callback' => 'wor_reader_vip_rest_chapter',
    'permission_callback' => 'wor_reader_vip_rest_chapters_permission',
    'args' => array(
        'chapter_id' => array('required' => true, 'sanitize_callback' => 'absint'),
    ),
));
```

The route response must match the existing public `ReaderChapterContent` JSON shape:

```json
{
  "data": {
    "id": 123,
    "novel_id": 45,
    "label": "الفصل 123",
    "title": "عنوان الفصل",
    "display_title": "الفصل 123: عنوان الفصل",
    "position": 123,
    "total": 200,
    "content_html": "<p>...</p>",
    "navigation": {
      "previous_api": "",
      "next_api": "vip:next:123",
      "previous_id": 122,
      "next_id": 124
    }
  }
}
```

The route must send `Cache-Control: private, no-store, no-cache, must-revalidate, max-age=0`.

- [ ] **Step 4: Commit nothing**

This is an execution gate only. No commit is needed.

---

### Task 1: Add VIP Chapter Domain And List Repository

**Files:**
- Create: `lib/features/vip/domain/vip_chapter.dart`
- Create: `lib/features/vip/application/vip_repository.dart`
- Create: `lib/features/vip/data/private_vip_repository.dart`
- Test: `test/features/vip/vip_chapter_test.dart`
- Test: `test/features/vip/private_vip_repository_test.dart`

**Interfaces:**
- Consumes: `PrivateApiClient.getAuthenticated`.
- Produces:
  - `VipChapter.fromJson(Map<String, dynamic>)`
  - `VipChapterPage.fromJson(Map<String, dynamic>)`
  - `VipRepository.loadChapters(VipChapterQuery query)`
  - `VipAccessException`

- [ ] **Step 1: Write failing model tests**

Create `test/features/vip/vip_chapter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/vip/domain/vip_chapter.dart';

void main() {
  test('parses a VIP chapter page', () {
    final page = VipChapterPage.fromJson({
      'items': [
        {
          'id': 11,
          'number': '164',
          'position': 164,
          'order': '164.000000',
          'title': 'الفصل 164',
          'url': 'https://galaxynovels.com/chapter-164/',
          'public_at': '2026/06/20 08:00',
          'views': 99,
          'comments': 4,
        },
      ],
      'has_more': true,
      'next_cursor': {'order': '164.000000', 'id': 11},
      'total_available': 40,
    });

    expect(page.items, hasLength(1));
    expect(page.items.single.id, 11);
    expect(page.items.single.displayLabel, 'الفصل 164');
    expect(page.hasMore, isTrue);
    expect(page.nextCursorOrder, '164.000000');
    expect(page.nextCursorId, 11);
    expect(page.totalAvailable, 40);
  });

  test('falls back to position when a VIP chapter has no number', () {
    final chapter = VipChapter.fromJson({
      'id': 7,
      'position': 3,
      'title': 'بداية خاصة',
    });

    expect(chapter.displayLabel, 'الفصل 3');
    expect(chapter.title, 'بداية خاصة');
  });
}
```

- [ ] **Step 2: Run model tests to verify they fail**

Run:

```powershell
flutter test test/features/vip/vip_chapter_test.dart
```

Expected: FAIL because `VipChapter` does not exist.

- [ ] **Step 3: Implement VIP domain models**

Create `lib/features/vip/domain/vip_chapter.dart`:

```dart
class VipChapter {
  const VipChapter({
    required this.id,
    required this.number,
    required this.position,
    required this.order,
    required this.title,
    required this.url,
    required this.publicAt,
    required this.views,
    required this.comments,
  });

  factory VipChapter.fromJson(Map<String, dynamic> json) {
    return VipChapter(
      id: _asInt(json['id']),
      number: _asString(json['number']),
      position: _asInt(json['position']),
      order: _asString(json['order']),
      title: _asString(json['title']),
      url: _asString(json['url']),
      publicAt: _asString(json['public_at']),
      views: _asInt(json['views']),
      comments: _asInt(json['comments']),
    );
  }

  final int id;
  final String number;
  final int position;
  final String order;
  final String title;
  final String url;
  final String publicAt;
  final int views;
  final int comments;

  String get displayLabel {
    if (number.isNotEmpty) {
      return 'الفصل $number';
    }
    if (position > 0) {
      return 'الفصل $position';
    }
    return 'فصل VIP';
  }
}

class VipChapterPage {
  const VipChapterPage({
    required this.items,
    required this.hasMore,
    required this.nextCursorOrder,
    required this.nextCursorId,
    required this.totalAvailable,
  });

  factory VipChapterPage.fromJson(Map<String, dynamic> json) {
    final cursor = _asMap(json['next_cursor']);
    return VipChapterPage(
      items: _asList(json['items'])
          .map((item) => VipChapter.fromJson(_asMap(item)))
          .where((chapter) => chapter.id > 0)
          .toList(growable: false),
      hasMore: json['has_more'] == true,
      nextCursorOrder: _asString(cursor['order']),
      nextCursorId: _asInt(cursor['id']),
      totalAvailable: _asInt(json['total_available']),
    );
  }

  final List<VipChapter> items;
  final bool hasMore;
  final String nextCursorOrder;
  final int nextCursorId;
  final int totalAvailable;
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

List<Object?> _asList(Object? value) {
  if (value is List) {
    return value.cast<Object?>();
  }
  return const [];
}

String _asString(Object? value) => value?.toString().trim() ?? '';

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
```

- [ ] **Step 4: Run model tests to verify they pass**

Run:

```powershell
flutter test test/features/vip/vip_chapter_test.dart
```

Expected: PASS.

- [ ] **Step 5: Write failing repository tests**

Create `test/features/vip/private_vip_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/vip/application/vip_repository.dart';
import 'package:galaxy_novels_app/features/vip/data/private_vip_repository.dart';

void main() {
  test('loads VIP chapters with bearer auth and query parameters', () async {
    late PrivateRawRequest sent;
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async {
        sent = request;
        return const PrivateRawResponse(
          statusCode: 200,
          body: '{"items":[{"id":9,"number":"9","position":9}],"has_more":false,"next_cursor":{"order":"","id":0},"total_available":1}',
        );
      },
    )..updateAccessToken('wra_vip_token');
    final repository = PrivateVipRepository(client: client);

    final page = await repository.loadChapters(
      const VipChapterQuery(
        novelId: 77,
        limit: 25,
        order: VipChapterOrder.desc,
        search: '9',
      ),
    );

    expect(sent.method, 'GET');
    expect(sent.uri.path, '/wp-json/wor-reader-app/v1/vip/chapters');
    expect(sent.uri.queryParameters['novel_id'], '77');
    expect(sent.uri.queryParameters['limit'], '25');
    expect(sent.uri.queryParameters['order'], 'desc');
    expect(sent.uri.queryParameters['search'], '9');
    expect(sent.headers['Authorization'], 'Bearer wra_vip_token');
    expect(sent.headers, isNot(contains('X-WP-Nonce')));
    expect(page.items.single.id, 9);
  });

  test('maps 401 and 403 into VIP access exceptions', () async {
    Future<VipAccessException> loadWith(int statusCode, String code) async {
      final repository = PrivateVipRepository(
        client: PrivateApiClient(
          config: const AppConfig(siteBaseUrl: 'https://example.com/'),
          requestSender: (_) async => PrivateRawResponse(
            statusCode: statusCode,
            body: '{"code":"$code","message":"blocked"}',
          ),
        )..updateAccessToken('wra_vip_token'),
      );
      try {
        await repository.loadChapters(const VipChapterQuery(novelId: 77));
        throw StateError('Expected VipAccessException.');
      } on VipAccessException catch (error) {
        return error;
      }
    }

    expect((await loadWith(401, 'login_required')).reason, VipAccessReason.loginRequired);
    expect((await loadWith(403, 'subscription_required')).reason, VipAccessReason.subscriptionRequired);
  });
}
```

- [ ] **Step 6: Run repository tests to verify they fail**

Run:

```powershell
flutter test test/features/vip/private_vip_repository_test.dart
```

Expected: FAIL because VIP repository files do not exist.

- [ ] **Step 7: Implement repository interface and private adapter**

Create `lib/features/vip/application/vip_repository.dart`:

```dart
import '../domain/vip_chapter.dart';

enum VipChapterOrder { asc, desc }

class VipChapterQuery {
  const VipChapterQuery({
    required this.novelId,
    this.cursorOrder = '',
    this.cursorId = 0,
    this.limit = 50,
    this.order = VipChapterOrder.asc,
    this.search = '',
  });

  final int novelId;
  final String cursorOrder;
  final int cursorId;
  final int limit;
  final VipChapterOrder order;
  final String search;
}

enum VipAccessReason { loginRequired, subscriptionRequired, unavailable }

class VipAccessException implements Exception {
  const VipAccessException(this.reason, this.message);

  final VipAccessReason reason;
  final String message;

  @override
  String toString() => 'VipAccessException($reason): $message';
}

abstract interface class VipRepository {
  Future<VipChapterPage> loadChapters(VipChapterQuery query);
}
```

Create `lib/features/vip/data/private_vip_repository.dart`:

```dart
import '../../../core/network/private_api_client.dart';
import '../../../data/models/reader_content_data.dart';
import '../application/vip_repository.dart';
import '../domain/vip_chapter.dart';

class PrivateVipRepository implements VipRepository {
  const PrivateVipRepository({required PrivateApiClient client})
    : _client = client;

  final PrivateApiClient _client;

  @override
  Future<VipChapterPage> loadChapters(VipChapterQuery query) async {
    try {
      final params = <String, String>{
        'novel_id': query.novelId.toString(),
        'limit': query.limit.toString(),
        'order': query.order == VipChapterOrder.desc ? 'desc' : 'asc',
      };
      if (query.cursorOrder.isNotEmpty) {
        params['cursor_order'] = query.cursorOrder;
        params['cursor_id'] = query.cursorId.toString();
      }
      if (query.search.trim().isNotEmpty) {
        params['search'] = query.search.trim();
      }
      final path = Uri(path: 'vip/chapters', queryParameters: params).toString();
      final json = await _client.getAuthenticated(path);
      return VipChapterPage.fromJson(json);
    } on PrivateApiException catch (error) {
      throw _vipExceptionFrom(error);
    }
  }

  Future<ReaderChapterContent> loadChapterById(int chapterId) async {
    if (chapterId <= 0) {
      throw const FormatException('VIP chapter id must be positive.');
    }
    try {
      final json = await _client.getAuthenticated('vip/chapter?chapter_id=$chapterId');
      return ReaderChapterContent.fromJson(json);
    } on PrivateApiException catch (error) {
      throw _vipExceptionFrom(error);
    }
  }

  Future<ReaderChapterContent> loadNextAfter(int chapterId) async {
    if (chapterId <= 0) {
      throw const FormatException('VIP chapter id must be positive.');
    }
    try {
      final json = await _client.getAuthenticated('vip/continuous-next?chapter_id=$chapterId');
      return _readerContentFromVipNext(json);
    } on PrivateApiException catch (error) {
      throw _vipExceptionFrom(error);
    }
  }
}

VipAccessException _vipExceptionFrom(PrivateApiException error) {
  if (error.statusCode == 401) {
    return VipAccessException(VipAccessReason.loginRequired, error.message);
  }
  if (error.statusCode == 403) {
    return VipAccessException(VipAccessReason.subscriptionRequired, error.message);
  }
  return VipAccessException(VipAccessReason.unavailable, error.message);
}

ReaderChapterContent _readerContentFromVipNext(Map<String, dynamic> json) {
  if (json.containsKey('data') || json.containsKey('content_html')) {
    return ReaderChapterContent.fromJson(json);
  }
  final html = json['html']?.toString() ?? '';
  final chapterId = int.tryParse(json['chapter_id']?.toString() ?? '') ?? 0;
  if (html.isEmpty || chapterId <= 0) {
    throw const FormatException('Invalid VIP next chapter response.');
  }
  final attrs = _articleAttributes(html);
  final contentHtml = _contentHtml(html);
  final nextId = int.tryParse(attrs['data-next-id'] ?? '') ?? 0;
  final previousUrl = attrs['data-previous-url'] ?? '';
  final previousId = _idFromUrl(previousUrl);
  return ReaderChapterContent(
    id: chapterId,
    novelId: int.tryParse(attrs['data-novel-id'] ?? '') ?? 0,
    label: attrs['data-chapter-label'] ?? '',
    title: attrs['data-chapter-title'] ?? '',
    displayTitle: attrs['data-chapter-title'] ?? attrs['data-chapter-label'] ?? '',
    position: int.tryParse(attrs['data-position'] ?? '') ?? 0,
    total: int.tryParse(attrs['data-total'] ?? '') ?? 0,
    contentHtml: contentHtml,
    navigation: ReaderChapterNavigation(
      previousApi: previousId > 0 ? 'vip:chapter:$previousId' : '',
      nextApi: nextId > 0 ? 'vip:next:$chapterId' : '',
      previousId: previousId,
      nextId: nextId,
    ),
  );
}

Map<String, String> _articleAttributes(String html) {
  final article = RegExp(r'<article\b([^>]*)>', multiLine: true).firstMatch(html)?.group(1) ?? '';
  final attrs = <String, String>{};
  for (final match in RegExp(r'(data-[a-zA-Z0-9_-]+)="([^"]*)"').allMatches(article)) {
    attrs[match.group(1)!] = match.group(2)!;
  }
  return attrs;
}

String _contentHtml(String html) {
  final match = RegExp(
    r'<div[^>]*class="[^"]*wor-reading-page__content[^"]*"[^>]*>([\s\S]*?)</div>\s*</article>',
    multiLine: true,
  ).firstMatch(html);
  return match?.group(1)?.trim() ?? html;
}

int _idFromUrl(String url) {
  final match = RegExp(r'(\d+)(?:/)?$').firstMatch(url);
  return int.tryParse(match?.group(1) ?? '') ?? 0;
}
```

- [ ] **Step 8: Run repository tests to verify they pass**

Run:

```powershell
flutter test test/features/vip/vip_chapter_test.dart test/features/vip/private_vip_repository_test.dart
```

Expected: PASS.

- [ ] **Step 9: Commit**

```powershell
git add lib/features/vip/domain/vip_chapter.dart lib/features/vip/application/vip_repository.dart lib/features/vip/data/private_vip_repository.dart test/features/vip/vip_chapter_test.dart test/features/vip/private_vip_repository_test.dart
git commit -m "feat(vip): add private chapter repository"
```

---

### Task 2: Add VIP-Aware Native Reader Routing

**Files:**
- Create: `lib/features/vip/data/vip_reader_request.dart`
- Create: `lib/features/vip/data/vip_aware_reader_repository.dart`
- Modify: `lib/features/vip/data/private_vip_repository.dart`
- Test: `test/features/vip/vip_aware_reader_repository_test.dart`

**Interfaces:**
- Consumes: `PrivateVipRepository.loadChapterById`, `PrivateVipRepository.loadNextAfter`, `ReaderRepository.loadChapter`.
- Produces:
  - `VipReaderRequest.chapter(int id)`
  - `VipReaderRequest.nextAfter(int id)`
  - `VipAwareReaderRepository.loadChapter(String contentApi)`

- [ ] **Step 1: Write failing routing tests**

Create `test/features/vip/vip_aware_reader_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/features/vip/data/private_vip_repository.dart';
import 'package:galaxy_novels_app/features/vip/data/vip_aware_reader_repository.dart';
import 'package:galaxy_novels_app/features/vip/data/vip_reader_request.dart';

void main() {
  test('routes public requests to the public reader repository', () async {
    final public = _FakeReaderRepository();
    final repository = VipAwareReaderRepository(
      publicReader: public,
      vipRepository: PrivateVipRepository(
        client: PrivateApiClient(
          config: const AppConfig(siteBaseUrl: 'https://example.com/'),
          requestSender: (_) async => throw StateError('VIP must not be called.'),
        ),
      ),
    );

    final content = await repository.loadChapter('/wp-json/wor-reader-app/v1/chapters/1');

    expect(content.id, 1);
    expect(public.calls, 1);
  });

  test('routes vip chapter requests to the private chapter endpoint', () async {
    late PrivateRawRequest sent;
    final vip = PrivateVipRepository(
      client: PrivateApiClient(
        config: const AppConfig(siteBaseUrl: 'https://example.com/'),
        requestSender: (request) async {
          sent = request;
          return const PrivateRawResponse(
            statusCode: 200,
            body: '{"data":{"id":44,"novel_id":8,"label":"الفصل 44","title":"VIP","display_title":"VIP","position":44,"total":80,"content_html":"<p>خاص</p>","navigation":{"previous_api":"","next_api":"vip:next:44","previous_id":0,"next_id":45}}}',
          );
        },
      )..updateAccessToken('wra_vip_token'),
    );
    final repository = VipAwareReaderRepository(
      publicReader: _FakeReaderRepository(),
      vipRepository: vip,
    );

    final content = await repository.loadChapter(VipReaderRequest.chapter(44));

    expect(sent.uri.path, '/wp-json/wor-reader-app/v1/vip/chapter');
    expect(sent.uri.queryParameters['chapter_id'], '44');
    expect(content.id, 44);
    expect(content.contentHtml, '<p>خاص</p>');
  });
}

class _FakeReaderRepository implements ReaderRepository {
  int calls = 0;

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    calls++;
    return const ReaderChapterContent(
      id: 1,
      novelId: 2,
      label: 'الفصل 1',
      title: 'عام',
      displayTitle: 'عام',
      position: 1,
      total: 10,
      contentHtml: '<p>عام</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }
}
```

- [ ] **Step 2: Run routing tests to verify they fail**

Run:

```powershell
flutter test test/features/vip/vip_aware_reader_repository_test.dart
```

Expected: FAIL because VIP-aware reader files do not exist.

- [ ] **Step 3: Implement VIP reader request parser**

Create `lib/features/vip/data/vip_reader_request.dart`:

```dart
enum VipReaderRequestKind { chapter, nextAfter }

class VipReaderRequest {
  const VipReaderRequest._({required this.kind, required this.chapterId});

  final VipReaderRequestKind kind;
  final int chapterId;

  static String chapter(int chapterId) => 'vip:chapter:$chapterId';

  static String nextAfter(int chapterId) => 'vip:next:$chapterId';

  static VipReaderRequest? tryParse(String value) {
    final parts = value.split(':');
    if (parts.length != 3 || parts.first != 'vip') {
      return null;
    }
    final chapterId = int.tryParse(parts[2]) ?? 0;
    if (chapterId <= 0) {
      return null;
    }
    return switch (parts[1]) {
      'chapter' => VipReaderRequest._(
        kind: VipReaderRequestKind.chapter,
        chapterId: chapterId,
      ),
      'next' => VipReaderRequest._(
        kind: VipReaderRequestKind.nextAfter,
        chapterId: chapterId,
      ),
      _ => null,
    };
  }
}
```

- [ ] **Step 4: Implement VIP-aware reader repository**

Create `lib/features/vip/data/vip_aware_reader_repository.dart`:

```dart
import '../../../data/models/reader_content_data.dart';
import '../../../data/repositories/reader_repository.dart';
import 'private_vip_repository.dart';
import 'vip_reader_request.dart';

class VipAwareReaderRepository implements ReaderRepository {
  const VipAwareReaderRepository({
    required ReaderRepository publicReader,
    required PrivateVipRepository vipRepository,
  }) : _publicReader = publicReader,
       _vipRepository = vipRepository;

  final ReaderRepository _publicReader;
  final PrivateVipRepository _vipRepository;

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) {
    final vipRequest = VipReaderRequest.tryParse(contentApi);
    if (vipRequest == null) {
      return _publicReader.loadChapter(contentApi);
    }
    return switch (vipRequest.kind) {
      VipReaderRequestKind.chapter => _vipRepository.loadChapterById(
        vipRequest.chapterId,
      ),
      VipReaderRequestKind.nextAfter => _vipRepository.loadNextAfter(
        vipRequest.chapterId,
      ),
    };
  }
}
```

- [ ] **Step 5: Update VIP next navigation to use internal paths**

In `lib/features/vip/data/private_vip_repository.dart`, import `vip_reader_request.dart` and replace hard-coded strings:

```dart
import 'vip_reader_request.dart';
```

Inside `_readerContentFromVipNext`, set navigation like this:

```dart
navigation: ReaderChapterNavigation(
  previousApi: previousId > 0 ? VipReaderRequest.chapter(previousId) : '',
  nextApi: nextId > 0 ? VipReaderRequest.nextAfter(chapterId) : '',
  previousId: previousId,
  nextId: nextId,
),
```

- [ ] **Step 6: Run routing tests to verify they pass**

Run:

```powershell
flutter test test/features/vip/vip_aware_reader_repository_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add lib/features/vip/data/vip_reader_request.dart lib/features/vip/data/vip_aware_reader_repository.dart lib/features/vip/data/private_vip_repository.dart test/features/vip/vip_aware_reader_repository_test.dart
git commit -m "feat(vip): route private chapters through native reader"
```

---

### Task 3: Wire VIP Dependencies Without Breaking Tests

**Files:**
- Modify: `lib/app/app_dependencies.dart`
- Modify: `lib/app/galaxy_novels_app.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `VipRepository`, `PrivateVipRepository`, `VipAwareReaderRepository`.
- Produces: `AppDependencies.vipRepository`.

- [ ] **Step 1: Write failing dependency assertion**

Add a widget test in `test/widget_test.dart` near existing dependency smoke tests:

```dart
testWidgets('app exposes the VIP repository dependency', (tester) async {
  late AppDependencies captured;
  await tester.pumpWidget(
    GalaxyNovelsApp(
      homeRepository: FakeHomeRepository(),
      catalogRepository: FakeCatalogRepository(),
      novelRepository: FakeNovelRepository(),
      readerRepository: FakeReaderRepository(),
      rankingsRepository: FakeRankingsRepository(),
      searchRepository: FakeSearchRepository(),
      readingHistoryRepository: FakeReadingHistoryRepository(),
      downloadsRepository: FakeDownloadsRepository(),
      readerPreferencesRepository: FakeReaderPreferencesRepository(),
      authRepository: FakeAuthRepository(),
      commentsRepository: FakeCommentsRepository(),
      favoritesRepository: FakeFavoritesRepository(),
      novelEngagementRepository: FakeNovelEngagementRepository(),
      readingActivityRecorder: const NoopReadingActivityRecorder(),
    ),
  );
  await tester.pump();
  captured = tester.element(find.byType(AppShell)).dependOnInheritedWidgetOfExactType<AppDependencies>()!;
  expect(captured.vipRepository, isNotNull);
});
```

If this exact harness does not match the current test helpers, keep the assertion target identical and adapt only object construction to the helper names already used in `test/widget_test.dart`.

- [ ] **Step 2: Run widget dependency test to verify it fails**

Run:

```powershell
flutter test test/widget_test.dart --plain-name "app exposes the VIP repository dependency"
```

Expected: FAIL because `vipRepository` is not exposed.

- [ ] **Step 3: Add VIP repository to dependencies**

In `lib/app/app_dependencies.dart`, import and add:

```dart
import '../features/vip/application/vip_repository.dart';
```

Add constructor parameter:

```dart
required this.vipRepository,
```

Add field:

```dart
final VipRepository vipRepository;
```

Add `updateShouldNotify` comparison:

```dart
vipRepository != oldWidget.vipRepository ||
```

- [ ] **Step 4: Wire default VIP repository and VIP-aware reader**

In `lib/app/galaxy_novels_app.dart`, import:

```dart
import '../features/vip/data/private_vip_repository.dart';
import '../features/vip/data/vip_aware_reader_repository.dart';
```

Add state field:

```dart
PrivateVipRepository? _defaultVipRepository;
```

In `didUpdateWidget`, when `configChanged`, add:

```dart
_defaultVipRepository = null;
```

In `build`, replace the reader and VIP setup with:

```dart
final effectiveVipRepository =
    _defaultVipRepository ??= PrivateVipRepository(client: _privateApiClientFor());
final publicReaderRepository = PublicReaderRepository(cacheClient: cacheClient);
final effectiveReaderRepository =
    widget.readerRepository ??
    VipAwareReaderRepository(
      publicReader: publicReaderRepository,
      vipRepository: effectiveVipRepository,
    );
```

Pass into `AppDependencies`:

```dart
vipRepository: effectiveVipRepository,
```

- [ ] **Step 5: Run dependency test and existing smoke tests**

Run:

```powershell
flutter test test/widget_test.dart --plain-name "app exposes the VIP repository dependency"
flutter test test/features/vip
```

Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add lib/app/app_dependencies.dart lib/app/galaxy_novels_app.dart test/widget_test.dart
git commit -m "feat(vip): wire VIP app dependencies"
```

---

### Task 4: Add VIP Chapters Tab To Novel Details

**Files:**
- Create: `lib/features/vip/application/vip_chapters_controller.dart`
- Create: `lib/features/vip/presentation/vip_chapters_section.dart`
- Modify: `lib/features/novel_details/presentation/novel_details_screen.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_details_content.dart`
- Test: `test/features/vip/vip_chapters_controller_test.dart`
- Test: `test/features/vip/vip_chapters_section_test.dart`

**Interfaces:**
- Consumes: `VipRepository.loadChapters`, `NovelEngagementState.userState?.vip.canReadPrivate`.
- Produces: VIP tab UI and row taps using `VipReaderRequest.chapter(chapter.id)`.

- [ ] **Step 1: Write failing controller tests**

Create `test/features/vip/vip_chapters_controller_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/vip/application/vip_chapters_controller.dart';
import 'package:galaxy_novels_app/features/vip/application/vip_repository.dart';
import 'package:galaxy_novels_app/features/vip/domain/vip_chapter.dart';

void main() {
  test('loads initial VIP chapters once', () async {
    final repository = _FakeVipRepository([
      const VipChapterPage(
        items: [VipChapter(id: 1, number: '1', position: 1, order: '1', title: 'VIP 1', url: '', publicAt: '', views: 0, comments: 0)],
        hasMore: false,
        nextCursorOrder: '',
        nextCursorId: 0,
        totalAvailable: 1,
      ),
    ]);
    final controller = VipChaptersController(repository: repository, novelId: 9);

    await controller.loadInitial();

    expect(controller.value.status, VipChaptersStatus.ready);
    expect(controller.value.chapters.single.id, 1);
    expect(repository.queries.single.novelId, 9);
  });

  test('maps subscription errors into blocked state', () async {
    final controller = VipChaptersController(
      repository: _FailingVipRepository(
        const VipAccessException(VipAccessReason.subscriptionRequired, 'VIP مطلوب'),
      ),
      novelId: 9,
    );

    await controller.loadInitial();

    expect(controller.value.status, VipChaptersStatus.subscriptionRequired);
    expect(controller.value.errorMessage, 'VIP مطلوب');
  });
}

class _FakeVipRepository implements VipRepository {
  _FakeVipRepository(this.pages);

  final List<VipChapterPage> pages;
  final queries = <VipChapterQuery>[];

  @override
  Future<VipChapterPage> loadChapters(VipChapterQuery query) async {
    queries.add(query);
    return pages.removeAt(0);
  }
}

class _FailingVipRepository implements VipRepository {
  const _FailingVipRepository(this.error);

  final Object error;

  @override
  Future<VipChapterPage> loadChapters(VipChapterQuery query) => Future.error(error);
}
```

- [ ] **Step 2: Run controller tests to verify they fail**

Run:

```powershell
flutter test test/features/vip/vip_chapters_controller_test.dart
```

Expected: FAIL because `VipChaptersController` does not exist.

- [ ] **Step 3: Implement VIP chapters controller**

Create `lib/features/vip/application/vip_chapters_controller.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../domain/vip_chapter.dart';
import 'vip_repository.dart';

enum VipChaptersStatus {
  idle,
  loading,
  ready,
  loginRequired,
  subscriptionRequired,
  failure,
}

class VipChaptersState {
  const VipChaptersState({
    required this.status,
    this.chapters = const [],
    this.hasMore = false,
    this.nextCursorOrder = '',
    this.nextCursorId = 0,
    this.totalAvailable = 0,
    this.errorMessage,
  });

  const VipChaptersState.idle() : this(status: VipChaptersStatus.idle);

  final VipChaptersStatus status;
  final List<VipChapter> chapters;
  final bool hasMore;
  final String nextCursorOrder;
  final int nextCursorId;
  final int totalAvailable;
  final String? errorMessage;
}

class VipChaptersController extends ValueNotifier<VipChaptersState> {
  VipChaptersController({required VipRepository repository, required int novelId})
    : _repository = repository,
      _novelId = novelId,
      super(const VipChaptersState.idle());

  final VipRepository _repository;
  final int _novelId;
  bool _loadingMore = false;

  Future<void> loadInitial() async {
    value = const VipChaptersState(status: VipChaptersStatus.loading);
    await _load(VipChapterQuery(novelId: _novelId), reset: true);
  }

  Future<void> loadMore() async {
    if (_loadingMore || !value.hasMore) {
      return;
    }
    _loadingMore = true;
    try {
      await _load(
        VipChapterQuery(
          novelId: _novelId,
          cursorOrder: value.nextCursorOrder,
          cursorId: value.nextCursorId,
        ),
        reset: false,
      );
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> retry() => loadInitial();

  Future<void> _load(VipChapterQuery query, {required bool reset}) async {
    final effectiveQuery = VipChapterQuery(
      novelId: _novelId,
      cursorOrder: reset ? '' : query.cursorOrder,
      cursorId: reset ? 0 : query.cursorId,
      limit: 50,
    );
    try {
      final page = await _repository.loadChapters(effectiveQuery);
      final chapters = reset ? page.items : [...value.chapters, ...page.items];
      value = VipChaptersState(
        status: VipChaptersStatus.ready,
        chapters: chapters,
        hasMore: page.hasMore,
        nextCursorOrder: page.nextCursorOrder,
        nextCursorId: page.nextCursorId,
        totalAvailable: page.totalAvailable,
      );
    } on VipAccessException catch (error) {
      value = VipChaptersState(
        status: switch (error.reason) {
          VipAccessReason.loginRequired => VipChaptersStatus.loginRequired,
          VipAccessReason.subscriptionRequired => VipChaptersStatus.subscriptionRequired,
          VipAccessReason.unavailable => VipChaptersStatus.failure,
        },
        errorMessage: error.message,
      );
    } on Object {
      value = const VipChaptersState(
        status: VipChaptersStatus.failure,
        errorMessage: 'تعذر تحميل فصول VIP الآن.',
      );
    }
  }
}
```

- [ ] **Step 4: Run controller tests to verify they pass**

Run:

```powershell
flutter test test/features/vip/vip_chapters_controller_test.dart
```

Expected: PASS.

- [ ] **Step 5: Create VIP section widget**

Create `lib/features/vip/presentation/vip_chapters_section.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../application/vip_chapters_controller.dart';
import '../data/vip_reader_request.dart';
import '../domain/vip_chapter.dart';

class VipChaptersSection extends StatefulWidget {
  const VipChaptersSection({
    required this.controller,
    required this.canReadPrivate,
    required this.onSignIn,
    required this.onOpenVipChapter,
    super.key,
  });

  final VipChaptersController controller;
  final bool canReadPrivate;
  final VoidCallback onSignIn;
  final void Function(String contentApi, String title) onOpenVipChapter;

  @override
  State<VipChaptersSection> createState() => _VipChaptersSectionState();
}

class _VipChaptersSectionState extends State<VipChaptersSection> {
  @override
  void initState() {
    super.initState();
    if (widget.canReadPrivate) {
      widget.controller.loadInitial();
    }
  }

  @override
  void didUpdateWidget(covariant VipChaptersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.canReadPrivate && widget.canReadPrivate) {
      widget.controller.loadInitial();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canReadPrivate) {
      return SliverToBoxAdapter(
        child: _VipMessage(
          icon: Icons.workspace_premium_outlined,
          title: 'فصول VIP',
          message: 'هذه الفصول متاحة للمشتركين فقط. الشراء داخل التطبيق مؤجل حاليا.',
          actionLabel: 'حسابي',
          onAction: widget.onSignIn,
        ),
      );
    }

    return ValueListenableBuilder<VipChaptersState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        return switch (state.status) {
          VipChaptersStatus.idle || VipChaptersStatus.loading => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
          VipChaptersStatus.loginRequired => SliverToBoxAdapter(
            child: _VipMessage(
              icon: Icons.login_rounded,
              title: 'سجّل الدخول',
              message: state.errorMessage ?? 'سجّل الدخول لعرض فصول VIP.',
              actionLabel: 'حسابي',
              onAction: widget.onSignIn,
            ),
          ),
          VipChaptersStatus.subscriptionRequired => SliverToBoxAdapter(
            child: _VipMessage(
              icon: Icons.lock_outline_rounded,
              title: 'اشتراك VIP مطلوب',
              message: state.errorMessage ?? 'لا يوجد اشتراك VIP فعال لهذا الحساب.',
            ),
          ),
          VipChaptersStatus.failure => SliverToBoxAdapter(
            child: _VipMessage(
              icon: Icons.cloud_off_outlined,
              title: 'تعذر تحميل فصول VIP',
              message: state.errorMessage ?? 'حاول مرة أخرى بعد قليل.',
              actionLabel: 'إعادة المحاولة',
              onAction: widget.controller.retry,
            ),
          ),
          VipChaptersStatus.ready => _VipChapterSliverList(
            state: state,
            onOpen: widget.onOpenVipChapter,
            onLoadMore: widget.controller.loadMore,
          ),
        };
      },
    );
  }
}

class _VipChapterSliverList extends StatelessWidget {
  const _VipChapterSliverList({
    required this.state,
    required this.onOpen,
    required this.onLoadMore,
  });

  final VipChaptersState state;
  final void Function(String contentApi, String title) onOpen;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.chapters.isEmpty) {
      return const SliverToBoxAdapter(
        child: _VipMessage(
          icon: Icons.workspace_premium_outlined,
          title: 'لا توجد فصول VIP متاحة',
          message: 'لا توجد فصول خاصة لهذه الرواية الآن.',
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == state.chapters.length) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: OutlinedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('تحميل المزيد'),
              ),
            );
          }
          final chapter = state.chapters[index];
          return _VipChapterRow(
            chapter: chapter,
            onTap: () => onOpen(
              VipReaderRequest.chapter(chapter.id),
              chapter.displayLabel,
            ),
          );
        },
        childCount: state.chapters.length + (state.hasMore ? 1 : 0),
        addAutomaticKeepAlives: false,
      ),
    );
  }
}

class _VipChapterRow extends StatelessWidget {
  const _VipChapterRow({required this.chapter, required this.onTap});

  final VipChapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          height: 74,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.gold.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.workspace_premium_outlined, color: tokens.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    if (chapter.title.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: tokens.gold),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _VipMessage extends StatelessWidget {
  const _VipMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: tokens.gold),
              const SizedBox(height: 10),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary)),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Add VIP tab to details content**

In `novel_details_content.dart`, import:

```dart
import '../../../vip/application/vip_chapters_controller.dart';
import '../../../vip/presentation/vip_chapters_section.dart';
```

Change enum:

```dart
enum _NovelDetailsSection { chapters, vip, comments }
```

Add `vipController` and `onOpenVipChapter` to `NovelDetailsContent` constructor:

```dart
required this.vipController,
required this.onOpenVipChapter,
```

Add fields:

```dart
final VipChaptersController vipController;
final void Function(String contentApi, String title) onOpenVipChapter;
```

In `_DetailsSectionTabs`, add a middle VIP tab with label `VIP`. Use the same segmented style, three equal `Expanded` buttons.

In the content switch, replace the current `if/else` section with:

```dart
switch (_section) {
  _NovelDetailsSection.chapters => NovelChaptersSection(
    result: loadResult,
    onRead: widget.onRead,
    onDownloadChapters: widget.onDownloadChapters,
  ),
  _NovelDetailsSection.vip => VipChaptersSection(
    controller: widget.vipController,
    canReadPrivate: widget.engagementState.userState?.vip.canReadPrivate ?? false,
    onSignIn: widget.onSignIn,
    onOpenVipChapter: widget.onOpenVipChapter,
  ),
  _NovelDetailsSection.comments => CommentsSliverSection(
    controller: _commentsController!,
    authRepository: widget.authRepository,
  ),
}
```

When selecting comments, keep the existing lazy comments controller logic. VIP does not need extra setup because `VipChaptersSection` owns its lazy initial load.

- [ ] **Step 7: Wire controller in details screen**

In `novel_details_screen.dart`, import:

```dart
import '../../vip/application/vip_chapters_controller.dart';
import '../../vip/application/vip_repository.dart';
```

Add state fields:

```dart
VipRepository? _vipRepository;
VipChaptersController? _vipChaptersController;
```

In `didChangeDependencies`, after engagement repository setup:

```dart
final vipRepository = dependencies.vipRepository;
if (_vipRepository != vipRepository || authRepositoryChanged) {
  _vipChaptersController?.dispose();
  _vipRepository = vipRepository;
  final novelId = _loadedNovelId;
  if (novelId != null) {
    _vipChaptersController = VipChaptersController(
      repository: vipRepository,
      novelId: novelId,
    );
  }
}
```

In `_loadNovel`, after `_loadedNovelId = novelLoad.details.id;`, recreate controller:

```dart
final vipRepository = _vipRepository;
if (vipRepository != null) {
  _vipChaptersController?.dispose();
  _vipChaptersController = VipChaptersController(
    repository: vipRepository,
    novelId: novelLoad.details.id,
  );
}
```

Pass into `NovelDetailsContent`:

```dart
vipController: _vipChaptersController!,
onOpenVipChapter: _openVipReader,
```

Add method:

```dart
void _openVipReader(String contentApi, String title) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => ReaderScreen(
        contentApi: contentApi,
        chapterTitle: title,
        novelTitle: _loadedNovelTitleForVip(),
      ),
    ),
  );
}

String _loadedNovelTitleForVip() {
  final future = _future;
  if (future == null) {
    return '';
  }
  return '';
}
```

Immediately replace `_loadedNovelTitleForVip` with a state field instead of reading a Future:

```dart
String _loadedNovelTitle = '';
```

Set it in `_loadNovel`:

```dart
_loadedNovelTitle = novelLoad.details.title;
```

Then use:

```dart
novelTitle: _loadedNovelTitle,
```

Dispose controller:

```dart
_vipChaptersController?.dispose();
```

- [ ] **Step 8: Run analyzer to catch wiring issues**

Run:

```powershell
flutter analyze
```

Expected: PASS after import and nullability fixes.

- [ ] **Step 9: Add widget tests for section states**

Create `test/features/vip/vip_chapters_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/vip/application/vip_chapters_controller.dart';
import 'package:galaxy_novels_app/features/vip/application/vip_repository.dart';
import 'package:galaxy_novels_app/features/vip/domain/vip_chapter.dart';
import 'package:galaxy_novels_app/features/vip/presentation/vip_chapters_section.dart';

void main() {
  testWidgets('shows subscription message when private reading is unavailable', (tester) async {
    final controller = VipChaptersController(
      repository: _FakeVipRepository(),
      novelId: 1,
    );

    await tester.pumpWidget(_wrap(VipChaptersSection(
      controller: controller,
      canReadPrivate: false,
      onSignIn: () {},
      onOpenVipChapter: (_, _) {},
    )));

    expect(find.text('فصول VIP'), findsOneWidget);
    expect(find.textContaining('المشتركين فقط'), findsOneWidget);
  });

  testWidgets('opens a VIP chapter through an internal vip path', (tester) async {
    String? openedPath;
    final controller = VipChaptersController(
      repository: _FakeVipRepository(),
      novelId: 1,
    );

    await tester.pumpWidget(_wrap(VipChaptersSection(
      controller: controller,
      canReadPrivate: true,
      onSignIn: () {},
      onOpenVipChapter: (path, _) => openedPath = path,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الفصل 1'));
    expect(openedPath, 'vip:chapter:1');
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: CustomScrollView(slivers: [child])),
    ),
  );
}

class _FakeVipRepository implements VipRepository {
  @override
  Future<VipChapterPage> loadChapters(VipChapterQuery query) async {
    return const VipChapterPage(
      items: [
        VipChapter(
          id: 1,
          number: '1',
          position: 1,
          order: '1',
          title: 'خاص',
          url: '',
          publicAt: '',
          views: 0,
          comments: 0,
        ),
      ],
      hasMore: false,
      nextCursorOrder: '',
      nextCursorId: 0,
      totalAvailable: 1,
    );
  }
}
```

- [ ] **Step 10: Run VIP UI tests**

Run:

```powershell
flutter test test/features/vip/vip_chapters_controller_test.dart test/features/vip/vip_chapters_section_test.dart
```

Expected: PASS.

- [ ] **Step 11: Commit**

```powershell
git add lib/features/vip/application/vip_chapters_controller.dart lib/features/vip/presentation/vip_chapters_section.dart lib/features/novel_details/presentation/novel_details_screen.dart lib/features/novel_details/presentation/widgets/novel_details_content.dart test/features/vip/vip_chapters_controller_test.dart test/features/vip/vip_chapters_section_test.dart
git commit -m "feat(vip): show private chapters in novel details"
```

---

### Task 5: Show VIP Expiry In Account

**Files:**
- Modify: `lib/features/account/presentation/widgets/signed_in_account_view.dart`
- Test: `test/widget_test.dart` or `test/features/account/signed_in_account_view_test.dart`

**Interfaces:**
- Consumes: `AuthUser.vip.expiresAt`, `AuthUser.vip.label`.
- Produces: visible account VIP status with expiry.

- [ ] **Step 1: Write failing account widget test**

Create `test/features/account/signed_in_account_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/signed_in_account_view.dart';

void main() {
  testWidgets('shows VIP label and expiry date', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: SignedInAccountView(
          user: AuthUser(
            id: 1,
            displayName: 'Shadow',
            avatar: null,
            vip: AuthVip(
              active: true,
              tier: 'vip',
              label: 'VIP شهري',
              expiresAt: DateTime.utc(2026, 7, 20),
            ),
            xp: const AuthXp(
              total: 0,
              today: 0,
              secondsTotal: 0,
              chaptersTotal: 0,
              rank: AuthRank(level: 0, display: ''),
            ),
          ),
          isSigningOut: false,
          onLogout: () async {},
        ),
      ),
    ));

    expect(find.text('VIP شهري'), findsOneWidget);
    expect(find.textContaining('ينتهي'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run account test to verify it fails**

Run:

```powershell
flutter test test/features/account/signed_in_account_view_test.dart
```

Expected: FAIL because expiry text is not displayed.

- [ ] **Step 3: Add expiry copy below VIP chip**

In `signed_in_account_view.dart`, replace the current VIP chip block with:

```dart
if (user.vip.active) ...[
  const SizedBox(height: 10),
  Align(
    child: Chip(
      avatar: const Icon(Icons.workspace_premium_outlined, size: 18),
      label: Text(user.vip.label.isEmpty ? 'عضو VIP' : user.vip.label),
    ),
  ),
  if (user.vip.expiresAt != null) ...[
    const SizedBox(height: 4),
    Text(
      'ينتهي في ${_dateLabel(user.vip.expiresAt!)}',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    ),
  ],
],
```

Add helper at the bottom:

```dart
String _dateLabel(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}
```

- [ ] **Step 4: Run account test to verify it passes**

Run:

```powershell
flutter test test/features/account/signed_in_account_view_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/account/presentation/widgets/signed_in_account_view.dart test/features/account/signed_in_account_view_test.dart
git commit -m "feat(account): show VIP expiry"
```

---

### Task 6: Final Verification And Documentation

**Files:**
- Modify: `docs/app_api_gap_audit.md`
- No production code changes unless tests reveal a defect.

**Interfaces:**
- Consumes: completed Tasks 1-5.
- Produces: updated implementation status and verified debug build.

- [ ] **Step 1: Update API gap audit**

In `docs/app_api_gap_audit.md`, change:

```markdown
| VIP الخاص | chapters وcontinuous-next وlibrary-counts | غير منفذ. |
```

to:

```markdown
| VIP الخاص | chapters وcontinuous-next | منفذ جزئيا. يعرض التطبيق حالة VIP وقائمة فصول VIP للمستخدم المصرح له، ويفتح المحتوى داخل القارئ الأصلي عندما يوفر السيرفر مسار `vip/chapter`. لا توجد تنزيلات VIP ولا دفع داخل التطبيق. |
```

Add a note near the VIP/store section:

```markdown
ملاحظة تنفيذ: على الإنتاج بتاريخ 2026-06-26 كان `vip/chapter` يرجع `rest_no_route`، لذلك فتح أول فصل VIP مباشرة يحتاج alias خاص في القالب. `vip/chapters` و`vip/continuous-next` موجودان ويرجعان `401` دون Bearer token.
```

- [ ] **Step 2: Run all automated checks**

Run:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Expected: all pass.

- [ ] **Step 3: Manual test on a non-VIP or guest account**

Install debug APK, open a novel that has VIP data, then verify:

- Guest sees the VIP tab message and no private content.
- Logged-in non-VIP sees subscription-required copy.
- No payment or purchase button appears.
- Public chapters still open and download normally.

- [ ] **Step 4: Manual test on a VIP account**

With a VIP account:

- Open a novel with private chapters.
- VIP tab lists private chapters.
- Tapping a row opens native reader if `vip/chapter` exists.
- If `vip/chapter` is missing, tapping must be disabled or show a clear message that the server route is not ready.
- Next button inside VIP reader uses `vip:next:<chapterId>` and does not use public `chapters/{id}`.

- [ ] **Step 5: Commit docs and any final fixes**

```powershell
git add docs/app_api_gap_audit.md
git commit -m "docs(api): mark read-only VIP progress"
```

If Task 6 includes production fixes, include those files in the same commit only if they are directly required to pass verification.
