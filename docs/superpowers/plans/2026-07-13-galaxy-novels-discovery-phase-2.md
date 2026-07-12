# Galaxy Novels Discovery — Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** تحويل الرئيسية والمكتبة والترتيبات إلى تجربة اكتشاف متماسكة بهوية «المكتبة المدارية الهادئة»، مع بطاقات روايات مشتركة وإتمام الوجهات الخمس المعتمدة من دون تغيير عقود البيانات أو سلوك «آخر التحديثات».

**Architecture:** تبقى المستودعات والنماذج والتنقل إلى التفاصيل كما هي. تُبنى بطاقتا عرض مشتركتان فوق `NovelCover` والتوكنات الدلالية، ثم تهاجر إليهما شاشات الاكتشاف تدريجيًا. يحتفظ `AdaptiveAppShell` بإنشائه الكسول، بينما تصبح وجهاته النهائية: الرئيسية، المكتبة، المفضلة، السجل، حسابي؛ تبقى التنزيلات والترتيبات متاحة من اختصارات واضحة ومسارات مستقلة.

**Tech Stack:** Flutter، Dart، Material 3، Slivers، widget tests، semantics tests.

## Global Constraints

- Android هو هدف البناء الحالي؛ لا تغييرات iOS.
- السمات المرئية Galaxy Noir وStarlight Paper فقط، مع خيار «حسب النظام».
- الدخول كزائر هو الوضع الطبيعي؛ لا تصبح القراءة أو الاكتشاف خلف تسجيل الدخول.
- الضغط على «آخر التحديثات» يفتح تفاصيل الرواية، ولا يفتح القارئ مباشرة.
- لا تتغير API أو المستودعات أو نماذج البيانات.
- نقاط التحول: أقل من 600 هاتف، 600–839 متوسط، و840 فأكثر موسع.
- الأهداف اللمسية 44×44 على الأقل، وRTL وتكبير النص 200% مطلوبان.
- الشاشات الطويلة تستخدم Slivers/قوائم كسولة، وأحجام فك صور الأغلفة تبقى مرتبطة بحجم العرض.
- لا stage أو commit لملف كان متسخًا قبل المهمة؛ لا تنشئ commit ذريًا ناقص الاعتماديات.

---

## File Map

### Shared discovery components

- Create: `galaxy_novels_app/lib/shared/widgets/novel_poster_card.dart` — بطاقة غلاف موحدة للشبكة والشريط الأفقي مع دلالات وبيانات وصفية اختيارية.
- Create: `galaxy_novels_app/lib/shared/widgets/novel_list_item.dart` — صف رواية موحد للترتيبات والقوائم مع موضع/غلاف وبيانات تفسيرية.
- Modify: `galaxy_novels_app/lib/shared/widgets/novel_poster_tile.dart` — غلاف توافق مؤقت فوق `NovelPosterCard`.
- Modify: `galaxy_novels_app/lib/shared/widgets/novel_list_row.dart` — غلاف توافق مؤقت فوق `NovelListItem` عند تطابق العقد.
- Modify: `galaxy_novels_app/test/shared/novel_components_test.dart` — العقود المرئية والدلالية والتكبير.

### Final shell destinations

- Modify: `galaxy_novels_app/lib/features/shell/presentation/shell_destination.dart` — الوجهات النهائية الخمس.
- Modify: `galaxy_novels_app/lib/features/shell/presentation/app_shell.dart` — ربط المفضلة والحساب بدل التنزيلات والترتيبات.
- Modify: `galaxy_novels_app/lib/features/favorites/presentation/favorites_screen.dart` — وضع embedded بلا Scaffold داخلي.
- Modify: `galaxy_novels_app/lib/features/account/presentation/account_screen.dart` — وضع embedded بلا Scaffold داخلي.
- Modify: `galaxy_novels_app/test/features/shell/adaptive_app_shell_test.dart` — العقود النهائية والإنشاء الكسول.
- Modify: `galaxy_novels_app/test/widget_test.dart` — الوجهات النهائية مع وصول الزائر.

### Home discovery

- Modify: `galaxy_novels_app/lib/features/home/presentation/home_screen.dart` — Slivers، اختيار تحريري، تابع القراءة، التحديثات، الترتيبات.
- Modify: `galaxy_novels_app/lib/features/home/presentation/latest_updates_section.dart` — بطاقة/شبكة متكيفة مشتركة وسلوك التفاصيل.
- Create: `galaxy_novels_app/lib/features/home/presentation/home_featured_novel.dart` — اختيار تحريري عرضي من أول رواية حديثة.
- Create: `galaxy_novels_app/lib/features/home/presentation/home_rankings_section.dart` — قسم ترتيب ثانوي لا يحجب الرئيسية عند فشله.
- Create: `galaxy_novels_app/test/features/home/home_discovery_test.dart` — الترتيب، التعطل الجزئي، والاستجابة.

### Library and rankings

- Modify: `galaxy_novels_app/lib/features/catalog/presentation/catalog_screen.dart` — رأس بحث/مرشحات مضغوط واختصارات التنزيلات والترتيبات وشبكة متكيفة.
- Modify: `galaxy_novels_app/lib/features/catalog/presentation/widgets/catalog_novel_tile.dart` — استخدام `NovelPosterCard`.
- Modify: `galaxy_novels_app/lib/features/rankings/presentation/rankings_screen.dart` — الحالات المشتركة.
- Modify: `galaxy_novels_app/lib/features/rankings/presentation/widgets/ranking_list_row.dart` — استخدام `NovelListItem`.
- Modify: `galaxy_novels_app/lib/features/rankings/presentation/widgets/top_rankings_strip.dart` — استخدام بطاقة الغلاف المشتركة مع شارة المركز.
- Modify: `galaxy_novels_app/test/features/catalog/catalog_novel_tile_test.dart` — العقد المشترك.
- Create: `galaxy_novels_app/test/features/catalog/catalog_discovery_test.dart` — الاختصارات والمرشحات والاستجابة.
- Create: `galaxy_novels_app/test/features/rankings/rankings_discovery_test.dart` — المركز وسبب الترتيب والحالات.

---

### Task 1: Shared poster and list components

**Interfaces:**

- Produces: `NovelPosterCard(title, imageUrl, statusLabel, metadata, leadingBadge, onTap)`.
- Produces: `NovelListItem(title, imageUrl, subtitle, metadata, leading, statusLabel, onTap)`.
- Preserves: constructors of `NovelPosterTile` and `NovelListRow` as temporary compatibility wrappers.

- [ ] **Step 1: Write failing component tests**

Add tests that pump both themes at 320px and 200% text scale. The core assertions are:

```dart
expect(find.byType(NovelPosterCard), findsOneWidget);
expect(tester.getSemantics(find.byType(NovelPosterCard)), matchesSemantics(
  label: 'رواية الاختبار',
  isButton: true,
  hasTapAction: true,
));
expect(tester.takeException(), isNull);

expect(find.byType(NovelListItem), findsOneWidget);
expect(find.text('#4'), findsOneWidget);
expect(find.text('12.4K مشاهدة'), findsOneWidget);
```

- [ ] **Step 2: Verify RED**

Run:

```powershell
flutter test test/shared/novel_components_test.dart
```

Expected: FAIL because `NovelPosterCard` and `NovelListItem` do not exist.

- [ ] **Step 3: Implement the minimal presentation-only components**

`NovelPosterCard` must use `Semantics(button: onTap != null, label: title)`, `RepaintBoundary`, `InkWell`, `NovelCover`, `StatusBadge`, semantic theme tokens, and a `Wrap`/flexible metadata region. `NovelListItem` must use a fixed optional leading slot, `NovelCover.list` otherwise, two-line-safe title/subtitle, wrapping metadata, and a trailing chevron only when tappable. Neither component may import repositories or feature models.

- [ ] **Step 4: Convert compatibility widgets into thin adapters**

`NovelPosterTile.build` returns `NovelPosterCard` with the current fixed width/height contract. `NovelListRow.build` maps current string fields into `NovelListItem` without changing existing caller behavior.

- [ ] **Step 5: Verify GREEN and review**

```powershell
dart format lib/shared/widgets/novel_poster_card.dart lib/shared/widgets/novel_list_item.dart lib/shared/widgets/novel_poster_tile.dart lib/shared/widgets/novel_list_row.dart test/shared/novel_components_test.dart
flutter test test/shared/novel_components_test.dart test/widget_test.dart
flutter analyze
```

Expected: PASS and no analysis issues. Request spec and code/test review before Task 2.

---

### Task 2: Final five lazy shell destinations

**Interfaces:**

- Changes `ShellDestination` to `home`, `library`, `favorites`, `history`, `account`.
- Produces: `FavoritesScreen({bool embedded = false})` and `AccountScreen({bool embedded = false})`; `embedded: true` returns content only and lets the shell own the app bar.
- Preserves: all five screens remain lazily created and preserve state across 599→600 and destination changes.

- [ ] **Step 1: Replace shell expectations with failing final-map tests**

Use one shared list:

```dart
const expectedLabels = ['الرئيسية', 'المكتبة', 'المفضلة', 'السجل', 'حسابي'];
expect(ShellDestination.values.map((value) => value.label), expectedLabels);
```

Add a widget test that opens «المفضلة» as a guest, confirms the shell remains visible, and sees the optional sign-in invitation without any startup login gate.

- [ ] **Step 2: Verify RED**

```powershell
flutter test test/features/shell/adaptive_app_shell_test.dart test/widget_test.dart
```

Expected: FAIL because the transitional downloads/rankings destinations still exist.

- [ ] **Step 3: Implement final destination metadata and production builders**

Map icons to home, local_library, bookmark, history, person. In `AppShell`, use:

```dart
ShellDestination.home: (_, __) => const HomeScreen(),
ShellDestination.library: (_, __) => const CatalogScreen(),
ShellDestination.favorites: (_, __) => const FavoritesScreen(embedded: true),
ShellDestination.history: (_, __) => const HistoryScreen(),
ShellDestination.account: (_, __) => const AccountScreen(embedded: true),
```

Extract the existing scaffold bodies in Favorites/Account into private `_content()` methods; standalone routes keep their app bars, embedded builders return only the content.

- [ ] **Step 4: Verify GREEN and review**

```powershell
flutter test test/features/shell/adaptive_app_shell_test.dart test/widget_test.dart test/features/account/account_shortcuts_test.dart
flutter analyze
```

Expected: PASS; builders for unvisited destinations remain at zero. Request spec and code/test review.

---

### Task 3: Editorial home discovery

**Interfaces:**

- `HomeFeaturedNovel(novel, onOpen)` consumes a `NovelSummary` and opens its manifest only when non-empty.
- `HomeRankingsSection(onOpenNovel, onViewAll)` loads through the existing `RankingsRepository`; loading/failure/empty are section-local and never replace the rest of Home.
- `LatestUpdatesSection` preserves `onNovelTap(manifestPath)`.

- [ ] **Step 1: Write failing home discovery tests**

Test the visible order with `find.text`: اختيار المحرر, أكمل القراءة (when present), روايات محدثة, آخر تحديثات الروايات, الترتيب. Test that tapping `latest-update-*` still opens `NovelDetailsScreen`. Inject a failing rankings repository and assert recent/latest content remains visible. At widths 390, 600, and 840 with 200% text, assert `tester.takeException()` is null.

- [ ] **Step 2: Verify RED**

```powershell
flutter test test/features/home/home_discovery_test.dart test/widget_test.dart
```

Expected: FAIL because the featured and rankings sections are absent.

- [ ] **Step 3: Implement Home as a lazy sliver composition**

Use `CustomScrollView`/slivers and `AppSectionHeader`; choose `home.recentNovels.first` as the deterministic editorial pick (no new API). Keep local reading history above server fallback. Convert loading/error/empty to `AppAsyncState`, with retry calling the same existing repositories. Limit horizontal strips and decode dimensions through existing `NovelCover` behavior.

- [ ] **Step 4: Make latest-updates grid adaptive**

Replace fixed three columns with `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, ...)` or a width-derived 2/3/4/5 count matching the approved breakpoints. Keep list/grid toggle at least 44×44 and keep the details callback unchanged.

- [ ] **Step 5: Verify GREEN and review**

```powershell
flutter test test/features/home/home_discovery_test.dart test/widget_test.dart
flutter analyze
```

Expected: PASS. Request spec and code/test review.

---

### Task 4: Compact library controls and visible feature shortcuts

**Interfaces:**

- Produces optional callbacks on `CatalogScreen`: `onOpenDownloads`, `onOpenRankings`; when absent, the screen pushes `DownloadsScreen`/`RankingsScreen` itself.
- Preserves `CatalogQuery`, search debounce, cached-data notices, filter/sort semantics, and `NovelDetailsScreen(manifestPath)`.

- [ ] **Step 1: Write failing library tests**

Assert buttons keyed `catalog-open-downloads` and `catalog-open-rankings` are visible and at least 44×44, invoke callbacks, and do not alter the filtered item count. Test exact grid counts: 2 at 390, 3 at 599, 4 at 700, 5 at 1000 where minimum card width permits. Test selected `FilterChip` semantics and 200% text without overflow.

- [ ] **Step 2: Verify RED**

```powershell
flutter test test/features/catalog/catalog_discovery_test.dart test/features/catalog/catalog_novel_tile_test.dart
```

Expected: FAIL because discovery shortcuts and shared poster card are absent.

- [ ] **Step 3: Implement compact controls and shortcuts**

Keep search, filter, sort, count, active filters, and shortcuts inside the first sliver; use `Wrap` at 200% rather than a fixed `Row`. Shortcut fallbacks push standalone routes; Downloads receives `onOpenLibrary: Navigator.pop`. Keep `SliverGrid` lazy and derive count from the available cross-axis extent.

- [ ] **Step 4: Migrate `CatalogNovelTile` to `NovelPosterCard`**

Map the existing cover priority, status, views, and chapter count into the shared component. Preserve `ValueKey`, `RepaintBoundary`, title semantics, and cache-sized cover layout.

- [ ] **Step 5: Verify GREEN and review**

```powershell
flutter test test/features/catalog/catalog_discovery_test.dart test/features/catalog/catalog_novel_tile_test.dart test/widget_test.dart
flutter analyze
```

Expected: PASS. Request spec and code/test review.

---

### Task 5: Rankings shared presentation and unified states

**Interfaces:**

- `RankingsScreen` keeps its existing repository and retry contract.
- `RankingListRow` becomes an adapter to `NovelListItem` with rank, chapters, views, rating, status, and details callback.
- Top three use `NovelPosterCard` plus a rank badge; rank and views remain visible explanations of ordering.

- [ ] **Step 1: Write failing ranking tests**

For ranks 1–4 assert visible rank, title, views, chapters, and details callback. Assert loading uses `AppSkeleton`, empty uses `AppEmptyState`, error exposes the 44px retry action, and 320px/200% has no overflow.

- [ ] **Step 2: Verify RED**

```powershell
flutter test test/features/rankings/rankings_discovery_test.dart
```

Expected: FAIL because the shared components/states are not yet used.

- [ ] **Step 3: Implement adapters and shared async states**

Replace `_RankingsMessage` with `AppAsyncState`; preserve `_retry`. Map remaining rows to `NovelListItem`, and top-three cards to `NovelPosterCard` without changing manifest navigation. Keep `CustomScrollView` and `SliverList` lazy.

- [ ] **Step 4: Verify GREEN and review**

```powershell
flutter test test/features/rankings/rankings_discovery_test.dart test/widget_test.dart
flutter analyze
```

Expected: PASS. Request spec and code/test review.

---

### Task 6: Phase-2 quality gate

- [ ] **Step 1: Format only phase-2 files** with `dart format` and confirm no unrelated file changes.
- [ ] **Step 2: Run `flutter analyze`**; expected `No issues found!`.
- [ ] **Step 3: Run `flutter test`**; expected all tests pass and record the count.
- [ ] **Step 4: Run `flutter build apk --debug`**; expected `build/app/outputs/flutter-apk/app-debug.apk`.
- [ ] **Step 5: Run `git diff --check`, `git diff --cached --check`, `git status --short`, and `git diff --stat`**; expected no whitespace errors and no staged implementation files.
- [ ] **Step 6: Request final spec/code/test review** and fix every Critical/Important finding through a RED→GREEN regression test.

## Self-Review Record

- Spec coverage: final destinations, home editorial order, latest-details contract, catalog search/filters, downloads/rankings shortcuts, shared poster/list components, async states, lazy slivers, RTL/200%, and phase gate are mapped to tasks.
- Deliberately deferred: details, reader, comments, VIP, ads belong to phase 3; personal-library visual polish, drawer polish, privacy/about, and final goldens belong to phase 4.
- Placeholder scan: no TBD/TODO or undefined future type remains; every task names files, interfaces, red/green commands, and expected behavior.
- Type consistency: `NovelPosterCard`, `NovelListItem`, `ShellDestination`, embedded screen constructors, and optional catalog callbacks have one spelling across producers and consumers.
