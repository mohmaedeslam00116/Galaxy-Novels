# Account Profile Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** تحديث XP والرتبة من GET /me بعد تفريغ أحداث القراءة وعند فتح شاشة الحساب، مع دمج الطلبات وتهدئتها دون تعطيل الجلسة أو الواجهة.

**Architecture:** يبقى SessionAuthRepository المصدر الوحيد لـAuthUser ويضيف refreshProfile(). يطلب SyncedReadingActivityRepository التحديث بعد آخر دفعة ناجحة، وتستمع واجهة الحساب إلى حالة الجلسة نفسها فتتحدث تلقائيا.

**Tech Stack:** Flutter, Dart, Material 3, ChangeNotifier, ValueListenable, PrivateApiClient, flutter_test.

---

## خريطة الملفات

- إنشاء lib/features/account/data/auth_profile_payload.dart لتحليل استجابة GET /me والتحقق من الهوية.
- تعديل lib/features/account/application/auth_repository.dart لإضافة عقد refreshProfile().
- تعديل lib/features/account/data/session_auth_repository.dart للطلب والدمج والتهدئة وحماية تبديل الحساب.
- تعديل lib/features/reading_activity/data/synced_reading_activity_repository.dart للتحديث بعد تفريغ queue فقط.
- تعديل account_screen.dart وsigned_in_account_view.dart لطلب التحديث وعرض XP اليوم.
- تحديث الاختبارات الموجهة وdocs/app_api_gap_audit.md وREADME.md.

### Task 1: Parse the authenticated profile payload

**Files:**
- Create: lib/features/account/data/auth_profile_payload.dart
- Create: test/features/account/auth_profile_payload_test.dart

- [ ] **Step 1: Write the failing parser tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/account/data/auth_profile_payload.dart';

void main() {
  test('parses the user returned by me', () {
    final payload = AuthProfilePayload.fromResponse(
      _response(userId: 7),
      expectedUserId: 7,
    );

    expect(payload.user.id, 7);
    expect(payload.user.xp.total, 480);
    expect(payload.user.xp.today, 35);
    expect(payload.user.xp.rank.display, 'مستكشف');
  });

  test('rejects another account or a missing user', () {
    expect(
      () => AuthProfilePayload.fromResponse(
        _response(userId: 8),
        expectedUserId: 7,
      ),
      throwsFormatException,
    );
    expect(
      () => AuthProfilePayload.fromResponse(const {}, expectedUserId: 7),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> _response({required int userId}) => {
  'user': {
    'id': userId,
    'display_name': 'قارئ المجرة',
    'avatar': 'https://example.com/avatar.jpg',
    'vip': {'active': false},
    'xp': {
      'total': 480,
      'today': 35,
      'seconds_total': 1200,
      'chapters_total': 18,
      'rank': {'level': 3, 'display': 'مستكشف'},
    },
  },
};
```

- [ ] **Step 2: Run RED**

```powershell
flutter test test/features/account/auth_profile_payload_test.dart
```

Expected: FAIL because AuthProfilePayload does not exist.

- [ ] **Step 3: Implement the parser**

```dart
import '../domain/auth_session.dart';

class AuthProfilePayload {
  const AuthProfilePayload({required this.user});

  factory AuthProfilePayload.fromResponse(
    Map<String, dynamic> response, {
    required int expectedUserId,
  }) {
    final userJson = response['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Missing authenticated user profile.');
    }
    final user = AuthUser.fromJson(userJson);
    if (user.id != expectedUserId) {
      throw const FormatException('Authenticated user profile changed.');
    }
    return AuthProfilePayload(user: user);
  }

  final AuthUser user;
}
```

- [ ] **Step 4: Run GREEN and commit**

```powershell
flutter test test/features/account/auth_profile_payload_test.dart
git add lib/features/account/data/auth_profile_payload.dart test/features/account/auth_profile_payload_test.dart
git commit -m "feat(account): parse refreshed profile payload"
```

Expected: both parser tests PASS.

### Task 2: Refresh the profile without disrupting the session

**Files:**
- Modify: lib/features/account/application/auth_repository.dart
- Modify: lib/features/account/data/session_auth_repository.dart
- Modify: test/helpers/fake_auth_repository.dart
- Modify: test/features/account/session_auth_repository_test.dart

- [ ] **Step 1: Add failing repository tests**

Add concrete tests that log in through the existing harness, then return a GET /me payload:

```dart
test('refreshes the user from me without publishing loading', () async {
  final harness = _AuthHarness(
    responses: [
      _authenticatedResponse(setCookie: true),
      _profileResponse(totalXp: 990, todayXp: 45),
    ],
  );
  addTearDown(harness.repository.dispose);
  await harness.repository.login(_credentials);
  final statuses = <AuthSessionStatus>[];
  harness.repository.addListener(() {
    statuses.add(harness.repository.value.status);
  });

  await harness.repository.refreshProfile();

  expect(harness.requests.last.uri.path, endsWith('/me'));
  expect(harness.repository.value.user?.xp.total, 990);
  expect(harness.repository.value.user?.xp.today, 45);
  expect(statuses, isNot(contains(AuthSessionStatus.restoring)));
});

test('profile 401 restores the server session', () async {
  final harness = _AuthHarness(
    responses: [
      _authenticatedResponse(setCookie: true),
      const PrivateRawResponse(
        statusCode: 401,
        body: '{"code":"wor_reader_app_login_required"}',
      ),
      const PrivateRawResponse(
        statusCode: 200,
        body: '{"logged_in":false}',
      ),
    ],
  );
  addTearDown(harness.repository.dispose);
  await harness.repository.login(_credentials);

  await harness.repository.refreshProfile();

  expect(harness.repository.value.status, AuthSessionStatus.guest);
  expect(harness.requests.last.uri.path, endsWith('/session'));
});

test('profile network failure keeps the authenticated user', () async {
  final harness = _AuthHarness(
    responses: const [],
    responseHandler: (request) async {
      if (request.uri.path.endsWith('/auth/login')) {
        return _authenticatedResponse(setCookie: true);
      }
      throw const PrivateApiException(
        code: 'network_unavailable',
        message: 'offline',
      );
    },
  );
  addTearDown(harness.repository.dispose);
  await harness.repository.login(_credentials);

  await harness.repository.refreshProfile();

  expect(harness.repository.value.status, AuthSessionStatus.authenticated);
  expect(harness.repository.value.user?.xp.total, 320);
});

const _credentials = LoginCredentials(
  username: 'reader',
  password: 'secret',
  rememberSession: true,
);

PrivateRawResponse _profileResponse({
  required int totalXp,
  required int todayXp,
}) {
  return PrivateRawResponse(
    statusCode: 200,
    body: '''
      {
        "user": {
          "id": 7,
          "display_name": "قارئ المجرة",
          "avatar": "https://example.com/avatar.jpg",
          "vip": {"active": false},
          "xp": {
            "total": $totalXp,
            "today": $todayXp,
            "seconds_total": 1200,
            "chapters_total": 18,
            "rank": {"level": 3, "display": "مستكشف"}
          }
        }
      }
    ''',
  );
}
```

Extend `_AuthHarness` with an optional response handler while preserving its recorded requests:

```dart
_AuthHarness({
  required List<PrivateRawResponse> responses,
  FakeAuthSessionStore? sessionStore,
  Future<PrivateRawResponse> Function(PrivateRawRequest request)?
      responseHandler,
}) : responses = [...responses],
     sessionStore = sessionStore ?? FakeAuthSessionStore() {
  final client = PrivateApiClient(
    config: const AppConfig(siteBaseUrl: 'https://example.com/'),
    requestSender: (request) async {
      requests.add(request);
      if (responseHandler != null) {
        return responseHandler(request);
      }
      return this.responses.removeAt(0);
    },
  );
  repository = SessionAuthRepository(
    client: client,
    sessionStore: this.sessionStore,
  );
}
```

- [ ] **Step 2: Run RED**

```powershell
flutter test test/features/account/session_auth_repository_test.dart --plain-name "refreshes the user from me without publishing loading"
```

Expected: FAIL because refreshProfile is undefined.

- [ ] **Step 3: Add the contract and fake**

Add to AuthRepository:

```dart
Future<void> refreshProfile();
```

Add to FakeAuthRepository:

```dart
int refreshProfileCalls = 0;

@override
Future<void> refreshProfile() async {
  refreshProfileCalls++;
}
```

- [ ] **Step 4: Implement safe immediate refresh**

Import auth_profile_payload.dart and add:

```dart
@override
Future<void> refreshProfile() async {
  final state = _value;
  final owner = state.status == AuthSessionStatus.authenticated
      ? state.user
      : null;
  if (owner == null || _disposed) {
    return;
  }

  try {
    final response = await _client.getAuthenticatedWithNonceRefresh('me');
    final refreshed = AuthProfilePayload.fromResponse(
      response,
      expectedUserId: owner.id,
    ).user;
    final current = _value;
    if (current.status == AuthSessionStatus.authenticated &&
        current.user?.id == owner.id) {
      _publishState(
        AuthSessionState.authenticated(
          refreshed,
          noticeMessage: current.noticeMessage,
        ),
      );
    }
  } on PrivateApiException catch (error) {
    if (error.statusCode == 401 && _value.user?.id == owner.id) {
      await restoreSession();
    }
  } on FormatException {
    return;
  }
}
```

Do not publish restoring or failure for network, server, or payload errors. The 401 branch alone revalidates the session.

- [ ] **Step 5: Run GREEN and commit**

```powershell
flutter test test/features/account/auth_profile_payload_test.dart test/features/account/session_auth_repository_test.dart
git add lib/features/account/application/auth_repository.dart lib/features/account/data/session_auth_repository.dart test/helpers/fake_auth_repository.dart test/features/account/session_auth_repository_test.dart
git commit -m "feat(account): refresh server profile safely"
```

Expected: all account data tests PASS.

### Task 3: Deduplicate and throttle refresh requests

**Files:**
- Modify: lib/features/account/data/session_auth_repository.dart
- Modify: test/features/account/session_auth_repository_test.dart

- [ ] **Step 1: Write failing request-control tests**

Use a Completer response to prove concurrent calls send one request:

```dart
test('deduplicates concurrent profile refresh requests', () async {
  final profile = Completer<PrivateRawResponse>();
  final harness = _AuthHarness(
    responses: const [],
    responseHandler: (request) {
      if (request.uri.path.endsWith('/auth/login')) {
        return Future.value(_authenticatedResponse(setCookie: true));
      }
      return profile.future;
    },
  );
  addTearDown(harness.repository.dispose);
  await harness.repository.login(_credentials);

  final first = harness.repository.refreshProfile();
  final second = harness.repository.refreshProfile();
  expect(
    harness.requests.where((request) => request.uri.path.endsWith('/me')),
    hasLength(1),
  );

  profile.complete(_profileResponse(totalXp: 500, todayXp: 20));
  await Future.wait([first, second]);
});

test('schedules one refresh after the cooldown', () async {
  final harness = _AuthHarness(
    responses: [
      _authenticatedResponse(setCookie: true),
      _profileResponse(totalXp: 500, todayXp: 20),
      _profileResponse(totalXp: 520, todayXp: 40),
    ],
    profileRefreshCooldown: const Duration(milliseconds: 30),
  );
  addTearDown(harness.repository.dispose);
  await harness.repository.login(_credentials);
  await harness.repository.refreshProfile();

  await harness.repository.refreshProfile();
  await harness.repository.refreshProfile();
  expect(
    harness.requests.where((request) => request.uri.path.endsWith('/me')),
    hasLength(1),
  );

  await Future<void>.delayed(const Duration(milliseconds: 45));
  expect(
    harness.requests.where((request) => request.uri.path.endsWith('/me')),
    hasLength(2),
  );
  expect(harness.repository.value.user?.xp.total, 520);
});

test('ignores an old profile response after logout', () async {
  final profile = Completer<PrivateRawResponse>();
  final harness = _AuthHarness(
    responses: const [],
    responseHandler: (request) {
      if (request.uri.path.endsWith('/auth/login')) {
        return Future.value(_authenticatedResponse(setCookie: true));
      }
      if (request.uri.path.endsWith('/auth/logout')) {
        return Future.value(
          const PrivateRawResponse(
            statusCode: 200,
            body: '{"logged_in":false}',
          ),
        );
      }
      return profile.future;
    },
  );
  addTearDown(harness.repository.dispose);
  await harness.repository.login(_credentials);

  final refresh = harness.repository.refreshProfile();
  await harness.repository.logout();
  profile.complete(_profileResponse(totalXp: 999, todayXp: 99));
  await refresh;

  expect(harness.repository.value.status, AuthSessionStatus.guest);
});
```

Extend `_AuthHarness` with a `profileRefreshCooldown` argument and pass it through the production constructor:

```dart
_AuthHarness({
  required List<PrivateRawResponse> responses,
  FakeAuthSessionStore? sessionStore,
  Future<PrivateRawResponse> Function(PrivateRawRequest request)?
      responseHandler,
  Duration profileRefreshCooldown = const Duration(seconds: 60),
}) : responses = [...responses],
     sessionStore = sessionStore ?? FakeAuthSessionStore() {
  final client = PrivateApiClient(
    config: const AppConfig(siteBaseUrl: 'https://example.com/'),
    requestSender: (request) async {
      requests.add(request);
      if (responseHandler != null) {
        return responseHandler(request);
      }
      return this.responses.removeAt(0);
    },
  );
  repository = SessionAuthRepository(
    client: client,
    sessionStore: this.sessionStore,
    profileRefreshCooldown: profileRefreshCooldown,
  );
}
```

- [ ] **Step 2: Run RED**

```powershell
flutter test test/features/account/session_auth_repository_test.dart --plain-name "deduplicates concurrent profile refresh requests"
```

Expected: FAIL because two GET /me requests are sent.

- [ ] **Step 3: Add request-control state**

```dart
final Duration _profileRefreshCooldown;
Future<void>? _profileRefreshInFlight;
int? _profileRefreshInFlightUserId;
DateTime? _lastProfileRefreshAttemptAt;
Timer? _profileRefreshTimer;
int? _profileRefreshTimerUserId;
```

The constructor default is Duration(seconds: 60). Import dart:async.

- [ ] **Step 4: Refactor refreshProfile**

```dart
@override
Future<void> refreshProfile() {
  final userId = _authenticatedUserId;
  if (userId == null || _disposed) {
    return Future.value();
  }
  final inFlight = _profileRefreshInFlight;
  if (inFlight != null && _profileRefreshInFlightUserId == userId) {
    return inFlight;
  }

  final lastAttempt = _lastProfileRefreshAttemptAt;
  final elapsed = lastAttempt == null
      ? _profileRefreshCooldown
      : DateTime.now().toUtc().difference(lastAttempt);
  final remaining = _profileRefreshCooldown - elapsed;
  if (remaining > Duration.zero) {
    _scheduleProfileRefresh(userId, remaining);
    return Future.value();
  }
  return _startProfileRefresh(userId);
}
```

Move Task 2's request body to `_refreshProfileNow(int userId)` and add the helpers below:

```dart
int? get _authenticatedUserId {
  final state = _value;
  return state.status == AuthSessionStatus.authenticated
      ? state.user?.id
      : null;
}

Future<void> _startProfileRefresh(int userId) {
  final existing = _profileRefreshInFlight;
  if (existing != null && _profileRefreshInFlightUserId == userId) {
    return existing;
  }
  _profileRefreshTimer?.cancel();
  _profileRefreshTimer = null;
  _profileRefreshTimerUserId = null;
  _lastProfileRefreshAttemptAt = DateTime.now().toUtc();

  final refresh = _refreshProfileNow(userId);
  _profileRefreshInFlight = refresh;
  _profileRefreshInFlightUserId = userId;
  return refresh.whenComplete(() {
    if (identical(_profileRefreshInFlight, refresh)) {
      _profileRefreshInFlight = null;
      _profileRefreshInFlightUserId = null;
    }
  });
}

void _scheduleProfileRefresh(int userId, Duration delay) {
  final currentTimer = _profileRefreshTimer;
  if (currentTimer?.isActive == true &&
      _profileRefreshTimerUserId == userId) {
    return;
  }
  currentTimer?.cancel();
  _profileRefreshTimerUserId = userId;
  _profileRefreshTimer = Timer(delay, () {
    _profileRefreshTimer = null;
    _profileRefreshTimerUserId = null;
    if (!_disposed && _authenticatedUserId == userId) {
      unawaited(_startProfileRefresh(userId));
    }
  });
}

void _resetProfileRefreshSchedule() {
  _profileRefreshTimer?.cancel();
  _profileRefreshTimer = null;
  _profileRefreshTimerUserId = null;
  _lastProfileRefreshAttemptAt = null;
}
```

At the start of `_publishState`, compare the old authenticated ID with the next authenticated ID and call `_resetProfileRefreshSchedule()` when they differ. In `_refreshProfileNow`, parse with `expectedUserId: userId` and publish only if `_authenticatedUserId == userId`. In `dispose`, call `_resetProfileRefreshSchedule()` before `super.dispose()`.

- [ ] **Step 5: Run GREEN and commit**

```powershell
flutter test test/features/account
git add lib/features/account/data/session_auth_repository.dart test/features/account/session_auth_repository_test.dart
git commit -m "feat(account): throttle profile refresh requests"
```

Expected: all account tests PASS, including the delayed update.

### Task 4: Refresh only after the final reading sync batch

**Files:**
- Modify: lib/features/reading_activity/data/synced_reading_activity_repository.dart
- Modify: test/features/reading_activity/synced_reading_activity_repository_test.dart

- [ ] **Step 1: Write failing integration tests**

```dart
test('refreshes the account after the queue is fully synchronized', () async {
  final harness = _Harness(events: [_eventAt(1)]);
  addTearDown(harness.dispose);

  await harness.repository.syncPending();

  expect(await harness.store.read(7), isEmpty);
  expect(harness.auth.refreshProfileCalls, 1);
});

test('waits for the final batch before refreshing the account', () async {
  final harness = _Harness(
    events: List.generate(51, (index) => _eventAt(index + 1)),
  );
  addTearDown(harness.dispose);

  await harness.repository.syncPending();
  expect(await harness.store.read(7), hasLength(1));
  expect(harness.auth.refreshProfileCalls, 0);

  await harness.repository.syncPending();
  expect(await harness.store.read(7), isEmpty);
  expect(harness.auth.refreshProfileCalls, 1);
});
```

Also assert refreshProfileCalls remains zero for the existing offline and 401 tests.

- [ ] **Step 2: Run RED**

```powershell
flutter test test/features/reading_activity/synced_reading_activity_repository_test.dart --plain-name "refreshes the account after the queue is fully synchronized"
```

Expected: FAIL with refreshProfileCalls equal to zero.

- [ ] **Step 3: Distinguish removal failure and trigger refresh**

Change _removeSentBatch to Future<int?> and return null on ReadingActivityStoreException. Then use:

```dart
final remainingCount = await _removeSentBatch(userId, batch);
if (remainingCount == null || _authenticatedUserId != userId) {
  return;
}
if (remainingCount > 0) {
  _scheduleSync(userId);
  return;
}
await _authRepository.refreshProfile();
```

This runs only after successful upload and successful local removal. refreshProfile absorbs expected profile errors, so accepted reading events are never restored.

- [ ] **Step 4: Run GREEN and commit**

```powershell
flutter test test/features/reading_activity
git add lib/features/reading_activity/data/synced_reading_activity_repository.dart test/features/reading_activity/synced_reading_activity_repository_test.dart
git commit -m "feat(reading): refresh account after final sync batch"
```

Expected: all reading activity tests PASS.

### Task 5: Refresh and present account statistics

**Files:**
- Modify: lib/features/account/presentation/account_screen.dart
- Modify: lib/features/account/presentation/widgets/signed_in_account_view.dart
- Modify: test/widget_test.dart

- [ ] **Step 1: Write the failing narrow-screen widget test**

```dart
testWidgets('signed in account refreshes and shows server XP statistics', (
  tester,
) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final authRepository = FakeAuthRepository(
    initialState: const AuthSessionState.authenticated(_testAuthUser),
  );
  await tester.pumpWidget(
    GalaxyNovelsApp(
      homeRepository: _TestHomeRepository(_homeData),
      catalogRepository: const _TestCatalogRepository(),
      novelRepository: const _TestNovelRepository(),
      authRepository: authRepository,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text('حسابي'));
  await tester.pumpAndSettle();

  expect(authRepository.refreshProfileCalls, 1);
  expect(find.text('نقاط XP'), findsOneWidget);
  expect(find.text('XP اليوم'), findsOneWidget);
  expect(find.text('فصول مقروءة'), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Run RED**

```powershell
flutter test test/widget_test.dart --plain-name "signed in account refreshes and shows server XP statistics"
```

Expected: FAIL because XP اليوم is absent and refreshProfileCalls is zero.

- [ ] **Step 3: Trigger refresh on account open**

In AccountScreen.didChangeDependencies:

```dart
if (repository.value.status == AuthSessionStatus.idle) {
  unawaited(repository.restoreSession());
} else if (repository.value.status == AuthSessionStatus.authenticated) {
  unawaited(repository.refreshProfile());
}
```

- [ ] **Step 4: Render three compact statistics**

Replace the two-item Row with:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    const spacing = 8.0;
    final width = (constraints.maxWidth - spacing * 2) / 3;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        SizedBox(
          width: width,
          child: _AccountStat(
            label: 'نقاط XP',
            value: user.xp.total.toString(),
          ),
        ),
        SizedBox(
          width: width,
          child: _AccountStat(
            label: 'XP اليوم',
            value: user.xp.today.toString(),
          ),
        ),
        SizedBox(
          width: width,
          child: _AccountStat(
            label: 'فصول مقروءة',
            value: user.xp.chaptersTotal.toString(),
          ),
        ),
      ],
    );
  },
)
```

Wrap only the numeric value in FittedBox(fit: BoxFit.scaleDown), keep labels centered, radius 8, and theme colors only.

- [ ] **Step 5: Run GREEN and commit**

```powershell
flutter test test/widget_test.dart --plain-name "signed in account"
git add lib/features/account/presentation/account_screen.dart lib/features/account/presentation/widgets/signed_in_account_view.dart test/widget_test.dart
git commit -m "feat(account): show refreshed daily XP statistics"
```

Expected: account refresh/statistics and logout tests PASS without overflow.

### Task 6: Update the audit and verify the app

**Files:**
- Modify: docs/app_api_gap_audit.md
- Modify: README.md

- [ ] **Step 1: Update documentation**

Mark GET /me and server-authoritative XP/rank display as implemented. State that profile refresh happens only after the final accepted reading batch and on account open. Keep local XP calculation, rewards history, download points, and advertisements unimplemented. Set the next API work to GET /me/novels/{novel_id} and ratings unless project priority changes.

Add one README sentence that XP and rank refresh from the server after reading activity synchronization.

- [ ] **Step 2: Format and inspect**

```powershell
dart format lib test
git diff --check
git diff --stat
```

Expected: formatting succeeds, diff check exits zero, and only scoped files changed.

- [ ] **Step 3: Run full verification**

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Expected: no analyzer issues, all tests pass, and build/app/outputs/flutter-apk/app-debug.apk is produced.

- [ ] **Step 4: Commit and confirm clean state**

```powershell
git add README.md docs/app_api_gap_audit.md
git commit -m "docs(account): complete server profile refresh audit"
git status --short
```

Expected: commit succeeds and status prints no output.
