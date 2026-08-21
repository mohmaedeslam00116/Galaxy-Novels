# Stitch Novel Details Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Do not use subagents; the user explicitly requested inline execution only. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** إعادة بناء شاشة تفاصيل الرواية في Flutter وفق تصميم `stitch_/_2` مع ألوان Stitch الداكنة، شبكة معلومات وتقييم تفاعلي، ومن دون إعادة أي جزء من ميزة التنزيلات.

**Architecture:** تبقى طبقات البيانات ووحدات التحكم الحالية دون تغيير. يُقسّم العرض إلى رموز بصرية محلية للشاشة، رأس رواية وشبكة معلومات، بطاقة ملخص وتبويبات، وقسم فصول قابل للبحث والترتيب؛ تستقبل هذه المكونات الحالة والـcallbacks من `NovelDetailsScreen` ولا تحتوي منطق أعمال جديدًا.

**Tech Stack:** Flutter، Dart، Material 3، `ValueListenableBuilder`، `flutter_test`، اختبارات Golden الحالية.

## Global Constraints

- المصدر البصري هو `../stitch_/_2/screen.png` و`../stitch_/_2/code.html`.
- ألوان الوضع الداكن للشاشة: الخلفية `#131313`، السطح `#201F1F`، السطح المرتفع `#2A2A2A`، البنفسجي `#9D4EDD`، النص الأساسي `#ECE9E8`، النص الثانوي `#D9CEDC`، والحدود `#4D4353`.
- لا تغيّر رموز `AppTheme` العامة ولا مظهر الشاشات الأخرى؛ استخدم رموزًا محلية لشاشة التفاصيل.
- الوضع الفاتح يستخدم رموز `Starlight Paper` مع بنفسجي إجراء واضح وتباين WCAG AA.
- شبكة المعلومات: الكاتب، المترجم، عدد الفصول المرئية، والتقييم التفاعلي. لا تعرض سنة الإصدار ولا تشتقها من `updatedAt`.
- احتفظ بالمفضلة والقراءة والتقييم الشخصي والتعليقات والبحث والترتيب وVIP وسلوك المصادقة الحالي.
- لا تضف API أو dependency أو عقد repository جديدة.
- لا تضف زرًا أو رمزًا أو callback أو مساحة محجوزة للتنزيلات.
- حافظ على تعديلات المستخدم الموجودة في worktree، ولا تنسّق أو تلتزم بملفات خارج نطاق المهمة.
- لا تستخدم subagents في أي خطوة.

---

## File Map

- Create: `lib/features/novel_details/presentation/novel_details_visual_tokens.dart` — لوحة الشاشة المحلية للثيمين.
- Create: `lib/features/novel_details/presentation/widgets/novel_details_rating_tile.dart` — خلية التقييم العام/الشخصي التفاعلية.
- Create: `lib/features/novel_details/presentation/widgets/novel_details_summary_card.dart` — الملخص القابل للتوسعة.
- Create: `lib/features/novel_details/presentation/widgets/novel_details_section_tabs.dart` — تبويبا الفصول والتعليقات.
- Modify: `lib/features/novel_details/presentation/novel_details_screen.dart` — شريط التطبيق والمفضلة وربط الحالة.
- Modify: `lib/features/novel_details/presentation/widgets/novel_details_content.dart` — ترتيب صفحة Stitch وإجراء القراءة.
- Modify: `lib/features/novel_details/presentation/widgets/novel_details_header.dart` — الغلاف المركزي وشبكة 2×2 والتصنيفات.
- Modify: `lib/features/novel_details/presentation/widgets/novel_chapters_section.dart` — البحث والترتيب والقائمة الجديدة.
- Modify: `lib/features/novel_details/presentation/widgets/readable_chapter_tile.dart` — صف Stitch دون trailing action.
- Modify: `lib/features/novel_details/presentation/widgets/novel_chapter_tile.dart` — إزالة نقطة التوسعة القديمة الخاصة بالإجراء اللاحق.
- Modify: `lib/features/novel_details/domain/readable_chapter.dart` — ترشيح وترتيب الفصول بشكل قابل للاختبار.
- Modify: `lib/features/novel_details/presentation/all_chapters_screen.dart` — إعادة استخدام مرشح الفصول المشترك.
- Modify: `lib/features/novel_details/presentation/widgets/favorite_toggle_button.dart` — أيقونة قلب مدمجة في شريط التطبيق.
- Delete: `lib/features/novel_engagement/presentation/novel_personal_state_section.dart` — تنتقل وظيفتاه إلى شبكة المعلومات ومنطقة البطل.
- Modify: `test/features/novel_details/novel_details_widgets_test.dart`.
- Modify: `test/features/novel_details/novel_details_responsive_test.dart`.
- Modify: `test/features/novel_details/novel_details_chapter_list_test.dart`.
- Modify: `test/features/novel_details/readable_chapter_list_test.dart`.
- Modify: `test/widget_test.dart`.
- Modify: `test/goldens/phase4_surfaces_golden_test.dart` وإضافة ست صور Golden لشاشة التفاصيل.
- Modify: `docs/manual_test_plan.md`.

---

### Task 1: Local visual tokens for the Stitch screen

**Files:**
- Create: `lib/features/novel_details/presentation/novel_details_visual_tokens.dart`
- Create: `test/features/novel_details/novel_details_visual_tokens_test.dart`

**Interfaces:**
- Consumes: `AppThemeTokens` من `lib/app/app_theme.dart`.
- Produces: `NovelDetailsVisualTokens.of(BuildContext)` و`NovelDetailsVisualTokens.resolve({required Brightness brightness, required AppThemeTokens appTokens})`.

- [ ] **Step 1: Write the failing color-contract tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/novel_details_visual_tokens.dart';

void main() {
  test('dark novel details tokens match the approved Stitch palette', () {
    final tokens = NovelDetailsVisualTokens.resolve(
      brightness: Brightness.dark,
      appTokens: AppTheme.galaxyNoir,
    );

    expect(tokens.background, const Color(0xFF131313));
    expect(tokens.surface, const Color(0xFF201F1F));
    expect(tokens.surfaceHigh, const Color(0xFF2A2A2A));
    expect(tokens.primary, const Color(0xFF9D4EDD));
    expect(tokens.textPrimary, const Color(0xFFECE9E8));
    expect(tokens.textSecondary, const Color(0xFFD9CEDC));
    expect(tokens.border, const Color(0xFF4D4353));
  });

  test('light novel details tokens retain app surfaces and purple action', () {
    final tokens = NovelDetailsVisualTokens.resolve(
      brightness: Brightness.light,
      appTokens: AppTheme.starlightPaper,
    );

    expect(tokens.background, AppTheme.starlightPaper.canvas);
    expect(tokens.surface, AppTheme.starlightPaper.surface);
    expect(tokens.primary, const Color(0xFF7226A5));
    expect(tokens.onPrimary, Colors.white);
  });
}
```

- [ ] **Step 2: Run the test and verify RED**

Run: `flutter test --no-pub test/features/novel_details/novel_details_visual_tokens_test.dart`

Expected: FAIL because `novel_details_visual_tokens.dart` does not exist.

- [ ] **Step 3: Implement the local token resolver**

```dart
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

@immutable
class NovelDetailsVisualTokens {
  const NovelDetailsVisualTokens({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.primary,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color primary;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  static NovelDetailsVisualTokens of(BuildContext context) {
    final appTokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    return resolve(
      brightness: Theme.of(context).brightness,
      appTokens: appTokens,
    );
  }

  static NovelDetailsVisualTokens resolve({
    required Brightness brightness,
    required AppThemeTokens appTokens,
  }) {
    if (brightness == Brightness.dark) {
      return const NovelDetailsVisualTokens(
        background: Color(0xFF131313),
        surface: Color(0xFF201F1F),
        surfaceHigh: Color(0xFF2A2A2A),
        primary: Color(0xFF9D4EDD),
        onPrimary: Color(0xFFFFFDFF),
        textPrimary: Color(0xFFECE9E8),
        textSecondary: Color(0xFFD9CEDC),
        border: Color(0xFF4D4353),
      );
    }
    return NovelDetailsVisualTokens(
      background: appTokens.canvas,
      surface: appTokens.surface,
      surfaceHigh: appTokens.surfaceRaised,
      primary: const Color(0xFF7226A5),
      onPrimary: Colors.white,
      textPrimary: appTokens.contentPrimary,
      textSecondary: appTokens.contentSecondary,
      border: appTokens.outline,
    );
  }
}
```

- [ ] **Step 4: Run the focused test and format both files**

Run: `dart format lib/features/novel_details/presentation/novel_details_visual_tokens.dart test/features/novel_details/novel_details_visual_tokens_test.dart && flutter test --no-pub test/features/novel_details/novel_details_visual_tokens_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit the isolated token contract**

```bash
git add lib/features/novel_details/presentation/novel_details_visual_tokens.dart test/features/novel_details/novel_details_visual_tokens_test.dart
git commit -m "feat: add Stitch novel detail colors"
```

---

### Task 2: Hero, metadata grid, and interactive rating tile

**Files:**
- Create: `lib/features/novel_details/presentation/widgets/novel_details_rating_tile.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_details_header.dart`
- Modify: `test/features/novel_details/novel_details_widgets_test.dart`

**Interfaces:**
- Consumes: `NovelDetails`, `NovelEngagementState`, `NovelDetailsVisualTokens`.
- Produces constructor:

```dart
NovelDetailsHeader({
  required NovelDetails details,
  required int chaptersCount,
  required NovelEngagementState engagementState,
  required VoidCallback onRate,
  required VoidCallback onSignIn,
  required VoidCallback onRetryEngagement,
})
```

- Produces keys: `novel-details-hero`, `novel-details-metadata-grid`, `novel-details-rating-action`, `novel-details-rating-help`, `novel-details-genres`.

- [ ] **Step 1: Replace header expectations with failing Stitch structure tests**

Add tests that pump `NovelDetailsHeader` with `translator: ''` and a ready engagement state, then assert:

```dart
expect(find.byKey(const ValueKey('novel-details-hero')), findsOneWidget);
expect(find.byKey(const ValueKey('novel-details-metadata-grid')), findsOneWidget);
expect(find.text('الكاتب'), findsOneWidget);
expect(find.text('المترجم'), findsOneWidget);
expect(find.text('عدد الفصول'), findsOneWidget);
expect(find.text('التقييم'), findsOneWidget);
expect(find.text('غير متوفر'), findsOneWidget);
expect(find.text('تقييمك: 4 من 5'), findsOneWidget);
expect(find.byTooltip('اضغط لإضافة أو تعديل تقييمك'), findsOneWidget);
expect(find.textContaining('2024'), findsNothing);
```

Add an interaction test:

```dart
var ratingPressed = false;
await tester.tap(find.byKey(const ValueKey('novel-details-rating-action')));
await tester.pump();
expect(ratingPressed, isTrue);
```

Add guest and failure cases verifying that the same tile invokes `onSignIn` and `onRetryEngagement`, respectively.

- [ ] **Step 2: Run the tests and verify RED**

Run: `flutter test --no-pub test/features/novel_details/novel_details_widgets_test.dart`

Expected: FAIL because the old horizontal header and stats strip are still rendered.

- [ ] **Step 3: Implement the rating tile state mapping**

Use this state mapping inside `NovelDetailsRatingTile`:

```dart
VoidCallback? _actionFor(NovelEngagementState state) => switch (state.status) {
  NovelEngagementStatus.guest => onSignIn,
  NovelEngagementStatus.loading => null,
  NovelEngagementStatus.failure => onRetry,
  NovelEngagementStatus.ready => state.isSubmitting ? null : onRate,
};

String _personalLabel(NovelEngagementState state) {
  if (state.status == NovelEngagementStatus.failure) return 'إعادة المحاولة';
  if (state.status == NovelEngagementStatus.loading) return 'جارٍ تحميل تقييمك';
  final rating = state.userState?.myRating ?? 0;
  return rating > 0 ? 'تقييمك: $rating من 5' : 'اضغط لإضافة تقييمك';
}
```

Build the tile as one `Semantics(button: true)` + `InkWell` target. Put the question mark inside:

```dart
Tooltip(
  key: const ValueKey('novel-details-rating-help'),
  message: 'اضغط لإضافة أو تعديل تقييمك',
  child: const Icon(Icons.help_outline_rounded, size: 16),
)
```

Do not wrap the help icon in a second `IconButton`.

- [ ] **Step 4: Rebuild `NovelDetailsHeader` around the Stitch hierarchy**

The file must render, in order:

```dart
Column(
  key: const ValueKey('novel-details-hero'),
  children: [
    _CenteredCover(details: details),
    _NovelTitles(details: details),
    _MetadataGrid(
      details: details,
      chaptersCount: chaptersCount,
      engagementState: engagementState,
      onRate: onRate,
      onSignIn: onSignIn,
      onRetryEngagement: onRetryEngagement,
    ),
    _GenreChips(genres: details.genres),
  ],
)
```

Use a 2-column `GridView` with `NeverScrollableScrollPhysics`, `shrinkWrap: true`, and a one-column fallback when the available width is below 280 logical pixels. The fixed cells are author, translator, chapter count, and `NovelDetailsRatingTile`. Show `غير متوفر` for missing author/translator. Display the VIP-active badge below the cover when `engagementState.userState?.vip.active == true`.

- [ ] **Step 5: Run focused tests**

Run: `dart format lib/features/novel_details/presentation/widgets/novel_details_header.dart lib/features/novel_details/presentation/widgets/novel_details_rating_tile.dart test/features/novel_details/novel_details_widgets_test.dart && flutter test --no-pub test/features/novel_details/novel_details_widgets_test.dart`

Expected: PASS with no overflow or duplicate semantics targets.

- [ ] **Step 6: Commit the hero and rating grid**

```bash
git add lib/features/novel_details/presentation/widgets/novel_details_header.dart lib/features/novel_details/presentation/widgets/novel_details_rating_tile.dart test/features/novel_details/novel_details_widgets_test.dart
git commit -m "feat: rebuild novel detail hero and rating grid"
```

---

### Task 3: Screen chrome, summary, read action, and two-section content

**Files:**
- Create: `lib/features/novel_details/presentation/widgets/novel_details_summary_card.dart`
- Create: `lib/features/novel_details/presentation/widgets/novel_details_section_tabs.dart`
- Modify: `lib/features/novel_details/presentation/novel_details_screen.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_details_content.dart`
- Modify: `lib/features/novel_details/presentation/widgets/favorite_toggle_button.dart`
- Delete: `lib/features/novel_engagement/presentation/novel_personal_state_section.dart`
- Modify: `test/features/novel_details/novel_details_responsive_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- `NovelDetailsContent` keeps all current callbacks except `onToggleFavorite`; favorite ownership moves to `NovelDetailsScreen`.
- Produces `NovelDetailsSectionTabs(selected: NovelDetailsSection, onSelected: ValueChanged<NovelDetailsSection>, chaptersCount: int, commentsCount: int?)` with public enum `NovelDetailsSection { chapters, comments }`.
- Produces `NovelDetailsSummaryCard(summary: String)`.

- [ ] **Step 1: Write failing tests for the approved information architecture**

Replace three-tab/overview tests with:

```dart
expect(find.byKey(const ValueKey('novel-section-overview')), findsNothing);
expect(find.byKey(const ValueKey('novel-section-chapters')), findsOneWidget);
expect(find.byKey(const ValueKey('novel-section-comments')), findsOneWidget);
expect(find.byKey(const ValueKey('novel-details-summary-card')), findsOneWidget);
expect(find.byKey(const ValueKey('novel-details-read-action')), findsOneWidget);
expect(find.byKey(const ValueKey('novel-personal-state-ready')), findsNothing);
```

Verify `novel-section-chapters` starts with selected semantics, comments load lazily, and selecting comments switches selected semantics without removing the hero or read action.

Update the integration rating tests in `test/widget_test.dart` to reveal and tap `novel-details-rating-action`, then assert the existing `NovelRatingSheet` submission and guest account routing.

- [ ] **Step 2: Run the focused tests and verify RED**

Run: `flutter test --no-pub test/features/novel_details/novel_details_responsive_test.dart test/widget_test.dart --name "rating|detail tabs|comments"`

Expected: FAIL because overview is still the default and rating is still in `NovelPersonalStateSection`.

- [ ] **Step 3: Move the dynamic title and favorite into the app bar**

Refactor `NovelDetailsScreen.build` so the `FutureBuilder` returns the `Scaffold` and can use loaded data:

```dart
return FutureBuilder<NovelDetailsLoadResult>(
  future: _future,
  builder: (context, snapshot) {
    final result = snapshot.data;
    return Scaffold(
      backgroundColor: result == null
          ? null
          : NovelDetailsVisualTokens.of(context).background,
      appBar: AppBar(
        title: Text(result?.details.title ?? 'تفاصيل الرواية'),
        actions: result == null
            ? null
            : [
                FavoriteToggleButton(
                  novelId: result.details.id,
                  authRepository: _authRepository!,
                  favoritesRepository: _favoritesRepository!,
                  onPressed: () => _toggleFavorite(result.details),
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: _bodyFor(snapshot),
    );
  },
);
```

Keep `_bodyFor` private and return skeleton, retry message, or the existing engagement builder. Change `FavoriteToggleButton` to a 48×48 heart/heart-outline target while preserving its repository state and tooltip.

- [ ] **Step 4: Implement the always-visible summary and two tabs**

`NovelDetailsSummaryCard` owns only expansion state. It displays at most four lines before expansion and only shows the toggle when `summary.length > 220`.

`NovelDetailsContent` must initialize:

```dart
NovelDetailsSection _section = NovelDetailsSection.chapters;
```

Its slivers are ordered as:

```dart
NovelDetailsHeader(...),
_ReadAction(...),
if (details.summary.isNotEmpty) NovelDetailsSummaryCard(summary: details.summary),
NovelDetailsSectionTabs(...),
switch (_section) {
  NovelDetailsSection.chapters => NovelChaptersSection(...),
  NovelDetailsSection.comments => CommentsSliverSection(...),
},
const SliverToBoxAdapter(child: SizedBox(height: 32)),
```

Remove `_NovelOverviewSection`, `_LatestChaptersSection`, `_DetailsBottomBar`, and the `NovelPersonalStateSection` import. `_ReadAction` is an in-flow full-width `FilledButton.icon` with the existing continuation label and disabled `لا يوجد فصل متاح` state. It has no sibling download control.

- [ ] **Step 5: Delete the obsolete personal-state section and update fixtures**

Delete `novel_personal_state_section.dart` after this search returns only the file itself:

Run: `rg -n "NovelPersonalStateSection|novel-personal-state|personal-rating-action" lib test`

Update remaining tests to use `novel-details-rating-action`. Preserve VIP assertions using the new hero badge key `novel-details-vip-badge`.

- [ ] **Step 6: Run the content and integration tests**

Run: `dart format lib/features/novel_details/presentation test/features/novel_details test/widget_test.dart && flutter test --no-pub test/features/novel_details test/widget_test.dart`

Expected: PASS; comments remain lazy, rating submission still reaches `(novelId, rating)`, and guest rating still opens account.

- [ ] **Step 7: Commit the screen composition**

```bash
git add lib/features/novel_details/presentation/novel_details_screen.dart lib/features/novel_details/presentation/widgets/novel_details_content.dart lib/features/novel_details/presentation/widgets/novel_details_summary_card.dart lib/features/novel_details/presentation/widgets/novel_details_section_tabs.dart lib/features/novel_details/presentation/widgets/favorite_toggle_button.dart lib/features/novel_engagement/presentation/novel_personal_state_section.dart test/features/novel_details/novel_details_responsive_test.dart test/widget_test.dart
git commit -m "feat: compose Stitch novel details screen"
```

---

### Task 4: Inline chapter search, order toggle, and Stitch rows

**Files:**
- Modify: `lib/features/novel_details/domain/readable_chapter.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_chapters_section.dart`
- Modify: `lib/features/novel_details/presentation/widgets/readable_chapter_tile.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_chapter_tile.dart`
- Modify: `lib/features/novel_details/presentation/all_chapters_screen.dart`
- Modify: `test/features/novel_details/readable_chapter_list_test.dart`
- Modify: `test/features/novel_details/novel_details_chapter_list_test.dart`
- Modify: `test/features/novel_details/novel_details_widgets_test.dart`

**Interfaces:**
- Produces:

```dart
List<ReadableChapter> readableChaptersForDisplay(
  Iterable<ReadableChapter> chapters, {
  required String query,
  required bool descending,
})
```

- Produces keys: `novel-chapter-search-field`, `novel-chapter-order-toggle`, `novel-chapters-list-surface`, `novel-chapters-empty-search`.

- [ ] **Step 1: Write failing unit tests for normalized search and ordering**

```dart
test('filters readable chapters in Arabic and reverses the result', () {
  final chapters = mergeReadableChapters(
    publicChapters: [_chapter(1, 'البداية'), _chapter(2, 'السر الغامض')],
    vipChapters: const [],
  );

  expect(
    readableChaptersForDisplay(
      chapters,
      query: 'غامض',
      descending: false,
    ).map((chapter) => chapter.number),
    ['2'],
  );
  expect(
    readableChaptersForDisplay(chapters, query: '', descending: true)
        .map((chapter) => chapter.number),
    ['2', '1'],
  );
});
```

- [ ] **Step 2: Run the domain test and verify RED**

Run: `flutter test --no-pub test/features/novel_details/readable_chapter_list_test.dart`

Expected: FAIL because `readableChaptersForDisplay` does not exist.

- [ ] **Step 3: Implement the shared filter**

```dart
List<ReadableChapter> readableChaptersForDisplay(
  Iterable<ReadableChapter> chapters, {
  required String query,
  required bool descending,
}) {
  final normalizedQuery = normalizeArabicSearch(query);
  final result = chapters.where((chapter) {
    if (normalizedQuery.isEmpty) return true;
    final searchable = normalizeArabicSearch([
      chapter.number,
      chapter.label,
      chapter.title,
      chapter.dateLabel,
      chapter.isVip ? 'vip' : '',
    ].join(' '));
    return searchable.contains(normalizedQuery);
  }).toList(growable: false);
  if (descending) return List.unmodifiable(result.reversed);
  return List.unmodifiable(result);
}
```

Import `arabic_search_normalizer.dart`. Replace `_filteredChapters`, `_chapterMatchesQuery`, and `_normalizeChapterSearchText` in `AllChaptersScreen` with this shared function.

- [ ] **Step 4: Add failing widget tests for search, reverse order, and no download affordance**

Tests must:

```dart
await tester.enterText(
  find.byKey(const ValueKey('novel-chapter-search-field')),
  'المتابعة',
);
await tester.pump();
expect(find.text('الفصل 2'), findsOneWidget);
expect(find.text('الفصل 1'), findsNothing);

await tester.enterText(
  find.byKey(const ValueKey('novel-chapter-search-field')),
  '',
);
await tester.pump();
await tester.tap(find.byKey(const ValueKey('novel-chapter-order-toggle')));
await tester.pump();
expect(
  tester.getTopLeft(find.text('الفصل 2')).dy,
  lessThan(tester.getTopLeft(find.text('الفصل 1')).dy),
);

expect(find.byIcon(Icons.download_outlined), findsNothing);
expect(find.byIcon(Icons.download_rounded), findsNothing);
```

Delete the old `chapter tile can show a download action` test.

- [ ] **Step 5: Implement inline search and order state**

In `_NovelChaptersSectionState` add:

```dart
final TextEditingController _searchController = TextEditingController();
String _query = '';
bool _descending = false;

@override
void dispose() {
  _searchController.dispose();
  super.dispose();
}
```

Render a rounded `TextField` and 48×48 order button before the list. Compute:

```dart
final displayed = readableChaptersForDisplay(
  chapters,
  query: _query,
  descending: _descending,
);
final visibleRows = _query.trim().isEmpty
    ? chapterPageItems(displayed, 0)
    : displayed;
```

Show the search-empty state when `chapters.isNotEmpty && displayed.isEmpty`. Keep `عرض كل الفصول` only when the unfiltered collection has more than one page or more VIP pages exist.

- [ ] **Step 6: Restyle rows and remove trailing-action APIs**

Remove `trailingAction` from `ReadableChapterTile` and `NovelChapterTile`. Render rows inside one rounded parent surface keyed `novel-chapters-list-surface`; use a circular number badge, title/date, VIP/lock status, and chevron. Each row remains a single tap target of at least 72 logical pixels high.

- [ ] **Step 7: Run chapter, pagination, and VIP regression tests**

Run: `dart format lib/features/novel_details test/features/novel_details && flutter test --no-pub test/features/novel_details test/features/vip/vip_chapters_section_test.dart test/features/vip/vip_locked_chapters_integration_test.dart`

Expected: PASS; public and VIP ordering, direct VIP routes, pagination, inline search, and empty states remain correct.

- [ ] **Step 8: Commit the chapter experience**

```bash
git add lib/features/novel_details/domain/readable_chapter.dart lib/features/novel_details/presentation/widgets/novel_chapters_section.dart lib/features/novel_details/presentation/widgets/readable_chapter_tile.dart lib/features/novel_details/presentation/widgets/novel_chapter_tile.dart lib/features/novel_details/presentation/all_chapters_screen.dart test/features/novel_details/readable_chapter_list_test.dart test/features/novel_details/novel_details_chapter_list_test.dart test/features/novel_details/novel_details_widgets_test.dart
git commit -m "feat: add inline chapter discovery to novel details"
```

---

### Task 5: Responsive behavior, accessibility, loading states, and Golden coverage

**Files:**
- Modify: `lib/features/novel_details/presentation/widgets/novel_details_content.dart`
- Modify: `test/features/novel_details/novel_details_responsive_test.dart`
- Modify: `test/goldens/phase4_surfaces_golden_test.dart`
- Create: six `test/goldens/goldens/phase4_novelDetails_<theme>_<width>.png` files.

**Interfaces:**
- Extends `_GoldenGroup` with `novelDetails`.
- Reuses `NovelDetailsScreen(manifestPath: '/golden-novel.json')` and existing fake repositories.

- [ ] **Step 1: Rewrite responsive tests around the taller Stitch layout**

For sizes 320×720، 600×900، 840×1000 and 200% text:

```dart
expect(tester.takeException(), isNull);
expect(find.byKey(const ValueKey('novel-details-metadata-grid')), findsOneWidget);
expect(find.byKey(const ValueKey('novel-details-rating-action')), findsOneWidget);
await tester.scrollUntilVisible(
  find.byKey(const ValueKey('novel-details-read-action')),
  240,
  scrollable: find.byType(Scrollable).first,
);
_expectAccessibleAction(
  tester,
  const ValueKey('novel-details-read-action'),
  size.height,
);
```

Do not require the entire hero and action area to fit in the first 720 pixels; the approved Stitch page is intentionally scrollable. Keep 48×48 targets and selected semantics assertions.

- [ ] **Step 2: Add exact color and semantic assertions**

Pump `AppTheme.dark()` and assert the background/primary/text colors through `NovelDetailsVisualTokens.of(context)`. Assert the rating node is a button with tap action and contains the help text. Assert selected state changes between only the chapter and comment tabs.

- [ ] **Step 3: Update skeleton and failure layout**

Make `NovelDetailsSkeleton` mirror a centered 160×240 cover, two title bars, four metadata cells, full-width action placeholder, summary card, and tab placeholder. Continue using `NovelDetailsMessage` for load failure and preserve its retry callback.

- [ ] **Step 4: Add the novel-details Golden group**

Update:

```dart
enum _GoldenGroup { personalLibrary, accountSettings, support, novelDetails }
```

For `novelDetails`, configure an authenticated fake user, `FakeNovelRepository(result: _goldenNovelDetails)`, and `FakeNovelEngagementRepository(state: _goldenNovelUserState)`. Render:

```dart
const NovelDetailsScreen(manifestPath: '/golden-novel.json')
```

Use a fixed cover asset or an empty cover placeholder; never rely on a network image in a Golden test.

- [ ] **Step 5: Run Golden tests once to verify expected diffs**

Run: `flutter test --no-pub test/goldens/phase4_surfaces_golden_test.dart --plain-name "novelDetails"`

Expected: FAIL because the six new masters do not exist.

- [ ] **Step 6: Generate and visually inspect only the six new masters**

Run: `flutter test --no-pub --update-goldens test/goldens/phase4_surfaces_golden_test.dart --plain-name "novelDetails"`

Inspect all six images for RTL order, 2×2 grid, exact dark purple palette, light contrast, no overflow, and no download icons. Do not update unrelated Golden files.

- [ ] **Step 7: Run responsive and complete Golden suites**

Run: `flutter test --no-pub test/features/novel_details/novel_details_responsive_test.dart test/goldens/phase4_surfaces_golden_test.dart`

Expected: PASS for all widths and both themes.

- [ ] **Step 8: Commit responsive and Golden coverage**

```bash
git add lib/features/novel_details/presentation/widgets/novel_details_content.dart test/features/novel_details/novel_details_responsive_test.dart test/goldens/phase4_surfaces_golden_test.dart test/goldens/goldens/phase4_novelDetails_*.png
git commit -m "test: cover responsive Stitch novel details"
```

---

### Task 6: Documentation, guard review, and full verification

**Files:**
- Modify: `docs/manual_test_plan.md`
- Review all files changed in Tasks 1–5.

**Interfaces:**
- No new interfaces. This task validates the completed screen against the approved spec.

- [ ] **Step 1: Update the manual test plan with exact new behavior**

Under `## 6. تفاصيل الرواية`, replace old layout expectations with checks for:

```markdown
- الغلاف المركزي، الاسم الأصلي، الحالة والتصنيفات.
- شبكة الكاتب والمترجم وعدد الفصول والتقييم.
- الضغط على خانة التقييم كضيف وكمستخدم مسجل، ثم ظهور «تقييمك: X من 5».
- بقاء الملخص ظاهرًا قبل تبويبي الفصول والتعليقات.
- البحث داخل الفصول وعكس الترتيب.
- عدم ظهور أي عنصر تنزيل.
```

- [ ] **Step 2: Run active-download and obsolete-widget scans**

Run:

```powershell
rg -n -i 'DownloadManager|DownloadsRepository|DownloadedChapter|DownloadsScreen|DownloadForegroundService|onOpenDownloads|onDownloadChapters|Icons\.download|NovelPersonalStateSection|personal-rating-action|novel-section-overview' lib test android
```

Expected: no matches. Generic Arabic loading text such as `تحميل البيانات` is not a download feature and must not be changed.

- [ ] **Step 3: Run formatter on touched files only**

Run:

```powershell
dart format lib/features/novel_details/presentation/novel_details_visual_tokens.dart lib/features/novel_details/presentation/novel_details_screen.dart lib/features/novel_details/presentation/all_chapters_screen.dart lib/features/novel_details/presentation/widgets/novel_details_rating_tile.dart lib/features/novel_details/presentation/widgets/novel_details_header.dart lib/features/novel_details/presentation/widgets/novel_details_summary_card.dart lib/features/novel_details/presentation/widgets/novel_details_section_tabs.dart lib/features/novel_details/presentation/widgets/novel_details_content.dart lib/features/novel_details/presentation/widgets/favorite_toggle_button.dart lib/features/novel_details/presentation/widgets/novel_chapters_section.dart lib/features/novel_details/presentation/widgets/readable_chapter_tile.dart lib/features/novel_details/presentation/widgets/novel_chapter_tile.dart lib/features/novel_details/domain/readable_chapter.dart test/features/novel_details/novel_details_visual_tokens_test.dart test/features/novel_details/novel_details_widgets_test.dart test/features/novel_details/novel_details_responsive_test.dart test/features/novel_details/novel_details_chapter_list_test.dart test/features/novel_details/readable_chapter_list_test.dart test/goldens/phase4_surfaces_golden_test.dart test/widget_test.dart
```

Expected: formatting completes without touching unrelated feature directories.

- [ ] **Step 4: Run static analysis and focused suites**

Run:

```powershell
flutter analyze --no-pub
flutter test --no-pub test/features/novel_details test/features/vip test/widget_test.dart test/goldens/phase4_surfaces_golden_test.dart
```

Expected: analyzer reports `No issues found!`; all focused tests pass.

- [ ] **Step 5: Run the complete suite**

Run: `flutter test --no-pub`

Expected: all tests pass; intentional skips may remain unchanged.

- [ ] **Step 6: Build Android debug APK**

Run: `flutter build apk --debug --no-pub`

Expected: `build/app/outputs/flutter-apk/app-debug.apk` is created successfully.

- [ ] **Step 7: Review diff quality and scope**

Run:

```powershell
git diff --check
git status --short
git diff --stat -- lib/features/novel_details lib/features/novel_engagement/presentation test/features/novel_details test/goldens docs/manual_test_plan.md
```

Expected: no whitespace errors; only planned files are attributed to this feature. Preserve all unrelated pre-existing changes.

- [ ] **Step 8: Commit documentation and final corrections**

```bash
git add docs/manual_test_plan.md
git commit -m "docs: update novel details test plan"
```
