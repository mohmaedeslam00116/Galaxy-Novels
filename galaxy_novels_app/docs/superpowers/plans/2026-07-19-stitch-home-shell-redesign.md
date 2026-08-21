# Stitch Home and Shell Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the home screen and adaptive shell from Stitch `_3`, add the Reader Journey destination, and preserve all supported data and navigation behavior without restoring downloads.

**Architecture:** Keep `AdaptiveAppShell` as the owner of responsive navigation and retained destination state, but replace its destination contract and extract the Stitch top bar. Keep `HomeScreen` as the data coordinator while moving each visual home section into a focused widget. Reuse existing repositories and models; derive the two latest chapter rows from `ChapterSummary.visibleChapters`.

**Tech Stack:** Flutter, Dart, Material 3, `flutter_test`, existing repository interfaces, golden tests.

## Global Constraints

- Execute inline in the current session; the user explicitly prohibited subagents.
- Use the five destinations in this order: الرئيسية، المكتبة، رحلة القارئ، الترتيب، حسابي.
- Keep favorites accessible from the existing drawer.
- Reader Journey opens the existing history screen and shows Downloads disabled with `قريبًا`.
- Show Notifications disabled; do not create notification state or a notification screen.
- Do not restore or import any removed download file, repository, service, or screen.
- Remove the editor choice and embedded rankings sections from Home.
- Keep Home order: أكمل القراءة، روايات محدثة، آخر تحديثات الروايات.
- Keep both list and grid modes for latest updates.
- Use Stitch dark colors only in dark mode; use semantic `ColorScheme` roles in light mode.
- Do not copy Stitch demo image URLs or implement the decorative particle effect.
- Support widths 320/600/840, short landscape, 200% text, RTL, and 44×44 minimum active targets.
- Preserve unrelated dirty-worktree changes. Do not stage an overlapping file unless its full diff is known to belong to this task; skip task commits when isolation is unsafe.

---

### Task 1: Lock the new destination contract and Reader Journey behavior

**Files:**
- Modify: `lib/features/shell/presentation/shell_destination.dart`
- Modify: `lib/features/shell/presentation/app_shell.dart`
- Create: `lib/features/reader_journey/presentation/reader_journey_screen.dart`
- Modify: `test/features/shell/adaptive_app_shell_test.dart`
- Create: `test/features/reader_journey/reader_journey_screen_test.dart`

**Interfaces:**
- Produces: `ShellDestination.readerJourney`, `ShellDestination.rankings`.
- Produces: `ReaderJourneyScreen({required VoidCallback onOpenHistory})`.
- Consumes: existing `HistoryScreen`, `RankingsScreen`, `CatalogScreen`, `AccountScreen`.

- [ ] **Step 1: Change the destination test first**

Replace the expected destination tuples in `adaptive_app_shell_test.dart` with:

```dart
expect(
  ShellDestination.values.map(
    (destination) => (
      destination.name,
      destination.label,
      destination.icon,
      destination.selectedIcon,
    ),
  ),
  const [
    ('home', 'الرئيسية', Icons.home_outlined, Icons.home),
    (
      'library',
      'المكتبة',
      Icons.local_library_outlined,
      Icons.local_library,
    ),
    (
      'readerJourney',
      'رحلة القارئ',
      Icons.auto_stories_outlined,
      Icons.auto_stories,
    ),
    ('rankings', 'الترتيب', Icons.bar_chart_outlined, Icons.bar_chart),
    ('account', 'حسابي', Icons.person_outline, Icons.person),
  ],
);
```

Update `_finalLabels`, builder counters, state-preservation cases, and the real `AppShell` navigation loop to use `readerJourney` and `rankings` instead of `favorites` and `history`.

- [ ] **Step 2: Add failing Reader Journey widget tests**

Create `reader_journey_screen_test.dart` with the project test harness and these observable assertions:

```dart
testWidgets('reader journey opens history and keeps downloads unavailable', (
  tester,
) async {
  var historyOpenCount = 0;
  await tester.pumpWidget(
    MaterialApp(
      home: ReaderJourneyScreen(
        onOpenHistory: () => historyOpenCount += 1,
      ),
    ),
  );

  final historyAction = find.byKey(
    const ValueKey('reader-journey-history'),
  );
  final downloadsAction = find.byKey(
    const ValueKey('reader-journey-downloads'),
  );
  expect(historyAction, findsOneWidget);
  expect(downloadsAction, findsOneWidget);
  expect(find.text('قريبًا'), findsOneWidget);

  await tester.tap(historyAction);
  await tester.pump();
  expect(historyOpenCount, 1);

  final downloadsButton = tester.widget<FilledButton>(
    find.descendant(of: downloadsAction, matching: find.byType(FilledButton)),
  );
  expect(downloadsButton.onPressed, isNull);
});

testWidgets('reader journey fits 320 pixels at 200 percent text', (
  tester,
) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    MaterialApp(
      home: ReaderJourneyScreen(onOpenHistory: () {}),
    ),
  );

  expect(tester.takeException(), isNull);
  expect(
    tester.getSize(find.byKey(const ValueKey('reader-journey-history'))).height,
    greaterThanOrEqualTo(44),
  );
});
```

- [ ] **Step 3: Run the tests and verify red**

Run:

```powershell
flutter test --no-pub test/features/shell/adaptive_app_shell_test.dart test/features/reader_journey/reader_journey_screen_test.dart
```

Expected: FAIL because the enum variants and `ReaderJourneyScreen` do not exist.

- [ ] **Step 4: Implement the destination enum**

Replace `ShellDestination` with:

```dart
enum ShellDestination { home, library, readerJourney, rankings, account }

extension ShellDestinationPresentation on ShellDestination {
  String get label => switch (this) {
    ShellDestination.home => 'الرئيسية',
    ShellDestination.library => 'المكتبة',
    ShellDestination.readerJourney => 'رحلة القارئ',
    ShellDestination.rankings => 'الترتيب',
    ShellDestination.account => 'حسابي',
  };

  IconData get icon => switch (this) {
    ShellDestination.home => Icons.home_outlined,
    ShellDestination.library => Icons.local_library_outlined,
    ShellDestination.readerJourney => Icons.auto_stories_outlined,
    ShellDestination.rankings => Icons.bar_chart_outlined,
    ShellDestination.account => Icons.person_outline,
  };

  IconData get selectedIcon => switch (this) {
    ShellDestination.home => Icons.home,
    ShellDestination.library => Icons.local_library,
    ShellDestination.readerJourney => Icons.auto_stories,
    ShellDestination.rankings => Icons.bar_chart,
    ShellDestination.account => Icons.person,
  };
}
```

- [ ] **Step 5: Implement the Reader Journey screen**

Create a scrollable `ReaderJourneyScreen` with two focused cards. The active card uses an `OutlinedButton` or `FilledButton` keyed `reader-journey-history`. The disabled card is keyed `reader-journey-downloads`, contains `FilledButton(onPressed: null, ...)`, and displays `قريبًا`. Do not import anything from `features/downloads`.

The public constructor must remain:

```dart
class ReaderJourneyScreen extends StatelessWidget {
  const ReaderJourneyScreen({required this.onOpenHistory, super.key});

  final VoidCallback onOpenHistory;
}
```

- [ ] **Step 6: Wire real destination surfaces**

Update `AppShell.screenBuilders` to:

```dart
screenBuilders: {
  ShellDestination.home: (context, select) => const HomeScreen(),
  ShellDestination.library: (context, select) => const CatalogScreen(),
  ShellDestination.readerJourney: (context, select) => ReaderJourneyScreen(
    onOpenHistory: () => _openHistory(context, select),
  ),
  ShellDestination.rankings: (context, select) => const RankingsScreen(),
  ShellDestination.account: (context, select) =>
      const AccountScreen(embedded: true),
},
```

Add a private `_openHistory` that pushes a `Scaffold` with an app bar titled `سجل القراءة` and a `HistoryScreen(onOpenLibrary: () { Navigator.pop(context); select(ShellDestination.library); })` body.

- [ ] **Step 7: Run focused tests**

Run:

```powershell
dart format lib/features/shell/presentation/shell_destination.dart lib/features/shell/presentation/app_shell.dart lib/features/reader_journey/presentation/reader_journey_screen.dart test/features/shell/adaptive_app_shell_test.dart test/features/reader_journey/reader_journey_screen_test.dart
flutter test --no-pub test/features/shell/adaptive_app_shell_test.dart test/features/reader_journey/reader_journey_screen_test.dart test/features/shell/app_drawer_test.dart
```

Expected: PASS. The drawer test must continue proving that the removed downloads destination is absent.

- [ ] **Step 8: Record the checkpoint**

Inspect only the task files with `git diff -- <paths>`. If their complete diffs belong to this task, commit with `feat: add reader journey navigation`; otherwise leave them unstaged because this is a shared dirty worktree.

---

### Task 2: Build the Stitch shell chrome and disabled notifications action

**Files:**
- Create: `lib/features/shell/presentation/stitch_shell_app_bar.dart`
- Modify: `lib/features/shell/presentation/adaptive_app_shell.dart`
- Modify: `test/features/shell/adaptive_app_shell_test.dart`

**Interfaces:**
- Consumes: `ShellDestination selected`, `ColorScheme`, Scaffold drawer behavior.
- Produces: `StitchShellAppBar({required ShellDestination destination})`.
- Produces stable keys: `shell-app-bar`, `shell-notifications-button`.

- [ ] **Step 1: Add failing shell chrome assertions**

Add a compact Home test:

```dart
testWidgets('home shell uses the Stitch brand bar with disabled notifications', (
  tester,
) async {
  await _pumpAt(tester, const Size(390, 844), _counts());

  final appBar = find.byKey(const ValueKey('shell-app-bar'));
  expect(appBar, findsOneWidget);
  expect(find.descendant(of: appBar, matching: find.text('مجرة الروايات')), findsOneWidget);

  final notifications = find.byKey(
    const ValueKey('shell-notifications-button'),
  );
  expect(notifications, findsOneWidget);
  expect(tester.widget<IconButton>(notifications).onPressed, isNull);
  expect(
    find.bySemanticsLabel('الإشعارات غير متاحة حاليًا'),
    findsOneWidget,
  );
});
```

Add another test that selects Library and expects the title `المكتبة` and no notifications button.

- [ ] **Step 2: Run the test and verify red**

Run:

```powershell
flutter test --no-pub test/features/shell/adaptive_app_shell_test.dart --plain-name "Stitch brand bar"
```

Expected: FAIL because `shell-app-bar` and the disabled notifications action do not exist.

- [ ] **Step 3: Implement `StitchShellAppBar`**

Create a `StatelessWidget` returning an `AppBar`:

```dart
class StitchShellAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const StitchShellAppBar({required this.destination, super.key});

  final ShellDestination destination;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isHome = destination == ShellDestination.home;
    return AppBar(
      key: const ValueKey('shell-app-bar'),
      toolbarHeight: 64,
      centerTitle: true,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: .4)),
      ),
      title: Text(isHome ? 'مجرة الروايات' : destination.label),
      actions: isHome
          ? const [_DisabledNotificationsButton()]
          : const [],
    );
  }
}
```

The private notifications widget wraps `IconButton(key: ValueKey('shell-notifications-button'), onPressed: null, icon: Icon(Icons.notifications_outlined))` in `Semantics(label: 'الإشعارات غير متاحة حاليًا', button: true, enabled: false, excludeSemantics: true)`.

- [ ] **Step 4: Replace the generic app bar**

In `AdaptiveAppShell`, replace `_appBar()` with:

```dart
PreferredSizeWidget _appBar() => StitchShellAppBar(
  destination: _selected,
);
```

Keep the existing responsive `NavigationBar`, `NavigationRail`, and `NavigationDrawer`. Apply local `NavigationBarThemeData` only if needed to match the selected violet capsule; do not change global component themes unrelated to the shell.

- [ ] **Step 5: Verify compact, medium, and expanded shells**

Run:

```powershell
dart format lib/features/shell/presentation/stitch_shell_app_bar.dart lib/features/shell/presentation/adaptive_app_shell.dart test/features/shell/adaptive_app_shell_test.dart
flutter test --no-pub test/features/shell
```

Expected: PASS for all three breakpoints and state-retention tests.

- [ ] **Step 6: Record the checkpoint**

Commit `feat: apply Stitch shell chrome` only if the task-file diffs are isolated; otherwise leave them unstaged.

---

### Task 3: Rebuild Continue Reading and Updated Novels as horizontal Stitch strips

**Files:**
- Modify: `lib/features/home/presentation/home_continue_reading.dart`
- Create: `lib/features/home/presentation/home_updated_novels_strip.dart`
- Modify: `lib/features/home/presentation/home_screen.dart`
- Delete: `lib/features/home/presentation/home_featured_novel.dart` only after all imports and tests prove it unused.
- Modify: `test/features/home/home_discovery_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Produces: `HomeContinueReadingStrip({required List<HomeContinueReadingEntry> entries, required ValueChanged<HomeContinueReadingEntry> onOpen})`.
- Produces: `HomeUpdatedNovelsStrip({required List<NovelSummary> novels, required ValueChanged<String> onNovelTap})`.
- Keeps: `HomeContinueReadingEntry.fromHome`, `HomeContinueReadingEntry.fromLocal`.

- [ ] **Step 1: Add failing multi-history and order tests**

Extend the Home harness to accept a reading-history repository with at least two real `ReadingProgress` instances. Assert:

```dart
expect(find.byKey(const ValueKey('home-featured-header')), findsNothing);
expect(find.byKey(const ValueKey('home-rankings-section')), findsNothing);
expect(find.byKey(const ValueKey('continue-reading-strip')), findsOneWidget);
expect(find.byKey(const ValueKey('continue-reading-card-0')), findsOneWidget);
expect(find.byKey(const ValueKey('continue-reading-card-1')), findsOneWidget);
expect(find.text('رواية السجل الأولى'), findsOneWidget);
expect(find.text('رواية السجل الثانية'), findsOneWidget);
```

Keep an opening test that taps `continue-reading-card-1` and verifies the corresponding `contentApi` reaches `ReaderRepository.loadChapter`.

Assert vertical order after revealing each section:

```dart
expect(
  tester.getTopLeft(find.text('أكمل القراءة')).dy,
  lessThan(tester.getTopLeft(find.text('روايات محدثة')).dy),
);
expect(
  tester.getTopLeft(find.text('روايات محدثة')).dy,
  lessThan(tester.getTopLeft(find.text('آخر تحديثات الروايات')).dy),
);
```

- [ ] **Step 2: Run focused tests and verify red**

Run:

```powershell
flutter test --no-pub test/features/home/home_discovery_test.dart test/widget_test.dart --plain-name "home"
```

Expected: FAIL because Home still selects only the first history item and still renders editor choice and embedded rankings.

- [ ] **Step 3: Extend `HomeContinueReadingEntry` without changing repositories**

Add `chapterPosition` and `chaptersTotal` fields, populated from local progress and set to zero for the remote fallback. Add:

```dart
String get chapterProgressLabel {
  if (chapterPosition <= 0 || chaptersTotal <= 0) {
    return chapterTitle;
  }
  return 'الفصل $chapterPosition من $chaptersTotal';
}

double get completionFraction => completionPercent == null
    ? 0
    : (completionPercent! / 100).clamp(0.0, 1.0);
```

Replace the single-row widget with `HomeContinueReadingStrip`. It must use a horizontal `ListView.separated`, 280-pixel cards, real `NovelCover`, ellipsized title, chapter progress label, and `LinearProgressIndicator`. Key the strip `continue-reading-strip` and cards `continue-reading-card-$index`.

- [ ] **Step 4: Add the updated novels strip**

Create `HomeUpdatedNovelsStrip` with a horizontal `ListView.separated`, `NovelCover`, title, and status badge. Use keys `updated-novels-strip` and `updated-novel-${novel.id}`. Keep `manifest.isEmpty` cards disabled; otherwise call `onNovelTap(novel.manifest)`.

- [ ] **Step 5: Simplify Home composition**

Change `_homeWithHistory` to pass the complete list:

```dart
final history = historySnapshot.data ?? const [];
return _buildHome(home, history);
```

Derive entries with:

```dart
List<HomeContinueReadingEntry> _continueReadingEntries(
  HomeData home,
  List<local_progress.ReadingProgress> history,
) {
  if (history.isNotEmpty) {
    return history
        .map(HomeContinueReadingEntry.fromLocal)
        .toList(growable: false);
  }
  final remote = home.continueReading;
  return remote == null
      ? const []
      : [HomeContinueReadingEntry.fromHome(remote)];
}
```

Build only these slivers, in order:

```dart
..._continueReadingSlivers(continueReadingEntries),
..._recentSlivers(home.recentNovels),
..._latestSlivers(home, novelsById),
const SliverToBoxAdapter(child: SizedBox(height: 28)),
```

Delete `_featuredSlivers`, the `HomeFeaturedNovel` import, the embedded `HomeRankingsSection`, and the old private `_RecentNovelsStrip` after the replacement is wired.

- [ ] **Step 6: Run Home behavior and narrow-layout tests**

Run:

```powershell
dart format lib/features/home/presentation/home_continue_reading.dart lib/features/home/presentation/home_updated_novels_strip.dart lib/features/home/presentation/home_screen.dart test/features/home/home_discovery_test.dart test/widget_test.dart
flutter test --no-pub test/features/home/home_discovery_test.dart test/widget_test.dart
```

Expected: PASS with no overflow at 320 pixels and 200% text. Existing tests that expected `NovelListRow` must be updated to assert the saved cover through the new card subtree rather than the deleted implementation type.

- [ ] **Step 7: Scan for dead featured/rankings Home code**

Run:

```powershell
rg -n "HomeFeaturedNovel|home-featured|HomeRankingsSection|home-rankings-section" lib/features/home test/features/home test/widget_test.dart
```

Expected: no production matches. Delete `home_featured_novel.dart` only when the scan confirms it has no caller. Keep `home_rankings_section.dart` only if another current production caller exists; otherwise delete it and its now-obsolete tests.

- [ ] **Step 8: Record the checkpoint**

Commit `feat: rebuild Stitch home discovery strips` only if complete file diffs are isolated; otherwise leave unstaged.

---

### Task 4: Redesign latest updates list and grid without losing the toggle

**Files:**
- Modify: `lib/features/home/presentation/latest_updates_section.dart`
- Modify: `test/features/home/home_discovery_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `ChapterSummary.visibleChapters`, `NovelSummary`, current manifest fallback helpers.
- Keeps stable keys: `latest-updates-section`, `latest-view-toggle`, `latest-list`, `latest-grid`, `latest-update-<id>`, `latest-grid-<id>`.
- Produces list cards showing at most two `ChapterSummaryItem` rows.

- [ ] **Step 1: Add failing grouped-row tests**

Create a fixture with three visible chapters and assert only the first two labels and their separate dates appear in list mode:

```dart
expect(find.text('الفصل 207'), findsOneWidget);
expect(find.text('الفصل 206'), findsOneWidget);
expect(find.text('الفصل 205'), findsNothing);
expect(find.text('منذ ساعتين'), findsOneWidget);
expect(find.text('منذ ثلاث ساعات'), findsOneWidget);
expect(
  find.descendant(
    of: find.byKey(const ValueKey('latest-update-207')),
    matching: find.byKey(const ValueKey('latest-status-207')),
  ),
  findsOneWidget,
);
```

Keep the existing manifest fallback test and the 320/390/600/720/840 grid-column parameterized test.

- [ ] **Step 2: Run the tests and verify red**

Run:

```powershell
flutter test --no-pub test/features/home/home_discovery_test.dart --plain-name "latest"
```

Expected: FAIL because list mode currently flattens labels into one subtitle and does not expose two chapter/date rows.

- [ ] **Step 3: Implement the Stitch list card**

Replace `NovelListItem` in `_LatestUpdatesList` with a focused `_LatestUpdateCard`. Its public inputs are the `ChapterSummary`, optional `NovelSummary`, and `VoidCallback? onTap`. Build:

```dart
final visibleChapters = chapter.visibleChapters.take(2).toList();
return Card(
  key: ValueKey('latest-update-${chapter.id}'),
  clipBehavior: Clip.antiAlias,
  child: InkWell(
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 116,
          child: Stack(
            children: [
              Positioned.fill(child: NovelCover(imageUrl: coverUrl)),
              if (statusLabel.isNotEmpty)
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: StatusBadge(
                    key: ValueKey('latest-status-${chapter.id}'),
                    label: statusLabel,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.novelTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                for (final visible in visibleChapters)
                  _LatestChapterRow(chapter: visible),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
);
```

Use a bounded list-card extent that scales with text, and ensure the cover remains on the RTL-leading/right side. `_LatestChapterRow` displays label and date in one row with flexible ellipsis.

- [ ] **Step 4: Restyle the grid while preserving its adaptive math**

Keep `_columnCount`, `_cardExtent`, and the manifest/cover fallback helpers. Restyle the `NovelPosterCard` wrapper or introduce a local `_LatestGridCard` only if the shared card cannot match without changing other screens. Do not alter expected columns: 2 at 320/390, 3 at 600, 4 at 720, 5 at 840.

- [ ] **Step 5: Preserve toggle semantics and navigation**

Keep these exact semantics:

```dart
label: showingList ? 'العرض الحالي: قائمة' : 'العرض الحالي: شبكة',
hint: showingList ? 'التبديل إلى شبكة' : 'التبديل إلى قائمة',
```

Both list and grid cards must call the existing details manifest fallback; neither opens the Reader directly.

- [ ] **Step 6: Run latest and full Home tests**

Run:

```powershell
dart format lib/features/home/presentation/latest_updates_section.dart test/features/home/home_discovery_test.dart test/widget_test.dart
flutter test --no-pub test/features/home test/widget_test.dart
```

Expected: PASS with no overflow and the list/grid toggle behavior unchanged.

- [ ] **Step 7: Record the checkpoint**

Commit `feat: redesign latest update cards` only if the diffs are isolated; otherwise leave unstaged.

---

### Task 5: Responsive integration, documentation, visual verification, and Android build

**Files:**
- Modify: `test/features/phase3/phase3_reading_surfaces_test.dart` only if its shell destination assumptions changed.
- Modify or create: `test/features/phase4/phase4_home_shell_test.dart`
- Modify: `test/goldens/phase4_surfaces_golden_test.dart`
- Create: six `test/goldens/goldens/phase4_homeShell_<theme>_<width>.png` files.
- Modify: `docs/manual_test_plan.md`

**Interfaces:**
- Consumes the completed shell, Reader Journey, and Home sections.
- Produces regression coverage at 320/600/840 in both approved themes.

- [ ] **Step 1: Add the responsive shell and Home journey test**

Cover this path in a new or existing phase-4 test loop:

```dart
for (final variant in variants) {
  testWidgets('Stitch home shell is responsive in ${variant.name}', (
    tester,
  ) async {
    await pumpApp(tester, size: variant.size, theme: variant.theme);

    expect(find.text('مجرة الروايات'), findsOneWidget);
    expect(find.byKey(const ValueKey('continue-reading-strip')), findsOneWidget);
    expect(find.byKey(const ValueKey('updated-novels-strip')), findsOneWidget);
    expect(find.byKey(const ValueKey('latest-updates-section')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-featured-header')), findsNothing);
    expect(tester.takeException(), isNull);

    await tapShellDestination(tester, ShellDestination.readerJourney);
    expect(find.byKey(const ValueKey('reader-journey-history')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-journey-downloads')), findsOneWidget);
  });
}
```

Use existing phase harnesses and real state objects; do not mock internal widgets.

- [ ] **Step 2: Extend the golden showcase**

Add `_GoldenGroup.homeShell` to `phase4_surfaces_golden_test.dart` and render `const AppShell()`. Keep the established 320/600/840 × galaxyNoir/starlightPaper matrix. Generate only the six new files first:

```powershell
flutter test --no-pub --update-goldens test/goldens/phase4_surfaces_golden_test.dart --plain-name homeShell
```

Then inspect at least `phase4_homeShell_galaxyNoir_320.png`, `phase4_homeShell_galaxyNoir_840.png`, and `phase4_homeShell_starlightPaper_320.png` with the image viewer. Correct clipping, ordering, contrast, or disabled-state ambiguity before accepting the goldens.

- [ ] **Step 3: Update the manual test plan**

Update startup/navigation/Home/history sections to state:

```markdown
- يظهر الشريط السفلي: الرئيسية، المكتبة، رحلة القارئ، الترتيب، حسابي.
- يظهر زر الإشعارات معطّلًا ولا يفتح شاشة.
- تعرض رحلة القارئ سجل القراءة وزر تنزيلات معطّلًا يحمل «قريبًا».
- ترتب الرئيسية: أكمل القراءة، روايات محدثة، آخر تحديثات الروايات.
- يعرض أكمل القراءة عناصر السجل في شريط أفقي، وتفتح كل بطاقة فصلها المحفوظ.
- يعمل التبديل بين قائمة آخر التحديثات وشبكتها.
```

Remove old claims that Favorites or History are bottom destinations and old claims about an embedded Home rankings section.

- [ ] **Step 4: Run all focused verification**

Run:

```powershell
flutter test --no-pub test/features/shell test/features/reader_journey test/features/home test/features/phase4/phase4_home_shell_test.dart test/widget_test.dart
flutter test --no-pub test/goldens/phase4_surfaces_golden_test.dart
flutter analyze --no-pub
```

Expected: all tests PASS; analyzer reports `No issues found!`.

- [ ] **Step 5: Verify forbidden downloads and obsolete shell variants**

Run:

```powershell
rg -n "features/downloads|DownloadsScreen|DownloadManager|ShellDestination\.favorites|ShellDestination\.history" lib/features/home lib/features/shell lib/features/reader_journey
```

Expected: no matches. Favorites may remain in `app_drawer.dart`; this scan intentionally targets the Home/Shell/Journey implementation only.

Run:

```powershell
git diff --check -- docs/manual_test_plan.md lib/features/home lib/features/shell lib/features/reader_journey test/features/home test/features/shell test/features/reader_journey test/features/phase4 test/goldens
```

Expected: exit code 0, apart from harmless line-ending warnings.

- [ ] **Step 6: Build Android**

Run:

```powershell
flutter build apk --debug --no-pub
```

Expected: `build/app/outputs/flutter-apk/app-debug.apk` is produced successfully.

- [ ] **Step 7: Final guard pass and handoff**

Apply clean-code, test, and docs guard passes to the task diff. Confirm there are no boolean flag arguments, generic names, duplicate widget trees, implementation-detail tests, false manual-test claims, or dead imports. Report the exact test/analyzer/build results and provide links to the APK and the inspected dark golden.

