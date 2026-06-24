# Novel User State And Ratings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** عرض حالة المستخدم داخل تفاصيل الرواية، متابعة آخر فصل عام متاح، وإرسال تقييم شخصي من نجمة إلى خمس عبر الـ API الخاص.

**Architecture:** نضيف `NovelEngagementRepository` مستقلًا فوق `PrivateApiClient` وController محليًا لكل شاشة تفاصيل يستمع إلى الجلسة ويحمي الواجهة من النتائج المتأخرة. تبقى المفضلة في مستودعها الحالي، ويستخدم `my_rating` القادم من `GET /me/novels/{id}` بدل تنفيذ GET إضافي للتقييم.

**Tech Stack:** Flutter, Dart, Material 3, `ChangeNotifier`/`ValueListenable`, WordPress private REST API, `flutter_test`.

---

## File Map

- Create `lib/features/novel_engagement/domain/novel_user_state.dart`: نماذج حالة الرواية وبيانات آخر قراءة وVIP.
- Create `lib/features/novel_engagement/application/novel_engagement_repository.dart`: عقد الشبكة الذي يستهلكه Controller.
- Create `lib/features/novel_engagement/data/private_novel_engagement_repository.dart`: GET حالة الرواية وPOST التقييم عبر `PrivateApiClient`.
- Create `lib/features/novel_engagement/application/novel_engagement_controller.dart`: دورة تحميل محلية، حماية تبديل الجلسة، وحالة إرسال التقييم.
- Create `lib/features/novel_engagement/presentation/novel_personal_state_section.dart`: band خفيف لحالة التقييم وVIP.
- Create `lib/features/novel_engagement/presentation/novel_rating_sheet.dart`: bottom sheet بخمس نجوم وحالة إرسال داخلية.
- Modify `lib/app/app_dependencies.dart`: حقن المستودع في الشجرة.
- Modify `lib/app/galaxy_novels_app.dart`: إنشاء التنفيذ الخاص الافتراضي والسماح بحقن fake في الاختبارات.
- Modify `lib/features/novel_details/presentation/novel_details_screen.dart`: إنشاء Controller وربطه بالرواية والجلسة وفتح التقييم والحساب.
- Modify `lib/features/novel_details/presentation/widgets/novel_details_content.dart`: عرض الحالة واختيار فصل المتابعة ونص زر القراءة.
- Create `test/features/novel_engagement/novel_user_state_test.dart`.
- Create `test/features/novel_engagement/private_novel_engagement_repository_test.dart`.
- Create `test/features/novel_engagement/novel_engagement_controller_test.dart`.
- Create `test/features/novel_engagement/novel_engagement_widgets_test.dart`.
- Create `test/helpers/fake_novel_engagement_repository.dart`.
- Modify `test/widget_test.dart`: تغطية التدفق من شاشة التفاصيل.
- Modify `docs/app_api_gap_audit.md`: تعليم حالة الرواية وPOST التقييم كمكتملين.

---

### Task 1: Parse Per-Novel Account State

**Files:**
- Create: `test/features/novel_engagement/novel_user_state_test.dart`
- Create: `lib/features/novel_engagement/domain/novel_user_state.dart`

- [ ] **Step 1: Write the failing parser tests**

```dart
test('parses a complete per-novel user state', () {
  final state = NovelUserState.fromResponse({
    'novel_id': 123,
    'favorite': true,
    'my_rating': 4,
    'last_read': {
      'chapter_id': 555,
      'chapter_url': '/chapter-555/',
      'progress': 96,
      'updated_at': '2026-06-18T10:00:00+00:00',
    },
    'vip': {'active': true, 'can_read_private': true},
  }, expectedNovelId: 123);

  expect(state.novelId, 123);
  expect(state.favorite, isTrue);
  expect(state.myRating, 4);
  expect(state.lastRead.chapterId, 555);
  expect(state.lastRead.progress, 96);
  expect(state.vip.canReadPrivate, isTrue);
});

test('uses safe optional defaults and clamps progress', () {
  final state = NovelUserState.fromResponse({
    'novel_id': 123,
    'my_rating': 9,
    'last_read': {'progress': 140},
  }, expectedNovelId: 123);

  expect(state.myRating, 0);
  expect(state.lastRead.chapterId, 0);
  expect(state.lastRead.progress, 100);
  expect(state.lastRead.updatedAt, isNull);
});

test('rejects a response for another novel', () {
  expect(
    () => NovelUserState.fromResponse(
      {'novel_id': 999},
      expectedNovelId: 123,
    ),
    throwsFormatException,
  );
});

test('copyWith changes only the requested personal field', () {
  final state = NovelUserState.fromResponse({
    'novel_id': 123,
    'favorite': true,
    'my_rating': 2,
  }, expectedNovelId: 123);

  final updated = state.copyWith(myRating: 5);

  expect(updated.myRating, 5);
  expect(updated.favorite, isTrue);
  expect(updated.lastRead, same(state.lastRead));
  expect(updated.vip, same(state.vip));
});
```

- [ ] **Step 2: Run the parser tests and verify RED**

Run: `flutter test test/features/novel_engagement/novel_user_state_test.dart`

Expected: FAIL because `NovelUserState` does not exist.

- [ ] **Step 3: Implement the immutable models**

```dart
class NovelUserState {
  const NovelUserState({
    required this.novelId,
    required this.favorite,
    required this.myRating,
    required this.lastRead,
    required this.vip,
  });

  factory NovelUserState.fromResponse(
    Map<String, dynamic> json, {
    required int expectedNovelId,
  }) {
    final novelId = _asInt(json['novel_id']);
    if (novelId <= 0 || novelId != expectedNovelId) {
      throw const FormatException('Unexpected novel user state payload.');
    }
    final rawRating = _asInt(json['my_rating']);
    return NovelUserState(
      novelId: novelId,
      favorite: json['favorite'] == true,
      myRating: rawRating >= 1 && rawRating <= 5 ? rawRating : 0,
      lastRead: NovelLastRead.fromJson(_asMap(json['last_read'])),
      vip: NovelVipAccess.fromJson(_asMap(json['vip'])),
    );
  }

  final int novelId;
  final bool favorite;
  final int myRating;
  final NovelLastRead lastRead;
  final NovelVipAccess vip;

  NovelUserState copyWith({
    bool? favorite,
    int? myRating,
    NovelLastRead? lastRead,
    NovelVipAccess? vip,
  }) => NovelUserState(
    novelId: novelId,
    favorite: favorite ?? this.favorite,
    myRating: myRating ?? this.myRating,
    lastRead: lastRead ?? this.lastRead,
    vip: vip ?? this.vip,
  );
}

class NovelLastRead {
  const NovelLastRead({
    required this.chapterId,
    required this.chapterUrl,
    required this.progress,
    required this.updatedAt,
  });

  factory NovelLastRead.fromJson(Map<String, dynamic> json) {
    return NovelLastRead(
      chapterId: _asInt(json['chapter_id']).clamp(0, 0x7fffffff).toInt(),
      chapterUrl: json['chapter_url']?.toString().trim() ?? '',
      progress: _asInt(json['progress']).clamp(0, 100).toInt(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toUtc(),
    );
  }

  final int chapterId;
  final String chapterUrl;
  final int progress;
  final DateTime? updatedAt;
}

class NovelVipAccess {
  const NovelVipAccess({required this.active, required this.canReadPrivate});

  factory NovelVipAccess.fromJson(Map<String, dynamic> json) => NovelVipAccess(
    active: json['active'] == true,
    canReadPrivate: json['can_read_private'] == true,
  );

  final bool active;
  final bool canReadPrivate;
}
```

Add the tolerant helpers in the same file:

```dart
Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
```

- [ ] **Step 4: Run the parser tests and verify GREEN**

Run: `flutter test test/features/novel_engagement/novel_user_state_test.dart`

Expected: PASS, 4 tests.

- [ ] **Step 5: Commit the parser slice**

```powershell
git add lib/features/novel_engagement/domain/novel_user_state.dart test/features/novel_engagement/novel_user_state_test.dart
git commit -m "feat(novel): parse personal novel state"
```

---

### Task 2: Call The Private State And Rating Endpoints

**Files:**
- Create: `lib/features/novel_engagement/application/novel_engagement_repository.dart`
- Create: `lib/features/novel_engagement/data/private_novel_engagement_repository.dart`
- Create: `test/features/novel_engagement/private_novel_engagement_repository_test.dart`
- Create: `test/helpers/fake_novel_engagement_repository.dart`

- [ ] **Step 1: Write failing request-contract tests**

```dart
test('loads state through the authenticated novel endpoint', () async {
  late PrivateRawRequest sent;
  final client = PrivateApiClient(
    config: const AppConfig(),
    requestSender: (request) async {
      sent = request;
      return const PrivateRawResponse(
        statusCode: 200,
        body: '{"novel_id":123,"my_rating":4}',
      );
    },
  )..updateNonce('nonce-1');
  final repository = PrivateNovelEngagementRepository(client: client);

  final state = await repository.loadState(123);

  expect(sent.method, 'GET');
  expect(sent.uri.path, endsWith('/me/novels/123'));
  expect(sent.headers['X-WP-Nonce'], 'nonce-1');
  expect(state.myRating, 4);
});

test('submits a validated rating and trusts the server value', () async {
  late PrivateRawRequest sent;
  final client = PrivateApiClient(
    config: const AppConfig(),
    requestSender: (request) async {
      sent = request;
      return const PrivateRawResponse(
        statusCode: 200,
        body: '{"rating":5,"message":"saved"}',
      );
    },
  )..updateNonce('nonce-2');
  final repository = PrivateNovelEngagementRepository(client: client);

  final rating = await repository.submitRating(novelId: 123, rating: 5);

  expect(sent.uri.path, endsWith('/ratings/novel/123'));
  expect(jsonDecode(sent.body!), {'rating': 5});
  expect(rating, 5);
});

test('rejects ratings outside one to five without a request', () async {
  var calls = 0;
  final repository = PrivateNovelEngagementRepository(
    client: PrivateApiClient(
      config: const AppConfig(),
      requestSender: (_) async {
        calls++;
        throw StateError('must not run');
      },
    )..updateNonce('nonce'),
  );

  await expectLater(
    repository.submitRating(novelId: 123, rating: 0),
    throwsRangeError,
  );
  expect(calls, 0);
});
```

- [ ] **Step 2: Run repository tests and verify RED**

Run: `flutter test test/features/novel_engagement/private_novel_engagement_repository_test.dart`

Expected: FAIL because repository types are missing.

- [ ] **Step 3: Implement the repository contract and private adapter**

```dart
abstract class NovelEngagementRepository {
  Future<NovelUserState> loadState(int novelId);

  Future<int> submitRating({required int novelId, required int rating});
}

class PrivateNovelEngagementRepository implements NovelEngagementRepository {
  const PrivateNovelEngagementRepository({required PrivateApiClient client})
    : _client = client;

  final PrivateApiClient _client;

  @override
  Future<NovelUserState> loadState(int novelId) async {
    if (novelId <= 0) throw RangeError.value(novelId, 'novelId');
    final response = await _client.getAuthenticatedWithNonceRefresh(
      'me/novels/$novelId',
    );
    return NovelUserState.fromResponse(
      response,
      expectedNovelId: novelId,
    );
  }

  @override
  Future<int> submitRating({required int novelId, required int rating}) async {
    if (novelId <= 0) throw RangeError.value(novelId, 'novelId');
    if (rating < 1 || rating > 5) throw RangeError.range(rating, 1, 5);
    final response = await _client.postAuthenticatedWithNonceRefresh(
      'ratings/novel/$novelId',
      body: {'rating': rating},
    );
    final saved = int.tryParse(response['rating']?.toString() ?? '') ?? 0;
    if (saved < 1 || saved > 5) {
      throw const FormatException('Invalid saved rating payload.');
    }
    return saved;
  }
}
```

Implement this reusable test fake:

```dart
class FakeNovelEngagementRepository implements NovelEngagementRepository {
  FakeNovelEngagementRepository({
    this.state,
    this.loadHandler,
    this.submitHandler,
  });

  final NovelUserState? state;
  final Future<NovelUserState> Function(int novelId)? loadHandler;
  final Future<int> Function(int novelId, int rating)? submitHandler;
  final List<int> loadedNovelIds = [];
  final List<(int, int)> submittedRatings = [];

  @override
  Future<NovelUserState> loadState(int novelId) async {
    loadedNovelIds.add(novelId);
    final handler = loadHandler;
    if (handler != null) return handler(novelId);
    return state ?? (throw StateError('No fake novel state configured.'));
  }

  @override
  Future<int> submitRating({required int novelId, required int rating}) async {
    submittedRatings.add((novelId, rating));
    final handler = submitHandler;
    return handler == null ? rating : handler(novelId, rating);
  }
}
```

- [ ] **Step 4: Run repository and private-client regression tests**

Run: `flutter test test/features/novel_engagement/private_novel_engagement_repository_test.dart test/core/private_api_client_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit the private adapter**

```powershell
git add lib/features/novel_engagement/application lib/features/novel_engagement/data test/features/novel_engagement/private_novel_engagement_repository_test.dart test/helpers/fake_novel_engagement_repository.dart
git commit -m "feat(novel): connect personal state and rating API"
```

---

### Task 3: Coordinate Session-Safe Screen State

**Files:**
- Create: `lib/features/novel_engagement/application/novel_engagement_controller.dart`
- Create: `lib/features/novel_engagement/data/novel_engagement_error_messages.dart`
- Create: `test/features/novel_engagement/novel_engagement_controller_test.dart`

- [ ] **Step 1: Write failing controller tests**

Use a local `_state(int novelId, {int rating = 0})` fixture and add these executable tests:

```dart
test('guest state never calls the private repository', () async {
  final auth = FakeAuthRepository();
  final repository = FakeNovelEngagementRepository(state: _state(123));
  final controller = NovelEngagementController(
    repository: repository,
    authRepository: auth,
  );
  addTearDown(controller.dispose);

  await controller.loadNovel(123);

  expect(controller.value.status, NovelEngagementStatus.guest);
  expect(repository.loadedNovelIds, isEmpty);
});

test('authenticated load publishes the matching novel state', () async {
  final auth = FakeAuthRepository(
    initialState: AuthSessionState.authenticated(_user(7)),
  );
  final repository = FakeNovelEngagementRepository(state: _state(123, rating: 4));
  final controller = NovelEngagementController(
    repository: repository,
    authRepository: auth,
  );
  addTearDown(controller.dispose);

  await controller.loadNovel(123);

  expect(controller.value.status, NovelEngagementStatus.ready);
  expect(controller.value.userId, 7);
  expect(controller.value.userState?.myRating, 4);
});

test('logout clears personal state immediately', () async {
  final auth = FakeAuthRepository(
    initialState: AuthSessionState.authenticated(_user(7)),
  );
  final controller = NovelEngagementController(
    repository: FakeNovelEngagementRepository(state: _state(123, rating: 4)),
    authRepository: auth,
  );
  addTearDown(controller.dispose);
  await controller.loadNovel(123);

  auth.value = const AuthSessionState.guest();
  await Future<void>.delayed(Duration.zero);

  expect(controller.value.status, NovelEngagementStatus.guest);
  expect(controller.value.userState, isNull);
});

test('late response cannot overwrite a different account', () async {
  final first = Completer<NovelUserState>();
  final second = Completer<NovelUserState>();
  var call = 0;
  final auth = FakeAuthRepository(
    initialState: AuthSessionState.authenticated(_user(7)),
  );
  final repository = FakeNovelEngagementRepository(
    loadHandler: (_) => call++ == 0 ? first.future : second.future,
  );
  final controller = NovelEngagementController(
    repository: repository,
    authRepository: auth,
  );
  addTearDown(controller.dispose);
  final oldLoad = controller.loadNovel(123);

  auth.value = AuthSessionState.authenticated(_user(8));
  await Future<void>.delayed(Duration.zero);
  second.complete(_state(123, rating: 5));
  await Future<void>.delayed(Duration.zero);
  first.complete(_state(123, rating: 1));
  await oldLoad;

  expect(controller.value.userId, 8);
  expect(controller.value.userState?.myRating, 5);
});

test('successful submit publishes only the server rating', () async {
  final auth = FakeAuthRepository(
    initialState: AuthSessionState.authenticated(_user(7)),
  );
  final repository = FakeNovelEngagementRepository(
    state: _state(123, rating: 2),
    submitHandler: (_, _) async => 5,
  );
  final controller = NovelEngagementController(
    repository: repository,
    authRepository: auth,
  );
  addTearDown(controller.dispose);
  await controller.loadNovel(123);

  final outcome = await controller.submitRating(4);

  expect(outcome.status, RatingSubmitStatus.saved);
  expect(repository.submittedRatings, [(123, 4)]);
  expect(controller.value.userState?.myRating, 5);
});

test('rate limit keeps the previous rating and exposes an Arabic message', () async {
  final auth = FakeAuthRepository(
    initialState: AuthSessionState.authenticated(_user(7)),
  );
  final repository = FakeNovelEngagementRepository(
    state: _state(123, rating: 2),
    submitHandler: (_, _) => Future.error(
      const PrivateApiException(
        statusCode: 429,
        message: 'rate limited',
      ),
    ),
  );
  final controller = NovelEngagementController(
    repository: repository,
    authRepository: auth,
  );
  addTearDown(controller.dispose);
  await controller.loadNovel(123);

  final outcome = await controller.submitRating(4);

  expect(outcome.status, RatingSubmitStatus.failed);
  expect(outcome.errorMessage, 'محاولات كثيرة. حاول لاحقًا.');
  expect(controller.value.userState?.myRating, 2);
});

test('unauthorized submit asks auth repository to restore the session', () async {
  final auth = _TrackingAuthRepository(
    AuthSessionState.authenticated(_user(7)),
  );
  final repository = FakeNovelEngagementRepository(
    state: _state(123),
    submitHandler: (_, _) => Future.error(
      const PrivateApiException(statusCode: 401, message: 'expired'),
    ),
  );
  final controller = NovelEngagementController(
    repository: repository,
    authRepository: auth,
  );
  addTearDown(controller.dispose);
  await controller.loadNovel(123);

  await controller.submitRating(3);

  expect(auth.restoreCalls, 1);
});
```

Add these fixtures below the tests:

```dart
AuthUser _user(int id) => AuthUser(
  id: id,
  displayName: 'قارئ $id',
  avatar: null,
  vip: const AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: const AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 1, display: ''),
  ),
);

NovelUserState _state(int novelId, {int rating = 0}) => NovelUserState(
  novelId: novelId,
  favorite: false,
  myRating: rating,
  lastRead: const NovelLastRead(
    chapterId: 0,
    chapterUrl: '',
    progress: 0,
    updatedAt: null,
  ),
  vip: const NovelVipAccess(active: false, canReadPrivate: false),
);

class _TrackingAuthRepository extends FakeAuthRepository {
  _TrackingAuthRepository(AuthSessionState state) : super(initialState: state);

  int restoreCalls = 0;

  @override
  Future<void> restoreSession() async {
    restoreCalls++;
    await super.restoreSession();
  }
}
```

- [ ] **Step 2: Run controller tests and verify RED**

Run: `flutter test test/features/novel_engagement/novel_engagement_controller_test.dart`

Expected: FAIL because `NovelEngagementController` is missing.

- [ ] **Step 3: Implement immutable view state and controller**

Expose this public surface:

```dart
enum NovelEngagementStatus { guest, loading, ready, failure }

enum RatingSubmitStatus { saved, signInRequired, busy, failed }

class RatingSubmitOutcome {
  const RatingSubmitOutcome(this.status, {this.errorMessage});

  final RatingSubmitStatus status;
  final String? errorMessage;
}

class NovelEngagementState {
  const NovelEngagementState({
    required this.status,
    required this.novelId,
    this.userId,
    this.userState,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final NovelEngagementStatus status;
  final int novelId;
  final int? userId;
  final NovelUserState? userState;
  final bool isSubmitting;
  final String? errorMessage;

  NovelEngagementState startRatingSubmission();

  NovelEngagementState completeRatingSubmission(
    NovelUserState updatedUserState,
  );

  NovelEngagementState failRatingSubmission(String message);
}

class NovelEngagementController extends ChangeNotifier
    implements ValueListenable<NovelEngagementState> {
  NovelEngagementController({
    required NovelEngagementRepository repository,
    required AuthRepository authRepository,
  });

  @override
  NovelEngagementState get value;

  Future<void> loadNovel(int novelId);

  Future<void> retry();

  Future<RatingSubmitOutcome> submitRating(int rating);

  @override
  void dispose();
}
```

Implementation rules:

- Register one auth listener in the constructor and remove it in `dispose`.
- Increment `_generation` before every new load, logout, or account switch.
- Capture `(novelId, userId, generation)` before awaiting and publish only if all still match.
- Deduplicate an identical in-flight load.
- On guest, publish `guest` without calling the repository.
- On 401 or 403, call `authRepository.restoreSession()` and avoid retaining stale personal data.
- Map 429 to `محاولات كثيرة. حاول لاحقًا.` and network/5xx to `تعذر الاتصال الآن. حاول مجددًا.`.
- Set `isSubmitting` before POST, reject a second submit as `busy`, and apply only the integer returned by the server.

- [ ] **Step 4: Run controller tests and verify GREEN**

Run: `flutter test test/features/novel_engagement/novel_engagement_controller_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit the controller slice**

```powershell
git add lib/features/novel_engagement/application/novel_engagement_controller.dart lib/features/novel_engagement/data/novel_engagement_error_messages.dart test/features/novel_engagement/novel_engagement_controller_test.dart
git commit -m "feat(novel): coordinate personal state safely"
```

---

### Task 4: Wire The Repository Into App Dependencies

**Files:**
- Modify: `lib/app/app_dependencies.dart`
- Modify: `lib/app/galaxy_novels_app.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write a failing app wiring test**

Add this widget test using the existing app fixtures in `test/widget_test.dart`:

```dart
final engagement = FakeNovelEngagementRepository();
await tester.pumpWidget(GalaxyNovelsApp(
  homeRepository: _TestHomeRepository(_homeData),
  catalogRepository: const _TestCatalogRepository(),
  novelRepository: const _TestNovelRepository(),
  novelEngagementRepository: engagement,
));
await tester.pumpAndSettle();

final shellContext = tester.element(find.byType(AppShell));
expect(
  AppDependencies.of(shellContext).novelEngagementRepository,
  same(engagement),
);
```

- [ ] **Step 2: Run the targeted widget test and verify RED**

Run: `flutter test test/widget_test.dart --plain-name "injects the configured novel engagement repository"`

Expected: FAIL because the constructor/dependency field does not exist.

- [ ] **Step 3: Add dependency injection**

In `AppDependencies`:

```dart
required this.novelEngagementRepository,

final NovelEngagementRepository novelEngagementRepository;
```

Include the field in `updateShouldNotify`. Pass `FakeNovelEngagementRepository()` explicitly from direct `AppDependencies` test harnesses; no fallback that refuses the repository contract belongs in production code.

In `GalaxyNovelsApp`:

```dart
final NovelEngagementRepository? novelEngagementRepository;

final effectiveNovelEngagementRepository =
    widget.novelEngagementRepository ??
    PrivateNovelEngagementRepository(client: _privateApiClientFor());
```

Pass it to `AppDependencies`. The implementation is stateless, so no extra `dispose` lifecycle is required.

- [ ] **Step 4: Run widget and dependency regression tests**

Run: `flutter test test/widget_test.dart test/features/novel_details/novel_details_chapter_list_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit app wiring**

```powershell
git add lib/app/app_dependencies.dart lib/app/galaxy_novels_app.dart test/widget_test.dart
git commit -m "feat(app): inject novel engagement service"
```

---

### Task 5: Add Native Continue Reading And Rating UI

**Files:**
- Create: `lib/features/novel_engagement/presentation/novel_personal_state_section.dart`
- Create: `lib/features/novel_engagement/presentation/novel_rating_sheet.dart`
- Modify: `lib/features/novel_details/presentation/novel_details_screen.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_details_content.dart`
- Create: `test/features/novel_engagement/novel_engagement_widgets_test.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write failing UI behavior tests**

Add these integration tests to `test/widget_test.dart` using the existing app fixtures. Extend `_TestNovelRepository` with a second public chapter whose ID is 2 and `contentApi` is `/wp-json/wor-reader-app/v1/chapters/2`.

```dart
testWidgets('matching last read chapter becomes the native continue action', (
  tester,
) async {
  String? openedApi;
  final engagement = FakeNovelEngagementRepository(
    state: _personalState(novelId: 99).copyWith(
      lastRead: const NovelLastRead(
        chapterId: 2,
        chapterUrl: '/chapter-2/',
        progress: 45,
        updatedAt: null,
      ),
    ),
  );
  await _pumpOpenedDetails(
    tester,
    authRepository: FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_testAuthUser),
    ),
    engagementRepository: engagement,
    readerRepository: _TestReaderRepository(onLoad: (api) => openedApi = api),
  );

  expect(find.text('متابعة الفصل 2'), findsOneWidget);
  await tester.tap(find.text('متابعة الفصل 2'));
  await tester.pumpAndSettle();
  expect(openedApi, '/wp-json/wor-reader-app/v1/chapters/2');
});

testWidgets('missing last read chapter keeps the first public chapter action', (
  tester,
) async {
  final engagement = FakeNovelEngagementRepository(
    state: _personalState(novelId: 99).copyWith(
      lastRead: const NovelLastRead(
        chapterId: 700,
        chapterUrl: '/private-700/',
        progress: 20,
        updatedAt: null,
      ),
    ),
  );
  await _pumpOpenedDetails(
    tester,
    authRepository: FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_testAuthUser),
    ),
    engagementRepository: engagement,
  );

  expect(find.text('ابدأ القراءة'), findsOneWidget);
  expect(find.textContaining('متابعة'), findsNothing);
});

testWidgets('authenticated reader sees and edits the personal rating', (
  tester,
) async {
  final engagement = FakeNovelEngagementRepository(
    state: _personalState(novelId: 99),
    submitHandler: (_, _) async => 5,
  );
  await _pumpOpenedDetails(
    tester,
    authRepository: FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_testAuthUser),
    ),
    engagementRepository: engagement,
  );

  await tester.tap(find.text('تقييمك'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('personal-rating-5')));
  await tester.tap(find.text('حفظ التقييم'));
  await tester.pumpAndSettle();

  expect(engagement.submittedRatings, [(99, 5)]);
  expect(find.text('تم حفظ تقييمك'), findsOneWidget);
});

testWidgets('guest rating action opens the account screen', (tester) async {
  await _pumpOpenedDetails(
    tester,
    authRepository: FakeAuthRepository(),
    engagementRepository: FakeNovelEngagementRepository(
      state: _personalState(novelId: 99),
    ),
  );

  await tester.tap(find.text('سجّل الدخول للتقييم'));
  await tester.pumpAndSettle();

  expect(find.text('حسابي'), findsOneWidget);
  expect(find.text('تسجيل الدخول'), findsOneWidget);
});
```

Define `_pumpOpenedDetails` in `test/widget_test.dart`:

```dart
Future<void> _pumpOpenedDetails(
  WidgetTester tester, {
  required AuthRepository authRepository,
  required NovelEngagementRepository engagementRepository,
  ReaderRepository readerRepository = const _TestReaderRepository(),
}) async {
  await tester.pumpWidget(GalaxyNovelsApp(
    homeRepository: _TestHomeRepository(_homeData),
    catalogRepository: const _TestCatalogRepository(),
    novelRepository: const _TestNovelRepository(),
    readerRepository: readerRepository,
    authRepository: authRepository,
    novelEngagementRepository: engagementRepository,
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('المكتبة'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('مكتبة الاختبار'));
  await tester.pumpAndSettle();
}
```

Add standalone widget tests in `novel_engagement_widgets_test.dart`:

```dart
testWidgets('rating sheet blocks duplicate submits and shows the error', (
  tester,
) async {
  final completion = Completer<RatingSubmitOutcome>();
  var calls = 0;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: NovelRatingSheet(
        initialRating: 2,
        onSubmit: (rating) {
          calls++;
          return completion.future;
        },
      ),
    ),
  ));

  await tester.tap(find.byKey(const ValueKey('personal-rating-4')));
  await tester.tap(find.text('حفظ التقييم'));
  await tester.pump();
  await tester.tap(find.text('حفظ التقييم'));
  expect(calls, 1);

  completion.complete(const RatingSubmitOutcome(
    RatingSubmitStatus.failed,
    errorMessage: 'محاولات كثيرة. حاول لاحقًا.',
  ));
  await tester.pumpAndSettle();
  expect(find.text('محاولات كثيرة. حاول لاحقًا.'), findsOneWidget);
});

testWidgets('personal state section fits a 320 pixel phone', (tester) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: NovelPersonalStateSection(
        state: NovelEngagementState(
          status: NovelEngagementStatus.ready,
          novelId: 99,
          userId: 7,
          userState: _widgetPersonalState(),
        ),
        onRate: () {},
        onSignIn: () {},
        onRetry: () {},
      ),
    ),
  ));

  expect(find.text('تقييمك'), findsOneWidget);
  expect(tester.takeException(), isNull);
});

NovelUserState _widgetPersonalState() => const NovelUserState(
  novelId: 99,
  favorite: false,
  myRating: 4,
  lastRead: NovelLastRead(
    chapterId: 0,
    chapterUrl: '',
    progress: 0,
    updatedAt: null,
  ),
  vip: NovelVipAccess(active: false, canReadPrivate: false),
);
```

- [ ] **Step 2: Run UI tests and verify RED**

Run: `flutter test test/features/novel_engagement/novel_engagement_widgets_test.dart test/widget_test.dart`

Expected: FAIL because the widgets and screen integration are missing.

- [ ] **Step 3: Build the personal state band**

`NovelPersonalStateSection` must accept only render state and callbacks:

```dart
class NovelPersonalStateSection extends StatelessWidget {
  const NovelPersonalStateSection({
    required this.state,
    required this.onRate,
    required this.onSignIn,
    required this.onRetry,
    super.key,
  });

  final NovelEngagementState state;
  final VoidCallback onRate;
  final VoidCallback onSignIn;
  final VoidCallback onRetry;
}
```

Render it as an unframed full-width band with top/bottom borders, an outlined star action, optional VIP badge, a compact retry action for `failure`, and colors exclusively from `AppThemeTokens`. Do not nest cards or add gradients.

- [ ] **Step 4: Build the five-star sheet**

```dart
class NovelRatingSheet extends StatefulWidget {
  const NovelRatingSheet({
    required this.initialRating,
    required this.onSubmit,
    super.key,
  });

  final int initialRating;
  final Future<RatingSubmitOutcome> Function(int rating) onSubmit;
}
```

Keep `_selectedRating` and `_isSubmitting` local. Each star has a 48x48 touch target and tooltip. `حفظ التقييم` is disabled until a star is selected and remains disabled during POST. Pop with `true` only on `saved`; for `failed`, keep the sheet open and show the controller's Arabic error text.

- [ ] **Step 5: Bind controller lifecycle in `NovelDetailsScreen`**

Create/dispose the controller when `authRepository` or `novelEngagementRepository` changes. Store the loaded novel ID and call `loadNovel(details.id)` once after the public future resolves. Pass controller state and callbacks into `NovelDetailsContent`.

On rating success, show `تم حفظ تقييمك`. On guest action, push `AccountScreen`. Never block or replace the public details future when private state fails.

- [ ] **Step 6: Select the native continuation chapter**

In `NovelDetailsContent`, select a continuation only when:

```dart
chapter.id == engagementState.userState?.lastRead.chapterId &&
chapter.effectiveContentApi.isNotEmpty
```

Use it before the first readable chapter. Pass `متابعة ${chapter.label}` to `_DetailsBottomBar`; otherwise pass `ابدأ القراءة`. Keep the existing callback opening `ReaderScreen`, so no URL/WebView path is introduced.

- [ ] **Step 7: Run UI tests and verify GREEN**

Run: `flutter test test/features/novel_engagement/novel_engagement_widgets_test.dart test/features/novel_details test/widget_test.dart`

Expected: PASS with no overflow exceptions.

- [ ] **Step 8: Commit the UI slice**

```powershell
git add lib/features/novel_engagement/presentation lib/features/novel_details/presentation test/features/novel_engagement/novel_engagement_widgets_test.dart test/widget_test.dart
git commit -m "feat(novel): add personal state and rating UI"
```

---

### Task 6: Audit Documentation And Full Verification

**Files:**
- Modify: `docs/app_api_gap_audit.md`
- Modify: `README.md`

- [ ] **Step 1: Update the API matrix accurately**

Mark `GET /me/novels/{novel_id}` implemented. Mark `POST /ratings/novel/{id}` implemented and state that the app intentionally uses `my_rating` from the novel-state response instead of issuing redundant `GET /ratings/novel/{id}` calls. Do not claim private VIP chapter support.

- [ ] **Step 2: Format and inspect the diff**

Run:

```powershell
dart format lib test
git diff --check
git status --short
```

Expected: formatting completes; `git diff --check` exits 0; only intended files are modified.

- [ ] **Step 3: Run focused and complete verification**

Run:

```powershell
flutter test test/features/novel_engagement test/features/novel_details
flutter analyze
flutter test --reporter compact
flutter build apk --debug
```

Expected: all commands exit 0 and APK is produced at `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 4: Commit documentation**

```powershell
git add README.md docs/app_api_gap_audit.md
git commit -m "docs(novel): complete engagement API audit"
```

- [ ] **Step 5: Confirm a clean branch**

Run:

```powershell
git status --short
git log -8 --oneline
```

Expected: empty status and the feature commits visible in order.
