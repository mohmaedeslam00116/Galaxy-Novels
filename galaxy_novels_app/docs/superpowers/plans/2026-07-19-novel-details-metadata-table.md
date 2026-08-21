# Novel Details Metadata Table Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 2×2 novel metadata grid with one accessible four-row information table whose final rating row keeps the existing interaction behavior.

**Architecture:** Extract metadata rendering from `NovelDetailsHeader` into a focused `NovelDetailsMetadataTable`. Keep the rating state mapping in a dedicated `NovelDetailsRatingRow`, while the table owns its shared surface, separators, clipping, and row order.

**Tech Stack:** Flutter, Dart, Material, flutter_test, golden_toolkit-style image comparisons already present in the repository.

## Global Constraints

- Execute inline in this session; the user explicitly prohibited subagents.
- Preserve all existing rating, authentication, retry, chapter, VIP, favorite, and comments behavior.
- Keep the approved Stitch dark colors and the existing light-theme mapping.
- Do not add or restore any download UI or logic.
- Support RTL, widths 320/600/840, and 200% text scaling.
- Preserve unrelated dirty-worktree changes.

---

### Task 1: Lock the metadata table contract with widget tests

**Files:**
- Modify: `test/features/novel_details/novel_details_widgets_test.dart`
- Modify: `test/features/novel_details/novel_details_responsive_test.dart`

**Interfaces:**
- Consumes: `NovelDetailsHeader` and its current constructor.
- Produces: stable keys `novel-details-metadata-table`, `novel-metadata-author`, `novel-metadata-translator`, `novel-metadata-chapters`, and `novel-details-rating-action`.

- [ ] **Step 1: Replace the grid assertion with a four-row table assertion**

```dart
final table = find.byKey(const ValueKey('novel-details-metadata-table'));
expect(table, findsOneWidget);
expect(find.byKey(const ValueKey('novel-details-metadata-grid')), findsNothing);
for (final key in const [
  'novel-metadata-author',
  'novel-metadata-translator',
  'novel-metadata-chapters',
  'novel-details-rating-action',
]) {
  expect(find.descendant(of: table, matching: find.byKey(ValueKey(key))), findsOneWidget);
}
```

- [ ] **Step 2: Assert the approved text and rating behavior remain observable**

```dart
expect(find.text('كاتب الاختبار'), findsOneWidget);
expect(find.text('غير متوفر'), findsOneWidget);
expect(find.text('تقييمك: 4 من 5'), findsOneWidget);
expect(find.byTooltip('اضغط لإضافة أو تعديل تقييمك'), findsOneWidget);
```

- [ ] **Step 3: Update responsive assertions to target the table**

```dart
expect(find.byKey(const ValueKey('novel-details-metadata-table')), findsOneWidget);
expect(tester.takeException(), isNull);
```

- [ ] **Step 4: Run the focused tests and verify red**

Run: `flutter test --no-pub test/features/novel_details/novel_details_widgets_test.dart test/features/novel_details/novel_details_responsive_test.dart`

Expected: FAIL because `novel-details-metadata-table` and the row keys do not exist and the legacy grid still renders.

---

### Task 2: Implement the shared metadata card and interactive rating row

**Files:**
- Create: `lib/features/novel_details/presentation/widgets/novel_details_metadata_table.dart`
- Create: `lib/features/novel_details/presentation/widgets/novel_details_rating_row.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_details_header.dart`
- Delete: `lib/features/novel_details/presentation/widgets/novel_details_rating_tile.dart`

**Interfaces:**
- Consumes: `NovelDetails`, `NovelEngagementState`, `NovelDetailsVisualTokens`, and the existing callbacks.
- Produces: `NovelDetailsMetadataTable` and `NovelDetailsRatingRow` with the same state-to-action mapping as the current rating tile.

- [ ] **Step 1: Add the shared table component**

```dart
class NovelDetailsMetadataTable extends StatelessWidget {
  const NovelDetailsMetadataTable({
    required this.details,
    required this.chaptersCount,
    required this.engagementState,
    required this.onRate,
    required this.onSignIn,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = NovelDetailsVisualTokens.of(context);
    return Container(
      key: const ValueKey('novel-details-metadata-table'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Column(children: [
        NovelDetailsMetadataRow(key: const ValueKey('novel-metadata-author'), icon: Icons.person_outline_rounded, label: 'الكاتب', value: _orUnavailable(details.author)),
        const _MetadataDivider(),
        NovelDetailsMetadataRow(key: const ValueKey('novel-metadata-translator'), icon: Icons.translate_rounded, label: 'المترجم', value: _orUnavailable(details.translator)),
        const _MetadataDivider(),
        NovelDetailsMetadataRow(key: const ValueKey('novel-metadata-chapters'), icon: Icons.menu_book_outlined, label: 'عدد الفصول', value: '$chaptersCount'),
        const _MetadataDivider(),
        NovelDetailsRatingRow(average: details.ratingAverage, ratingCount: details.ratingCount, engagementState: engagementState, onRate: onRate, onSignIn: onSignIn, onRetry: onRetry),
      ]),
    );
  }
}
```

- [ ] **Step 2: Make ordinary rows readable and responsive**

```dart
class NovelDetailsMetadataRow extends StatelessWidget {
  const NovelDetailsMetadataRow({required this.icon, required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          _MetadataIcon(icon: icon),
          const SizedBox(width: 12),
          SizedBox(width: 88, child: Text(label, maxLines: 1)),
          const SizedBox(width: 10),
          Expanded(child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}
```

Use this exact responsive content branch inside the padded row:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final stackText = constraints.maxWidth < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.5;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _MetadataIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: stackText
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 2, child: Text(label, maxLines: 1)),
                    const SizedBox(width: 10),
                    Expanded(flex: 3, child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
        ),
      ],
    );
  },
)
```

- [ ] **Step 3: Refactor the rating tile into the final table row**

```dart
class NovelDetailsRatingRow extends StatelessWidget {
  const NovelDetailsRatingRow({
    required this.average,
    required this.ratingCount,
    required this.engagementState,
    required this.onRate,
    required this.onSignIn,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final action = _action;
    return Semantics(
      button: true,
      enabled: action != null,
      onTap: action,
      child: InkWell(
        key: const ValueKey('novel-details-rating-action'),
        onTap: action,
        child: Ink(
          color: NovelDetailsVisualTokens.of(context).primary.withValues(alpha: 0.08),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 78),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          const Expanded(child: Text('التقييم')),
                          Tooltip(
                            key: const ValueKey('novel-details-rating-help'),
                            message: 'اضغط لإضافة أو تعديل تقييمك',
                            child: const Icon(Icons.help_outline_rounded),
                          ),
                        ]),
                        Text(average > 0 ? average.toStringAsFixed(1) : '—'),
                        Text(_personalLabel, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (ratingCount > 0) Text(_ratingCountLabel(ratingCount)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Move the current `_action`, `_personalLabel`, and `_ratingCountLabel` implementations unchanged into `novel_details_rating_row.dart`. Loading and submitting therefore remain disabled; guest, failure, and ready continue to map to sign-in, retry, and rate respectively.

- [ ] **Step 4: Replace `_MetadataGrid` in the header**

```dart
NovelDetailsMetadataTable(
  details: details,
  chaptersCount: chaptersCount,
  engagementState: engagementState,
  onRate: onRate,
  onSignIn: onSignIn,
  onRetry: onRetryEngagement,
)
```

Delete `_MetadataGrid`, `_InformationTile`, and the local `_orUnavailable` copy from `novel_details_header.dart` after their responsibility moves into the table file.

- [ ] **Step 5: Format and run the focused tests**

Run: `dart format lib/features/novel_details/presentation/widgets/novel_details_header.dart lib/features/novel_details/presentation/widgets/novel_details_metadata_table.dart lib/features/novel_details/presentation/widgets/novel_details_rating_row.dart test/features/novel_details/novel_details_widgets_test.dart test/features/novel_details/novel_details_responsive_test.dart`

Run: `flutter test --no-pub test/features/novel_details/novel_details_widgets_test.dart test/features/novel_details/novel_details_responsive_test.dart`

Expected: PASS with no overflow or semantics failures.

---

### Task 3: Refresh visual references and complete verification

**Files:**
- Modify: `test/goldens/goldens/phase4_novelDetails_galaxyNoir_320.png`
- Modify: `test/goldens/goldens/phase4_novelDetails_galaxyNoir_600.png`
- Modify: `test/goldens/goldens/phase4_novelDetails_galaxyNoir_840.png`
- Modify: `test/goldens/goldens/phase4_novelDetails_starlightPaper_320.png`
- Modify: `test/goldens/goldens/phase4_novelDetails_starlightPaper_600.png`
- Modify: `test/goldens/goldens/phase4_novelDetails_starlightPaper_840.png`
- Modify: `docs/manual_test_plan.md`

**Interfaces:**
- Consumes: the implemented table layout.
- Produces: reviewed goldens and updated manual acceptance wording.

- [ ] **Step 1: Generate only the novel-details golden group**

Run: `flutter test --no-pub --update-goldens test/goldens/phase4_surfaces_golden_test.dart --plain-name novelDetails`

Expected: six updated images for dark/light at 320/600/840.

- [ ] **Step 2: Inspect the six images**

Verify one shared card, four ordered rows, readable long values, purple rating row, no download action, and centered content at 840.

- [ ] **Step 3: Update the manual test plan wording**

Replace the 2×2 grid expectation with:

```markdown
- تظهر بطاقة معلومات رأسية بأربعة صفوف: الكاتب، المترجم، عدد الفصول، والتقييم.
- يكون التقييم هو الصف الأخير، والصف كاملًا قابل للضغط لإضافة أو تعديل تقييم المستخدم.
```

- [ ] **Step 4: Run static and focused verification**

Run: `flutter analyze --no-pub`

Run: `flutter test --no-pub test/features/novel_details test/features/novel_engagement/novel_engagement_widgets_test.dart test/features/favorites/favorites_integration_test.dart test/features/phase3/phase3_reading_surfaces_test.dart test/widget_test.dart test/goldens/phase4_surfaces_golden_test.dart`

Expected: analyzer clean and all selected tests pass.

- [ ] **Step 5: Verify removed UI and whitespace**

Run: `rg -n "novel-details-metadata-grid|NovelDetailsRatingTile|Icons\\.download" lib/features/novel_details`

Expected: no matches.

Run: `git diff --check`

Expected: exit code 0.

- [ ] **Step 6: Build the installed-platform artifact**

Run: `flutter build apk --debug --no-pub`

Expected: `build/app/outputs/flutter-apk/app-debug.apk` is produced successfully.
