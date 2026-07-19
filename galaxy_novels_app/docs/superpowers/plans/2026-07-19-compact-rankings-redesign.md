# Compact Rankings Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Do not use subagents; the user explicitly prohibited them. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the oversized horizontal rankings cards with a compact adaptive awards podium, a continuous rankings table, and a matching loading skeleton.

**Architecture:** Keep repository loading and navigation in `RankingsScreen`. Split the successful surface into a compact header, an adaptive `RankingsPodium`, and lazy table rows; share rank badges and metric atoms between the horizontal podium, accessible vertical podium, and table.

**Tech Stack:** Flutter, Dart, Material, `flutter_test`, golden tests.

## Global Constraints

- Do not use subagents.
- Do not add filters, API requests, repositories, or model fields.
- Preserve repository order and derive rank numbers from list position.
- Show only title, compact views, optional rating, and a non-empty status label; never show chapter count on the redesigned rankings surface.
- Keep interactive targets at least 44×44 logical pixels.
- Use `AppThemeTokens` for dark/light colors; rank must remain readable without depending on medal color.
- Keep the normal narrow layout horizontal, but switch the podium to a vertical medal list when text scale is at least `1.6` or available width is below `300`.
- Verify widths 320, 600, and 840, 200% text, and short landscape.
- Preserve unrelated dirty-worktree changes. Before every commit, inspect the staged diff and skip the commit if it would capture unrelated pre-existing edits.

---

## File Map

- Modify `lib/features/rankings/presentation/rankings_screen.dart`: use the rankings-specific loading skeleton while preserving error, empty, retry, and navigation behavior.
- Modify `lib/features/rankings/presentation/widgets/rankings_header.dart`: replace the large statistics card with the approved compact title, period chip, and explanatory line.
- Create `lib/features/rankings/presentation/widgets/rankings_podium.dart`: render 2–1–3 horizontal awards and the accessible vertical fallback.
- Delete `lib/features/rankings/presentation/widgets/top_rankings_strip.dart`: remove the superseded oversized horizontal strip.
- Modify `lib/features/rankings/presentation/widgets/ranking_atoms.dart`: provide medal-aware rank badges and reusable views/rating metrics.
- Modify `lib/features/rankings/presentation/widgets/ranking_list_row.dart`: render a compact continuous-table row instead of delegating to `NovelListItem`.
- Modify `lib/features/rankings/presentation/widgets/rankings_content.dart`: compose the compact header, podium, and lazily rendered continuous table.
- Modify `lib/features/rankings/presentation/widgets/ranking_formatters.dart`: remove chapter counts from rankings semantics and provide optional rating text.
- Create `lib/features/rankings/presentation/widgets/rankings_loading_state.dart`: mirror the new header, podium, and rows with shared `AppSkeleton` blocks.
- Modify `test/features/rankings/rankings_discovery_test.dart`: define the new content, interaction, accessibility, adaptive, partial-data, and loading contracts.
- Modify `test/widget_test.dart`: update integration expectations from the old header and poster/list components.
- Modify `test/goldens/phase4_surfaces_golden_test.dart`: add a deterministic rankings group and fixture repository.
- Create six `test/goldens/goldens/phase4_rankings_{galaxyNoir,starlightPaper}_{320,600,840}.png` baselines.

### Task 1: Lock the compact content contract and formatter semantics

**Files:**
- Modify: `test/features/rankings/rankings_discovery_test.dart`
- Modify: `lib/features/rankings/presentation/widgets/ranking_formatters.dart`

**Interfaces:**
- Consumes: `CatalogNovel`, `compactRankingNumber`, and source list order.
- Produces: `rankingRatingLabel(CatalogNovel) -> String?` and a chapter-free `rankingSemanticLabel(CatalogNovel, int) -> String`.

- [ ] **Step 1: Add a focused formatter test before changing production code**

Import `ranking_formatters.dart` and add:

```dart
test('ranking semantic label contains only approved metrics', () {
  final label = rankingSemanticLabel(_rankings.items.first, 1);

  expect(
    label,
    'الأولى، الترتيب 1، 1.5K مشاهدة، التقييم 4.8 من 5',
  );
  expect(label, isNot(contains('فصل')));
});
```

- [ ] **Step 2: Change accessibility expectations to exclude chapter counts**

Use these semantic labels in the existing enabled/disabled tests:

```dart
'الأولى، الترتيب 1، 1.5K مشاهدة، التقييم 4.8 من 5'
'الثانية، الترتيب 2، 1.2K مشاهدة'
'الرابعة، الترتيب 4، 900 مشاهدة، التقييم 4.1 من 5'
```

Keep the existing button/enabled/tap-action assertions unchanged.

- [ ] **Step 3: Run the focused formatter test and verify RED**

Run:

```powershell
flutter test test/features/rankings/rankings_discovery_test.dart --plain-name "ranking semantic label contains only approved metrics"
```

Expected: FAIL because the current semantic label still includes `12 فصل`.

- [ ] **Step 4: Implement chapter-free rating and semantic formatters**

In `ranking_formatters.dart`, remove `rankingSubtitle` if no caller remains and add:

```dart
String? rankingRatingLabel(CatalogNovel novel) {
  if (novel.ratingAverage <= 0) return null;
  return novel.ratingAverage.toStringAsFixed(1);
}

String rankingSemanticLabel(CatalogNovel novel, int rank) {
  final rating = rankingRatingLabel(novel);
  final ratingText = rating == null ? '' : '، التقييم $rating من 5';
  return '${novel.title}، الترتيب $rank، '
      '${compactRankingNumber(novel.views)} مشاهدة$ratingText';
}
```

- [ ] **Step 5: Run formatter and interaction semantics tests**

Run:

```powershell
flutter test test/features/rankings/rankings_discovery_test.dart --plain-name "ranking semantic label contains only approved metrics"
flutter test test/features/rankings/rankings_discovery_test.dart --plain-name "metrics and interaction semantics"
```

Expected: the formatter test plus top and list semantic tests PASS with no chapter count in accessibility labels. Visible chapter metadata remains unchanged until Task 3.

- [ ] **Step 6: Commit only if the staged diff is isolated**

Run:

```powershell
git add -- lib/features/rankings/presentation/widgets/ranking_formatters.dart test/features/rankings/rankings_discovery_test.dart
git diff --cached --check
git diff --cached --name-only
git commit -m "test: define compact rankings contract"
```

Expected: only the formatter and rankings test are staged. If existing overlapping edits cannot be isolated, unstage and continue without committing.

### Task 2: Build the compact header and adaptive awards podium

**Files:**
- Modify: `lib/features/rankings/presentation/widgets/rankings_header.dart`
- Modify: `lib/features/rankings/presentation/widgets/ranking_atoms.dart`
- Create: `lib/features/rankings/presentation/widgets/rankings_podium.dart`
- Delete: `lib/features/rankings/presentation/widgets/top_rankings_strip.dart`
- Modify: `lib/features/rankings/presentation/widgets/rankings_content.dart`
- Test: `test/features/rankings/rankings_discovery_test.dart`

**Interfaces:**
- Consumes: `rankingPeriodLabel`, `rankingCoverUrl`, `rankingRatingLabel`, `rankingSemanticLabel`, and `List<CatalogNovel>` in source order.
- Produces: `RankingsPodium({required List<CatalogNovel> novels, required ValueChanged<String> onOpenNovel})` with stable `ranking-top-pick-N` and layout keys.

- [ ] **Step 1: Add failing order and partial-data tests**

Replace the old `rankings preserve source ranks and use shared novel components` test with:

```dart
testWidgets('rankings show compact header and source-order podium', (
  tester,
) async {
  await _pumpLoadedRankings(tester, size: const Size(960, 1000));

  expect(find.text('ترتيب الروايات'), findsOneWidget);
  expect(find.text('هذا الشهر'), findsOneWidget);
  expect(find.text('الأعلى مشاهدة داخل المجرة'), findsOneWidget);
  expect(find.text('إحصاء الروايات'), findsNothing);
  expect(
    find.byKey(const ValueKey('rankings-podium-horizontal')),
    findsOneWidget,
  );
  for (var rank = 1; rank <= 3; rank += 1) {
    expect(find.byKey(ValueKey('ranking-top-pick-$rank')), findsOneWidget);
  }
  expect(find.byKey(const ValueKey('ranking-list-row-4')), findsOneWidget);
});
```

Add the order and partial-data tests:

```dart
testWidgets('horizontal podium places first between second and third', (
  tester,
) async {
  await _pumpLoadedRankings(tester, size: const Size(390, 1000));

  final secondX = tester.getCenter(
    find.byKey(const ValueKey('ranking-top-pick-2')),
  ).dx;
  final firstX = tester.getCenter(
    find.byKey(const ValueKey('ranking-top-pick-1')),
  ).dx;
  final thirdX = tester.getCenter(
    find.byKey(const ValueKey('ranking-top-pick-3')),
  ).dx;

  expect(secondX, greaterThan(firstX));
  expect(firstX, greaterThan(thirdX));
  expect(
    tester.getSize(find.byKey(const ValueKey('ranking-top-pick-1'))).height,
    greaterThan(
      tester.getSize(find.byKey(const ValueKey('ranking-top-pick-2'))).height,
    ),
  );
});

testWidgets('podium renders only available novels without empty places', (
  tester,
) async {
  await _pumpLoadedRankings(
    tester,
    rankings: RankingsData(
      period: _rankings.period,
      items: _rankings.items.take(2).toList(growable: false),
    ),
  );

  expect(find.byKey(const ValueKey('ranking-top-pick-1')), findsOneWidget);
  expect(find.byKey(const ValueKey('ranking-top-pick-2')), findsOneWidget);
  expect(find.byKey(const ValueKey('ranking-top-pick-3')), findsNothing);
  expect(find.byKey(const ValueKey('rankings-table')), findsNothing);
});
```

Replace both old horizontal-strip 200% tests with:

```dart
testWidgets('normal narrow rankings keep the horizontal podium', (
  tester,
) async {
  await _pumpLoadedRankings(tester, size: const Size(320, 1000));

  expect(
    find.byKey(const ValueKey('rankings-podium-horizontal')),
    findsOneWidget,
  );
  expect(tester.takeException(), isNull);
});

testWidgets('podium switches to vertical medals at 200 percent text', (
  tester,
) async {
  await _pumpLoadedRankings(
    tester,
    size: const Size(320, 1200),
    textScaler: const TextScaler.linear(2),
  );

  expect(
    find.byKey(const ValueKey('rankings-podium-vertical')),
    findsOneWidget,
  );
  expect(
    find.byKey(const ValueKey('rankings-podium-horizontal')),
    findsNothing,
  );
  for (final textElement in find.byType(Text).evaluate()) {
    final renderObject = textElement.renderObject;
    if (renderObject is RenderParagraph) {
      expect(renderObject.didExceedMaxLines, isFalse);
    }
  }
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Verify the podium tests fail**

Run:

```powershell
flutter test test/features/rankings/rankings_discovery_test.dart --plain-name "horizontal podium places first between second and third"
flutter test test/features/rankings/rankings_discovery_test.dart --plain-name "podium renders only available novels without empty places"
flutter test test/features/rankings/rankings_discovery_test.dart --plain-name "podium switches to vertical medals"
```

Expected: FAIL because `RankingsPodium` and the stable layout keys do not exist.

- [ ] **Step 3: Replace the large header with the compact approved header**

Reduce `RankingsHeader` to `periodLabel` only and render:

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: tokens.accent,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ترتيب الروايات',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _PeriodChip(label: periodLabel),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'الأعلى مشاهدة داخل المجرة',
        style: theme.textTheme.bodySmall?.copyWith(
          color: tokens.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  ),
)
```

Delete `_HeaderMetric`; keep `_PeriodChip` compact with a 28-pixel minimum height and semantic theme colors.

- [ ] **Step 4: Extend shared ranking atoms for medal colors and metrics**

Define the medal palette in `ranking_atoms.dart`:

```dart
Color rankingMedalColor(AppThemeTokens tokens, int rank) => switch (rank) {
  1 => tokens.gold,
  2 => tokens.textSecondary,
  3 => Color.lerp(tokens.warning, tokens.danger, 0.45)!,
  _ => tokens.accent,
};
```

Change `RankingRankBadge` to use `rankingMedalColor(tokens, rank)` and expose compact `featured` sizing. Keep `RankingInlineMetric` and use it once for views and once for optional rating.

- [ ] **Step 5: Implement `RankingsPodium` with horizontal and vertical builders**

Create `rankings_podium.dart` with this public structure:

```dart
class RankingsPodium extends StatelessWidget {
  const RankingsPodium({
    required this.novels,
    required this.onOpenNovel,
    super.key,
  });

  final List<CatalogNovel> novels;
  final ValueChanged<String> onOpenNovel;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = textScale >= 1.6 || constraints.maxWidth < 300;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: vertical
                ? _VerticalPodium(
                    novels: novels,
                    onOpenNovel: onOpenNovel,
                  )
                : _HorizontalPodium(
                    novels: novels,
                    onOpenNovel: onOpenNovel,
                  ),
          ),
        );
      },
    );
  }
}
```

The horizontal builder must order three items as ranks `[2, 1, 3]`, filter ranks above `novels.length`, use `Row(mainAxisAlignment: MainAxisAlignment.center)`, and give rank 1 an 8-pixel larger cover and top offset. The vertical builder must render ranks `[1, 2, 3]` as compact medal rows. Both variants must:

```dart
final onTap = novel.manifest.isEmpty
    ? null
    : () => onOpenNovel(novel.manifest);
final rating = rankingRatingLabel(novel);

Semantics(
  button: onTap != null,
  enabled: onTap != null,
  label: rankingSemanticLabel(novel, rank),
  child: Material(
    type: MaterialType.transparency,
    child: InkWell(
      key: ValueKey('ranking-top-pick-$rank'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RankingRankBadge(rank: rank, featured: rank == 1),
            const SizedBox(height: 6),
            NovelCover(
              title: novel.title,
              imageUrl: rankingCoverUrl(novel),
              width: rank == 1 ? 80 : 72,
              height: rank == 1 ? 116 : 104,
            ),
            const SizedBox(height: 6),
            Text(
              novel.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            RankingInlineMetric(
              icon: Icons.visibility_outlined,
              value: '${compactRankingNumber(novel.views)} مشاهدة',
            ),
            if (rating != null)
              RankingInlineMetric(
                icon: Icons.star_rounded,
                value: rating,
                gold: true,
              ),
            if (novel.statusLabel.trim().isNotEmpty)
              StatusBadge(label: novel.statusLabel),
          ],
        ),
      ),
    ),
  ),
)
```

The snippet defines horizontal content. Vertical rows use the same atoms in a `Row`, a 52×76 cover, and an uncapped title inside `Expanded`. Do not pass chapter count to any text or semantic label.

After the discovery tests no longer import or reference `TopRankingsStrip`, delete `top_rankings_strip.dart` and remove its import.

- [ ] **Step 6: Compose the header and podium in `RankingsContent`**

Replace `TopRankingsStrip` with:

```dart
SliverToBoxAdapter(
  child: RankingsPodium(
    novels: topNovels,
    onOpenNovel: onOpenNovel,
  ),
),
```

Construct `RankingsHeader` with only:

```dart
RankingsHeader(periodLabel: rankingPeriodLabel(rankings.period))
```

Remove the `الأكثر شهرة` section label because the podium communicates hierarchy directly.

- [ ] **Step 7: Run the podium, navigation, and semantics tests**

Run:

```powershell
dart format lib/features/rankings/presentation/widgets test/features/rankings/rankings_discovery_test.dart
flutter test test/features/rankings/rankings_discovery_test.dart --plain-name "podium"
flutter test test/features/rankings/rankings_discovery_test.dart --plain-name "ranking with a manifest opens novel details"
flutter test test/features/rankings/rankings_discovery_test.dart --plain-name "top rankings expose complete metrics and interaction semantics"
```

Expected: all selected tests PASS; an empty manifest remains non-interactive.

- [ ] **Step 8: Commit only if the staged diff is isolated**

Run:

```powershell
git add -- lib/features/rankings/presentation/widgets/rankings_header.dart lib/features/rankings/presentation/widgets/ranking_atoms.dart lib/features/rankings/presentation/widgets/rankings_podium.dart lib/features/rankings/presentation/widgets/top_rankings_strip.dart lib/features/rankings/presentation/widgets/rankings_content.dart test/features/rankings/rankings_discovery_test.dart
git diff --cached --check
git diff --cached --name-only
git commit -m "feat: add adaptive rankings podium"
```

Expected: only podium-related rankings files and their test are staged. Skip the commit if overlapping pre-existing edits cannot be isolated.

### Task 3: Build the continuous rankings table and accessible fallback

**Files:**
- Modify: `lib/features/rankings/presentation/widgets/ranking_list_row.dart`
- Modify: `lib/features/rankings/presentation/widgets/rankings_content.dart`
- Test: `test/features/rankings/rankings_discovery_test.dart`

**Interfaces:**
- Consumes: `RankingRankBadge`, `RankingInlineMetric`, `NovelCover`, `StatusBadge`, and chapter-free formatter functions.
- Produces: `RankingListRow({required int rank, required CatalogNovel novel, required bool first, required bool last, VoidCallback? onTap})` and `rankings-table`.

- [ ] **Step 1: Add the failing continuous-table test**

Add:

```dart
testWidgets('remaining ranks form one continuous bordered table', (
  tester,
) async {
  await _pumpLoadedRankings(
    tester,
    rankings: _rankingsWithEmptyListItem,
  );
  await _revealRanking(
    tester,
    find.byKey(const ValueKey('ranking-list-row-4')),
  );

  expect(find.byKey(const ValueKey('rankings-table')), findsOneWidget);
  expect(find.byKey(const ValueKey('ranking-list-row-4')), findsOneWidget);
  expect(find.byKey(const ValueKey('ranking-list-row-5')), findsOneWidget);
  expect(find.textContaining('44 فصل'), findsNothing);
});

testWidgets('rankings remain overflow free in short landscape', (
  tester,
) async {
  await _pumpLoadedRankings(tester, size: const Size(840, 420));
  await _revealRanking(
    tester,
    find.byKey(const ValueKey('ranking-list-row-4')),
  );

  expect(find.byKey(const ValueKey('ranking-list-row-4')), findsOneWidget);
  expect(tester.takeException(), isNull);
});

```

- [ ] **Step 2: Verify the new continuous-table test fails**

Run:

```powershell
flutter test test/features/rankings/rankings_discovery_test.dart --plain-name "remaining ranks form one continuous bordered table"
```

Expected: FAIL because the continuous table key and custom compact rows are not implemented.

- [ ] **Step 3: Replace `NovelListItem` with the compact rankings row**

Implement `RankingListRow` using a transparent `Material` + `InkWell`, a minimum height of 72, `NovelCover(width: 46, height: 66)`, `RankingRankBadge`, title, compact views/rating metrics, optional `StatusBadge`, and a left chevron. Do not cap the title to one line.

Use these border rules so adjacent rows read as one panel:

```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
  final side = BorderSide(color: tokens.border);
  final divider = BorderSide(
    color: tokens.border.withValues(alpha: 0.72),
  );
  final border = Border(
    top: first ? side : divider,
    right: side,
    bottom: last ? side : BorderSide.none,
    left: side,
  );
  final radius = BorderRadius.vertical(
    top: first ? const Radius.circular(8) : Radius.zero,
    bottom: last ? const Radius.circular(8) : Radius.zero,
  );
  final rating = rankingRatingLabel(novel);

  return Semantics(
    button: onTap != null,
    enabled: onTap != null,
    label: rankingSemanticLabel(novel, rank),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        border: border,
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    RankingRankBadge(rank: rank),
                    const SizedBox(width: 8),
                    NovelCover(
                      title: novel.title,
                      imageUrl: rankingCoverUrl(novel),
                      width: 46,
                      height: 66,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            novel.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              RankingInlineMetric(
                                icon: Icons.visibility_outlined,
                                value:
                                    '${compactRankingNumber(novel.views)} مشاهدة',
                              ),
                              if (rating != null)
                                RankingInlineMetric(
                                  icon: Icons.star_rounded,
                                  value: rating,
                                  gold: true,
                                ),
                              if (novel.statusLabel.trim().isNotEmpty)
                                StatusBadge(label: novel.statusLabel),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: onTap == null
                          ? tokens.textSecondary.withValues(alpha: 0.5)
                          : tokens.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
```

Use top corner radii only for `first` and bottom corner radii only for `last`. The top border on every non-first row is the visible divider.

- [ ] **Step 4: Keep the table lazy in `RankingsContent`**

Wrap the existing `SliverList` with:

```dart
SliverPadding(
  key: const ValueKey('rankings-table'),
  padding: const EdgeInsets.symmetric(horizontal: 12),
  sliver: SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        final rank = index + topNovels.length + 1;
        final novel = remainingNovels[index];
        return RankingListRow(
          key: ValueKey('ranking-list-row-$rank'),
          rank: rank,
          novel: novel,
          first: index == 0,
          last: index == remainingNovels.length - 1,
          onTap: novel.manifest.isEmpty
              ? null
              : () => onOpenNovel(novel.manifest),
        );
      },
      childCount: remainingNovels.length,
    ),
  ),
)
```

Render the `بقية الترتيب` heading only when `remainingNovels.isNotEmpty`.

- [ ] **Step 5: Run the complete rankings discovery suite**

Run:

```powershell
dart format lib/features/rankings/presentation/widgets test/features/rankings/rankings_discovery_test.dart
flutter test test/features/rankings/rankings_discovery_test.dart
```

Expected: all loading, empty, retry, ordering, enabled/disabled, navigation, semantics, adaptive, and overflow tests PASS.

- [ ] **Step 6: Commit only if the staged diff is isolated**

Run:

```powershell
git add -- lib/features/rankings/presentation/widgets/ranking_list_row.dart lib/features/rankings/presentation/widgets/rankings_content.dart test/features/rankings/rankings_discovery_test.dart
git diff --cached --check
git diff --cached --name-only
git commit -m "feat: add compact rankings table"
```

Expected: only table-related rankings files and their test are staged. Skip the commit if overlapping edits cannot be isolated.

### Task 4: Match loading state, integration tests, and golden surfaces

**Files:**
- Create: `lib/features/rankings/presentation/widgets/rankings_loading_state.dart`
- Modify: `lib/features/rankings/presentation/rankings_screen.dart`
- Modify: `test/features/rankings/rankings_discovery_test.dart`
- Modify: `test/widget_test.dart`
- Modify: `test/goldens/phase4_surfaces_golden_test.dart`
- Create: `test/goldens/goldens/phase4_rankings_galaxyNoir_320.png`
- Create: `test/goldens/goldens/phase4_rankings_galaxyNoir_600.png`
- Create: `test/goldens/goldens/phase4_rankings_galaxyNoir_840.png`
- Create: `test/goldens/goldens/phase4_rankings_starlightPaper_320.png`
- Create: `test/goldens/goldens/phase4_rankings_starlightPaper_600.png`
- Create: `test/goldens/goldens/phase4_rankings_starlightPaper_840.png`

**Interfaces:**
- Consumes: `AppSkeleton`, `RankingsScreen`, `_GoldenGroup`, and `RankingsRepository`.
- Produces: `RankingsLoadingState` keyed `rankings-loading-state` and six deterministic rankings golden baselines.

- [ ] **Step 1: Change the loading test to the approved skeleton shape**

Replace the old loading expectations with:

```dart
expect(
  find.byKey(const ValueKey('rankings-loading-state')),
  findsOneWidget,
);
expect(find.byType(AppSkeleton), findsNWidgets(5));
expect(find.text('جار تحميل الترتيب...'), findsNothing);
```

Keep the pending completer and live-loading behavior.

- [ ] **Step 2: Verify the loading test fails**

Run:

```powershell
flutter test test/features/rankings/rankings_discovery_test.dart --plain-name "rankings loading uses the shared async skeleton state"
```

Expected: FAIL because the current generic loading state has three skeletons and no rankings loading key.

- [ ] **Step 3: Implement the rankings-specific skeleton**

Create `RankingsLoadingState` as:

```dart
class RankingsLoadingState extends StatelessWidget {
  const RankingsLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'جارٍ تحميل الترتيب...',
      liveRegion: true,
      child: ListView(
        key: const ValueKey('rankings-loading-state'),
        padding: const EdgeInsets.all(12),
        children: const [
          AppSkeleton(height: 64),
          SizedBox(height: 12),
          AppSkeleton(height: 236),
          SizedBox(height: 14),
          AppSkeleton(height: 72),
          SizedBox(height: 1),
          AppSkeleton(height: 72),
          SizedBox(height: 1),
          AppSkeleton(height: 72),
        ],
      ),
    );
  }
}
```

Return `const RankingsLoadingState()` from the pending branch in `RankingsScreen`. Keep `AppAsyncState.error` and `AppEmptyState` unchanged.

- [ ] **Step 4: Update app-level rankings expectations**

In `test/widget_test.dart`, replace `إحصاء الروايات` with `ترتيب الروايات`, keep `هذا الشهر`, assert the three `ranking-top-pick-*` keys and `ranking-list-row-4`, and assert chapter-count strings are absent from the rankings screen.

- [ ] **Step 5: Add deterministic rankings data to the phase-4 golden harness**

Add `_GoldenGroup.rankings`, render:

```dart
_GoldenGroup.rankings => const Scaffold(body: RankingsScreen()),
```

Inject a `_GoldenRankingsRepository` for only that group:

```dart
rankingsRepository: group == _GoldenGroup.rankings
    ? const _GoldenRankingsRepository()
    : const FakeRankingsRepository(),
```

Implement `_GoldenRankingsRepository.loadRankings()` with four `CatalogNovel` fixtures containing distinct Arabic titles, ranks 1–4 by list order, non-empty views, mixed ratings, non-empty statuses, and manifests. Reuse existing model constructors; do not add production fixtures.

Add the model/repository imports and this deterministic fixture:

```dart
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/data/models/rankings_data.dart';
import 'package:galaxy_novels_app/data/repositories/rankings_repository.dart';

class _GoldenRankingsRepository implements RankingsRepository {
  const _GoldenRankingsRepository();

  @override
  Future<RankingsData> loadRankings() async => _goldenRankings;
}

const _goldenRankings = RankingsData(
  period: 'month',
  items: [
    CatalogNovel(
      id: 101,
      title: 'سيدة العوالم',
      originalTitle: '',
      url: '/novel/world-lady/',
      coverThumbnail: '',
      coverMedium: '',
      statusKey: 'ongoing',
      statusLabel: 'مستمرة',
      genres: [],
      chaptersCount: 88,
      ratingAverage: 4.9,
      ratingCount: 340,
      views: 24800,
      updatedAt: null,
      manifest: '/golden-rank-1.json',
    ),
    CatalogNovel(
      id: 102,
      title: 'حارس النجوم',
      originalTitle: '',
      url: '/novel/star-guard/',
      coverThumbnail: '',
      coverMedium: '',
      statusKey: 'completed',
      statusLabel: 'مكتملة',
      genres: [],
      chaptersCount: 64,
      ratingAverage: 4.7,
      ratingCount: 210,
      views: 19300,
      updatedAt: null,
      manifest: '/golden-rank-2.json',
    ),
    CatalogNovel(
      id: 103,
      title: 'بوابة السديم',
      originalTitle: '',
      url: '/novel/nebula-gate/',
      coverThumbnail: '',
      coverMedium: '',
      statusKey: 'ongoing',
      statusLabel: 'مستمرة',
      genres: [],
      chaptersCount: 51,
      ratingAverage: 0,
      ratingCount: 0,
      views: 15700,
      updatedAt: null,
      manifest: '/golden-rank-3.json',
    ),
    CatalogNovel(
      id: 104,
      title: 'رحلة إلى أندروميدا',
      originalTitle: '',
      url: '/novel/andromeda/',
      coverThumbnail: '',
      coverMedium: '',
      statusKey: 'ongoing',
      statusLabel: 'مستمرة',
      genres: [],
      chaptersCount: 42,
      ratingAverage: 4.4,
      ratingCount: 98,
      views: 9800,
      updatedAt: null,
      manifest: '/golden-rank-4.json',
    ),
  ],
);
```

- [ ] **Step 6: Run functional and integration verification before goldens**

Run:

```powershell
dart format lib/features/rankings test/features/rankings test/widget_test.dart test/goldens/phase4_surfaces_golden_test.dart
flutter test test/features/rankings/rankings_discovery_test.dart
flutter test test/widget_test.dart --plain-name "rankings"
```

Expected: all selected tests PASS with no overflow or raw repository error text.

- [ ] **Step 7: Generate only the six rankings golden images**

Run:

```powershell
flutter test --update-goldens test/goldens/phase4_surfaces_golden_test.dart --plain-name rankings
```

Expected: exactly six `phase4_rankings_*` PNG files are created or changed.

- [ ] **Step 8: Inspect representative dark/light images**

Open:

```text
test/goldens/goldens/phase4_rankings_galaxyNoir_320.png
test/goldens/goldens/phase4_rankings_starlightPaper_840.png
```

Verify: compact header, 2–1–3 podium order, gold/silver/bronze cues, first place visually stronger, one continuous table, no chapter counts, no clipping, and no excessive tablet stretching.

- [ ] **Step 9: Run final verification**

Run:

```powershell
flutter test test/features/rankings/rankings_discovery_test.dart
flutter test test/widget_test.dart --plain-name "rankings"
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name rankings
flutter analyze
flutter build apk --debug
```

Expected: all tests PASS, six rankings goldens match, analysis reports `No issues found!`, and `build/app/outputs/flutter-apk/app-debug.apk` is produced.

- [ ] **Step 10: Commit verification artifacts only if the staged diff is isolated**

Run:

```powershell
git add -- lib/features/rankings/presentation/rankings_screen.dart lib/features/rankings/presentation/widgets/rankings_loading_state.dart test/features/rankings/rankings_discovery_test.dart test/widget_test.dart test/goldens/phase4_surfaces_golden_test.dart test/goldens/goldens/phase4_rankings_galaxyNoir_320.png test/goldens/goldens/phase4_rankings_galaxyNoir_600.png test/goldens/goldens/phase4_rankings_galaxyNoir_840.png test/goldens/goldens/phase4_rankings_starlightPaper_320.png test/goldens/goldens/phase4_rankings_starlightPaper_600.png test/goldens/goldens/phase4_rankings_starlightPaper_840.png
git diff --cached --check
git diff --cached --name-only
git commit -m "test: approve compact rankings surfaces"
```

Expected: only rankings loading/integration/golden artifacts are staged. Skip the commit if overlapping pre-existing edits cannot be isolated.
