# Reading Activity Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Measure account reading activity in the Native reader, persist immutable per-account events, and synchronize them safely with `POST /reading/sync`.

**Architecture:** A pure domain tracker computes foreground, active, and progress deltas. A focused data repository owns the durable per-user queue and remote batching, while a small application session binds tracker checkpoints to the queue. `ReaderScreen` only forwards lifecycle and interaction events.

**Tech Stack:** Flutter/Dart, `SharedPreferences`, `PrivateApiClient`, `ChangeNotifier` auth state, `flutter_test`.

---

## File Map

- Create `lib/features/reading_activity/domain/reading_activity_event.dart`: immutable persisted/request event.
- Create `lib/features/reading_activity/domain/reading_session_tracker.dart`: pure time and progress calculation.
- Create `lib/features/reading_activity/application/reading_activity_recorder.dart`: UI-facing recorder and session contracts plus no-op default.
- Create `lib/features/reading_activity/application/tracked_reading_activity_session.dart`: checkpoint scheduling and event creation.
- Create `lib/features/reading_activity/data/reading_activity_store.dart`: per-user queue contract.
- Create `lib/features/reading_activity/data/shared_preferences_reading_activity_store.dart`: bounded JSON queue.
- Create `lib/features/reading_activity/data/reading_activity_remote_service.dart`: `/reading/sync` request adapter.
- Create `lib/features/reading_activity/data/synced_reading_activity_repository.dart`: queue mutation, batching, retry, and account isolation.
- Modify `lib/app/app_dependencies.dart`: expose `ReadingActivityRecorder` with a no-op default.
- Modify `lib/app/galaxy_novels_app.dart`: create and dispose the production recorder.
- Modify `lib/features/reader/presentation/native_reader_content.dart`: report pointer and scroll progress.
- Modify `lib/features/reader/presentation/reader_screen.dart`: bind chapter and app lifecycle to a reading session.
- Modify `docs/app_api_gap_audit.md`: mark `/reading/sync` queue and transport complete while leaving XP UI incomplete.

### Task 0: Checkpoint the completed history merge

**Files:**
- Stage only the already completed history and nonce changes shown by `git status`.
- Exclude this plan and all future reading-activity files.

- [ ] **Step 1: Re-run the completed feature checks**

Run:

```powershell
flutter test test/features/history test/features/favorites/synced_favorites_repository_test.dart
flutter analyze
```

Expected: all tests pass and analysis reports no issues.

- [ ] **Step 2: Commit the existing history feature separately**

```powershell
git add README.md docs/app_api_gap_audit.md lib/app/galaxy_novels_app.dart lib/core/network/private_api_client.dart lib/data/models/reading_progress.dart lib/features/favorites/data/favorites_remote_service.dart lib/features/history test/features/history
git commit -m "feat(history): merge local and account reading history"
```

Expected: the remaining worktree contains only this implementation plan before Task 1 begins.

### Task 1: Immutable event model

**Files:**
- Create: `lib/features/reading_activity/domain/reading_activity_event.dart`
- Test: `test/features/reading_activity/reading_activity_event_test.dart`

- [ ] **Step 1: Write the failing serialization test**

```dart
test('keeps owner metadata locally and omits it from the server request', () {
  final event = ReadingActivityEvent(
    ownerUserId: 7,
    eventId: 'app:7:501:1:a1b2c3d4',
    novelId: 42,
    chapterId: 501,
    activeSeconds: 48,
    openSeconds: 60,
    progress: 37,
    completed: false,
    views: 1,
    readAt: DateTime.utc(2026, 6, 23, 12, 30),
  );

  final restored = ReadingActivityEvent.fromStorageJson(event.toStorageJson());

  expect(restored.ownerUserId, 7);
  expect(restored.eventId, event.eventId);
  expect(restored.toRequestJson(), {
    'event_id': event.eventId,
    'object_type': 'chapter',
    'object_id': 501,
    'parent_id': 42,
    'reading_seconds': 48,
    'open_seconds': 60,
    'progress': 37,
    'completed': false,
    'views': 1,
    'read_at': '2026-06-23T12:30:00.000Z',
  });
});
```

- [ ] **Step 2: Run the test and verify RED**

Run: `flutter test test/features/reading_activity/reading_activity_event_test.dart`

Expected: compilation fails because `ReadingActivityEvent` does not exist.

- [ ] **Step 3: Implement the immutable model**

Implement a `const` class with the fields in the test. Clamp request values in `toRequestJson()` to active `0..300`, open `0..900`, progress `0..100`, and views `0..1`. `fromStorageJson` must reject invalid owner, event, novel, chapter, or date data with `FormatException`.

```dart
Map<String, Object?> toRequestJson() => {
  'event_id': eventId,
  'object_type': 'chapter',
  'object_id': chapterId,
  'parent_id': novelId,
  'reading_seconds': activeSeconds.clamp(0, 300),
  'open_seconds': openSeconds.clamp(0, 900),
  'progress': progress.clamp(0, 100),
  'completed': completed,
  'views': views.clamp(0, 1),
  'read_at': readAt.toUtc().toIso8601String(),
};
```

- [ ] **Step 4: Verify GREEN and commit**

Run: `flutter test test/features/reading_activity/reading_activity_event_test.dart`

Expected: PASS.

```powershell
git add lib/features/reading_activity/domain/reading_activity_event.dart test/features/reading_activity/reading_activity_event_test.dart
git commit -m "feat(reading): add immutable activity events"
```

### Task 2: Pure session tracker

**Files:**
- Create: `lib/features/reading_activity/domain/reading_session_tracker.dart`
- Test: `test/features/reading_activity/reading_session_tracker_test.dart`

- [ ] **Step 1: Write failing tests for active, idle, lifecycle, and completion**

```dart
test('counts foreground open time and only sixty seconds of idle activity', () {
  final start = DateTime.utc(2026, 6, 23, 12);
  final tracker = ReadingSessionTracker(startedAt: start);

  tracker.recordInteraction(start, progress: 10);
  final delta = tracker.checkpoint(start.add(const Duration(seconds: 90)));

  expect(delta, isNotNull);
  expect(delta!.openSeconds, 90);
  expect(delta.activeSeconds, 60);
  expect(delta.progress, 10);
  expect(delta.views, 1);
});

test('does not count background time and waits for interaction after resume', () {
  final start = DateTime.utc(2026, 6, 23, 12);
  final tracker = ReadingSessionTracker(startedAt: start)
    ..recordInteraction(start, progress: 20)
    ..pause(start.add(const Duration(seconds: 20)))
    ..resume(start.add(const Duration(minutes: 2)));

  final delta = tracker.checkpoint(start.add(const Duration(minutes: 2, seconds: 30)));

  expect(delta!.openSeconds, 50);
  expect(delta.activeSeconds, 20);
});

test('marks chapter complete at ninety two percent', () {
  final start = DateTime.utc(2026, 6, 23, 12);
  final tracker = ReadingSessionTracker(startedAt: start)
    ..recordInteraction(start, progress: 92);

  expect(tracker.checkpoint(start.add(const Duration(seconds: 1)))!.completed, isTrue);
});
```

- [ ] **Step 2: Run the tests and verify RED**

Run: `flutter test test/features/reading_activity/reading_session_tracker_test.dart`

Expected: compilation fails because the tracker and delta types do not exist.

- [ ] **Step 3: Implement elapsed-time accumulation**

Create `ReadingActivityDelta` and `ReadingSessionTracker`. The tracker keeps `lastSampleAt`, `activeUntil`, foreground state, accumulated milliseconds, highest progress, sent progress, first-view state, and completion state.

```dart
void _accrue(DateTime now) {
  if (!now.isAfter(_lastSampleAt)) return;
  if (_foreground) {
    _openMilliseconds += now.difference(_lastSampleAt).inMilliseconds;
    final activeEnd = now.isBefore(_activeUntil) ? now : _activeUntil;
    if (activeEnd.isAfter(_lastSampleAt)) {
      _activeMilliseconds += activeEnd.difference(_lastSampleAt).inMilliseconds;
    }
  }
  _lastSampleAt = now;
}
```

`checkpoint` returns null unless the snapshot has a first view, positive active seconds, newer progress, or newly completed state. It retains `open_seconds` until a sendable delta exists, then resets only accumulated time and first-view state.

- [ ] **Step 4: Verify GREEN and commit**

Run: `flutter test test/features/reading_activity/reading_session_tracker_test.dart`

Expected: PASS.

```powershell
git add lib/features/reading_activity/domain/reading_session_tracker.dart test/features/reading_activity/reading_session_tracker_test.dart
git commit -m "feat(reading): track active chapter sessions"
```

### Task 3: Durable per-account queue

**Files:**
- Create: `lib/features/reading_activity/data/reading_activity_store.dart`
- Create: `lib/features/reading_activity/data/shared_preferences_reading_activity_store.dart`
- Test: `test/features/reading_activity/reading_activity_store_test.dart`

- [ ] **Step 1: Write the failing account-isolation and queue-bound tests**

```dart
test('stores queues independently by account', () async {
  SharedPreferences.setMockInitialValues({});
  final store = SharedPreferencesReadingActivityStore();
  await store.write(7, [_event(ownerUserId: 7, eventId: 'event-7')]);
  await store.write(8, [_event(ownerUserId: 8, eventId: 'event-8')]);

  expect((await store.read(7)).single.eventId, 'event-7');
  expect((await store.read(8)).single.eventId, 'event-8');
});

test('keeps the newest five hundred events', () async {
  SharedPreferences.setMockInitialValues({});
  final store = SharedPreferencesReadingActivityStore();
  final events = List.generate(501, (index) => _event(eventId: 'event-$index'));

  await store.write(7, events);
  final restored = await store.read(7);

  expect(restored, hasLength(500));
  expect(restored.first.eventId, 'event-1');
});

ReadingActivityEvent _event({
  int ownerUserId = 7,
  String eventId = 'event',
}) {
  return ReadingActivityEvent(
    ownerUserId: ownerUserId,
    eventId: eventId,
    novelId: 42,
    chapterId: 501,
    activeSeconds: 10,
    openSeconds: 12,
    progress: 20,
    completed: false,
    views: 0,
    readAt: DateTime.utc(2026, 6, 23),
  );
}
```

- [ ] **Step 2: Run the tests and verify RED**

Run: `flutter test test/features/reading_activity/reading_activity_store_test.dart`

Expected: compilation fails because the store types do not exist.

- [ ] **Step 3: Implement the store**

Use key `reading_activity_queue.v1.<userId>`, JSON encode the list, keep the newest 500 entries, and return an empty list for missing or malformed payloads. Throw `ReadingActivityStoreException` only when SharedPreferences access or write fails.

- [ ] **Step 4: Verify GREEN and commit**

Run: `flutter test test/features/reading_activity/reading_activity_store_test.dart`

Expected: PASS.

```powershell
git add lib/features/reading_activity/data/reading_activity_store.dart lib/features/reading_activity/data/shared_preferences_reading_activity_store.dart test/features/reading_activity/reading_activity_store_test.dart
git commit -m "feat(reading): persist account activity queue"
```

### Task 4: Remote batch adapter

**Files:**
- Create: `lib/features/reading_activity/data/reading_activity_remote_service.dart`
- Test: `test/features/reading_activity/reading_activity_remote_service_test.dart`

- [ ] **Step 1: Write the failing request-shape test**

```dart
test('posts at most fifty immutable events to reading sync', () async {
  late PrivateRawRequest captured;
  final client = PrivateApiClient(
    config: const AppConfig(siteBaseUrl: 'https://example.com/'),
    requestSender: (request) async {
      captured = request;
      return const PrivateRawResponse(
        statusCode: 200,
        body: '{"success":true,"accepted":50,"duplicates":0}',
      );
    },
  )..updateNonce('nonce');
  final service = ReadingActivityRemoteService(client: client);

  final response = await service.sync(List.generate(55, _eventAt));

  expect(captured.uri.path, endsWith('/reading/sync'));
  expect((jsonDecode(captured.body!)['items'] as List), hasLength(50));
  expect(response.accepted, 50);
});

ReadingActivityEvent _eventAt(int index) {
  return ReadingActivityEvent(
    ownerUserId: 7,
    eventId: 'event-$index',
    novelId: 42,
    chapterId: 500 + index,
    activeSeconds: 10,
    openSeconds: 12,
    progress: 20,
    completed: false,
    views: index == 0 ? 1 : 0,
    readAt: DateTime.utc(2026, 6, 23),
  );
}
```

- [ ] **Step 2: Run the test and verify RED**

Run: `flutter test test/features/reading_activity/reading_activity_remote_service_test.dart`

Expected: compilation fails because the service does not exist.

- [ ] **Step 3: Implement the service**

Call `postAuthenticatedWithNonceRefresh('reading/sync', body: {'items': ...})`. Return `ReadingActivitySyncResult(accepted, duplicates)` and never send `final: true`.

- [ ] **Step 4: Verify GREEN and commit**

Run: `flutter test test/features/reading_activity/reading_activity_remote_service_test.dart`

Expected: PASS.

```powershell
git add lib/features/reading_activity/data/reading_activity_remote_service.dart test/features/reading_activity/reading_activity_remote_service_test.dart
git commit -m "feat(reading): add activity sync transport"
```

### Task 5: Synced repository and tracked session

**Files:**
- Create: `lib/features/reading_activity/application/reading_activity_recorder.dart`
- Create: `lib/features/reading_activity/application/tracked_reading_activity_session.dart`
- Create: `lib/features/reading_activity/data/synced_reading_activity_repository.dart`
- Test: `test/features/reading_activity/synced_reading_activity_repository_test.dart`
- Test: `test/features/reading_activity/tracked_reading_activity_session_test.dart`

- [ ] **Step 1: Write failing repository tests**

Cover these observable scenarios with a fake store boundary and fake HTTP sender:

```dart
test('guest chapter sessions are not created', () {
  final harness = _Harness(authState: const AuthSessionState.guest());
  addTearDown(harness.dispose);

  expect(harness.repository.startChapter(novelId: 42, chapterId: 501), isNull);
});

test('successful sync removes only the sent fifty events', () async {
  final harness = _Harness(events: List.generate(55, _eventAt));
  addTearDown(harness.dispose);

  await harness.repository.syncPending();

  expect(harness.server.batchSizes, [50]);
  expect(await harness.store.read(7), hasLength(5));
});

test('network failure keeps the complete batch for retry', () async {
  final harness = _Harness(events: [_eventAt(1)], offline: true);
  addTearDown(harness.dispose);

  await harness.repository.syncPending();

  expect(await harness.store.read(7), hasLength(1));
});

test('account switch never uploads the previous account queue', () async {
  final harness = _Harness(eventsByUser: {7: [_eventAt(7)], 8: [_eventAt(8, ownerUserId: 8)]});
  addTearDown(harness.dispose);
  harness.auth.value = const AuthSessionState.authenticated(secondUser);

  await harness.repository.syncPending();

  expect(harness.server.chapterIds, [8]);
});
```

- [ ] **Step 2: Run repository tests and verify RED**

Run: `flutter test test/features/reading_activity/synced_reading_activity_repository_test.dart`

Expected: compilation fails because the contracts and repository do not exist.

- [ ] **Step 3: Implement recorder contracts and repository**

The UI-facing contracts are:

```dart
abstract interface class ReadingActivitySession {
  void recordInteraction(int progress);
  Future<void> checkpoint();
  Future<void> pause();
  void resume();
  Future<void> finish();
}

abstract interface class ReadingActivityRecorder {
  ReadingActivitySession? startChapter({required int novelId, required int chapterId});
  Future<void> syncPending();
  void dispose();
}
```

Provide `NoopReadingActivityRecorder` as the default for direct `AppDependencies` test harnesses. `SyncedReadingActivityRepository` must serialize store mutations, bind sessions to the current authenticated `userId`, batch the oldest 50 events, remove sent IDs after a successful response, retain them for `PrivateApiException`, and call `restoreSession()` only for a current-user `401`.

Use this constructor so production and tests share one API:

```dart
SyncedReadingActivityRepository({
  required ReadingActivityStore store,
  required ReadingActivityRemoteService remoteService,
  required AuthRepository authRepository,
  Duration syncDelay = const Duration(seconds: 21),
});
```

Define the repository test boundaries explicitly:

```dart
class _MemoryReadingActivityStore implements ReadingActivityStore {
  _MemoryReadingActivityStore([Map<int, List<ReadingActivityEvent>> initial = const {}])
    : queues = {for (final entry in initial.entries) entry.key: [...entry.value]};

  final Map<int, List<ReadingActivityEvent>> queues;

  @override
  Future<List<ReadingActivityEvent>> read(int userId) async =>
      List.unmodifiable(queues[userId] ?? const []);

  @override
  Future<void> write(int userId, List<ReadingActivityEvent> events) async {
    queues[userId] = [...events];
  }
}

class _FakeReadingActivityServer {
  bool offline = false;
  final List<int> batchSizes = [];
  final List<int> chapterIds = [];

  Future<PrivateRawResponse> send(PrivateRawRequest request) async {
    if (offline) {
      throw const PrivateApiException(
        code: 'network_unavailable',
        message: 'offline',
      );
    }
    final body = jsonDecode(request.body!) as Map<String, dynamic>;
    final items = (body['items'] as List).cast<Map<String, dynamic>>();
    batchSizes.add(items.length);
    chapterIds.addAll(items.map((item) => item['object_id'] as int));
    return PrivateRawResponse(
      statusCode: 200,
      body: jsonEncode({
        'success': true,
        'accepted': items.length,
        'duplicates': 0,
      }),
    );
  }
}

class _Harness {
  _Harness({
    AuthSessionState authState = const AuthSessionState.authenticated(firstUser),
    List<ReadingActivityEvent> events = const [],
    Map<int, List<ReadingActivityEvent>> eventsByUser = const {},
    bool offline = false,
  }) : auth = FakeAuthRepository(initialState: authState),
       store = _MemoryReadingActivityStore(
         eventsByUser.isEmpty ? {7: events} : eventsByUser,
       ) {
    server.offline = offline;
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: server.send,
    )..updateNonce('nonce');
    repository = SyncedReadingActivityRepository(
      store: store,
      remoteService: ReadingActivityRemoteService(client: client),
      authRepository: auth,
      syncDelay: const Duration(days: 1),
    );
  }

  final FakeAuthRepository auth;
  final _MemoryReadingActivityStore store;
  final _FakeReadingActivityServer server = _FakeReadingActivityServer();
  late final SyncedReadingActivityRepository repository;

  void dispose() {
    repository.dispose();
    auth.dispose();
  }
}

ReadingActivityEvent _eventAt(int index, {int ownerUserId = 7}) {
  return ReadingActivityEvent(
    ownerUserId: ownerUserId,
    eventId: 'event-$ownerUserId-$index',
    novelId: 42,
    chapterId: index,
    activeSeconds: 10,
    openSeconds: 12,
    progress: 20,
    completed: false,
    views: 0,
    readAt: DateTime.utc(2026, 6, 23),
  );
}
```

Use real account value objects rather than mocks:

```dart
const firstUser = AuthUser(
  id: 7,
  displayName: 'القارئ الأول',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 1, display: ''),
  ),
);

const secondUser = AuthUser(
  id: 8,
  displayName: 'القارئ الثاني',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 1, display: ''),
  ),
);
```

- [ ] **Step 4: Write the failing tracked-session test**

```dart
test('checkpoint creates a stable event and forwards it once', () async {
  final events = <ReadingActivityEvent>[];
  final start = DateTime.utc(2026, 6, 23, 12);
  var now = start;
  final session = TrackedReadingActivitySession(
    ownerUserId: 7,
    novelId: 42,
    chapterId: 501,
    now: () => now,
    enqueue: (event) async => events.add(event),
  );
  session.recordInteraction(30);
  now = start.add(const Duration(seconds: 20));

  await session.checkpoint();
  await session.checkpoint();

  expect(events, hasLength(1));
  expect(events.single.activeSeconds, 20);
  expect(events.single.progress, 30);
  expect(events.single.eventId, isNotEmpty);
});
```

- [ ] **Step 5: Run the session test and verify RED**

Run: `flutter test test/features/reading_activity/tracked_reading_activity_session_test.dart`

Expected: compilation fails because `TrackedReadingActivitySession` does not exist.

- [ ] **Step 6: Implement session checkpointing and event IDs**

The session wraps `ReadingSessionTracker`, uses a single 60-second periodic timer, and creates IDs matching:

```text
app:<userId>:<chapterId>:<utcMicroseconds>:<8 hex chars>
```

`pause` checkpoints then pauses, `resume` resumes without marking activity, and `finish` cancels the timer and checkpoints once. Timer callbacks use `unawaited(checkpoint())`; the tracker snapshot is consumed synchronously before storage awaits.

- [ ] **Step 7: Verify GREEN and commit**

Run:

```powershell
flutter test test/features/reading_activity/synced_reading_activity_repository_test.dart
flutter test test/features/reading_activity/tracked_reading_activity_session_test.dart
```

Expected: PASS.

```powershell
git add lib/features/reading_activity/application lib/features/reading_activity/data/synced_reading_activity_repository.dart test/features/reading_activity/synced_reading_activity_repository_test.dart test/features/reading_activity/tracked_reading_activity_session_test.dart
git commit -m "feat(reading): queue and retry account activity"
```

### Task 6: App and Native reader integration

**Files:**
- Modify: `lib/app/app_dependencies.dart`
- Modify: `lib/app/galaxy_novels_app.dart`
- Modify: `lib/features/reader/presentation/native_reader_content.dart`
- Modify: `lib/features/reader/presentation/reader_screen.dart`
- Modify: `test/features/reader/reader_screen_test.dart`

- [ ] **Step 1: Write the failing reader interaction test**

Add a fake recorder/session to `_ReaderTestApp`, then test:

```dart
testWidgets('scrolling reports chapter progress to the account session', (tester) async {
  final recorder = _TestReadingActivityRecorder();
  await tester.pumpWidget(_ReaderTestApp(
    readingActivityRecorder: recorder,
    readerRepository: const _LongChapterReaderRepository(),
    child: const ReaderScreen(contentApi: '/chapters/10'),
  ));
  await tester.pumpAndSettle();

  await tester.drag(find.byType(ListView), const Offset(0, -500));
  await tester.pump();

  expect(recorder.sessions.single.progress, greaterThan(0));
});

class _TestReadingActivitySession implements ReadingActivitySession {
  int progress = 0;
  int finishCount = 0;

  @override
  void recordInteraction(int nextProgress) => progress = nextProgress;
  @override
  Future<void> checkpoint() async {}
  @override
  Future<void> pause() async {}
  @override
  void resume() {}
  @override
  Future<void> finish() async => finishCount++;
}

class _TestReadingActivityRecorder implements ReadingActivityRecorder {
  final sessions = <_TestReadingActivitySession>[];

  @override
  ReadingActivitySession startChapter({required int novelId, required int chapterId}) {
    final session = _TestReadingActivitySession();
    sessions.add(session);
    return session;
  }

  @override
  Future<void> syncPending() async {}
  @override
  void dispose() {}
}

class _LongChapterReaderRepository implements ReaderRepository {
  const _LongChapterReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    return ReaderChapterContent(
      id: 10,
      novelId: 1,
      label: 'الفصل 1',
      title: '',
      displayTitle: 'فصل طويل',
      position: 1,
      total: 2,
      contentHtml: List.filled(80, '<p>سطر قراءة طويل للاختبار</p>').join(),
      navigation: const ReaderChapterNavigation(
        previousApi: '',
        nextApi: '/chapters/11',
        previousId: 0,
        nextId: 11,
      ),
    );
  }
}
```

Add a second test that taps next and asserts the old session `finishCount == 1` before a new chapter session is present.

- [ ] **Step 2: Run the widget tests and verify RED**

Run: `flutter test test/features/reader/reader_screen_test.dart`

Expected: compilation fails because the recorder is not exposed and reader callbacks do not exist.

- [ ] **Step 3: Wire dependencies and lifecycle**

`AppDependencies` gets:

```dart
this.readingActivityRecorder = const NoopReadingActivityRecorder(),
final ReadingActivityRecorder readingActivityRecorder;
```

`GalaxyNovelsApp` lazily creates `SyncedReadingActivityRepository` with the shared `AuthRepository`, `PrivateApiClient`, `SharedPreferencesReadingActivityStore`, and `ReadingActivityRemoteService`. Dispose it before disposing auth.

Make `_ReaderScreenState` implement `WidgetsBindingObserver`. Add/remove the observer in `initState`/`dispose`, finish the previous session before chapter switches, pause on `inactive`, `paused`, and `detached`, and resume on `resumed`.

- [ ] **Step 4: Report scroll progress without rebuilding**

Give `NativeReaderContent` a required `ValueChanged<int> onReadingActivity`. Add a `ScrollController`, emit progress from its listener, and use:

```dart
final viewedExtent = controller.position.pixels + controller.position.viewportDimension;
final totalExtent = controller.position.maxScrollExtent + controller.position.viewportDimension;
final progress = totalExtent <= 0 ? 100 : ((viewedExtent / totalExtent) * 100).round().clamp(0, 100);
widget.onReadingActivity(progress);
```

Wrap the tap area with `Listener(onPointerDown: (_) => _emitReadingActivity())`. Reset scroll and emit initial progress after a chapter ID change.

- [ ] **Step 5: Verify GREEN and commit**

Run:

```powershell
flutter test test/features/reader/reader_screen_test.dart
flutter test test/features/reading_activity
```

Expected: PASS.

```powershell
git add lib/app/app_dependencies.dart lib/app/galaxy_novels_app.dart lib/features/reader/presentation/native_reader_content.dart lib/features/reader/presentation/reader_screen.dart test/features/reader/reader_screen_test.dart
git commit -m "feat(reader): record account reading activity"
```

### Task 7: Audit documentation and full verification

**Files:**
- Modify: `docs/app_api_gap_audit.md`
- Modify: `README.md` only if its feature summary needs to mention activity synchronization.

- [ ] **Step 1: Update the implementation matrix**

Make these exact status changes:

- `سجل القراءة`: keep account history merge complete and add durable `/reading/sync` activity queue.
- `نشاط القراءة وXP`: mark transport and queue complete; state that XP display is still not implemented.
- Stage 3 item 3: append `(مكتمل)`.
- Stage 3 item 4: leave incomplete.
- `الخطوة التالية مباشرة`: change to displaying server XP through `/me` or the available account payload, without calculating XP locally.

- [ ] **Step 2: Run documentation and diff checks**

```powershell
rg -n "reading/sync|نشاط القراءة|المرحلة 3|الخطوة التالية" docs/app_api_gap_audit.md README.md
git diff --check
```

Expected: no stale claim says `/reading/sync` is unimplemented, and `git diff --check` has no errors.

- [ ] **Step 3: Run the complete verification gate**

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Expected: analysis has zero issues, all tests pass, and the APK is created at `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 4: Review and commit**

Apply `clean-code-guard`, `test-guard`, and `docs-guard` to the final diff, fix findings, rerun the relevant verification, then commit:

```powershell
git add README.md docs/app_api_gap_audit.md lib/features/reading_activity lib/app lib/features/reader test/features/reading_activity test/features/reader/reader_screen_test.dart
git commit -m "feat(reading): sync durable account activity"
```

Expected: the final worktree contains no uncommitted reading-activity changes.
