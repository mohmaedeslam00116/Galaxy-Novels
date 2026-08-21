# Bulk Download Entry and Chapter Status Implementation Plan

> **For agentic workers:** Execute inline in this session. Do not use subagents; the user explicitly prohibited them. Track every checkbox and preserve unrelated worktree changes.

**Goal:** Add a visible multi-chapter download entry to the novel details page and make every chapter download action reflect the live repository state.

**Architecture:** Keep `DownloadRepository.value` as the single source of truth. A focused presentation resolver maps a chapter key plus `DownloadsDashboard` to one of four UI states; the details preview and full chapter list listen to the repository and pass that state into the stateless chapter tile. The existing full-list selection flow remains responsible for building bulk requests.

**Tech Stack:** Flutter 3.41.7, Dart 3.11.5, Material 3, `ValueListenableBuilder`, `flutter_test`.

## Global Constraints

- Android remains the target platform for downloads.
- Do not add dependencies or a second download state store.
- The bulk button must be inside the novel details chapter section, above search and ordering controls.
- Bulk download means manual chapter selection, not downloading the whole novel in one tap.
- Chapter states are available, pending, downloaded, and failed; icon and Arabic semantics must both change.
- Keep interactive targets at least 44×44 and support 320px width with 200% text.
- Do not use subagents.

---

### Task 1: Resolve live chapter download state

**Files:**
- Create: `lib/features/novel_details/presentation/chapter_download_state.dart`
- Create: `test/features/novel_details/chapter_download_state_test.dart`

**Interfaces:**
- Consumes: `DownloadsDashboard`, `DownloadJobStatus`, and `chapterKey`.
- Produces: `ChapterDownloadState resolveChapterDownloadState(DownloadsDashboard dashboard, String chapterKey)` with optional `retryJobId`.

- [ ] **Step 1: Write the failing resolver tests**

Cover precedence and terminal behavior with real domain objects:

```dart
test('downloaded chapter wins over historical jobs', () {
  expect(
    resolveChapterDownloadState(
      _dashboardWith(downloaded: true, jobStatus: DownloadJobStatus.failed),
      'public:71',
    ).status,
    ChapterDownloadStatus.downloaded,
  );
});

test('active jobs are pending and failed jobs expose their retry id', () {
  final pending = resolveChapterDownloadState(
    _dashboardWith(jobStatus: DownloadJobStatus.transferring),
    'public:71',
  );
  final failed = resolveChapterDownloadState(
    _dashboardWith(jobStatus: DownloadJobStatus.failed),
    'public:71',
  );

  expect(pending.status, ChapterDownloadStatus.pending);
  expect(failed.status, ChapterDownloadStatus.failed);
  expect(failed.retryJobId, 'job-71');
});
```

Define `_dashboardWith({bool downloaded = false, DownloadJobStatus? jobStatus})` in the same test file using the real `DownloadsDashboard`, `DownloadedNovel`, `DownloadedChapter`, `DownloadGroup`, and `DownloadJob` constructors. Use `chapterKey: 'public:71'` and `jobId: 'job-71'`; leave `groups` or `novels` empty when their corresponding argument is absent.

- [ ] **Step 2: Run the resolver test and verify RED**

Run:

```powershell
flutter test test/features/novel_details/chapter_download_state_test.dart
```

Expected: compilation failure because the resolver file and types do not exist.

- [ ] **Step 3: Implement the minimal resolver**

Define:

```dart
enum ChapterDownloadStatus { available, pending, downloaded, failed }

class ChapterDownloadState {
  const ChapterDownloadState(this.status, {this.retryJobId});

  final ChapterDownloadStatus status;
  final String? retryJobId;
}
```

Resolve in this order: a matching `DownloadedChapter`, a matching nonterminal job, a matching failed job, then available. Treat `queued`, `reserved`, `transferring`, `processing`, and `paused` as pending. Ignore canceled jobs. A completed database job is downloaded only when the chapter also exists in `dashboard.novels`, so a missing file never receives a false success state.

- [ ] **Step 4: Run the resolver test and verify GREEN**

Run:

```powershell
flutter test test/features/novel_details/chapter_download_state_test.dart
```

Expected: all resolver tests pass.

- [ ] **Step 5: Commit Task 1**

```powershell
git add lib/features/novel_details/presentation/chapter_download_state.dart test/features/novel_details/chapter_download_state_test.dart
git commit -m "feat(downloads): resolve chapter download presentation state"
```

---

### Task 2: Render chapter action states

**Files:**
- Modify: `lib/features/novel_details/presentation/widgets/readable_chapter_tile.dart`
- Modify: `test/features/novel_details/chapter_download_action_test.dart`

**Interfaces:**
- Consumes: `ChapterDownloadState`, `onDownload`, and `onRetryDownload`.
- Produces: one 44×44 action whose icon, tooltip, semantics, and enabled state match the repository.

- [ ] **Step 1: Write failing widget tests for the four states**

Pump the tile with each state and assert:

```dart
expect(find.byIcon(Icons.download_rounded), findsOneWidget);
expect(find.byTooltip('تنزيل الفصل'), findsOneWidget);

expect(find.byType(CircularProgressIndicator), findsOneWidget);
expect(find.bySemanticsLabel('الفصل قيد التنزيل'), findsOneWidget);

expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
expect(find.byTooltip('تم تنزيل الفصل'), findsOneWidget);

expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
expect(find.byTooltip('إعادة محاولة تنزيل الفصل'), findsOneWidget);
```

Also tap available and failed actions to prove they call separate callbacks, and verify tapping the downloaded action cannot enqueue again.

- [ ] **Step 2: Run the tile test and verify RED**

Run:

```powershell
flutter test test/features/novel_details/chapter_download_action_test.dart
```

Expected: compilation failure because `ReadableChapterTile` does not accept `downloadState` or `onRetryDownload`.

- [ ] **Step 3: Implement the compact stateful action rendering**

Add inputs:

```dart
final ChapterDownloadState downloadState;
final VoidCallback? onRetryDownload;
```

Keep selection mode unchanged. Outside selection mode render:

- available: enabled `Icons.download_rounded` using the existing key;
- pending: a noninteractive 20px `CircularProgressIndicator` with Arabic semantics;
- downloaded: disabled `Icons.download_done_rounded` with tooltip `تم تنزيل الفصل`;
- failed: enabled `Icons.refresh_rounded` wired only to `onRetryDownload`.

Use `SizedBox.square(dimension: 48)` around the pending and downloaded states so row geometry does not jump.

- [ ] **Step 4: Run the tile test and verify GREEN**

Run:

```powershell
flutter test test/features/novel_details/chapter_download_action_test.dart
```

Expected: all tile action tests pass.

- [ ] **Step 5: Commit Task 2**

```powershell
git add lib/features/novel_details/presentation/widgets/readable_chapter_tile.dart test/features/novel_details/chapter_download_action_test.dart
git commit -m "feat(downloads): show live chapter action states"
```

---

### Task 3: Wire the details page and direct bulk-selection entry

**Files:**
- Modify: `lib/features/novel_details/presentation/widgets/novel_chapters_section.dart`
- Modify: `lib/features/novel_details/presentation/all_chapters_screen.dart`
- Modify: `test/features/novel_details/novel_details_chapter_list_test.dart`

**Interfaces:**
- Consumes: `AppDependencies.of(context).downloadRepository` and the Task 1 resolver.
- Produces: `AllChaptersScreen.selecting(...)` from a visible details-page button and live state updates in both chapter lists.

- [ ] **Step 1: Write failing details integration tests**

Use a mutable fake `DownloadRepository` implementing `ChangeNotifier`. Assert:

```dart
expect(find.byKey(const ValueKey('novel-details-bulk-download')), findsOneWidget);
await tester.tap(find.byKey(const ValueKey('novel-details-bulk-download')));
await tester.pumpAndSettle();
expect(find.text('اختر الفصول'), findsOneWidget);
expect(find.byKey(const ValueKey('chapters-download-selected')), findsOneWidget);
```

Then publish a dashboard containing `public:1` in `DownloadedNovel.chapters`, call `notifyListeners()`, pump, and expect `Icons.download_done_rounded`. Publish a transferring job and expect a progress indicator; publish a failed job, tap refresh, and expect `retryJob('job-1')`.

- [ ] **Step 2: Run the details test and verify RED**

Run:

```powershell
flutter test test/features/novel_details/novel_details_chapter_list_test.dart
```

Expected: failure because the bulk key is absent and chapter rows do not listen to the download repository.

- [ ] **Step 3: Add the details-page bulk button**

Place an `OutlinedButton.icon` immediately before `_ChapterDiscoveryControls`:

```dart
OutlinedButton.icon(
  key: const ValueKey('novel-details-bulk-download'),
  onPressed: _openAllChaptersForSelection,
  icon: const Icon(Icons.download_for_offline_outlined),
  label: const Text('تنزيل عدة فصول'),
)
```

Keep its minimum height at 48 and use `NovelDetailsVisualTokens` for border and foreground colors.

- [ ] **Step 4: Let the full list start in selection mode**

Add a named constructor to `AllChaptersScreen`:

```dart
const AllChaptersScreen.selecting({
  required this.result,
  required this.vipController,
  required this.canReadPrivate,
  required this.isVipDirectContentRouteAvailable,
  super.key,
}) : _startsSelecting = true;
```

Keep the default constructor with `_startsSelecting = false`, and set `_selectionMode = widget._startsSelecting` in `initState`. The existing toolbar entry still toggles selection normally.

- [ ] **Step 5: Subscribe both lists to repository state**

Wrap the relevant chapter list builders with:

```dart
ValueListenableBuilder<DownloadsDashboard>(
  valueListenable: AppDependencies.of(context).downloadRepository,
  builder: (context, dashboard, child) => _PreviewChapterSliverList(
    result: widget.result,
    chapters: previewChapters,
    dashboard: dashboard,
    isVipDirectContentRouteAvailable:
        widget.isVipDirectContentRouteAvailable,
    onRead: widget.onRead,
    onOpenVipChapter: widget.onOpenVipChapter,
  ),
)
```

Add a required `DownloadsDashboard dashboard` field to `_PreviewChapterSliverList`. In `AllChaptersScreen`, wrap the existing `ValueListenableBuilder<VipChaptersState>` with another `ValueListenableBuilder<DownloadsDashboard>` from the same repository. For each chapter pass `resolveChapterDownloadState(dashboard, chapterDownloadKey(chapter))`. Available taps call the existing enqueue flow. Failed taps call `downloadRepository.retryJob(retryJobId)` and surface `تعذر إعادة محاولة التنزيل الآن.` only when `DownloadUnavailableException` occurs.

- [ ] **Step 6: Run focused tests and verify GREEN**

Run:

```powershell
flutter test test/features/novel_details/chapter_download_state_test.dart test/features/novel_details/chapter_download_action_test.dart test/features/novel_details/novel_details_chapter_list_test.dart
```

Expected: all tests pass with no overflow exceptions.

- [ ] **Step 7: Run regression and static checks**

Run:

```powershell
dart format lib/features/novel_details test/features/novel_details
flutter analyze
flutter test
flutter build apk --debug
```

Expected: formatting makes no further changes, analyze reports no issues, the full suite passes, and the debug APK builds.

- [ ] **Step 8: Verify on the connected Android phone**

Install with `adb install -r`, open a novel details page, and confirm:

1. «تنزيل عدة فصول» is visible above chapter search.
2. It opens the full list with selection active.
3. A selected chapter moves from pending to a check without leaving the page.
4. Reopening details retains the check from SQLite.
5. Downloaded chapters cannot be enqueued again.

- [ ] **Step 9: Commit Task 3**

```powershell
git add lib/features/novel_details/presentation/widgets/novel_chapters_section.dart lib/features/novel_details/presentation/all_chapters_screen.dart test/features/novel_details/novel_details_chapter_list_test.dart
git commit -m "feat(downloads): add bulk entry and sync chapter states"
```
