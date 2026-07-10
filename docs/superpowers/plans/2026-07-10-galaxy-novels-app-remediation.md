# Galaxy Novels App Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix every confirmed app-side defect in the current Flutter application while preserving the intentional behavior that tapping “Latest Updates” opens the novel-details screen and while keeping iOS advertising disabled for this release cycle.

**Architecture:** Introduce small, testable boundaries instead of broad rewrites: a shared Android-only AdMob readiness coordinator, scoped reading-history persistence, lifecycle generations for asynchronous controllers, injectable public-network timeouts, and crash-recoverable download-index replacement. Preserve the existing repository interfaces used by screens where possible, and add narrowly scoped companion interfaces only where account isolation requires them.

**Tech Stack:** Flutter, Dart, Material 3, ChangeNotifier/ValueListenable, SharedPreferencesAsync, dart:io, google_mobile_ads 9.0.0, Android Gradle Kotlin DSL, flutter_test.

## Global Constraints

- Work from "D:\Galaxy Novels"; Flutter commands run from "D:\Galaxy Novels\galaxy_novels_app".
- The worktree already contains user changes. Never reset, discard, reformat, stage, or commit unrelated files.
- Several implementation files below already overlap the user's work. In this shared worktree, replace every normal per-task commit with a local checkpoint: run the focused tests, run "git diff --check", and inspect only the paths named by that task.
- Do not change the product contract for “Latest Updates”. Its cards continue to open novel details, not a chapter.
- Do not add iOS AdMob IDs or initialize the ads SDK on iOS. iOS repositories return null/unavailable until a later release project.
- Do not add packages. The existing Dart, Flutter, and google_mobile_ads APIs are sufficient.
- For every behavioral fix, add the regression test first, run it, and confirm the expected failure before editing production code.
- Preserve Arabic user-facing messages unless this plan gives an exact replacement.
- Do not weaken a test to hide an asynchronous error. All timers/futures created by a test must either complete or be cancelled.
- Android Gradle commands must use Android Studio's JBR because the machine's other JDK is incompatible:

      $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'

- Before starting, record the baseline without modifying it:

      git status --short
      Set-Location .\galaxy_novels_app
      dart analyze
      flutter test

  Expected baseline: analysis passes; the suite reports 18 widget failures caused by the pending 1.2-second ad initialization timer.

---

### Task 1: Make Android Release Signing Fail Closed

**Files:**

- Modify: "galaxy_novels_app/android/app/build.gradle.kts"

- [ ] **Step 1: Reproduce the unsafe release configuration**

  From "galaxy_novels_app/android", run:

      $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
      .\gradlew.bat signingReport --console=plain
      .\gradlew.bat build --dry-run --console=plain

  Expected before the fix:

  - signingReport prints the release variant with "Config: debug".
  - generic build succeeds even though no production key is configured.

- [ ] **Step 2: Separate production signing, explicit local debug signing, and unsigned release**

  In "android/app/build.gradle.kts":

  1. Remove the current startParameter-based "releaseBuildRequested" check.
  2. Remove the complete "ALLOW_TEST_ADS_IN_RELEASE" path; it cannot keep the Android App ID and Dart ad-unit IDs consistent.
  3. Resolve "ALLOW_DEBUG_SIGNING_IN_RELEASE" once at the top level from a Gradle property or environment variable.
  4. Keep the production signing config only when every required key property is present.
  5. In buildTypes.release, choose exactly one signing config:

         signingConfig = when {
           hasProductionSigningConfig -> signingConfigs.getByName("release")
           allowDebugSigningInRelease -> signingConfigs.getByName("debug")
           else -> null
         }

  6. Add a task-graph guard after Android configuration. It must detect app artifact tasks whose names both produce an artifact and contain "Release", including assembleRelease, bundleRelease, packageRelease, and installRelease. Because generic build depends on assembleRelease, it is covered automatically:

         gradle.taskGraph.whenReady {
           val releaseArtifactRequested = allTasks.any { task ->
             task.project == project &&
               task.name.contains("Release", ignoreCase = true) &&
               listOf("assemble", "bundle", "package", "install")
                 .any { prefix -> task.name.startsWith(prefix) }
           }
           if (
             releaseArtifactRequested &&
             !hasProductionSigningConfig &&
             !allowDebugSigningInRelease
           ) {
             throw GradleException(
               "Missing Android release signing config. Configure the " +
                 "production keystore or set " +
                 "ALLOW_DEBUG_SIGNING_IN_RELEASE=true for local testing only."
             )
           }
         }

  Keep debug/profile using Google's test App ID. Keep release using the bundled production App ID or "ADMOB_ANDROID_APP_ID"; do not reintroduce a release test-ID switch.

- [ ] **Step 3: Verify all four signing paths**

  Run:

      .\gradlew.bat signingReport --console=plain
      .\gradlew.bat build --dry-run --console=plain
      .\gradlew.bat assembleDebug --dry-run --console=plain
      $env:ALLOW_DEBUG_SIGNING_IN_RELEASE = 'true'
      .\gradlew.bat build --dry-run --console=plain
      Remove-Item Env:ALLOW_DEBUG_SIGNING_IN_RELEASE

  Expected after the fix:

  - signingReport no longer binds release to debug by default.
  - generic build fails with the exact missing-signing explanation.
  - assembleDebug succeeds.
  - the explicitly opted-in local release dry-run succeeds.

- [ ] **Step 4: Checkpoint**

      Set-Location ..\..
      git diff --check
      git diff -- galaxy_novels_app/android/app/build.gradle.kts

  Do not stage or commit this overlapping user file.

---

### Task 2: Gate All Android Ads Behind One UMP Readiness Future

**Files:**

- Create: "galaxy_novels_app/lib/features/ads/data/admob_initialization_coordinator.dart"
- Modify: "galaxy_novels_app/lib/features/ads/data/admob_reader_ad_repository.dart"
- Modify: "galaxy_novels_app/lib/features/ads/data/admob_rewarded_ad_repository.dart"
- Modify: "galaxy_novels_app/lib/features/ads/presentation/admob_adaptive_banner.dart"
- Modify: "galaxy_novels_app/lib/app/galaxy_novels_app.dart"
- Create: "galaxy_novels_app/test/features/ads/admob_initialization_coordinator_test.dart"
- Create: "galaxy_novels_app/test/features/ads/admob_ad_repositories_test.dart"
- Create: "galaxy_novels_app/test/features/ads/admob_adaptive_banner_test.dart"

- [ ] **Step 1: Write coordinator tests before the class exists**

  Define test doubles with ordinary callbacks and event lists; do not mock static plugin singletons. Add these tests:

  - "runs consent update, required form, permission check, and SDK init in order"
  - "does not show a form or initialize ads when consent update fails"
  - "does not initialize ads when the consent form reports an error"
  - "does not initialize ads when canRequestAds is false"
  - "shares one initialization future across concurrent callers"
  - "returns false without plugin work outside Android"

  The success test should assert:

      expect(events, ['update', 'form', 'canRequest', 'mobileAds']);
      expect(await coordinator.initialize(), isTrue);

  The concurrent test must call initialize twice before completing the first consent callback and assert that every callback ran exactly once.

- [ ] **Step 2: Run the new tests and confirm RED**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      flutter test test/features/ads/admob_initialization_coordinator_test.dart

  Expected: compilation fails because AdMobInitializationCoordinator does not exist.

- [ ] **Step 3: Implement the coordinator with production-useful seams**

  Add these public callback types and API:

      typedef AdsPlatformCheck = bool Function();
      typedef AdsAsyncStep = Future<void> Function();
      typedef AdsPermissionCheck = Future<bool> Function();

      class AdMobInitializationCoordinator {
        AdMobInitializationCoordinator({
          AdsPlatformCheck? isAndroid,
          AdsAsyncStep? updateConsentInfo,
          AdsAsyncStep? showConsentFormIfRequired,
          AdsPermissionCheck? canRequestAds,
          AdsAsyncStep? initializeMobileAds,
        });

        static final shared = AdMobInitializationCoordinator();

        bool get isSupported;
        Future<bool> initialize();
      }

  Required behavior:

  - Default isSupported is true only when not web and defaultTargetPlatform is Android.
  - Cache one "Future<bool>?" and return it from every initialize call.
  - For unsupported platforms, return false before touching any plugin API.
  - Execute update consent info, show required form, canRequestAds, then MobileAds.initialize.
  - Return false for consent/form/plugin errors and never leak an unhandled asynchronous error.

  Convert the callback API exactly once:

      Future<void> _updateConsentInfo() {
        final completer = Completer<void>();
        ConsentInformation.instance.requestConsentInfoUpdate(
          const ConsentRequestParameters(),
          completer.complete,
          (error) => completer.completeError(error),
        );
        return completer.future;
      }

      Future<void> _showConsentFormIfRequired() {
        final completer = Completer<void>();
        ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error == null) {
            completer.complete();
          } else {
            completer.completeError(error);
          }
        });
        return completer.future;
      }

  The MobileAds seam returns Future<void> and discards InitializationStatus after awaiting it.

- [ ] **Step 4: Run coordinator tests and confirm GREEN**

      flutter test test/features/ads/admob_initialization_coordinator_test.dart

  Expected: all coordinator tests pass without a platform channel.

- [ ] **Step 5: Add repository and banner regression tests**

  In "admob_ad_repositories_test.dart", add:

  - "reader ads return no banner on an unsupported platform"
  - "rewarded ads return unavailable when consent does not allow ads"
  - "reader and rewarded repositories can share one coordinator"

  In "admob_adaptive_banner_test.dart", pump a finite-width banner with a pending readiness Future:

      final readiness = Completer<bool>();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: AdMobAdaptiveBanner.reservedHeight,
            child: AdMobAdaptiveBanner(
              adUnitId: 'test-unit',
              readiness: readiness.future,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

  Complete readiness with false, pump again, and assert there is still no exception. If AdSize or BannerAd.load runs before true, the test environment will expose the unwanted platform call.

- [ ] **Step 6: Run repository/banner tests and confirm RED**

      flutter test test/features/ads/admob_ad_repositories_test.dart
      flutter test test/features/ads/admob_adaptive_banner_test.dart

  Expected: constructors do not accept a coordinator/readiness Future and iOS is currently treated as supported.

- [ ] **Step 7: Route both ad surfaces through the coordinator**

  Implement these rules:

  - AdMobReaderAdRepository receives an optional coordinator, defaulting to AdMobInitializationCoordinator.shared.
  - initialize awaits coordinator.initialize and discards the bool to preserve ReaderAdRepository's public interface.
  - buildReaderBanner returns null immediately when coordinator.isSupported is false.
  - On Android it builds AdMobAdaptiveBanner with "readiness: coordinator.initialize()".
  - AdMobRewardedAdRepository receives the same optional coordinator.
  - showRewardedAd starts with:

        if (!await _coordinator.initialize()) {
          return RewardedAdOutcome.unavailable;
        }

  - Wrap load/show plugin failures and convert them to unavailable/failed according to the existing outcome semantics.
  - Replace each old Android-or-iOS platform getter; iOS must not initialize, size, load, or show an ad.

  Refactor AdMobAdaptiveBanner so the stateful loader is created only after a FutureBuilder sees "snapshot.data == true". While readiness is pending/false/error, return SizedBox.expand. This guarantees AdSize and BannerAd.load cannot run before UMP permission.

  In GalaxyNovelsApp, construct one late-final default coordinator and inject that exact instance into the default reader and rewarded repositories.

- [ ] **Step 8: Run the complete ads slice**

      flutter test test/features/ads

  Expected: all ads tests pass; no MissingPluginException and no pending timers.

- [ ] **Step 9: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check
      git diff -- galaxy_novels_app/lib/features/ads galaxy_novels_app/lib/app/galaxy_novels_app.dart galaxy_novels_app/test/features/ads

  Do not stage or commit overlapping files.

---

### Task 3: Cancel Deferred Ad Initialization with the App Lifecycle

**Files:**

- Modify: "galaxy_novels_app/lib/app/galaxy_novels_app.dart"
- Modify: "galaxy_novels_app/test/widget_test.dart"

- [ ] **Step 1: Add the timer-disposal regression test**

  Reuse the existing _CountingReaderAdRepository and _CountingRewardedAdRepository helpers in widget_test.dart. Add:

      testWidgets(
        'cancels deferred ad initialization timer when app is disposed',
        (tester) async {
          final readerAds = _CountingReaderAdRepository();
          final rewardedAds = _CountingRewardedAdRepository();

          await tester.pumpWidget(
            GalaxyNovelsApp(
              readerAdRepository: readerAds,
              rewardedAdRepository: rewardedAds,
            ),
          );
          await tester.pump();
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();

          expect(readerAds.initializeCalls, 0);
          expect(rewardedAds.initializeCalls, 0);
        },
      );

  If the existing deferral test injects additional fake repositories to avoid network work, copy that exact app fixture into this test.

- [ ] **Step 2: Run the focused test and confirm RED**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      flutter test test/widget_test.dart --plain-name "cancels deferred ad initialization timer when app is disposed"

  Expected: flutter_test reports a Timer still pending after the widget tree was disposed.

- [ ] **Step 3: Replace Future.delayed with an owned Timer**

  Add:

      Timer? _adInitializationTimer;

  In _scheduleAdInitialization:

  - Keep the identity early-return for the same pair of repositories.
  - Cancel and clear the previous timer when the repository pair changes.
  - Increment the generation.
  - In the post-frame callback, check mounted and generation before creating a Timer.
  - Store the Timer and clear the field from its own callback before initializing repositories.

  Use an identity-safe callback:

      late final Timer timer;
      timer = Timer(_postStartupAdInitializationDelay, () {
        if (identical(_adInitializationTimer, timer)) {
          _adInitializationTimer = null;
        }
        if (!mounted || generation != _adInitializationGeneration) {
          return;
        }
        unawaited(readerAdRepository.initialize());
        unawaited(rewardedAdRepository.initialize());
      });
      _adInitializationTimer = timer;

  In dispose, increment the generation, cancel the timer, clear the field, then dispose the remaining owned objects.

- [ ] **Step 4: Prove both cancellation and intended delay**

      flutter test test/widget_test.dart --plain-name "cancels deferred ad initialization timer when app is disposed"
      flutter test test/widget_test.dart --plain-name "defers ad initialization until after startup paint"

  Expected: both pass. The delay test must still observe zero calls before 1200 ms and one call afterward.

- [ ] **Step 5: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check
      git diff -- galaxy_novels_app/lib/app/galaxy_novels_app.dart galaxy_novels_app/test/widget_test.dart

---

### Task 4: Make Logout Local-First and Treat Expired Restores as Guest

**Files:**

- Modify: "galaxy_novels_app/lib/features/account/data/session_auth_repository.dart"
- Modify: "galaxy_novels_app/test/features/account/session_auth_repository_test.dart"
- Modify: "galaxy_novels_app/test/helpers/fake_auth_session_store.dart"

- [ ] **Step 1: Extend the fake store and add RED tests**

  Add "bool failClear = false" to FakeAuthSessionStore. clear must increment clearCount, throw AuthSessionStoreException when failClear is true, and otherwise clear the stored snapshot.

  Add these exact tests:

  - "logout becomes guest before the remote request completes"
  - "logout network failure cannot restore the authenticated session"
  - "logout storage cleanup failure remains guest with an error"
  - "restore rejects a locally expired snapshot without a network request"
  - "restore treats status 401 as an expired session"
  - "restore treats status 403 as an expired session"
  - "restore treats wor_reader_app_login_required as an expired session"

  The first logout test uses a Completer for the request sender, calls logout without awaiting its remote request, pumps a microtask, and expects:

      expect(repository.value.status, AuthSessionStatus.guest);
      expect(client.accessToken, isNull);
      expect(store.session, isNull);

  Then complete the remote response so the test leaves no pending Future.

  The local-expiry test stores a snapshot whose expiresAt is in the past and asserts the fake request list remains empty.

- [ ] **Step 2: Run the focused tests and confirm RED**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      flutter test test/features/account/session_auth_repository_test.dart --plain-name "logout becomes guest before the remote request completes"
      flutter test test/features/account/session_auth_repository_test.dart --plain-name "restore rejects a locally expired snapshot without a network request"

  Expected: logout remains signingOut while the request is pending; restore sends an expired token to the server.

- [ ] **Step 3: Reject an expired snapshot before import/network**

  Change _restore to read the store once and pass the value into:

      Future<AuthSessionPayload?> _loadServerSession(
        PrivateSessionSnapshot? storedSession,
      )

  Add:

      bool _isLocallyExpired(PrivateSessionSnapshot? snapshot) {
        final expiresAt = snapshot?.expiresAt;
        return expiresAt != null &&
          !expiresAt.toUtc().isAfter(DateTime.now().toUtc());
      }

  If expired, call _clearSessionAfterExpiry and return before importSessionSnapshot or getPublic.

  Add:

      bool _isExpiredSessionFailure(PrivateApiException error) {
        final code = error.code?.trim().toLowerCase();
        return error.statusCode == 401 ||
          error.statusCode == 403 ||
          code == 'wor_reader_app_login_required';
      }

  In restore's PrivateApiException catch, clear as expired and publish guest for those cases; keep the existing failure message for other API failures.

- [ ] **Step 4: Make logout publish guest without waiting for the network**

  Add a best-effort helper:

      Future<void> _revokeRemoteSessionBestEffort() async {
        try {
          await _client.postAuthenticated('auth/logout');
        } on PrivateApiException {
          // Local logout is authoritative.
        } on FormatException {
          // Local logout is authoritative.
        }
      }

  In logout:

  1. Publish signingOut.
  2. Call the helper and retain its Future before clearing the client. PrivateApiClient constructs the request and captures Authorization synchronously before its first await.
  3. Clear the client token and disable persistence.
  4. Clear the secure store and publish guest immediately.
  5. On AuthSessionStoreException, still publish guest with:

         تم تسجيل الخروج، لكن تعذر تنظيف الجلسة المحفوظة.

  6. Detach the already-safe remote Future with unawaited. Never publish authenticated from a logout error path.

- [ ] **Step 5: Run the complete auth repository tests**

      flutter test test/features/account/session_auth_repository_test.dart

  Expected: all existing and new auth tests pass, including remembered-session and refresh tests.

- [ ] **Step 6: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check
      git diff -- galaxy_novels_app/lib/features/account/data/session_auth_repository.dart galaxy_novels_app/test/features/account/session_auth_repository_test.dart galaxy_novels_app/test/helpers/fake_auth_session_store.dart

---

### Task 5: Isolate Reading History by Guest/User Scope and Serialize Writes

**Files:**

- Modify: "galaxy_novels_app/lib/data/repositories/reading_history_repository.dart"
- Modify: "galaxy_novels_app/lib/data/repositories/stored_reading_history_repository.dart"
- Modify: "galaxy_novels_app/lib/data/repositories/shared_preferences_reading_history_store.dart"
- Modify: "galaxy_novels_app/lib/features/history/data/account_reading_history_repository.dart"
- Modify: "galaxy_novels_app/test/data/reading_history_repository_test.dart"
- Create: "galaxy_novels_app/test/data/shared_preferences_reading_history_store_test.dart"
- Modify: "galaxy_novels_app/test/features/history/account_reading_history_repository_test.dart"

- [ ] **Step 1: Add scope and migration tests**

  Create shared_preferences_reading_history_store_test.dart with a map-backed fake SharedPreferencesAsync and these tests:

  - "stores guest and account history in isolated v2 keys"
  - "migrates reading_history.v1 only when the guest scope is read"
  - "does not expose legacy guest history through an account scope"

  Required key assertions:

      reading_history.v2.guest
      reading_history.v2.user.7

  A user-scope read must neither return nor remove legacy v1 data. The first guest read copies v1 to v2.guest and removes v1 only after the v2 write succeeds.

- [ ] **Step 2: Add concurrent-write tests**

  In reading_history_repository_test.dart add a blocking scoped store and:

  - "serializes concurrent records in the same scope without losing entries"
  - "a failed scoped write does not block the next record"
  - "mutations in different scopes do not block each other"

  Start two recordForScope calls before releasing the first write. After both finish, load the scope and assert that both novel IDs remain.

- [ ] **Step 3: Add account-isolation tests**

  Change the local fake in account_reading_history_repository_test.dart to implement the new scoped companion interface, backed by a map keyed by ReadingHistoryScope. Add:

  - "keeps guest and account local histories isolated"
  - "does not expose user A local history after switching to user B"
  - "record keeps the scope captured when the account changes mid-write"

  For the last test, block user A's write, switch auth to user B, release the write, and assert only user A's key contains the record.

- [ ] **Step 4: Run all new tests and confirm RED**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      flutter test test/data/shared_preferences_reading_history_store_test.dart
      flutter test test/data/reading_history_repository_test.dart
      flutter test test/features/history/account_reading_history_repository_test.dart

  Expected: scoped types/methods do not exist and current concurrent records lose an entry.

- [ ] **Step 5: Add explicit scope types without breaking screen-facing APIs**

  Keep ReadingHistoryRepository's existing parameterless load and record methods. Beside it, add:

      final class ReadingHistoryScope {
        const ReadingHistoryScope._(this.storageSuffix);

        static const guest = ReadingHistoryScope._('guest');

        factory ReadingHistoryScope.user(int userId) {
          if (userId <= 0) {
            throw ArgumentError.value(userId, 'userId', 'must be positive');
          }
          return ReadingHistoryScope._('user.' + userId.toString());
        }

        final String storageSuffix;

        @override
        bool operator ==(Object other) =>
          other is ReadingHistoryScope &&
          other.storageSuffix == storageSuffix;

        @override
        int get hashCode => storageSuffix.hashCode;
      }

      abstract class ScopedReadingHistoryRepository extends Listenable {
        Future<List<ReadingProgress>> loadForScope(
          ReadingHistoryScope scope,
        );

        Future<void> recordForScope(
          ReadingHistoryScope scope,
          ReadingProgress progress,
        );
      }

  Change ReadingHistoryStore to accept a scope on read/write. StoredReadingHistoryRepository implements both interfaces:

      Future<List<ReadingProgress>> load() =>
        loadForScope(ReadingHistoryScope.guest);

      Future<void> record(ReadingProgress progress) =>
        recordForScope(ReadingHistoryScope.guest, progress);

  This preserves GalaxyNovelsApp/AppDependencies and screen code while making AccountReadingHistoryRepository explicit.

- [ ] **Step 6: Implement v2 SharedPreferences keys and guest-only migration**

  Use:

      static const legacyKey = 'reading_history.v1';
      static const keyPrefix = 'reading_history.v2.';

      String _keyFor(ReadingHistoryScope scope) =>
        keyPrefix + scope.storageSuffix;

  Replace the single fallback string with a map keyed by the full preference key. Deduplicate guest migration with "Future<void>? _guestMigrationInFlight".

  Migration order:

  1. Only guest read invokes migration.
  2. If v2.guest already exists, remove obsolete v1 and keep v2.
  3. Otherwise read v1.
  4. If v1 exists, write it to v2.guest.
  5. Remove v1 only after the v2 write completes.
  6. Account reads never inspect/remove v1.

- [ ] **Step 7: Serialize read-modify-write per scope**

  Add:

      final Map<ReadingHistoryScope, Future<void>> _mutationQueues = {};

  Implement a private serializer whose returned Future exposes the current operation's error, while its stored tail swallows that error so the next operation can run:

      Future<void> _serializeMutation(
        ReadingHistoryScope scope,
        Future<void> Function() mutation,
      ) {
        final previous =
            _mutationQueues[scope] ?? Future<void>.value();
        final operation = previous.then<void>(
          (_) => mutation(),
          onError: (Object _, StackTrace __) => mutation(),
        );

        late final Future<void> tail;
        tail = operation.then<void>(
          (_) {},
          onError: (Object _, StackTrace __) {},
        ).whenComplete(() {
          if (identical(_mutationQueues[scope], tail)) {
            _mutationQueues.remove(scope);
          }
        });
        _mutationQueues[scope] = tail;
        return operation;
      }

  recordForScope validates the progress, then queues a private _recordNow(scope, progress) that loads, merges, writes, and notifies. Never use one global queue.

- [ ] **Step 8: Capture the account scope once per operation**

  Make AccountReadingHistoryRepository require ScopedReadingHistoryRepository as its local dependency while it still implements ReadingHistoryRepository for screens.

  Add:

      ReadingHistoryScope _scopeFor(int? userId) => userId == null
        ? ReadingHistoryScope.guest
        : ReadingHistoryScope.user(userId);

  In load:

  - Capture userId and scope before the first await.
  - Load only that scope.
  - After each await, compare with the current scope. If auth changed, return an empty list for the stale operation; the auth listener will trigger a fresh UI load.
  - For an authenticated, still-current user, merge only that user's local scope with that user's remote data.

  In record, capture the scope before awaiting and always write that captured scope.

- [ ] **Step 9: Run the complete history slice**

      flutter test test/data/shared_preferences_reading_history_store_test.dart
      flutter test test/data/reading_history_repository_test.dart
      flutter test test/features/history/account_reading_history_repository_test.dart

  Expected: migration, account switching, concurrent writes, write-failure recovery, and independent scopes all pass.

- [ ] **Step 10: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check
      git diff -- galaxy_novels_app/lib/data/repositories/reading_history_repository.dart galaxy_novels_app/lib/data/repositories/stored_reading_history_repository.dart galaxy_novels_app/lib/data/repositories/shared_preferences_reading_history_store.dart galaxy_novels_app/lib/features/history/data/account_reading_history_repository.dart galaxy_novels_app/test/data/reading_history_repository_test.dart galaxy_novels_app/test/data/shared_preferences_reading_history_store_test.dart galaxy_novels_app/test/features/history/account_reading_history_repository_test.dart

---

### Task 6: Guard VIP and Comment Composer Lifecycles

**Files:**

- Modify: "galaxy_novels_app/lib/features/vip/application/vip_chapters_controller.dart"
- Modify: "galaxy_novels_app/test/features/vip/vip_chapters_controller_test.dart"
- Modify: "galaxy_novels_app/lib/features/comments/presentation/widgets/comment_composer.dart"
- Modify: "galaxy_novels_app/test/features/comments/comments_surfaces_test.dart"

- [ ] **Step 1: Add the VIP late-response test**

  Add "ignores a late VIP response after dispose". Use Completer<VipChapterPage>, start loadInitial, dispose the controller, complete a valid empty page, and:

      await expectLater(pending, completes);

  Ensure the fake returns the completer Future and the test completes it even if an assertion fails.

- [ ] **Step 2: Run the VIP test and confirm RED**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      flutter test test/features/vip/vip_chapters_controller_test.dart --plain-name "ignores a late VIP response after dispose"

  Expected: a late write/notification occurs after disposal.

- [ ] **Step 3: Add disposal and request generations**

  Add:

      bool _disposed = false;
      int _requestGeneration = 0;

      bool _isActive(int generation) =>
        !_disposed && generation == _requestGeneration;

  loadInitial/retry/loadMore return immediately after dispose and pass a newly captured generation into _load. After every await and before every success/catch publication, return unless _isActive(generation).

  Override dispose idempotently: set disposed, increment generation, then call super.dispose.

- [ ] **Step 4: Add the composer-removal test**

  Add "does not complete composer callbacks after the composer is removed":

  - Use an authenticated repository/controller fixture.
  - Delay submitComment with a Completer<PublicComment>.
  - Enter text and tap the submit button.
  - Replace the tree with SizedBox.shrink.
  - Complete the comment Future and pump.
  - Assert tester.takeException is null and the onSubmitted flag is false.

- [ ] **Step 5: Run the composer test and confirm RED**

      flutter test test/features/comments/comments_surfaces_test.dart --plain-name "does not complete composer callbacks after the composer is removed"

  Expected: the current child closure touches a disposed TextEditingController/State or invokes the removed surface's callback.

- [ ] **Step 6: Move asynchronous completion into the owning State**

  Add _submit to _CommentComposerState:

      Future<void> _submit() async {
        final content = _textController.text;
        final parentId = widget.replyTarget?.id ?? 0;
        final isSpoiler = _isSpoiler;
        final outcome = await widget.controller.submitComment(
          content: content,
          parentId: parentId,
          isSpoiler: isSpoiler,
        );
        if (!mounted || outcome.status != CommentSubmitStatus.saved) {
          return;
        }
        _textController.clear();
        setState(() => _isSpoiler = false);
        widget.onSubmitted?.call();
      }

  _AuthenticatedComposer receives a required "Future<void> Function() onSubmit"; its button calls unawaited(onSubmit()). Remove its async method and any callback that clears the parent's controller.

- [ ] **Step 7: Run both lifecycle files**

      flutter test test/features/vip/vip_chapters_controller_test.dart
      flutter test test/features/comments/comments_surfaces_test.dart

- [ ] **Step 8: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check
      git diff -- galaxy_novels_app/lib/features/vip/application/vip_chapters_controller.dart galaxy_novels_app/test/features/vip/vip_chapters_controller_test.dart galaxy_novels_app/lib/features/comments/presentation/widgets/comment_composer.dart galaxy_novels_app/test/features/comments/comments_surfaces_test.dart

---

### Task 7: Separate Comment List Generations from Mutations

**Files:**

- Modify: "galaxy_novels_app/lib/features/comments/application/comments_controller.dart"
- Modify: "galaxy_novels_app/test/features/comments/comments_controller_test.dart"

- [ ] **Step 1: Add two controlled race tests**

  Add:

  - "changing sort keeps an in-flight submit busy"
  - "successful submit remains saved after changing sort"

  Use separate Completers for the submit and the new sorted first page.

  First test sequence:

  1. Load newest.
  2. Start a delayed submit.
  3. Start changeSort(top).
  4. Attempt a second submit.
  5. Assert the second result is busy and repository.submitCalls has length 1.

  Second test sequence:

  1. Start the same submit.
  2. Change to top and complete the top page.
  3. Complete submit with comment ID 99.
  4. Assert saved, sort remains top, ID 99 appears once, isSubmitting is false, and only one remote submit occurred.

  Complete every Completer in tearDown/finally so a RED assertion does not leave asynchronous work pending.

- [ ] **Step 2: Run each test and confirm the two distinct failures**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      flutter test test/features/comments/comments_controller_test.dart --plain-name "changing sort keeps an in-flight submit busy"
      flutter test test/features/comments/comments_controller_test.dart --plain-name "successful submit remains saved after changing sort"

  Expected:

  - changeSort reconstructs state with isSubmitting false, allowing duplicate submission.
  - successful server submission is reported as failed because the list generation changed.

- [ ] **Step 3: Reserve generations for list requests only**

  Rename:

      _generation -> _loadGeneration
      _isCurrent -> _isCurrentLoad

  Use them only in _loadFirst, _performFirst, loadMore, and _performLoadMore. Remove sort/generation capture and _isCurrent checks from submitComment, voteComment, and reactToTarget.

- [ ] **Step 4: Preserve independent flags in every state reconstruction**

  Audit every CommentsState creation in the controller. A list load must preserve:

      isSubmitting: _value.isSubmitting
      isInteracting: _value.isInteracting

  Mutation updates must preserve unrelated isLoadingMore/isSubmitting/isInteracting values. No list success/failure may silently unlock an in-flight mutation.

- [ ] **Step 5: Apply successful mutations to the current sorted state**

  After a submit/vote/reaction response:

  - Capture the currently active "_initialFuture".
  - If present, await that exact Future inside try/catch so its completion cannot erase the mutation.
  - If disposed, return failed without publishing.
  - Otherwise merge the result into the current state and return saved.

  Change failure helpers to check only disposal, not list generation/sort:

      void _finishFailedSubmit(String message) {
        if (_disposed) return;
        _publishSubmitFailure(message);
      }

      void _finishFailedInteraction(String message) {
        if (_disposed) return;
        _publishInteractionFailure(message);
      }

  Retain the existing one-submit and one-interaction busy guards. Use the existing ID-based merge helpers so a submitted comment cannot appear twice.

- [ ] **Step 6: Run controller and surface suites**

      flutter test test/features/comments/comments_controller_test.dart
      flutter test test/features/comments/comments_surfaces_test.dart

  Expected: existing paging, sort, authentication, vote, reaction, and new race tests all pass.

- [ ] **Step 7: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check
      git diff -- galaxy_novels_app/lib/features/comments/application/comments_controller.dart galaxy_novels_app/test/features/comments/comments_controller_test.dart

---

### Task 8: Add Public Network Timeouts and a Platform-Neutral User-Agent

**Files:**

- Modify: "galaxy_novels_app/lib/core/network/public_cache_client.dart"
- Modify: "galaxy_novels_app/lib/core/config/app_config.dart"
- Modify: "galaxy_novels_app/test/core/public_cache_client_test.dart"
- Modify: "galaxy_novels_app/test/core/app_config_test.dart"
- Modify: "galaxy_novels_app/test/core/private_api_client_test.dart"
- Modify: "galaxy_novels_app/test/data/public_reader_repository_test.dart"
- Modify: "galaxy_novels_app/test/features/account/session_auth_repository_test.dart"

- [ ] **Step 1: Add a hanging-network cache fallback test**

  Add "times out an injected JSON getter and falls back to cache":

  - Seed the fake cache under "https://example.com/slow.json".
  - Inject "requestTimeout: const Duration(milliseconds: 10)".
  - Make jsonGet return "Completer<Object?>().future".
  - Expect loadJson('/slow.json') to return the cached map.

- [ ] **Step 2: Run the timeout test and confirm RED**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      flutter test test/core/public_cache_client_test.dart --plain-name "times out an injected JSON getter and falls back to cache"

  Expected: requestTimeout is not accepted and the current request has no completion path.

- [ ] **Step 3: Add one timeout boundary to PublicCacheClient**

  Add constructor parameter/field:

      Duration requestTimeout = const Duration(seconds: 20)

  Wrap every injected getter Future with ".timeout(requestTimeout)" before cache write. Change the default getter to receive the duration and apply it to:

  - HttpClient.connectionTimeout
  - client.getUrl
  - request.close
  - response.transform(utf8.decoder).join

  Keep "client.close(force: true)" in finally. A TimeoutException must flow into loadJsonValue's cache fallback. If no valid cache exists, rethrow it.

  Narrow network/cache recovery catches from "on Object" to "on Exception" so programmer errors are not silently converted into cache hits.

- [ ] **Step 4: Verify timeout behavior**

      flutter test test/core/public_cache_client_test.dart

- [ ] **Step 5: Add and run the User-Agent RED test**

  Rename/update the config test to "uses a platform-neutral user agent by default" and expect:

      WorReaderApp/1.0

  Run:

      flutter test test/core/app_config_test.dart

  Expected before production edit: the default still ends with Android.

- [ ] **Step 6: Generalize the default and update all header expectations**

  Change only AppConfig's default string to "WorReaderApp/1.0"; retain constructor override support.

  Update exact expectations in:

  - app_config_test.dart
  - public_cache_client_test.dart
  - private_api_client_test.dart
  - public_reader_repository_test.dart
  - session_auth_repository_test.dart

  Confirm no stale assertion remains:

      rg -n "WorReaderApp/1\.0 Android" lib test

  Expected: no matches.

- [ ] **Step 7: Run all affected network/auth tests**

      flutter test test/core/app_config_test.dart test/core/public_cache_client_test.dart test/core/private_api_client_test.dart test/data/public_reader_repository_test.dart test/features/account/session_auth_repository_test.dart

- [ ] **Step 8: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check
      git diff -- galaxy_novels_app/lib/core/config/app_config.dart galaxy_novels_app/lib/core/network/public_cache_client.dart galaxy_novels_app/test/core galaxy_novels_app/test/data/public_reader_repository_test.dart galaxy_novels_app/test/features/account/session_auth_repository_test.dart

---

### Task 9: Recover Download Index Replacement After a Crash

**Files:**

- Modify: "galaxy_novels_app/lib/data/repositories/file_system_download_store.dart"
- Modify: "galaxy_novels_app/test/data/file_system_download_store_test.dart"

- [ ] **Step 1: Add three recovery tests**

  Add:

  - "restores a missing index from a valid next file"
  - "restores a missing index from a valid backup file"
  - "uses backup when next index is invalid"

  Create a valid store/index by calling writeChapters once, then manipulate only files inside the test's temporary root:

  - Rename index.json to index.json.next for the first test.
  - Rename index.json to index.json.bak for the second.
  - For the third, preserve valid JSON in .bak and write "{bad" to .next.

  Each read must return the original chapter and recreate index.json.

- [ ] **Step 2: Run the tests and confirm RED**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      flutter test test/data/file_system_download_store_test.dart --plain-name "restores a missing index from a valid next file"
      flutter test test/data/file_system_download_store_test.dart --plain-name "restores a missing index from a valid backup file"
      flutter test test/data/file_system_download_store_test.dart --plain-name "uses backup when next index is invalid"

  Expected: missing target triggers legacy migration/empty history and no recovery.

- [ ] **Step 3: Validate and recover index candidates**

  Add private helpers:

      Future<File?> _recoverIndexFile(Directory directory)
      Future<bool> _isValidIndex(File file)

  A valid candidate must decode to a map whose version equals 2 and whose chapters value is a List.

  Recovery algorithm:

  1. If index.json exists, use it.
  2. Otherwise validate index.json.next.
  3. If valid, rename it to index.json and use it.
  4. Otherwise validate index.json.bak.
  5. If valid, rename it to index.json and use it.
  6. Otherwise return null and allow the existing migration/empty path.

  Invoke recovery at the start of both readChapters and writeChapters, before legacy migration or orphan cleanup.

- [ ] **Step 4: Replace the index with target/next/bak semantics**

  Add:

      Future<void> _writeIndexAtomic(File target, String contents)

  Required order:

  1. Write target.path + ".next" with flush true.
  2. Remove a stale .bak only while the current target is still intact.
  3. Rename current target to .bak when present.
  4. Rename .next to target.
  5. If step 4 fails and target is missing, rename .bak back to target, then rethrow.
  6. After successful replacement, remove .bak best-effort; a cleanup failure after commit must not report that the write failed.
  7. Run orphan content deletion only after the new index is safely installed.

  Use this helper only for index.json. Existing chapter-content writes do not replace an existing target, so their simpler .next rename remains acceptable.

- [ ] **Step 5: Run the complete filesystem store suite**

      flutter test test/data/file_system_download_store_test.dart

- [ ] **Step 6: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check
      git diff -- galaxy_novels_app/lib/data/repositories/file_system_download_store.dart galaxy_novels_app/test/data/file_system_download_store_test.dart

---

### Task 10: Decode Catalog Covers at Finite Medium-Card Dimensions

**Files:**

- Modify: "galaxy_novels_app/lib/features/catalog/presentation/widgets/catalog_novel_tile.dart"
- Modify: "galaxy_novels_app/test/features/catalog/catalog_novel_tile_test.dart"

- [ ] **Step 1: Add the finite-cover test**

  Add "catalog tile uses the medium cover with finite decode dimensions". Build a CatalogNovel with:

      coverThumbnail: '/thumb.jpg'
      coverMedium: '/medium.jpg'
      coverLarge: '/large.jpg'

  Pump the tile inside the same finite grid-cell fixture used by current tests, read the NovelCover widget, and assert:

      expect(cover.imageUrl, '/medium.jpg');
      expect(cover.width.isFinite, isTrue);
      expect(cover.height.isFinite, isTrue);
      expect(cover.width, greaterThan(0));
      expect(cover.height, greaterThan(0));

- [ ] **Step 2: Run the test and confirm RED**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      flutter test test/features/catalog/catalog_novel_tile_test.dart --plain-name "catalog tile uses the medium cover with finite decode dimensions"

  Expected: the tile chooses bestCover/large and passes double.infinity dimensions.

- [ ] **Step 3: Choose a card-sized URL and derive finite dimensions**

  In CatalogNovelTile only, select in this order:

  1. coverMedium
  2. coverThumbnail
  3. coverLarge

  Wrap the cover area inside the existing Expanded with LayoutBuilder. Pass bounded finite maxWidth/maxHeight to NovelCover; if either constraint is unbounded/non-finite/non-positive, use NovelCover.posterWidth/posterHeight for that dimension.

  Keep StackFit.expand, status badge, semantics, and detail-screen cover behavior unchanged. Do not change CatalogNovel.bestCover or NovelCover.detail; large remains appropriate for details.

- [ ] **Step 4: Run catalog tile tests**

      flutter test test/features/catalog/catalog_novel_tile_test.dart

- [ ] **Step 5: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check
      git diff -- galaxy_novels_app/lib/features/catalog/presentation/widgets/catalog_novel_tile.dart galaxy_novels_app/test/features/catalog/catalog_novel_tile_test.dart

---

### Task 11: Cache Reader Parsing, Build Blocks Lazily, and Restore RTL Navigation

**Files:**

- Modify: "galaxy_novels_app/lib/features/reader/data/chapter_html_parser.dart"
- Modify: "galaxy_novels_app/lib/features/reader/presentation/native_reader_content.dart"
- Create: "galaxy_novels_app/test/features/reader/native_reader_content_test.dart"
- Modify: "galaxy_novels_app/test/features/reader/reader_screen_test.dart"

- [ ] **Step 1: Add parser injection and regression tests**

  Add this typedef to chapter_html_parser.dart:

      typedef ChapterHtmlParser =
        List<ChapterTextBlock> Function(String html);

  Write native_reader_content_test.dart with:

  - "does not parse chapter HTML again when controls toggle"
  - "builds chapter blocks lazily"

  First test:

  - Inject one parser function that increments a counter and returns a paragraph.
  - Pump NativeReaderContent and expect count 1.
  - Tap the "reader-content-tap-area", pump the controls animation, and still expect count 1.

  Second test:

  - Inject a parser result containing 200 uniquely named paragraphs.
  - Pump in a short viewport.
  - Assert paragraph 200 is not initially found.
  - Use scrollUntilVisible to reach it and then assert it is found.

- [ ] **Step 2: Run the reader-content tests and confirm RED**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      flutter test test/features/reader/native_reader_content_test.dart

  Expected: the widget has no parser seam and currently constructs every block in ListView.children.

- [ ] **Step 3: Cache parsed blocks in State**

  Add an optional widget field:

      final ChapterHtmlParser htmlParser;

  with constructor default "parseChapterHtml".

  State owns:

      late List<ChapterTextBlock> _blocks;

  Parse in initState. In didUpdateWidget, recompute only when contentHtml changed or the parser function changed. Existing chapter-ID handling still resets controls and scroll position; a controls toggle must never parse.

- [ ] **Step 4: Replace eager children with ListView.builder**

  Compute:

      final headerCount =
        content.effectiveTitle.isEmpty ? 0 : 2;
      final itemCount = headerCount + _blocks.length;

  itemBuilder returns the title at index 0, the 18px spacer at index 1, and the corresponding block afterward. Preserve all text styles, paddings, scroll controller, keys, gestures, and bottom space.

- [ ] **Step 5: Change the existing RTL navigation expectation to the product contract**

  Rename the reader-screen test to:

      floating controls place previous on the right and next on left

  Assert:

      expect(previousCenter.dx, greaterThan(nextCenter.dx));

  and icons:

      previous -> Icons.chevron_right_rounded
      next -> Icons.chevron_left_rounded

  Run it now and confirm RED if the current user edit still places next on the right:

      flutter test test/features/reader/reader_screen_test.dart --plain-name "floating controls place previous on the right and next on left"

- [ ] **Step 6: Make compact and wide controls consistent**

  In an RTL Row, put the previous control first so it renders on the right, and the next control last/second so it renders on the left:

  - previous: right chevron, onPrevious
  - next: left chevron, onNext

  Apply the same mapping to compact and wide layouts. Do not swap callbacks/tooltips; only restore consistent placement/icon direction.

- [ ] **Step 7: Run the reader suites**

      flutter test test/features/reader/native_reader_content_test.dart
      flutter test test/features/reader/reader_screen_test.dart

  Expected: parser count remains 1 on control toggles, distant blocks are lazy, and RTL button geometry/icons match.

- [ ] **Step 8: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check
      git diff -- galaxy_novels_app/lib/features/reader/data/chapter_html_parser.dart galaxy_novels_app/lib/features/reader/presentation/native_reader_content.dart galaxy_novels_app/test/features/reader/native_reader_content_test.dart galaxy_novels_app/test/features/reader/reader_screen_test.dart

---

### Task 12: Align Documentation and Run the Complete Acceptance Gate

**Files:**

- Modify: "galaxy_novels_app/docs/manual_test_plan.md"
- Modify: "galaxy_novels_app/docs/app_api_gap_audit.md"
- Modify: "galaxy_novels_app/README.md"
- Verify: every implementation/test file named in Tasks 1-11

- [ ] **Step 1: Correct the Latest Updates contract in both documents**

  Use this exact meaning in the manual plan and API audit:

      الضغط على بطاقة «آخر التحديثات» يفتح صفحة تفاصيل الرواية، ولا يفتح الفصل مباشرة.

  Remove any stale claim that these cards open a chapter directly. Do not alter the existing navigation implementation or its passing widget test.

- [ ] **Step 2: Document platform/release limits**

  In README:

  - State that iOS ads are temporarily disabled and no ads SDK initialization/request occurs there.
  - State that Android Release requires a valid production keystore.
  - State that "ALLOW_DEBUG_SIGNING_IN_RELEASE=true" is for explicit local verification only and must not be used for a published artifact.
  - Remove/qualify any claim that iOS advertising is production-ready.

- [ ] **Step 3: Search documentation and code for stale contracts**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      rg -n "آخر التحديثات|يفتح الفصل مباشرة|iOS|ALLOW_DEBUG_SIGNING_IN_RELEASE" README.md docs
      rg -n "ALLOW_TEST_ADS_IN_RELEASE|WorReaderApp/1\.0 Android" .

  Expected:

  - Latest Updates documentation says details.
  - iOS status and release signing escape hatch are explicit.
  - No ALLOW_TEST_ADS_IN_RELEASE or Android-only User-Agent remains.

- [ ] **Step 4: Run formatting only on files changed by this implementation**

  Use dart format with an explicit path list; never format the repository wholesale. Include only changed Dart files from Tasks 2-11.

      dart format <explicit changed Dart paths>
      git diff --check

- [ ] **Step 5: Run focused aggregate suites**

      flutter test test/features/ads
      flutter test test/features/account/session_auth_repository_test.dart
      flutter test test/data/shared_preferences_reading_history_store_test.dart test/data/reading_history_repository_test.dart test/features/history/account_reading_history_repository_test.dart
      flutter test test/features/vip/vip_chapters_controller_test.dart
      flutter test test/features/comments/comments_controller_test.dart test/features/comments/comments_surfaces_test.dart
      flutter test test/core/app_config_test.dart test/core/public_cache_client_test.dart test/core/private_api_client_test.dart
      flutter test test/data/file_system_download_store_test.dart test/features/catalog/catalog_novel_tile_test.dart
      flutter test test/features/reader/native_reader_content_test.dart test/features/reader/reader_screen_test.dart
      flutter test test/widget_test.dart

  Expected: every focused group passes without pending timers or unhandled asynchronous errors.

- [ ] **Step 6: Run the full Flutter acceptance gate**

      dart analyze
      flutter test
      flutter build apk --debug --no-pub

  Expected:

  - analysis has no issues.
  - all tests pass; the previous 18 timer failures are gone.
  - Android debug APK builds successfully.

- [ ] **Step 7: Run the final Android signing gate**

      Set-Location .\android
      $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
      .\gradlew.bat signingReport --console=plain
      .\gradlew.bat build --dry-run --console=plain
      .\gradlew.bat assembleDebug --dry-run --console=plain

  Expected:

  - release is not debug-signed by default.
  - build dry-run fails only because release production signing is intentionally absent.
  - assembleDebug dry-run succeeds.

- [ ] **Step 8: Review the final diff against the approved design**

  From the repository root:

      Set-Location D:\Galaxy Novels
      git status --short
      git diff --check
      git diff --stat

  Review each changed hunk and confirm:

  - no unrelated user edit was removed;
  - no iOS ad initialization remains;
  - no release signing silently falls back to debug;
  - guest/user history keys are isolated;
  - list generations do not invalidate comment mutations;
  - latest updates still opens novel details.

  Because the implementation overlaps a dirty user worktree, do not stage or commit the combined code automatically. Hand the verified diff back to the user for their preferred commit boundary.
