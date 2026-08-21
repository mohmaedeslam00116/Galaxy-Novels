# Compact Catalog Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Library screen as a compact, adaptive poster grid that matches the approved Galaxy Novels visual system without changing catalog data behavior.

**Architecture:** Keep `CatalogScreen` as the coordinator for repository streams, query state, and navigation. Move the catalog control surface into a focused presentation file, replace the shared poster card with a compact catalog-specific tile, and calculate grid geometry from the actual sliver width with a centered 900-pixel maximum. Preserve the existing repository and query contracts.

**Tech Stack:** Flutter, Dart, Material 3, `flutter_test`, existing `CatalogRepository`, `SearchRepository`, `CatalogQuery`, and phase 4 golden harness.

## Global Constraints

- Execute inline in the current session; the user explicitly prohibited subagents.
- Do not restore downloads or add any downloads destination, import, repository, service, or screen.
- Do not change catalog repositories, API models, endpoints, cache behavior, or search debounce behavior.
- Remove the in-library Rankings shortcut and fallback route; Rankings remains available through `ShellDestination.rankings`.
- Do not repeat the `المكتبة` title inside the catalog body because the shell app bar already shows it.
- Keep one display mode: a compact poster grid with no list/grid toggle.
- Cards show title, status, and chapter count only; views are absent.
- Use semantic theme roles. Deep Purple Night applies only in dark mode; light mode keeps its semantic `ColorScheme`.
- Verify RTL at widths 320, 600, and 840 pixels with 100% and 200% text.
- Keep every active target at least 44 by 44 pixels.
- Center content within a 900-pixel maximum on very wide screens and use at most five columns.
- Preserve unrelated dirty-worktree changes. Commit a checkpoint only when the complete diff of every staged file belongs to this task.

---

## File Structure

- Create `lib/features/catalog/presentation/widgets/catalog_controls.dart`: compact search, filter/sort row, active chips, result summary, and existing filter sheet behavior.
- Modify `lib/features/catalog/presentation/catalog_screen.dart`: repository/query coordinator, adaptive grid, navigation, loading/error composition; remove Rankings coupling and old control classes.
- Modify `lib/features/catalog/presentation/widgets/catalog_novel_tile.dart`: catalog-specific compact poster card with title, status, and chapter count.
- Modify `test/features/catalog/catalog_discovery_test.dart`: control behavior, removal of Rankings shortcut, responsive grid, loading/error paths, and 200% text.
- Modify `test/features/catalog/catalog_novel_tile_test.dart`: compact tile content, cover fallback, semantics, and tap behavior.
- Modify `test/features/shell/adaptive_app_shell_test.dart`: keep proof that Rankings is independently reachable from the shell while Catalog remains stateful.
- Modify `test/goldens/phase4_surfaces_golden_test.dart`: add the Catalog golden group.
- Create six `test/goldens/goldens/phase4_catalog_<theme>_<width>.png` baselines.
- Modify `docs/manual_test_plan.md`: document compact Library controls and card content.

---

### Task 1: Remove the redundant Rankings shortcut and compact the control surface

**Files:**
- Create: `lib/features/catalog/presentation/widgets/catalog_controls.dart`
- Modify: `lib/features/catalog/presentation/catalog_screen.dart`
- Modify: `test/features/catalog/catalog_discovery_test.dart`

**Interfaces:**
- Produces: `CatalogControls({required TextEditingController searchController, required CatalogControlsViewState viewState, required CatalogControlsActions actions})`.
- Produces: `CatalogControlsViewState` record with `query`, `resultCount`, `availableStatuses`, and `availableGenres`.
- Produces: `CatalogControlsActions` record with search, sort, filter, and clear callbacks.
- Consumes: existing `CatalogQuery`, `CatalogSort`, `AppThemeTokens`, and Material bottom sheet APIs.

- [ ] **Step 1: Replace Rankings shortcut tests with the approved absence and compact order tests**

Delete the tests that tap `catalog-open-rankings`, the fallback Rankings route test, `_tapCatalogShortcuts`, and the `onOpenRankings` argument from the catalog test harness. Add:

```dart
testWidgets('catalog starts with compact controls and no rankings shortcut', (
  tester,
) async {
  await _pumpCatalog(tester);

  final search = find.byKey(const ValueKey('catalog-search-field'));
  final tools = find.byKey(const ValueKey('catalog-tools-row'));
  final summary = find.byKey(const ValueKey('catalog-results-summary'));
  final grid = find.byKey(const ValueKey('catalog-sliver-grid'));

  expect(find.byKey(const ValueKey('catalog-open-rankings')), findsNothing);
  expect(find.text('مكتبة الروايات'), findsNothing);
  expect(tester.getTopLeft(search).dy, lessThan(tester.getTopLeft(tools).dy));
  expect(tester.getTopLeft(tools).dy, lessThan(tester.getTopLeft(summary).dy));
  expect(tester.getTopLeft(summary).dy, lessThan(tester.getTopLeft(grid).dy));
});
```

Keep the shell test that navigates to `ShellDestination.rankings`; it is the behavioral proof that removing the Library shortcut does not remove Rankings.

- [ ] **Step 2: Run the new test and verify red**

Run:

```powershell
flutter test --no-pub test/features/catalog/catalog_discovery_test.dart --plain-name "catalog starts with compact controls and no rankings shortcut"
```

Expected: FAIL because the Rankings shortcut and repeated heading still exist and the new stable keys do not.

- [ ] **Step 3: Create the focused controls API**

Create `catalog_controls.dart` with these public records and widget:

```dart
import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/catalog_query.dart';

typedef CatalogFiltersChanged =
    void Function(String? statusLabel, String? genreName);

typedef CatalogControlsViewState = ({
  List<String> availableGenres,
  List<String> availableStatuses,
  CatalogQuery query,
  int? resultCount,
});

typedef CatalogControlsActions = ({
  VoidCallback clearAll,
  VoidCallback clearSearch,
  CatalogFiltersChanged filtersChanged,
  ValueChanged<String> searchChanged,
  ValueChanged<CatalogSort> sortChanged,
});

class CatalogControls extends StatelessWidget {
  const CatalogControls({
    required this.searchController,
    required this.viewState,
    required this.actions,
    super.key,
  });

  final TextEditingController searchController;
  final CatalogControlsViewState viewState;
  final CatalogControlsActions actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CatalogSearchField(
            controller: searchController,
            query: viewState.query,
            onChanged: actions.searchChanged,
            onClear: actions.clearSearch,
          ),
          const SizedBox(height: 10),
          _CatalogTools(
            query: viewState.query,
            onSortChanged: actions.sortChanged,
            onOpenFilters: () => _showFilters(context),
          ),
          _ActiveCatalogFilters(
            query: viewState.query,
            onSearchCleared: actions.clearSearch,
            onSortReset: () => actions.sortChanged(CatalogSort.latest),
            onFiltersChanged: actions.filtersChanged,
            onClear: actions.clearAll,
          ),
          if (viewState.resultCount case final count?) ...[
            const SizedBox(height: 10),
            Text(
              '$count رواية',
              key: const ValueKey('catalog-results-summary'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

Relocate these complete existing definitions from `catalog_screen.dart` into `catalog_controls.dart`: `_CatalogSearchField`, `_CatalogSortButton`, `_CatalogToolButton`, `_CatalogToolSurface`, `_ActiveCatalogFilters`, `_ActiveFilterPill`, `_CatalogFiltersSheet`, `_CatalogFiltersSheetState`, and `_FilterSelection`. They stay private because every caller remains in the same new file. Keep their current stable keys, change the empty branch in `_ActiveCatalogFilters` from `const SizedBox(height: 10)` to `const SizedBox.shrink()`, and replace `_CatalogTools` with:

```dart
class _CatalogTools extends StatelessWidget {
  const _CatalogTools({
    required this.query,
    required this.onSortChanged,
    required this.onOpenFilters,
  });

  final CatalogQuery query;
  final ValueChanged<CatalogSort> onSortChanged;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackControls = MediaQuery.textScalerOf(context).scale(1) >= 2;
        final controlWidth = stackControls
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          key: const ValueKey('catalog-tools-row'),
          spacing: 10,
          runSpacing: 8,
          children: [
            SizedBox(
              width: controlWidth,
              child: _CatalogToolButton(
                key: const ValueKey('catalog-filter-button'),
                icon: Icons.category_outlined,
                label: query.genreName ?? 'كل التصنيفات',
                onTap: onOpenFilters,
              ),
            ),
            SizedBox(
              width: controlWidth,
              child: _CatalogSortButton(
                selectedSort: query.sort,
                onSelected: onSortChanged,
              ),
            ),
          ],
        );
      },
    );
  }
}
```

In `_CatalogSearchField`, add these decoration values while keeping its current prefix, suffix, and hint:

```dart
isDense: true,
constraints: const BoxConstraints(minHeight: 48),
contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
```

Replace the fixed-height `Ink` in `_CatalogToolSurface` with a growing minimum-height surface so 200% text is not clipped:

```dart
ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 48),
  child: Ink(
    decoration: BoxDecoration(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: tokens.border),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: tokens.accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(trailingIcon, color: tokens.textSecondary, size: 20),
        ],
      ),
    ),
  ),
)
```

- [ ] **Step 4: Wire compact controls and delete the obsolete Rankings path**

Change `CatalogScreen` to:

```dart
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}
```

Remove the `RankingsScreen` import, `onOpenRankings`, `_openRankings`, `_CatalogHeading`, `_CatalogShortcuts`, `_ResultCountPill`, and all control classes moved to `catalog_controls.dart`. Replace `_CatalogControls` with:

```dart
CatalogControls(
  searchController: _searchController,
  viewState: (
    query: _query,
    resultCount: state == null ? null : result.items.length,
    availableStatuses: result.availableStatuses,
    availableGenres: result.availableGenres,
  ),
  actions: (
    searchChanged: _onSearchChanged,
    clearSearch: _clearSearchText,
    sortChanged: (sort) {
      setState(() => _query = _query.copyWith(sort: sort));
    },
    filtersChanged: (status, genre) {
      setState(() {
        _query = _query.copyWith(
          statusLabel: status,
          genreName: genre,
          clearStatus: status == null,
          clearGenre: genre == null,
        );
      });
    },
    clearAll: _clearQuery,
  ),
),
```

- [ ] **Step 5: Format and run the control behavior suite**

Run:

```powershell
dart format lib/features/catalog/presentation/catalog_screen.dart lib/features/catalog/presentation/widgets/catalog_controls.dart test/features/catalog/catalog_discovery_test.dart
flutter test --no-pub test/features/catalog/catalog_discovery_test.dart test/features/shell/adaptive_app_shell_test.dart
```

Expected: PASS. Search/filter/sort tests remain green; the shell still opens Rankings independently.

- [ ] **Step 6: Record the checkpoint**

Inspect:

```powershell
git diff -- lib/features/catalog/presentation/catalog_screen.dart lib/features/catalog/presentation/widgets/catalog_controls.dart test/features/catalog/catalog_discovery_test.dart test/features/shell/adaptive_app_shell_test.dart
```

If every displayed line belongs to this task, commit with `feat: compact catalog discovery controls`. Otherwise leave these overlapping dirty files unstaged and continue.

---

### Task 2: Build the compact catalog-specific novel card

**Files:**
- Modify: `lib/features/catalog/presentation/widgets/catalog_novel_tile.dart`
- Modify: `test/features/catalog/catalog_novel_tile_test.dart`

**Interfaces:**
- Keeps: `CatalogNovelTile({required CatalogNovel novel, VoidCallback? onTap, Key? key})`.
- Consumes: `NovelCover`, `StatusBadge`, and `CatalogNovel`.
- Produces stable keys: `catalog-tile-cover`, `catalog-tile-status`, and `catalog-tile-chapters` within each card subtree.

- [ ] **Step 1: Replace poster-adapter assertions with compact content assertions**

Remove assertions against `NovelPosterCard` and `_compactNumber`. Add:

```dart
testWidgets('catalog tile shows only approved compact metadata', (
  tester,
) async {
  await _pumpTile(tester, _narrowStatsNovel);

  expect(find.text(_narrowStatsNovel.title), findsOneWidget);
  expect(find.text('مستمرة'), findsOneWidget);
  expect(find.text('999 فصل'), findsOneWidget);
  expect(find.textContaining('مشاهدة'), findsNothing);
  expect(find.byKey(const ValueKey('catalog-tile-cover')), findsOneWidget);
  expect(find.byKey(const ValueKey('catalog-tile-status')), findsOneWidget);
  expect(find.byKey(const ValueKey('catalog-tile-chapters')), findsOneWidget);
});
```

Keep data-driven medium/thumbnail/large cover fallback cases, but read the `NovelCover.imageUrl` directly. Keep tap and title semantics tests.

- [ ] **Step 2: Run the compact tile test and verify red**

Run:

```powershell
flutter test --no-pub test/features/catalog/catalog_novel_tile_test.dart --plain-name "catalog tile shows only approved compact metadata"
```

Expected: FAIL because the current tile still exposes views through `NovelPosterCard.metadata` and lacks the new keys.

- [ ] **Step 3: Implement the compact tile without changing shared poster cards**

Replace `CatalogNovelTile.build` with a catalog-specific composition:

```dart
@override
Widget build(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final imageUrl = novel.coverMedium.isNotEmpty
      ? novel.coverMedium
      : novel.coverThumbnail.isNotEmpty
      ? novel.coverThumbnail
      : novel.coverLarge;
  final enabled = onTap != null;

  return Semantics(
    label: novel.title,
    button: enabled,
    enabled: enabled ? true : null,
    onTap: onTap,
    excludeSemantics: true,
    child: RepaintBoundary(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return NovelCover(
                    key: const ValueKey('catalog-tile-cover'),
                    title: novel.title,
                    imageUrl: imageUrl,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    borderRadius: 18,
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              novel.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (novel.statusLabel.isNotEmpty)
                  StatusBadge(
                    key: const ValueKey('catalog-tile-status'),
                    label: novel.statusLabel,
                  ),
                Text(
                  novel.chaptersCount > 0
                      ? '${novel.chaptersCount} فصل'
                      : 'عدد الفصول غير متاح',
                  key: const ValueKey('catalog-tile-chapters'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
```

Do not change `NovelPosterCard`; Home and other surfaces continue using it.

- [ ] **Step 4: Verify normal and 200% text tile layouts**

Add this data-driven layout test and helper:

```dart
for (final (width, height, textScale) in const [
  (140.0, 258.0, 1.0),
  (176.0, 296.0, 1.0),
  (140.0, 328.0, 2.0),
  (176.0, 366.0, 2.0),
]) {
  testWidgets(
    'catalog tile fits ${width.toInt()}px at ${textScale.toInt()}x text',
    (tester) async {
      await _pumpTile(
        tester,
        novel: _narrowStatsNovel,
        size: Size(width, height),
        textScaler: TextScaler.linear(textScale),
      );

      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpTile(
  WidgetTester tester, {
  required CatalogNovel novel,
  required Size size,
  TextScaler textScaler = TextScaler.noScaling,
  VoidCallback? onTap,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: Scaffold(
            body: SizedBox.fromSize(
              size: size,
              child: CatalogNovelTile(novel: novel, onTap: onTap),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

Run:

```powershell
dart format lib/features/catalog/presentation/widgets/catalog_novel_tile.dart test/features/catalog/catalog_novel_tile_test.dart
flutter test --no-pub test/features/catalog/catalog_novel_tile_test.dart
```

Expected: PASS with no `RenderFlex` overflow.

- [ ] **Step 5: Record the checkpoint**

Commit `feat: add compact catalog novel cards` only if the complete tile and test diffs are isolated; otherwise leave them unstaged.

---

### Task 3: Make the grid compact, centered, and loading-state consistent

**Files:**
- Modify: `lib/features/catalog/presentation/catalog_screen.dart`
- Modify: `test/features/catalog/catalog_discovery_test.dart`

**Interfaces:**
- Produces: `_catalogColumnCount(double width)` returning 2–5.
- Produces: `_catalogHorizontalPadding(double width)` enforcing 16-pixel minimum and 900-pixel maximum grid width.
- Produces: `_catalogTileExtent(BuildContext context, double gridWidth, int columns)` accounting for cover ratio and text scale.

- [ ] **Step 1: Add failing geometry and loading-shape tests**

Use these cases in `catalog_discovery_test.dart`:

```dart
for (final (width, expectedColumns) in const [
  (320.0, 2),
  (390.0, 2),
  (600.0, 4),
  (840.0, 5),
  (1200.0, 5),
]) {
  testWidgets('compact catalog uses $expectedColumns columns at $width', (
    tester,
  ) async {
    await _pumpCatalog(tester, size: Size(width, 1200));

    final grid = tester.widget<SliverGrid>(
      find.byKey(const ValueKey('catalog-sliver-grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    final tileWidth = tester.getSize(find.byType(CatalogNovelTile).first).width;

    expect(delegate.crossAxisCount, expectedColumns);
    expect(tileWidth, inInclusiveRange(132, 176));
    expect(tester.takeException(), isNull);
  });
}

testWidgets('catalog loading state uses a compact poster grid skeleton', (
  tester,
) async {
  await _pumpCatalog(
    tester,
    catalogRepository: const _LoadingCatalogRepository(),
  );

  expect(find.byKey(const ValueKey('catalog-grid-skeleton')), findsOneWidget);
  expect(find.byKey(const ValueKey('catalog-skeleton-card-0')), findsOneWidget);
  expect(find.byType(ListView), findsNothing);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Run the geometry tests and verify red**

Run:

```powershell
flutter test --no-pub test/features/catalog/catalog_discovery_test.dart --plain-name "compact catalog uses"
flutter test --no-pub test/features/catalog/catalog_discovery_test.dart --plain-name "catalog loading state uses a compact poster grid skeleton"
```

Expected: FAIL because the old grid has no 900-pixel cap and loading uses a vertical list skeleton.

- [ ] **Step 3: Calculate grid geometry from actual sliver constraints**

Replace the current outer width decision with one `SliverLayoutBuilder`:

```dart
SliverLayoutBuilder(
  builder: (context, constraints) {
    final horizontalPadding = _catalogHorizontalPadding(
      constraints.crossAxisExtent,
    );
    final gridWidth = constraints.crossAxisExtent - horizontalPadding * 2;
    final columns = _catalogColumnCount(gridWidth);
    final tileExtent = _catalogTileExtent(context, gridWidth, columns);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverGrid(
        key: const ValueKey('catalog-sliver-grid'),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
          mainAxisExtent: tileExtent,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final novel = result.items[index];
            return CatalogNovelTile(
              novel: novel,
              onTap: novel.manifest.isEmpty
                  ? null
                  : () => _openNovelDetails(novel.manifest),
            );
          },
          childCount: result.items.length,
        ),
      ),
    );
  },
),
```

Use:

```dart
const _catalogGridSpacing = 10.0;
const _catalogMinimumCardWidth = 132.0;
const _catalogMaximumContentWidth = 900.0;

double _catalogHorizontalPadding(double width) {
  return math.max(16, (width - _catalogMaximumContentWidth) / 2);
}

int _catalogColumnCount(double gridWidth) {
  final fitted =
      ((gridWidth + _catalogGridSpacing) /
              (_catalogMinimumCardWidth + _catalogGridSpacing))
          .floor();
  return fitted.clamp(2, 5);
}

double _catalogTileExtent(
  BuildContext context,
  double gridWidth,
  int columns,
) {
  final cardWidth =
      (gridWidth - (columns - 1) * _catalogGridSpacing) / columns;
  const compactCoverAspectRatio = 0.78;
  final coverHeight = cardWidth / compactCoverAspectRatio;
  final scaler = MediaQuery.textScalerOf(context);
  final titleHeight = scaler.scale(14) * 2 * 1.2;
  final metadataHeight = scaler.scale(12) * 1.25;
  return coverHeight + titleHeight + metadataHeight + 22;
}
```

Import `dart:math` as `math` and `NovelCover`. If focused tests show that the existing Cairo line metrics require more space at 200%, increase only the final details allowance and add the exact regression case; do not clip text or weaken the test.

- [ ] **Step 4: Replace the list skeleton with grid-shaped cards**

Replace `_CatalogSkeleton` with:

```dart
class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _catalogHorizontalPadding(
          constraints.crossAxisExtent,
        );
        final gridWidth = constraints.crossAxisExtent - horizontalPadding * 2;
        final columns = _catalogColumnCount(gridWidth);
        final tileExtent = _catalogTileExtent(context, gridWidth, columns);
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            24,
          ),
          sliver: SliverGrid.builder(
            key: const ValueKey('catalog-grid-skeleton'),
            itemCount: 6,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: _catalogGridSpacing,
              mainAxisSpacing: 14,
              mainAxisExtent: tileExtent,
            ),
            itemBuilder: (context, index) {
              return _CatalogSkeletonCard(
                key: ValueKey('catalog-skeleton-card-$index'),
              );
            },
          ),
        );
      },
    );
  }
}

class _CatalogSkeletonCard extends StatelessWidget {
  const _CatalogSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 14, decoration: BoxDecoration(color: color)),
        const SizedBox(height: 6),
        FractionallySizedBox(
          widthFactor: 0.62,
          alignment: AlignmentDirectional.centerStart,
          child: Container(height: 12, decoration: BoxDecoration(color: color)),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Verify error, empty, retry, RTL, and 200% text paths**

Keep the current behavioral tests for initial error recovery, empty catalog, filtered empty result, background errors, search, filters, and sort. Update the 320/200% assertion so filter and sort wrap only when required:

```dart
expect(
  tester.getTopLeft(find.byKey(const ValueKey('catalog-sort-menu'))).dy,
  greaterThanOrEqualTo(
    tester.getTopLeft(find.byKey(const ValueKey('catalog-filter-button'))).dy,
  ),
);
expect(tester.takeException(), isNull);
```

Run:

```powershell
dart format lib/features/catalog/presentation/catalog_screen.dart test/features/catalog/catalog_discovery_test.dart
flutter test --no-pub test/features/catalog
```

Expected: PASS.

- [ ] **Step 6: Record the checkpoint**

Commit `feat: make catalog grid compact and adaptive` only if the complete file diffs are isolated; otherwise leave them unstaged.

---

### Task 4: Add Library golden coverage and update the manual test plan

**Files:**
- Modify: `test/goldens/phase4_surfaces_golden_test.dart`
- Create: `test/goldens/goldens/phase4_catalog_galaxyNoir_320.png`
- Create: `test/goldens/goldens/phase4_catalog_galaxyNoir_600.png`
- Create: `test/goldens/goldens/phase4_catalog_galaxyNoir_840.png`
- Create: `test/goldens/goldens/phase4_catalog_starlightPaper_320.png`
- Create: `test/goldens/goldens/phase4_catalog_starlightPaper_600.png`
- Create: `test/goldens/goldens/phase4_catalog_starlightPaper_840.png`
- Modify: `docs/manual_test_plan.md`

**Interfaces:**
- Adds `_GoldenGroup.catalog`.
- Consumes: existing `FakeCatalogRepository`, `CatalogScreen`, `AppTheme.dark()`, and `AppTheme.light()`.

- [ ] **Step 1: Add the Catalog golden surface**

Import `CatalogScreen`, add `catalog` to `_GoldenGroup`, and add this switch branch:

```dart
_GoldenGroup.catalog => Scaffold(
  appBar: AppBar(title: const Text('المكتبة')),
  body: const CatalogScreen(),
),
```

- [ ] **Step 2: Generate the six baselines**

Run:

```powershell
flutter test --no-pub test/goldens/phase4_surfaces_golden_test.dart --update-goldens --plain-name "catalog"
```

Expected: six new files for both themes at 320, 600, and 840.

- [ ] **Step 3: Inspect every new image**

Open all six images and verify:

- Search precedes the two compact tools.
- No large Rankings button or repeated `مكتبة الروايات` heading appears.
- Cards show compact title, status, and chapter count.
- Dark mode matches Deep Purple Night and light mode remains semantic and legible.
- Cards do not grow excessively at 600 or 840.
- No clipped Arabic labels, stripes, or unbounded empty gaps appear.

If an image exposes a layout defect, add a focused widget regression test before changing production code, then regenerate only the Catalog baselines.

- [ ] **Step 4: Update the manual Library checks**

Change `docs/manual_test_plan.md` Library expectations to:

```markdown
- يظهر عنوان `المكتبة` في الشريط العلوي دون عنوان كبير مكرر داخل المحتوى.
- يظهر حقل بحث مدمج ثم زرا `كل التصنيفات` و`آخر تحديث`.
- لا يظهر اختصار ترتيب كبير داخل المكتبة؛ شاشة `الترتيب` متاحة من شريط التنقل الرئيسي.
- تعرض الشبكة بطاقات مدمجة فيها الغلاف والعنوان والحالة وعدد الفصول فقط.
- لا تعرض بطاقة المكتبة عدد المشاهدات.
- عند تكبير النص تلتف أدوات التصنيف والترتيب دون قص أو تجاوز.
```

Retain the existing search, filter, sort, empty, and retry procedures that still match production behavior.

- [ ] **Step 5: Run golden and documentation verification**

Run:

```powershell
flutter test --no-pub test/goldens/phase4_surfaces_golden_test.dart
rg -n "catalog-open-rankings|مكتبة الروايات|مشاهدة" lib/features/catalog test/features/catalog docs/manual_test_plan.md
git diff --check -- test/goldens/phase4_surfaces_golden_test.dart docs/manual_test_plan.md
```

Expected: all golden tests pass; production Catalog has no Rankings shortcut, repeated body heading, or views metadata. Any remaining `مشاهدة` match must belong to a sort label or an explicitly negative test/documentation assertion.

- [ ] **Step 6: Record the checkpoint**

Commit `test: cover compact catalog visuals` only if the golden harness and documentation diffs are isolated; otherwise leave them unstaged.

---

### Task 5: Complete quality gates and build verification

**Files:**
- Review all files changed in Tasks 1–4.

**Interfaces:**
- Consumes: project formatter, analyzer, Flutter test runner, Android debug build.
- Produces: a verified debug APK and an evidence-backed completion report.

- [ ] **Step 1: Run focused catalog and shell tests**

```powershell
flutter test --no-pub test/features/catalog test/features/shell test/widget_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run the full phase 4 golden suite**

```powershell
flutter test --no-pub test/goldens/phase4_surfaces_golden_test.dart
```

Expected: PASS for all existing surfaces plus six Catalog cases.

- [ ] **Step 3: Run static analysis**

```powershell
flutter analyze --no-pub
```

Expected: `No issues found!`

- [ ] **Step 4: Scan forbidden and obsolete paths**

```powershell
rg -n "features/downloads|DownloadsScreen|DownloadManager|catalog-open-rankings|onOpenRankings" lib/features/catalog test/features/catalog
rg -n "HomeFeaturedNovel|HomeRankingsSection" lib/features/catalog
```

Expected: no matches.

- [ ] **Step 5: Run diff hygiene**

```powershell
git diff --check -- lib/features/catalog test/features/catalog test/features/shell test/goldens docs/manual_test_plan.md
```

Expected: exit code 0. Line-ending warnings are informational; whitespace errors are not allowed.

- [ ] **Step 6: Build Android debug APK**

```powershell
flutter build apk --debug --no-pub
```

Expected: `Built build\app\outputs\flutter-apk\app-debug.apk`.

- [ ] **Step 7: Final clean-code, test, and docs guard pass**

Review only the task diff. Remove unused imports and dead Rankings code; verify no generic shared component was changed unnecessarily; confirm tests assert behavior rather than internal helper calls; verify every updated manual-test claim against its widget key or production copy.

- [ ] **Step 8: Final checkpoint**

If all task diffs are isolated, commit with `feat: redesign compact catalog`. If any file contains earlier user changes that cannot be separated safely, leave the implementation unstaged and report that decision.
