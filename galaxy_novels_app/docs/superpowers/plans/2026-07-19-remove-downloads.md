# Legacy Downloads Removal Implementation Plan

> **For agentic workers:** Execute this plan inline in the current session. The user explicitly prohibited subagents.

**Goal:** Remove the current downloads implementation and every active product surface that depends on it while preserving unrelated work and previously stored device data.

**Architecture:** The app returns to a network/cache-backed reader flow through `ReaderRepository`; no downloads repository, manager, overlay, route, or native Android service remains. Reward points and rewarded ads are removed because their only production consumer is the legacy downloads system; ordinary reader ads remain intact.

**Tech Stack:** Flutter/Dart, widget tests, Kotlin Android host code, Gradle, Markdown documentation.

## Global Constraints

- Do not use subagents.
- Do not delete or migrate downloads already stored on user devices.
- Preserve all unrelated uncommitted workspace changes.
- Keep `path_provider` and `shared_preferences` while independent consumers remain.
- Keep ordinary reader advertising; remove only rewarded advertising used by downloads.
- Do not treat the Arabic word «تحميل» as a downloads reference when it means loading remote content.

---

### Task 1: Lock the removed product behavior with failing tests

**Files:**

- Modify: `test/features/shell/app_drawer_test.dart`
- Modify: `test/features/account/account_shortcuts_test.dart`
- Modify: `test/features/catalog/catalog_discovery_test.dart`
- Modify: `test/features/novel_details/novel_details_chapter_list_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**

- Consumes: existing widget-test pumps and fake repositories.
- Produces: regression assertions that the downloads destination and chapter download actions do not exist.

- [ ] **Step 1: Replace legacy-positive assertions with removal assertions**

```dart
expect(find.text('التنزيلات'), findsNothing);
expect(find.byKey(const ValueKey('drawer-destination-downloads')), findsNothing);
expect(find.byKey(const ValueKey('catalog-open-downloads')), findsNothing);
expect(find.byTooltip('تحميل الفصل'), findsNothing);
expect(find.byKey(const ValueKey('novel-details-download-action')), findsNothing);
```

- [ ] **Step 2: Run focused tests and verify RED**

Run:

```powershell
flutter test test/features/shell/app_drawer_test.dart test/features/account/account_shortcuts_test.dart test/features/catalog/catalog_discovery_test.dart test/features/novel_details/novel_details_chapter_list_test.dart
```

Expected: at least one assertion fails because the current UI still exposes downloads.

### Task 2: Remove downloads from shared UI surfaces and the reader

**Files:**

- Modify: `lib/features/shell/presentation/app_drawer.dart`
- Modify: `lib/features/catalog/presentation/catalog_screen.dart`
- Modify: `lib/features/account/presentation/account_screen.dart`
- Modify: `lib/features/account/presentation/widgets/account_session_view.dart`
- Modify: `lib/features/account/presentation/widgets/account_shortcuts.dart`
- Modify: `lib/features/account/presentation/widgets/signed_in_account_view.dart`
- Modify: `lib/features/novel_details/presentation/novel_details_screen.dart`
- Modify: `lib/features/novel_details/presentation/all_chapters_screen.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_chapters_section.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_details_content.dart`
- Modify: `lib/features/reader/presentation/reader_screen.dart`

**Interfaces:**

- Consumes: `ReaderRepository.loadChapter(String contentApi)` and existing navigation callbacks.
- Produces: UI with no downloads destination/action; `_loadChapter` reads from `ReaderRepository` only.

- [ ] **Step 1: Remove downloads routes and callback plumbing**

Delete the `_DrawerDestination.downloads` branch, catalog/account `onOpenDownloads` parameters, shortcut cards, screen imports, and navigation methods. Keep the remaining destinations in their current order.

- [ ] **Step 2: Remove chapter download actions**

Delete `onDownloadChapters`, `ChapterDownloadButton`, sheet-opening methods, manager/repository state builders, and download-specific exception messages. Chapter rows retain only their reading/navigation action.

- [ ] **Step 3: Simplify reader loading**

Use the existing remote repository directly:

```dart
Future<ReaderChapterContent> _loadChapter(String contentApi) async {
  final repository = _repository;
  if (repository == null) {
    throw StateError('Reader repository is not ready.');
  }
  final content = await repository.loadChapter(contentApi);
  await _completeChapterLoad(content, contentApi);
  return content;
}
```

- [ ] **Step 4: Re-run focused widget tests and verify GREEN**

Run the Task 1 command. Expected: PASS after test fixtures no longer inject removed dependencies.

### Task 3: Remove downloads and reward infrastructure from application composition

**Files:**

- Modify: `lib/app/app_dependencies.dart`
- Modify: `lib/app/galaxy_novels_app.dart`
- Delete: `lib/data/models/downloaded_chapter.dart`
- Delete: `lib/data/repositories/downloads_repository.dart`
- Delete: `lib/data/repositories/fake_downloads_repository.dart`
- Delete: `lib/data/repositories/file_system_download_store.dart`
- Delete: `lib/data/repositories/local_download_store.dart`
- Delete: `lib/data/repositories/shared_preferences_download_store.dart`
- Delete: `lib/data/repositories/stored_downloads_repository.dart`
- Delete: `lib/features/downloads/`
- Delete: `lib/features/rewards/application/reader_rewards_repository.dart`
- Delete: `lib/features/rewards/data/stored_reader_rewards_repository.dart`
- Delete: `lib/features/ads/application/rewarded_ad_repository.dart`
- Delete: `lib/features/ads/data/admob_rewarded_ad_repository.dart`

**Interfaces:**

- Consumes: remaining repositories already required by `AppDependencies`.
- Produces: `AppDependencies` and `GalaxyNovelsApp` constructors without downloads, download progress, reader rewards, or rewarded-ad arguments.

- [ ] **Step 1: Remove dependency fields and lifecycle code**

Delete downloads/rewarded imports, constructor parameters, fields, equality checks, default repositories, manager factories, notifier setup, load/dispose calls, and the `DownloadActivityLayer` wrapper.

- [ ] **Step 2: Delete standalone legacy implementation files**

Delete only the files/directories listed above. Do not delete public cache storage or reader ads.

- [ ] **Step 3: Update all test fixtures that construct app dependencies**

Remove arguments such as:

```dart
downloadsRepository: FakeDownloadsRepository(),
downloadManager: DownloadManager(repository: downloadsRepository),
downloadProgressNotifier: notifier,
readerRewardsRepository: rewards,
rewardedAdRepository: rewardedAds,
```

- [ ] **Step 4: Run analyzer to expose every stale reference**

Run:

```powershell
flutter analyze
```

Expected: no errors referencing deleted downloads/rewards types after all consumers are updated.

### Task 4: Remove Android native downloads support

**Files:**

- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/src/main/kotlin/com/galaxynovels/app/MainActivity.kt`
- Delete: `android/app/src/main/kotlin/com/galaxynovels/app/DownloadForegroundService.kt`
- Delete: `android/app/src/main/res/drawable/ic_download_notification.xml`

**Interfaces:**

- Consumes: the independent `galaxy_novels/reader_display` method channel.
- Produces: `MainActivity` containing only reader-display native integration.

- [ ] **Step 1: Remove downloads channel and helpers from `MainActivity`**

Keep `configureFlutterEngine` and the reader-display method channel. Remove notification permission checks, download service intents, argument helpers used only by downloads, and related imports.

- [ ] **Step 2: Remove service and permissions from the manifest**

Delete `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, and the `DownloadForegroundService` declaration. Preserve `INTERNET` and all unrelated application metadata.

- [ ] **Step 3: Delete the native service and icon**

Delete the two files listed above and run:

```powershell
flutter build apk --debug
```

Expected: Android debug APK builds without the removed service or drawable.

### Task 5: Remove obsolete tests/docs and verify the repository

**Files:**

- Delete: `test/data/downloaded_chapter_test.dart`
- Delete: `test/data/fake_downloads_repository_test.dart`
- Delete: `test/data/file_system_download_store_test.dart`
- Delete: `test/data/stored_downloads_repository_test.dart`
- Delete: `test/features/downloads/`
- Delete: `test/features/rewards/reader_rewards_repository_test.dart`
- Modify: all remaining test fixtures returned by the stale-symbol scan.
- Delete: `docs/superpowers/specs/2026-06-20-galaxy-novels-downloads-design.md`
- Delete: `docs/superpowers/plans/2026-06-20-galaxy-novels-downloads.md`
- Modify: `docs/manual_test_plan.md`
- Modify: `docs/app_api_gap_audit.md`
- Modify: `docs/updated_template_app_api_inventory.md`
- Modify: `README.md` if it advertises downloads.

**Interfaces:**

- Consumes: the final production tree.
- Produces: documentation and tests describing the app without the legacy feature.

- [ ] **Step 1: Delete tests whose subject no longer exists**

Remove only legacy downloads/reward tests. In shared test files, preserve unrelated coverage and remove stale imports, fixtures, and cases.

- [ ] **Step 2: Update current documentation**

Remove manual download scenarios and active implementation claims. Preserve API facts and uses of «تحميل» that mean network loading. Delete the two dedicated historical feature documents because the approved scope explicitly requests their removal.

- [ ] **Step 3: Search for stale active references**

Run:

```powershell
rg -n -i -g '*.dart' -g '*.kt' -g '*.xml' -g '*.yaml' 'DownloadsRepository|DownloadManager|DownloadedChapter|DownloadsScreen|DownloadForegroundService|readerRewards|RewardedAd|تنزيلات|تحميل الفصول' lib test android pubspec.yaml
```

Expected: no active feature-symbol or UI-label matches. Manually classify generic loading/download wording in errors and non-code docs before changing it.

- [ ] **Step 4: Format and run verification**

Run:

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
git diff --check
```

Expected: formatting completes, analyzer and tests pass, Android debug build succeeds, and `git diff --check` reports no whitespace errors.

- [ ] **Step 5: Review final diff without staging unrelated work**

Use `git diff --stat`, `git diff --name-status`, and focused diffs for every shared file. Confirm that unrelated pre-existing changes remain present and that the plan/design documents are the only task documentation additions.
