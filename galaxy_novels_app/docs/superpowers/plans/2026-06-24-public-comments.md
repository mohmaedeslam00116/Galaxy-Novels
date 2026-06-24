# Public Comments Reading Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** تمكين الضيف والمستخدم المسجل من قراءة تعليقات الروايات والفصول بصفحات مرتبة، من دون تحميل مسبق أو تعطيل شاشة التفاصيل والقارئ عند الفشل.

**Architecture:** ميزة مستقلة تحت `features/comments` تقسم عقد البيانات، repository العام، controller قصير العمر، وويدجات العرض المشتركة. تستخدم الرواية `CommentsSliverSection` داخل التمرير الحالي، بينما يفتح القارئ `ChapterCommentsSheet` فوق المحتوى مع controller مستقل للفصل.

**Tech Stack:** Flutter، Material 3، Dart `ChangeNotifier` و`ValueListenableBuilder`، `PrivateApiClient.getPublic`، واختبارات `flutter_test`.

---

## خريطة الملفات

### ملفات جديدة

- `lib/features/comments/domain/comment_target.dart`: نوع الهدف والترتيب والقيم المرسلة للـAPI.
- `lib/features/comments/domain/public_comment.dart`: تعليق عام وردوده وبيانات الكاتب والحرق والتعدادات.
- `lib/features/comments/domain/comments_page.dart`: صفحة موثقة ومتحقق منها مع pagination والتفاعلات الإجمالية.
- `lib/features/comments/application/comments_repository.dart`: عقد تحميل صفحة واحدة.
- `lib/features/comments/application/comments_controller.dart`: حالة العرض، منع الطلبات المتكررة، pagination، ورفض الاستجابات المتأخرة.
- `lib/features/comments/data/public_comments_repository.dart`: بناء مسار GET وتحويل JSON إلى domain.
- `lib/features/comments/data/comments_error_messages.dart`: رسائل عربية آمنة.
- `lib/features/comments/presentation/comments_sliver_section.dart`: حالات القائمة والترتيب وزر عرض المزيد.
- `lib/features/comments/presentation/chapter_comments_sheet.dart`: اللوحة السفلية القابلة للسحب.
- `lib/features/comments/presentation/widgets/comment_item.dart`: عرض التعليق والردود والحرق.
- `lib/features/comments/presentation/widgets/comments_states.dart`: التحميل والفراغ والفشل.
- `lib/features/comments/presentation/widgets/comments_sort_menu.dart`: قائمة الترتيب.
- `test/helpers/fake_comments_repository.dart`: fake موحد للاختبارات.
- اختبارات الوحدة والويدجات تحت `test/features/comments/`.

### ملفات معدلة

- `lib/app/app_dependencies.dart`: إتاحة `CommentsRepository` للشاشات.
- `lib/app/galaxy_novels_app.dart`: إنشاء repository الافتراضي وقبول fake في الاختبارات.
- ملفات الاختبارات التي تنشئ `AppDependencies` مباشرة: حقن fake فقط.
- `lib/features/novel_details/presentation/novel_details_screen.dart`: تمرير repository إلى المحتوى.
- `lib/features/novel_details/presentation/widgets/novel_details_content.dart`: إدارة تبويبي الفصول والتعليقات بصورة كسولة.
- `lib/features/reader/presentation/reader_screen.dart`: فتح لوحة تعليقات الفصل بعد تحميله.
- `lib/features/reader/presentation/native_reader_content.dart`: زر تعليقات ضمن الأدوات العائمة.
- `docs/app_api_gap_audit.md`: تعليم القراءة العامة كمكتملة وتحديد الخطوة اللاحقة.

---

### Task 1: نماذج الهدف والتعليق والصفحة

**Files:**
- Create: `lib/features/comments/domain/comment_target.dart`
- Create: `lib/features/comments/domain/public_comment.dart`
- Create: `lib/features/comments/domain/comments_page.dart`
- Test: `test/features/comments/comments_models_test.dart`

- [ ] **Step 1: كتابة اختبار parsing فاشل**

أنشئ الاختبار التالي ليثبت القيم، الردود، الحرق، والتحقق من هوية الهدف:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_target.dart';
import 'package:galaxy_novels_app/features/comments/domain/comments_page.dart';

void main() {
  final target = CommentTarget.novel(42);

  test('parses a public comments page and nested replies', () {
    final page = CommentsPage.fromJson(
      {
        'version': 2,
        'object_type': 'novel',
        'object_id': 42,
        'sort': 'newest',
        'page': 1,
        'per_page': 20,
        'total_comments': 2,
        'total_roots': 1,
        'total_pages': 1,
        'generated': 1782324555,
        'reactions': {'like': 3, 'love': 2},
        'comments': [
          {
            'id': 7,
            'parent_id': 0,
            'root_id': 0,
            'depth': 0,
            'author_name': 'قارئ أول',
            'author_rank': 'قارئ فضي',
            'avatar_url': '/avatar.webp',
            'reply_to_name': '',
            'content': 'تعليق رئيسي',
            'is_spoiler': 1,
            'like_count': 4,
            'dislike_count': 1,
            'replies_count': 1,
            'score': 3,
            'is_pinned': 1,
            'created_at': '24 يونيو 2026 10:00',
            'created_iso': '2026-06-24T10:00:00+03:00',
            'updated_at': '24 يونيو 2026 10:00',
            'updated_iso': '2026-06-24T10:00:00+03:00',
            'replies': [
              {
                'id': 8,
                'parent_id': 7,
                'root_id': 7,
                'depth': 1,
                'author_name': 'قارئ ثان',
                'content': 'رد',
                'created_at': '24 يونيو 2026 10:05',
              },
            ],
          },
        ],
      },
      expectedTarget: target,
      expectedSort: CommentsSort.newest,
      expectedPage: 1,
    );

    expect(page.target, target);
    expect(page.totalComments, 2);
    expect(page.reactions['like'], 3);
    expect(page.comments.single.isSpoiler, isTrue);
    expect(page.comments.single.isPinned, isTrue);
    expect(page.comments.single.replies.single.content, 'رد');
  });

  test('accepts the empty live response shape', () {
    final page = CommentsPage.fromJson(
      {
        'version': 2,
        'object_type': 'novel',
        'object_id': 42,
        'sort': 'newest',
        'page': 1,
        'per_page': 20,
        'total_comments': 0,
        'total_roots': 0,
        'total_pages': 0,
        'generated': 1782324555,
        'reactions': <String, int>{},
        'comments': <Object>[],
      },
      expectedTarget: target,
      expectedSort: CommentsSort.newest,
      expectedPage: 1,
    );

    expect(page.comments, isEmpty);
    expect(page.hasNextPage, isFalse);
  });

  test('rejects a response for another object', () {
    expect(
      () => CommentsPage.fromJson(
        {
          'object_type': 'chapter',
          'object_id': 42,
          'sort': 'newest',
          'page': 1,
          'per_page': 20,
          'total_pages': 0,
          'comments': <Object>[],
        },
        expectedTarget: target,
        expectedSort: CommentsSort.newest,
        expectedPage: 1,
      ),
      throwsFormatException,
    );
  });
}
```

- [ ] **Step 2: تشغيل الاختبار وإثبات فشله**

Run:

```powershell
flutter test test/features/comments/comments_models_test.dart
```

Expected: FAIL لأن ملفات domain غير موجودة.

- [ ] **Step 3: إنشاء أنواع الهدف والترتيب**

اكتب `comment_target.dart`:

```dart
enum CommentTargetType {
  novel('novel'),
  chapter('chapter');

  const CommentTargetType(this.apiValue);
  final String apiValue;
}

enum CommentsSort {
  newest('newest', 'الأحدث'),
  top('top', 'الأعلى'),
  replies('replies', 'الأكثر ردودًا'),
  oldest('oldest', 'الأقدم');

  const CommentsSort(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class CommentTarget {
  const CommentTarget._(this.type, this.id);

  factory CommentTarget.novel(int id) =>
      CommentTarget._(CommentTargetType.novel, _validatedId(id));

  factory CommentTarget.chapter(int id) =>
      CommentTarget._(CommentTargetType.chapter, _validatedId(id));

  final CommentTargetType type;
  final int id;

  String get pathSegment => '${type.apiValue}/$id';

  static int _validatedId(int id) {
    if (id <= 0) {
      throw RangeError.value(id, 'id', 'Comment target id must be positive.');
    }
    return id;
  }

  @override
  bool operator ==(Object other) =>
      other is CommentTarget && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}
```

- [ ] **Step 4: إنشاء نموذج التعليق**

اكتب `public_comment.dart` بنموذج immutable. استخدم `List<PublicComment>.unmodifiable` للردود، ارفض `id <= 0`، واقرأ boolean من `bool` أو `0/1`. الحقول المطلوبة في الواجهة:

```dart
class PublicComment {
  PublicComment({
    required this.id,
    required this.parentId,
    required this.rootId,
    required this.depth,
    required this.authorName,
    required this.authorRank,
    required this.avatarUrl,
    required this.replyToName,
    required this.content,
    required this.isSpoiler,
    required this.likeCount,
    required this.dislikeCount,
    required this.repliesCount,
    required this.score,
    required this.isPinned,
    required this.createdLabel,
    required this.createdAt,
    required List<PublicComment> replies,
  }) : replies = List<PublicComment>.unmodifiable(replies);

  factory PublicComment.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id <= 0) {
      throw const FormatException('Comment id must be positive.');
    }
    return PublicComment(
      id: id,
      parentId: _asInt(json['parent_id']),
      rootId: _asInt(json['root_id']),
      depth: _asInt(json['depth']).clamp(0, 2).toInt(),
      authorName: _asString(json['author_name'], fallback: 'قارئ'),
      authorRank: _asString(json['author_rank']),
      avatarUrl: _asString(json['avatar_url']),
      replyToName: _asString(json['reply_to_name']),
      content: _asString(json['content']),
      isSpoiler: _asBool(json['is_spoiler']),
      likeCount: _asInt(json['like_count']).clamp(0, 1 << 31).toInt(),
      dislikeCount: _asInt(json['dislike_count']).clamp(0, 1 << 31).toInt(),
      repliesCount: _asInt(json['replies_count']).clamp(0, 1 << 31).toInt(),
      score: _asInt(json['score']),
      isPinned: _asBool(json['is_pinned']),
      createdLabel: _asString(json['created_at']),
      createdAt: DateTime.tryParse(_asString(json['created_iso'])),
      replies: _asList(json['replies'])
          .map((item) => PublicComment.fromJson(_asMap(item)))
          .toList(growable: false),
    );
  }

  final int id;
  final int parentId;
  final int rootId;
  final int depth;
  final String authorName;
  final String authorRank;
  final String avatarUrl;
  final String replyToName;
  final String content;
  final bool isSpoiler;
  final int likeCount;
  final int dislikeCount;
  final int repliesCount;
  final int score;
  final bool isPinned;
  final String createdLabel;
  final DateTime? createdAt;
  final List<PublicComment> replies;
}

Map<String, dynamic> _asMap(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : const {};

List<Object?> _asList(Object? value) => value is List ? value : const [];

String _asString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _asInt(Object? value) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? 0;

bool _asBool(Object? value) =>
    value == true || value == 1 || value?.toString() == '1';
```

- [ ] **Step 5: إنشاء نموذج الصفحة والتحقق من العقد**

اكتب `comments_page.dart` كاملا:

```dart
import 'comment_target.dart';
import 'public_comment.dart';

class CommentsPage {
  CommentsPage({
    required this.version,
    required this.target,
    required this.sort,
    required this.page,
    required this.perPage,
    required this.totalComments,
    required this.totalRoots,
    required this.totalPages,
    required this.generated,
    required Map<String, int> reactions,
    required List<PublicComment> comments,
  }) : reactions = Map<String, int>.unmodifiable(reactions),
       comments = List<PublicComment>.unmodifiable(comments);

  factory CommentsPage.empty({
    required CommentTarget target,
    required CommentsSort sort,
    int page = 1,
  }) {
    return CommentsPage(
      version: 2,
      target: target,
      sort: sort,
      page: page,
      perPage: 20,
      totalComments: 0,
      totalRoots: 0,
      totalPages: 0,
      generated: 0,
      reactions: const {},
      comments: const [],
    );
  }

  factory CommentsPage.fromJson(
    Map<String, dynamic> json, {
    required CommentTarget expectedTarget,
    required CommentsSort expectedSort,
    required int expectedPage,
  }) {
    final objectType = json['object_type']?.toString() ?? '';
    final objectId = _asInt(json['object_id']);
    final sortValue = json['sort']?.toString() ?? '';
    final page = _asInt(json['page']);
    final perPage = _asInt(json['per_page']);
    final totalPages = _asInt(json['total_pages']);
    if (objectType != expectedTarget.type.apiValue ||
        objectId != expectedTarget.id ||
        sortValue != expectedSort.apiValue ||
        page != expectedPage ||
        perPage <= 0 ||
        totalPages < 0) {
      throw const FormatException('Invalid comments page identity.');
    }

    final reactions = <String, int>{};
    for (final entry in _asMap(json['reactions']).entries) {
      reactions[entry.key] = _asInt(entry.value).clamp(0, 1 << 31).toInt();
    }
    final comments = _asList(json['comments'])
        .map((item) => PublicComment.fromJson(_asMap(item)))
        .toList(growable: false);

    return CommentsPage(
      version: _asInt(json['version']),
      target: expectedTarget,
      sort: expectedSort,
      page: page,
      perPage: perPage,
      totalComments: _asInt(json['total_comments']).clamp(0, 1 << 31).toInt(),
      totalRoots: _asInt(json['total_roots']).clamp(0, 1 << 31).toInt(),
      totalPages: totalPages,
      generated: _asInt(json['generated']).clamp(0, 1 << 62).toInt(),
      reactions: reactions,
      comments: comments,
    );
  }

  final int version;
  final CommentTarget target;
  final CommentsSort sort;
  final int page;
  final int perPage;
  final int totalComments;
  final int totalRoots;
  final int totalPages;
  final int generated;
  final Map<String, int> reactions;
  final List<PublicComment> comments;

  bool get hasNextPage => page < totalPages;
}

Map<String, dynamic> _asMap(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : const {};

List<Object?> _asList(Object? value) => value is List ? value : const [];

int _asInt(Object? value) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? 0;
```

- [ ] **Step 6: تشغيل الاختبار وإثبات نجاحه**

```powershell
flutter test test/features/comments/comments_models_test.dart
```

Expected: PASS، ثلاثة اختبارات.

- [ ] **Step 7: تثبيت المهمة**

```powershell
git add lib/features/comments/domain test/features/comments/comments_models_test.dart
git commit -m "feat(comments): model public comment pages"
```

---

### Task 2: Repository القراءة العامة ورسائل الخطأ

**Files:**
- Create: `lib/features/comments/application/comments_repository.dart`
- Create: `lib/features/comments/data/public_comments_repository.dart`
- Create: `lib/features/comments/data/comments_error_messages.dart`
- Test: `test/features/comments/public_comments_repository_test.dart`

- [ ] **Step 1: كتابة اختبارات المسار والطلب العام**

استخدم `PrivateApiClient` مع `requestSender` مسجل، ثم تحقق من:

```dart
test('loads a public novel comments page without a nonce', () async {
  late PrivateRawRequest sent;
  final repository = PublicCommentsRepository(
    client: PrivateApiClient(
      config: const AppConfig(),
      requestSender: (request) async {
        sent = request;
        return const PrivateRawResponse(
          statusCode: 200,
          body: '{"version":2,"object_type":"novel","object_id":42,'
              '"sort":"top","page":2,"per_page":20,'
              '"total_comments":21,"total_roots":21,"total_pages":2,'
              '"generated":1,"reactions":{},"comments":[]}',
        );
      },
    ),
  );

  final page = await repository.loadPage(
    target: CommentTarget.novel(42),
    sort: CommentsSort.top,
    page: 2,
  );

  expect(sent.method, 'GET');
  expect(sent.uri.path, endsWith('/comments/novel/42'));
  expect(sent.uri.queryParameters, {'page': '2', 'sort': 'top'});
  expect(sent.headers.containsKey('X-WP-Nonce'), isFalse);
  expect(page.page, 2);
});
```

أضف اختبارا يمرر `page: 0` ويتوقع `RangeError` قبل الشبكة، واختبارا يعيد target مختلفا ويتوقع `FormatException`.

- [ ] **Step 2: تشغيل الاختبار وإثبات فشله**

```powershell
flutter test test/features/comments/public_comments_repository_test.dart
```

Expected: FAIL لأن repository غير موجود.

- [ ] **Step 3: كتابة عقد repository**

```dart
import '../domain/comment_target.dart';
import '../domain/comments_page.dart';

abstract class CommentsRepository {
  Future<CommentsPage> loadPage({
    required CommentTarget target,
    required CommentsSort sort,
    required int page,
  });
}
```

- [ ] **Step 4: كتابة التنفيذ العام**

```dart
class PublicCommentsRepository implements CommentsRepository {
  const PublicCommentsRepository({required PrivateApiClient client})
    : _client = client;

  final PrivateApiClient _client;

  @override
  Future<CommentsPage> loadPage({
    required CommentTarget target,
    required CommentsSort sort,
    required int page,
  }) async {
    if (page <= 0) {
      throw RangeError.value(page, 'page', 'Page must be positive.');
    }
    final response = await _client.getPublic(
      'comments/${target.pathSegment}?page=$page&sort=${sort.apiValue}',
    );
    return CommentsPage.fromJson(
      response,
      expectedTarget: target,
      expectedSort: sort,
      expectedPage: page,
    );
  }
}
```

- [ ] **Step 5: كتابة الرسائل العربية الآمنة**

```dart
String commentsMessageFor(Object error) {
  if (error is PrivateApiException) {
    if (error.statusCode == 404) {
      return 'لم تعد هذه التعليقات متاحة.';
    }
    if (error.statusCode == 429) {
      return 'طلبات كثيرة. حاول بعد قليل.';
    }
  }
  if (error is FormatException) {
    return 'تعذر قراءة بيانات التعليقات.';
  }
  return 'تعذر تحميل التعليقات الآن.';
}
```

- [ ] **Step 6: تشغيل الاختبارات**

```powershell
flutter test test/features/comments/public_comments_repository_test.dart
```

Expected: PASS.

- [ ] **Step 7: تثبيت المهمة**

```powershell
git add lib/features/comments/application/comments_repository.dart lib/features/comments/data test/features/comments/public_comments_repository_test.dart
git commit -m "feat(comments): load public comment pages"
```

---

### Task 3: Controller التحميل والترتيب والصفحات

**Files:**
- Create: `lib/features/comments/application/comments_controller.dart`
- Create: `test/helpers/fake_comments_repository.dart`
- Test: `test/features/comments/comments_controller_test.dart`

- [ ] **Step 1: كتابة اختبارات الحالة الحرجة**

يجب أن تغطي الاختبارات:

```dart
test('loads once and merges the next page without duplicate ids', () async {
  final repository = FakeCommentsRepository(
    handler: (target, sort, page) async => _page(
      target: target,
      sort: sort,
      page: page,
      totalPages: 2,
      comments: [
        _comment(page == 1 ? 1 : 2),
        _comment(1),
      ],
    ),
  );
  final controller = CommentsController(
    repository: repository,
    target: CommentTarget.novel(42),
  );
  addTearDown(controller.dispose);

  await Future.wait([controller.loadInitial(), controller.loadInitial()]);
  await controller.loadMore();

  expect(repository.calls.map((call) => call.page), [1, 2]);
  expect(controller.value.comments.map((item) => item.id), [1, 2]);
});

test('late sort response cannot replace the selected sort', () async {
  final newest = Completer<CommentsPage>();
  final top = Completer<CommentsPage>();
  final repository = FakeCommentsRepository(
    handler: (target, sort, page) =>
        sort == CommentsSort.newest ? newest.future : top.future,
  );
  final controller = CommentsController(
    repository: repository,
    target: CommentTarget.novel(42),
  );
  addTearDown(controller.dispose);

  final first = controller.loadInitial();
  final second = controller.changeSort(CommentsSort.top);
  top.complete(_page(target: CommentTarget.novel(42), sort: CommentsSort.top));
  await second;
  newest.complete(
    _page(target: CommentTarget.novel(42), sort: CommentsSort.newest),
  );
  await first;

  expect(controller.value.sort, CommentsSort.top);
});

PublicComment _comment(int id) {
  return PublicComment(
    id: id,
    parentId: 0,
    rootId: 0,
    depth: 0,
    authorName: 'قارئ $id',
    authorRank: '',
    avatarUrl: '',
    replyToName: '',
    content: 'تعليق $id',
    isSpoiler: false,
    likeCount: 0,
    dislikeCount: 0,
    repliesCount: 0,
    score: 0,
    isPinned: false,
    createdLabel: '',
    createdAt: null,
    replies: const [],
  );
}

CommentsPage _page({
  required CommentTarget target,
  required CommentsSort sort,
  int page = 1,
  int totalPages = 1,
  List<PublicComment> comments = const [],
}) {
  return CommentsPage(
    version: 2,
    target: target,
    sort: sort,
    page: page,
    perPage: 20,
    totalComments: comments.length,
    totalRoots: comments.length,
    totalPages: totalPages,
    generated: 1,
    reactions: const {},
    comments: comments,
  );
}
```

أضف اختبار فشل أولي ينتج `CommentsStatus.failure`، واختبار فشل صفحة لاحقة يبقي العناصر القديمة ويملأ `loadMoreErrorMessage`.

- [ ] **Step 2: تشغيل الاختبار وإثبات فشله**

```powershell
flutter test test/features/comments/comments_controller_test.dart
```

Expected: FAIL لأن controller وfake غير موجودين.

- [ ] **Step 3: كتابة الحالة العامة**

استخدم هذا العقد:

```dart
enum CommentsStatus { idle, loading, ready, failure }

class CommentsState {
  const CommentsState({
    required this.target,
    required this.sort,
    required this.status,
    this.comments = const [],
    this.page = 0,
    this.totalPages = 0,
    this.totalComments = 0,
    this.isLoadingMore = false,
    this.errorMessage,
    this.loadMoreErrorMessage,
  });

  final CommentTarget target;
  final CommentsSort sort;
  final CommentsStatus status;
  final List<PublicComment> comments;
  final int page;
  final int totalPages;
  final int totalComments;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? loadMoreErrorMessage;

  bool get hasNextPage => status == CommentsStatus.ready && page < totalPages;
}
```

- [ ] **Step 4: كتابة controller بمنع السباقات**

اكتب `CommentsController extends ChangeNotifier implements ValueListenable<CommentsState>` بهذا التنفيذ:

```dart
import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/comments_error_messages.dart';
import '../domain/comment_target.dart';
import '../domain/public_comment.dart';
import 'comments_repository.dart';

enum CommentsStatus { idle, loading, ready, failure }

class CommentsState {
  CommentsState({
    required this.target,
    required this.sort,
    required this.status,
    List<PublicComment> comments = const [],
    this.page = 0,
    this.totalPages = 0,
    this.totalComments = 0,
    this.isLoadingMore = false,
    this.errorMessage,
    this.loadMoreErrorMessage,
  }) : comments = List<PublicComment>.unmodifiable(comments);

  final CommentTarget target;
  final CommentsSort sort;
  final CommentsStatus status;
  final List<PublicComment> comments;
  final int page;
  final int totalPages;
  final int totalComments;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? loadMoreErrorMessage;

  bool get hasNextPage => status == CommentsStatus.ready && page < totalPages;
}

class CommentsController extends ChangeNotifier
    implements ValueListenable<CommentsState> {
  CommentsController({
    required CommentsRepository repository,
    required CommentTarget target,
  }) : _repository = repository,
       _target = target,
       _value = CommentsState(
         target: target,
         sort: CommentsSort.newest,
         status: CommentsStatus.idle,
       );

  final CommentsRepository _repository;
  final CommentTarget _target;
  CommentsState _value;
  Future<void>? _initialFuture;
  CommentsSort? _initialSort;
  Future<void>? _loadMoreFuture;
  int _generation = 0;
  bool _disposed = false;

  @override
  CommentsState get value => _value;

  Future<void> loadInitial() {
    if (_value.status == CommentsStatus.ready) {
      return Future.value();
    }
    return _loadFirst(_value.sort);
  }

  Future<void> retry() => _loadFirst(_value.sort, force: true);

  Future<void> changeSort(CommentsSort sort) {
    if (sort == _value.sort) {
      return loadInitial();
    }
    return _loadFirst(sort, force: true);
  }

  Future<void> _loadFirst(CommentsSort sort, {bool force = false}) {
    if (_disposed) {
      return Future.value();
    }
    final active = _initialFuture;
    if (!force && active != null && _initialSort == sort) {
      return active;
    }

    final generation = ++_generation;
    _loadMoreFuture = null;
    _publish(
      CommentsState(
        target: _target,
        sort: sort,
        status: CommentsStatus.loading,
      ),
    );

    late final Future<void> request;
    request = _performFirst(sort, generation).whenComplete(() {
      if (identical(_initialFuture, request)) {
        _initialFuture = null;
        _initialSort = null;
      }
    });
    _initialFuture = request;
    _initialSort = sort;
    return request;
  }

  Future<void> _performFirst(CommentsSort sort, int generation) async {
    try {
      final page = await _repository.loadPage(
        target: _target,
        sort: sort,
        page: 1,
      );
      if (!_isCurrent(sort, generation)) {
        return;
      }
      _publish(
        CommentsState(
          target: _target,
          sort: sort,
          status: CommentsStatus.ready,
          comments: page.comments,
          page: page.page,
          totalPages: page.totalPages,
          totalComments: page.totalComments,
        ),
      );
    } on Object catch (error) {
      if (!_isCurrent(sort, generation)) {
        return;
      }
      _publish(
        CommentsState(
          target: _target,
          sort: sort,
          status: CommentsStatus.failure,
          errorMessage: commentsMessageFor(error),
        ),
      );
    }
  }

  Future<void> loadMore() {
    if (_disposed) {
      return Future.value();
    }
    final active = _loadMoreFuture;
    if (active != null) {
      return active;
    }
    final current = _value;
    if (!current.hasNextPage || current.isLoadingMore) {
      return Future.value();
    }

    final generation = _generation;
    final nextPage = current.page + 1;
    _publish(
      CommentsState(
        target: current.target,
        sort: current.sort,
        status: current.status,
        comments: current.comments,
        page: current.page,
        totalPages: current.totalPages,
        totalComments: current.totalComments,
        isLoadingMore: true,
      ),
    );

    late final Future<void> request;
    request = _performLoadMore(current.sort, nextPage, generation)
        .whenComplete(() {
          if (identical(_loadMoreFuture, request)) {
            _loadMoreFuture = null;
          }
        });
    _loadMoreFuture = request;
    return request;
  }

  Future<void> _performLoadMore(
    CommentsSort sort,
    int nextPage,
    int generation,
  ) async {
    try {
      final page = await _repository.loadPage(
        target: _target,
        sort: sort,
        page: nextPage,
      );
      if (!_isCurrent(sort, generation)) {
        return;
      }
      final merged = LinkedHashMap<int, PublicComment>();
      for (final comment in _value.comments) {
        merged.putIfAbsent(comment.id, () => comment);
      }
      for (final comment in page.comments) {
        merged.putIfAbsent(comment.id, () => comment);
      }
      _publish(
        CommentsState(
          target: _target,
          sort: sort,
          status: CommentsStatus.ready,
          comments: merged.values.toList(growable: false),
          page: page.page,
          totalPages: page.totalPages,
          totalComments: page.totalComments,
        ),
      );
    } on Object catch (error) {
      if (!_isCurrent(sort, generation)) {
        return;
      }
      final current = _value;
      _publish(
        CommentsState(
          target: current.target,
          sort: current.sort,
          status: CommentsStatus.ready,
          comments: current.comments,
          page: current.page,
          totalPages: current.totalPages,
          totalComments: current.totalComments,
          loadMoreErrorMessage: commentsMessageFor(error),
        ),
      );
    }
  }

  bool _isCurrent(CommentsSort sort, int generation) {
    return !_disposed &&
        generation == _generation &&
        _value.target == _target &&
        _value.sort == sort;
  }

  void _publish(CommentsState state) {
    if (_disposed) {
      return;
    }
    _value = state;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
```

- [ ] **Step 5: كتابة fake صغير وقابل لإعادة الاستخدام**

```dart
typedef CommentsLoadHandler = Future<CommentsPage> Function(
  CommentTarget target,
  CommentsSort sort,
  int page,
);

class FakeCommentsRepository implements CommentsRepository {
  FakeCommentsRepository({required this.handler});

  final CommentsLoadHandler handler;
  final calls = <({CommentTarget target, CommentsSort sort, int page})>[];

  @override
  Future<CommentsPage> loadPage({
    required CommentTarget target,
    required CommentsSort sort,
    required int page,
  }) {
    calls.add((target: target, sort: sort, page: page));
    return handler(target, sort, page);
  }
}
```

- [ ] **Step 6: تشغيل الاختبارات**

```powershell
flutter test test/features/comments/comments_controller_test.dart
```

Expected: PASS لكل حالات الدمج والسباق والفشل.

- [ ] **Step 7: تثبيت المهمة**

```powershell
git add lib/features/comments/application/comments_controller.dart test/helpers/fake_comments_repository.dart test/features/comments/comments_controller_test.dart
git commit -m "feat(comments): coordinate paginated comment state"
```

---

### Task 4: عنصر التعليق والحرق والردود

**Files:**
- Create: `lib/features/comments/presentation/widgets/comment_item.dart`
- Test: `test/features/comments/comment_item_test.dart`

- [ ] **Step 1: كتابة اختبارات الحرق والردود والعرض الضيق**

أنشئ surface عربي بثيم `AppTheme.dark()` واختبر:

```dart
testWidgets('spoiler stays hidden until the reader reveals it', (tester) async {
  await tester.pumpWidget(_surface(CommentItem(comment: _spoilerComment())));

  expect(find.text('سر النهاية'), findsNothing);
  expect(find.text('إظهار المحتوى المحروق'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('comment-spoiler-7')));
  await tester.pump();

  expect(find.text('سر النهاية'), findsOneWidget);
});

testWidgets('renders replies and fits a 320 pixel screen', (tester) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(_surface(CommentItem(comment: _commentWithReply())));

  expect(find.text('رد طويل من قارئ آخر'), findsOneWidget);
  expect(tester.takeException(), isNull);
});

Widget _surface(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: SafeArea(child: child)),
    ),
  );
}

PublicComment _spoilerComment() {
  return _comment(id: 7, content: 'سر النهاية', isSpoiler: true);
}

PublicComment _commentWithReply() {
  return _comment(
    id: 1,
    content: 'تعليق رئيسي',
    replies: [_comment(id: 2, content: 'رد طويل من قارئ آخر', parentId: 1)],
  );
}

PublicComment _comment({
  required int id,
  required String content,
  int parentId = 0,
  bool isSpoiler = false,
  List<PublicComment> replies = const [],
}) {
  return PublicComment(
    id: id,
    parentId: parentId,
    rootId: parentId == 0 ? 0 : 1,
    depth: parentId == 0 ? 0 : 1,
    authorName: 'اسم قارئ طويل للاختبار',
    authorRank: 'قارئ فضي',
    avatarUrl: '',
    replyToName: parentId == 0 ? '' : 'قارئ أول',
    content: content,
    isSpoiler: isSpoiler,
    likeCount: 4,
    dislikeCount: 1,
    repliesCount: replies.length,
    score: 3,
    isPinned: id == 1,
    createdLabel: 'منذ ساعة',
    createdAt: null,
    replies: replies,
  );
}
```

- [ ] **Step 2: تشغيل الاختبار وإثبات فشله**

```powershell
flutter test test/features/comments/comment_item_test.dart
```

Expected: FAIL لأن `CommentItem` غير موجود.

- [ ] **Step 3: بناء العنصر من وحدات صغيرة**

نفذ `CommentItem` كـ`StatefulWidget` يحتفظ بـ`_spoilerRevealed`. استخدم:

- `ClipOval` بحجم ثابت `40x40` للصورة، و`errorBuilder` يعرض أول حرف.
- `Row` للترويسة مع `Expanded` للاسم و`TextOverflow.ellipsis`.
- `Wrap` للرتبة، الوقت، والتثبيت حتى لا يحدث overflow.
- `Semantics(button: true, label: 'إظهار المحتوى المحروق')` حول زر الكشف.
- `Wrap` غير تفاعلي لأيقونات الإعجاب وعدم الإعجاب والردود.
- الردود داخل `PaddingDirectional(start: 20)` مع `BorderDirectional(start: BorderSide(color: tokens.border))`، وكل رد يعرض `_CommentBody` فقط ولا ينشئ `CommentItem` أو بطاقة جديدة.
- `Divider` واحد بين التعليقات الجذرية؛ لا `Card` ولا ارتفاعات ثابتة للنص.

- [ ] **Step 4: تشغيل الاختبارات**

```powershell
flutter test test/features/comments/comment_item_test.dart
```

Expected: PASS، ولا exception على عرض 320px.

- [ ] **Step 5: تثبيت المهمة**

```powershell
git add lib/features/comments/presentation/widgets/comment_item.dart test/features/comments/comment_item_test.dart
git commit -m "feat(comments): render public comment threads"
```

---

### Task 5: قائمة التعليقات المشتركة واللوحة السفلية

**Files:**
- Create: `lib/features/comments/presentation/widgets/comments_states.dart`
- Create: `lib/features/comments/presentation/widgets/comments_sort_menu.dart`
- Create: `lib/features/comments/presentation/comments_sliver_section.dart`
- Create: `lib/features/comments/presentation/chapter_comments_sheet.dart`
- Test: `test/features/comments/comments_surfaces_test.dart`

- [ ] **Step 1: كتابة اختبارات الحالات والترتيب والصفحة التالية**

اختبر `CommentsSliverSection` داخل `CustomScrollView`:

```dart
expect(find.text('تحميل التعليقات...'), findsOneWidget);
expect(find.byKey(const ValueKey('comments-sort-menu')), findsOneWidget);
expect(find.byKey(const ValueKey('comments-load-more')), findsOneWidget);
```

بعد اختيار `CommentsSort.top` من `PopupMenuButton` تحقق من أن fake سجل الصفحة `1` والترتيب `top`. بعد الضغط على `comments-load-more` تحقق من طلب الصفحة `2`. أضف اختبار فشل أولي يظهر `إعادة المحاولة`، واختبار empty يظهر `لا توجد تعليقات بعد`.

- [ ] **Step 2: تشغيل الاختبار وإثبات فشله**

```powershell
flutter test test/features/comments/comments_surfaces_test.dart
```

Expected: FAIL لأن أسطح العرض غير موجودة.

- [ ] **Step 3: إنشاء ويدجات الحالات وقائمة الترتيب**

`CommentsSortMenu` يستخدم `PopupMenuButton<CommentsSort>` ومفتاح `comments-sort-menu`، يعرض `sort.label`، ويمرر القيمة المختارة إلى `controller.changeSort`.

في `comments_states.dart` أنشئ ثلاثة ويدجات مركزة:

```dart
class CommentsLoadingState extends StatelessWidget {
  const CommentsLoadingState({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Center(child: Text('تحميل التعليقات...')),
  );
}

class CommentsEmptyState extends StatelessWidget {
  const CommentsEmptyState({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Center(child: Text('لا توجد تعليقات بعد')),
  );
}

class CommentsErrorState extends StatelessWidget {
  const CommentsErrorState({required this.message, required this.onRetry, super.key});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: إنشاء `CommentsSliverSection`**

استخدم `ValueListenableBuilder<CommentsState>` وأعد `SliverMainAxisGroup`. الترتيب الداخلي ثابت:

1. ترويسة فيها `SectionTitle(title: 'التعليقات')` والعدد عند `ready`.
2. `CommentsSortMenu` في `SliverToBoxAdapter`.
3. loading أو empty أو error، أو `SliverList` كسولة من `CommentItem`.
4. footer فيه `عرض المزيد` فقط عند `hasNextPage`، spinner عند `isLoadingMore`، ورسالة الصفحة اللاحقة مع زر إعادة عند `loadMoreErrorMessage != null`.

لا تستدع `loadInitial` من `build`؛ المالك هو المسؤول عن بدء الطلب مرة واحدة.

- [ ] **Step 5: إنشاء لوحة الفصل**

`ChapterCommentsSheet` هو `StatefulWidget` يستقبل `CommentsRepository` و`CommentTarget`. في `initState` ينشئ controller ويستدعي `unawaited(controller.loadInitial())`، وفي `dispose` يغلقه. بنية العرض:

```dart
DraggableScrollableSheet(
  expand: false,
  initialChildSize: 0.78,
  minChildSize: 0.50,
  maxChildSize: 0.95,
  builder: (context, scrollController) => Material(
    color: tokens.background,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        const _SheetHandleAndTitle(),
        Expanded(
          child: CustomScrollView(
            controller: scrollController,
            slivers: [CommentsSliverSection(controller: controller)],
          ),
        ),
      ],
    ),
  ),
)
```

ضع `ValueKey('chapter-comments-sheet')` على `Material` وزر إغلاق بـtooltip `إغلاق تعليقات الفصل`.

- [ ] **Step 6: تشغيل اختبارات الأسطح**

```powershell
flutter test test/features/comments/comments_surfaces_test.dart
```

Expected: PASS لكل حالات القائمة واللوحة.

- [ ] **Step 7: تثبيت المهمة**

```powershell
git add lib/features/comments/presentation test/features/comments/comments_surfaces_test.dart
git commit -m "feat(comments): add reusable comment surfaces"
```

---

### Task 6: حقن CommentsRepository في التطبيق

**Files:**
- Modify: `lib/app/app_dependencies.dart`
- Modify: `lib/app/galaxy_novels_app.dart`
- Modify: ملفات الاختبار الأربعة التي تنشئ `AppDependencies` مباشرة
- Modify: `test/helpers/fake_comments_repository.dart`
- Test: `test/app/app_dependencies_test.dart`

- [ ] **Step 1: كتابة اختبار dependency فاشل**

أنشئ surface صغيرا يقرأ `AppDependencies.of(context).commentsRepository` ويتحقق من أنه نفس fake المحقون. استخدم repositories الوهمية الحالية لبقية الحقول.

- [ ] **Step 2: تشغيل الاختبار وإثبات فشله**

```powershell
flutter test test/app/app_dependencies_test.dart
```

Expected: FAIL لأن `commentsRepository` غير موجود في `AppDependencies`.

- [ ] **Step 3: إضافة الاعتماد إلى `AppDependencies`**

أضف import وconstructor field:

```dart
required this.commentsRepository,
```

```dart
final CommentsRepository commentsRepository;
```

وأضف إلى `updateShouldNotify`:

```dart
commentsRepository != oldWidget.commentsRepository ||
```

- [ ] **Step 4: إضافة repository الافتراضي إلى جذر التطبيق**

في `GalaxyNovelsApp` أضف optional injection:

```dart
final CommentsRepository? commentsRepository;
```

وفي state:

```dart
PublicCommentsRepository? _defaultCommentsRepository;
```

صفّر الافتراضي عند تغيير config، وأنشئه مرة واحدة:

```dart
CommentsRepository _defaultCommentsRepositoryFor() {
  return _defaultCommentsRepository ??=
      PublicCommentsRepository(client: _privateApiClientFor());
}
```

داخل `build`:

```dart
final effectiveCommentsRepository =
    widget.commentsRepository ?? _defaultCommentsRepositoryFor();
```

ثم مرره إلى `AppDependencies(commentsRepository: effectiveCommentsRepository)`.

- [ ] **Step 5: جعل fake يملك حالة فارغة افتراضية**

أضف constructor اختباري لا يحتاج handler مخصص:

```dart
FakeCommentsRepository.empty()
  : handler = ((target, sort, page) async => CommentsPage.empty(
      target: target,
      sort: sort,
      page: page,
    ));
```

يعتمد هذا constructor على `CommentsPage.empty` المعرّف صراحة في Task 1.

- [ ] **Step 6: تحديث test surfaces التي تبني `AppDependencies`**

أضف السطر التالي إلى كل constructor مباشر أظهره `rg "AppDependencies\(" test`:

```dart
commentsRepository: FakeCommentsRepository.empty(),
```

أضف import صريحا لـ`test/helpers/fake_comments_repository.dart` باستخدام المسار النسبي الصحيح لكل ملف اختبار.

- [ ] **Step 7: تشغيل اختبارات التطبيق الحالية**

```powershell
flutter test test/app/app_dependencies_test.dart test/features/reader/reader_screen_test.dart test/features/novel_details/novel_details_chapter_list_test.dart test/features/history/history_screen_test.dart test/features/downloads/downloads_screen_test.dart test/features/downloads/downloaded_novel_screen_test.dart
```

Expected: PASS ولا أخطاء constructor.

- [ ] **Step 8: تثبيت المهمة**

```powershell
git add lib/app test/app/app_dependencies_test.dart test/helpers/fake_comments_repository.dart test/features/reader/reader_screen_test.dart test/features/novel_details/novel_details_chapter_list_test.dart test/features/history/history_screen_test.dart test/features/downloads/downloads_screen_test.dart test/features/downloads/downloaded_novel_screen_test.dart
git commit -m "feat(app): inject public comments repository"
```

---

### Task 7: تبويب تعليقات الرواية

**Files:**
- Modify: `lib/features/novel_details/presentation/novel_details_screen.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_details_content.dart`
- Test: `test/features/novel_details/novel_details_comments_test.dart`

- [ ] **Step 1: كتابة اختبار التحميل الكسول والاحتفاظ بالحالة**

ابن test app يعيد رواية واحدة وfake comments فيه تعليق `تعليق الرواية`. تحقق من:

```dart
expect(commentsRepository.calls, isEmpty);
await tester.scrollUntilVisible(
  find.byKey(const ValueKey('novel-section-comments')),
  400,
  scrollable: _verticalScrollable(),
);
await tester.tap(find.byKey(const ValueKey('novel-section-comments')));
await tester.pumpAndSettle();
expect(find.text('تعليق الرواية'), findsOneWidget);
expect(commentsRepository.calls, hasLength(1));

await tester.tap(find.byKey(const ValueKey('novel-section-chapters')));
await tester.pump();
await tester.tap(find.byKey(const ValueKey('novel-section-comments')));
await tester.pump();
expect(commentsRepository.calls, hasLength(1));
```

أضف اختبار فشل التعليقات يتأكد أن زر `ابدأ القراءة` ما زال موجودا.

- [ ] **Step 2: تشغيل الاختبار وإثبات فشله**

```powershell
flutter test test/features/novel_details/novel_details_comments_test.dart
```

Expected: FAIL لعدم وجود التبويب.

- [ ] **Step 3: تمرير repository من الشاشة**

في `NovelDetailsScreen` خزّن `CommentsRepository? _commentsRepository` من `AppDependencies`، ومرره:

```dart
commentsRepository: _commentsRepository!,
```

لا تنشئ controller في الشاشة؛ دورة حياته تخص محتوى الرواية.

- [ ] **Step 4: تحويل `NovelDetailsContent` إلى StatefulWidget**

أضف:

```dart
enum _NovelDetailsSection { chapters, comments }
```

داخل state:

```dart
_NovelDetailsSection _section = _NovelDetailsSection.chapters;
CommentsController? _commentsController;

void _showComments() {
  final controller = _commentsController ??= CommentsController(
    repository: widget.commentsRepository,
    target: CommentTarget.novel(widget.loadResult.details.id),
  );
  setState(() => _section = _NovelDetailsSection.comments);
  unawaited(controller.loadInitial());
}
```

في `didUpdateWidget` إذا تغير novel id أو repository، أغلق controller وأعد القسم إلى الفصول. في `dispose` أغلق controller.

- [ ] **Step 5: إضافة شريط التبويب والسلايفر المختار**

بعد الملخص أضف `SliverToBoxAdapter` يحتوي `SegmentedButton<_NovelDetailsSection>` أو صف زرين ثابتين بمفاتيح:

```dart
ValueKey('novel-section-chapters')
ValueKey('novel-section-comments')
```

ثم استبدل الاستدعاء المباشر للفصول بـ:

```dart
if (_section == _NovelDetailsSection.chapters)
  NovelChaptersSection(
    result: widget.loadResult,
    onRead: widget.onRead,
    onDownloadChapters: widget.onDownloadChapters,
  )
else
  CommentsSliverSection(controller: _commentsController!),
```

استعمل `AnimatedSwitcher` فقط داخل شريط التبويب إذا احتجته، بزمن `180ms`، ولا تحرك قائمة التعليقات أثناء التمرير.

- [ ] **Step 6: تشغيل اختبارات التفاصيل**

```powershell
flutter test test/features/novel_details/novel_details_comments_test.dart test/features/novel_details/novel_details_chapter_list_test.dart test/features/novel_details/novel_details_widgets_test.dart
```

Expected: PASS؛ البحث الطويل ما زال كسولا والتعليقات لا تُطلب قبل فتحها.

- [ ] **Step 7: تثبيت المهمة**

```powershell
git add lib/features/novel_details test/features/novel_details
git commit -m "feat(novel): add public comments tab"
```

---

### Task 8: لوحة تعليقات الفصل داخل القارئ

**Files:**
- Modify: `lib/features/reader/presentation/reader_screen.dart`
- Modify: `lib/features/reader/presentation/native_reader_content.dart`
- Modify: `test/features/reader/reader_screen_test.dart`

- [ ] **Step 1: كتابة اختبار فتح اللوحة وبقاء الفصل**

مرر fake comments إلى `_ReaderTestApp` واختبر:

```dart
expect(commentsRepository.calls, isEmpty);
await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
await tester.pumpAndSettle();
await tester.tap(find.byKey(const ValueKey('reader-comments-button')));
await tester.pumpAndSettle();

expect(find.byKey(const ValueKey('chapter-comments-sheet')), findsOneWidget);
expect(find.text('تعليق الفصل'), findsOneWidget);
expect(commentsRepository.calls.single.target, CommentTarget.chapter(10));

await tester.tap(find.byTooltip('إغلاق تعليقات الفصل'));
await tester.pumpAndSettle();
expect(find.text('نص الفصل الأول'), findsOneWidget);
```

أضف اختبار فصل بلا previous/next يتأكد أن زر التعليقات والإعدادات يظهران عند إظهار الأدوات، وأن عرض `320px` لا ينتج overflow.

- [ ] **Step 2: تشغيل الاختبار وإثبات فشله**

```powershell
flutter test test/features/reader/reader_screen_test.dart
```

Expected: FAIL لعدم وجود زر التعليقات.

- [ ] **Step 3: إضافة callback إلى `NativeReaderContent`**

أضف:

```dart
required this.onOpenComments,
final VoidCallback onOpenComments;
```

مرره إلى `_ReaderFloatingControls`. اجعل الأدوات العائمة متاحة حتى عندما لا يوجد فصل سابق أو تال، لأن الإعدادات والتعليقات يجب ألا تختفيا.

- [ ] **Step 4: جعل شريط الأدوات صالحا للشاشات الضيقة**

استبدل أزرار السابق/التالي النصية بصف من أربعة `IconButton` بأبعاد ثابتة وتوزيع متساو:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [
    IconButton(
      tooltip: 'الفصل السابق',
      onPressed: hasPrevious ? onPrevious : null,
      icon: const Icon(Icons.chevron_right_rounded),
    ),
    IconButton.filledTonal(
      key: const ValueKey('reader-comments-button'),
      tooltip: 'تعليقات الفصل',
      onPressed: onComments,
      icon: const Icon(Icons.forum_outlined),
    ),
    IconButton.filledTonal(
      key: const ValueKey('reader-settings-button'),
      tooltip: 'إعدادات القراءة',
      onPressed: onSettings,
      icon: const Icon(Icons.tune_rounded),
    ),
    IconButton(
      tooltip: 'الفصل التالي',
      onPressed: hasNext ? onNext : null,
      icon: const Icon(Icons.chevron_left_rounded),
    ),
  ],
)
```

- [ ] **Step 5: فتح اللوحة من `ReaderScreen`**

بعد نجاح `FutureBuilder` مرر:

```dart
onOpenComments: () => _openChapterComments(snapshot.data!),
```

وأضف:

```dart
Future<void> _openChapterComments(ReaderChapterContent content) async {
  if (content.id <= 0) {
    return;
  }
  final repository = AppDependencies.of(context).commentsRepository;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChapterCommentsSheet(
      repository: repository,
      target: CommentTarget.chapter(content.id),
    ),
  );
}
```

لا تغير `_future` ولا `_contentApi` ولا ScrollController القارئ عند الفتح أو الإغلاق.

- [ ] **Step 6: تشغيل اختبارات القارئ**

```powershell
flutter test test/features/reader/reader_screen_test.dart
```

Expected: PASS لجميع اختبارات القارئ القديمة والجديدة.

- [ ] **Step 7: تثبيت المهمة**

```powershell
git add lib/features/reader test/features/reader/reader_screen_test.dart
git commit -m "feat(reader): add chapter comments sheet"
```

---

### Task 9: تدقيق الوثائق والتحقق الكامل

**Files:**
- Modify: `docs/app_api_gap_audit.md`
- Test: كل المشروع

- [ ] **Step 1: تحديث مصفوفة التنفيذ**

عدّل الوثيقة بدقة:

- تفاصيل الرواية: التقييمات والتعليقات العامة منفذة، والكتابة وVIP باقيان.
- التعليقات العامة: منفذة للرواية والفصل مع pagination وترتيب وحرق وردود.
- REST التعليقات: GET منفذ، POST والتصويت والتفاعل غير منفذة.
- المرحلة 4 بند عرض التعليقات العامة: `(مكتمل)`.
- الخطوة التالية: إنشاء التعليقات والردود للمستخدم المسجل، ولا تخلطها مع التصويت.

- [ ] **Step 2: تنسيق الملفات**

```powershell
dart format lib test
```

Expected: اكتمال التنسيق بلا أخطاء.

- [ ] **Step 3: تشغيل اختبارات الميزة**

```powershell
flutter test test/features/comments test/features/novel_details test/features/reader
```

Expected: All tests passed.

- [ ] **Step 4: تشغيل الحزمة كاملة**

```powershell
flutter test --reporter compact
```

Expected: All tests passed، وعدد الاختبارات أكبر من خط الأساس `260`.

- [ ] **Step 5: التحليل الساكن**

```powershell
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: بناء APK**

```powershell
flutter build apk --debug
```

Expected: إنشاء `build/app/outputs/flutter-apk/app-debug.apk` بنجاح.

- [ ] **Step 7: مراجعة النظافة والجودة**

```powershell
git diff --check
git status --short
```

Expected: لا whitespace errors، ولا ملفات مولدة غير مقصودة. راجع أن أي ملف إنتاج تجاوز حجما مريحا قد قُسم بحسب خريطة الملفات، وأنه لا توجد ألوان hardcoded أو طلبات شبكة من `build`.

- [ ] **Step 8: تثبيت التدقيق**

```powershell
git add docs/app_api_gap_audit.md
git commit -m "docs(comments): complete public reading audit"
```

---

## ترتيب التنفيذ الإجباري

نفذ المهام من 1 إلى 9 بالترتيب. لا تبدأ ربط الواجهة قبل نجاح domain وrepository وcontroller، ولا تضف POST أو التصويت أو reactions خلال هذه الخطة. عند فشل اختبار قديم، أصلح سبب التكامل داخل المهمة الحالية ولا توسع النطاق إلى refactor غير مرتبط.
