# Galaxy Novels Reading Phase 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** إعادة بناء رحلة تفاصيل الرواية والقراءة والتعليقات والتنزيل وVIP وإعلان القارئ وفق «المكتبة المدارية الهادئة»، مع بقاء القراءة متاحة للزائر وعدم تغيير عقود البيانات أو الخادم.

**Architecture:** تبقى المستودعات والمتحكمات الحالية مصدر الحالة، وتُعاد صياغة طبقة العرض فقط إلى مكونات متكيفة صغيرة وحالات مشتركة. تنفذ المهام بالتتابع لأن التفاصيل والقارئ والإعلانات تتشارك `AppDependencies` والتنقل، وتغلق كل مهمة بدورة RED→GREEN ومراجعة مستقلة قبل التالية.

**Tech Stack:** Flutter/Dart، Material 3، Slivers، Semantics، اختبارات Flutter unit/widget، AdMob Android الحالي.

## Global Constraints

- التطبيق يعمل كزائر في الرئيسية والمكتبة والتفاصيل والقارئ؛ تسجيل الدخول اختياري ولا يصبح بوابة للقراءة.
- كل نقاط الدخول، ومنها «آخر التحديثات»، تستمر في فتح `NovelDetailsScreen(manifestPath: ...)` نفسه.
- لا تتغير واجهات API أو عقود `NovelRepository` و`ReaderRepository` ومستودعات التعليقات والتنزيل والإعلانات أو نماذج البيانات.
- Android هو هدف هذه الدورة؛ لا تعدّل iOS أو تضف عمل نشر له.
- السمات العامة تبقى Galaxy Noir وStarlight Paper فقط؛ تفضيلات ألوان وخط القارئ مستقلة وليست سمات تطبيق إضافية.
- نقاط التحول: أقل من 600 هاتف، 600–839 متوسط، و840 فأكثر موسع؛ اختبارات المرحلة تغطي 320 و600 و840، والأفقي، وRTL، وتكبير النص 200%.
- كل هدف تفاعلي 44×44 على الأقل، والحالات المحددة تعلن `selected`، والتغيرات غير المرئية المناسبة تعلن `liveRegion`.
- لا تعرض أي شاشة `exception.toString()` أو مسار تنفيذ أو رسالة خادم خام للمستخدم.
- القوائم الطويلة تبقى كسولة، وتحليل HTML لا يتكرر مع تغير عناصر التحكم، وأحجام فك الأغلفة تبقى مرتبطة بحجم العرض.
- التعليقات لا تبدأ طلبها قبل فتح تبويب/ورقة التعليقات، وVIP لا يحمل قبل السماح، وAdMob لا يصبح شرطًا لعرض القارئ.
- تبقى عقود الفصول الحالية: الدمج العام/VIP ومنع التكرار، 50 فصلًا للصفحة، القراءة المحلية أولًا، حد 100 تنزيل، نقطة لكل فصل، مكافأة 25 نقطة، و6 إعلانات مكافئة يوميًا.
- سياسة بانر القارئ في هذه المرحلة جلسية: يحجز موضعًا لأول فصل مؤهل فقط داخل مثيل `ReaderScreen` ولا يعود في الانتقالات القصيرة بين الفصول.
- لا stage أو commit لملفات التنفيذ المتسخة مسبقًا، ولا reset/checkout لعمل المستخدم؛ التزام الخطة الوثائقية وحده منفصل وآمن.

---

## File Map

### تفاصيل الرواية

- Modify: `galaxy_novels_app/lib/features/novel_details/presentation/widgets/novel_details_header.dart` — رأس مضغوط متكيف دون Hero عملاق.
- Modify: `galaxy_novels_app/lib/features/novel_details/presentation/widgets/novel_details_content.dart` — أفعال القراءة/المفضلة/التنزيل، الأقسام، والحالات الآمنة.
- Modify: `galaxy_novels_app/lib/features/novel_details/presentation/widgets/novel_chapters_section.dart` — إشعار VIP الفعلي ورسالة خطأ الفصول الآمنة.
- Modify: `galaxy_novels_app/lib/features/novel_details/presentation/widgets/readable_chapter_tile.dart` — صف مرن عند 200%.
- Test/Create: `galaxy_novels_app/test/features/novel_details/novel_details_responsive_test.dart`.

### القارئ

- Create: `galaxy_novels_app/lib/features/reader/presentation/reader_reading_column.dart` — حد قياس النص المحسوب من الخط الفعلي وتفضيل العرض، مستقل عن عرض الخلفية.
- Modify: `galaxy_novels_app/lib/features/reader/presentation/reader_screen.dart` — chrome غامر، حالات آمنة، وتكامل الإعلان الجلسي.
- Modify: `galaxy_novels_app/lib/features/reader/presentation/native_reader_content.dart` — قياس النص، التقدم الواضح، الإخفاء/الإظهار، والفراغ.
- Modify: `galaxy_novels_app/lib/features/reader/presentation/reader_settings_sheet.dart` و`reader_font_selector.dart` — 320/أفقي/200%.
- Test/Create: `galaxy_novels_app/test/features/reader/reader_accessibility_test.dart`.

### التعليقات

- Modify: `galaxy_novels_app/lib/features/comments/presentation/comments_sliver_section.dart` — تمرير الرد إلى المحرر وتركيزه.
- Modify: `galaxy_novels_app/lib/features/comments/presentation/widgets/comment_composer.dart` — FocusNode وإعلانات الإرسال.
- Modify: `galaxy_novels_app/lib/features/comments/presentation/widgets/comment_item.dart` و`comments_sort_menu.dart` — أهداف ودلالات.
- Modify: `galaxy_novels_app/lib/features/comments/presentation/chapter_comments_sheet.dart` — CTA الضيف والحوار و`viewInsets`.
- Test/Create: `galaxy_novels_app/test/features/comments/comments_accessibility_test.dart`.

### التنزيل وVIP والإعلانات

- Modify: `galaxy_novels_app/lib/features/downloads/presentation/download_chapters_sheet.dart`, `downloads_screen.dart`, `download_progress_overlay.dart`, و`download_activity_layer.dart`.
- Create: `galaxy_novels_app/lib/features/vip/presentation/vip_access_notice.dart` — تفسير القفل وإجراؤه المتاح.
- Create: `galaxy_novels_app/lib/features/ads/application/reader_ad_session_policy.dart` — سياسة موضع واحد لكل جلسة قارئ.
- Create: `galaxy_novels_app/lib/features/ads/presentation/adaptive_banner_frame.dart` — سطح loaded/collapsed مستقل عن SDK وقابل للاختبار.
- Modify: `galaxy_novels_app/lib/features/ads/presentation/admob_adaptive_banner.dart` و`reader_banner_ad_slot.dart`.
- Test/Create: `galaxy_novels_app/test/features/vip/vip_locked_chapters_integration_test.dart`, `galaxy_novels_app/test/features/downloads/download_accessibility_test.dart`, و`galaxy_novels_app/test/features/ads/reader_ad_visibility_policy_test.dart`.

---

### Task 1: Compact information-first novel details

**Interfaces:**

- Preserves `NovelDetailsScreen(manifestPath: ...)`, `NovelDetailsContent` repository/controller inputs, and all existing read/favorite/rate/download callbacks.
- `NovelDetailsHeader(details, chaptersCount)` remains presentation-only and continues using `NovelCover`.
- Produces keys `novel-details-compact-header`, `novel-details-read-action`, and `novel-details-download-action`; the existing `novel-favorite-toggle` remains unchanged.

- [ ] **Step 1: Write failing responsive and first-viewport tests**

Create `novel_details_responsive_test.dart`. Pump real `NovelDetailsContent` with existing fakes at `(320, 720)`, `(600, 900)`, and `(840, 1000)`, then repeat 320 at `TextScaler.linear(2)`. Assert status, first genre, rating, chapter count, read, favorite, and download controls are laid out and hit-testable before scrolling; every action is at least 44×44 and `tester.takeException()` is null. Assert the section controls expose «نبذة»، «الفصول»، و«التعليقات»، وتعلن علامة التبويب الحالية `selected`. Assert `novel-details-latest-chapters` وأحدث فصلين يظهران في النبذة قبل فتح تبويب الفصول، بينما يبقى مستودع التعليقات بلا طلب حتى اختيار التعليقات. شغّل الحالة في الوضعين وافحص أزواج النص/السطح الدلالية المستخدمة في الرأس والأفعال بنسبة تباين ≥4.5.

```dart
for (final size in const [Size(320, 720), Size(600, 900), Size(840, 1000)]) {
  testWidgets('details keep facts and actions in the first viewport at $size', (tester) async {
    await pumpDetails(tester, size: size);
    expect(find.byKey(const ValueKey('novel-details-compact-header')), findsOneWidget);
    expect(find.byKey(const ValueKey('novel-details-read-action')), findsOneWidget);
    expect(find.byKey(const ValueKey('novel-details-download-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Verify RED**

```powershell
flutter test test/features/novel_details/novel_details_responsive_test.dart test/features/novel_details/novel_details_widgets_test.dart
```

Expected: FAIL because the phone header is vertical/large, download is below the fold, and the three-section contract is absent.

- [ ] **Step 3: Implement the compact header and primary actions**

Use one horizontal header at all supported widths: cover width 104–144 from `LayoutBuilder`, flexible information beside it, and a wrapping facts row for status, rating, visible chapters, and genres. Remove the broad shadow and `w900` styling; use semantic colors and weights 600–700. Preserve cover semantics and decode sizing.

Extend `_DetailsBottomBar` with a nullable `onDownload`; render favorite and download as 56×56 tooltip-labelled icon actions and the read action as the remaining flexible button. Keep the download control visible but disabled when no public downloadable chapter exists.

```dart
_DetailsBottomBar(
  novelId: details.id,
  onToggleFavorite: widget.onToggleFavorite,
  onDownload: loadResult.chapters.any((chapter) => chapter.effectiveContentApi.isNotEmpty)
      ? widget.onDownloadChapters
      : null,
  readLabel: continuationChapter == null ? 'ابدأ القراءة' : 'متابعة ${continuationChapter.label}',
  onRead: readChapter == null ? null : () => widget.onRead(readChapter, details.title),
)
```

- [ ] **Step 4: Make overview/chapters/comments explicit and safe**

Change `_NovelDetailsSection` to `overview`, `chapters`, `comments`; select `overview` initially. `_DetailsTabButton` wraps its control in `Semantics(button: true, selected: isSelected, label: label)`. Keep `CommentsController` creation inside the comments branch only. Show summary/personal state plus a keyed `novel-details-latest-chapters` preview of the newest two readable public chapters in overview, and the full lazy chapter section under chapters. Map `chaptersError` to the fixed Arabic copy «تعذر تحميل الفصول الآن. أعد المحاولة بعد قليل.» and never paint the raw value. Use only verified theme token foreground/background pairs whose normal-text contrast is ≥4.5 in both themes.

- [ ] **Step 5: Verify GREEN and review**

```powershell
flutter test test/features/novel_details/novel_details_responsive_test.dart test/features/novel_details/novel_details_widgets_test.dart test/features/novel_details/novel_details_chapter_list_test.dart test/widget_test.dart
flutter analyze --no-pub
```

Expected: PASS. Request independent spec/code/test review; fix every Critical/Important finding before Task 2.

---

### Task 2: Visible locked VIP chapters and flexible chapter rows

**Interfaces:**

- Preserves `mergeReadableChapters`, `readableChapterOpenContentApi`, `chaptersPerPage == 50`, and direct VIP route guards.
- Adds `isAuthenticated` and `onSignIn` to the internal `NovelChaptersSection` UI constructor. `NovelDetailsContent` derives the boolean observably from its existing `AuthRepository` notifier and passes its existing callback; no repository interface changes.
- Changes internal `ReadableChapterTile.onTap` from `VoidCallback` to `VoidCallback?`; a null callback renders a non-button row with no tap semantics.
- `VipAccessNotice` receives only `title`, `message`, optional `actionLabel`, and optional `onAction`; it never loads data.

- [ ] **Step 1: Write failing guest/non-subscriber/subscriber integration tests**

Create `vip_locked_chapters_integration_test.dart`. Through `NovelDetailsContent`, cover: guest + non-empty `vipScheduleManifest` sees a lock reason and working «فتح حسابي»; authenticated non-subscriber sees the subscription-unavailable reason without a fake purchase action; subscriber keeps the merged VIP rows and opens the existing internal route; unavailable direct content shows an inline disabled explanation. At 320/200%, rows grow instead of clipping and disabled rows are not semantic buttons.

- [ ] **Step 2: Verify RED**

```powershell
flutter test test/features/vip/vip_locked_chapters_integration_test.dart test/features/vip/vip_chapters_section_test.dart test/features/novel_details/readable_chapter_list_test.dart
```

Expected: FAIL because the production details path currently hides locked VIP content and chapter rows use fixed height.

- [ ] **Step 3: Extract and connect the access notice**

Create `vip_access_notice.dart` as a focused production component using `AppNotice` tokens, and connect it in `NovelChaptersSection` only when `details.vipScheduleManifest.isNotEmpty && !canReadPrivate`. Wrap the chapters branch in `NovelDetailsContent` with `ValueListenableBuilder<AuthSessionState>` and pass `isAuthenticated: session.status == AuthSessionStatus.authenticated`; do not read a repository from the notice and do not modify the unused legacy `VipChaptersSection`.

```dart
if (widget.result.details.vipScheduleManifest.isNotEmpty && !widget.canReadPrivate)
  SliverToBoxAdapter(
    child: VipAccessNotice(
      title: 'فصول VIP مقفلة',
      message: !widget.isAuthenticated
          ? 'سجّل الدخول بحساب يملك اشتراك VIP لقراءة هذه الفصول.'
          : 'لا يوجد اشتراك VIP فعال. الشراء داخل التطبيق غير متاح حاليًا.',
      actionLabel: !widget.isAuthenticated ? 'فتح حسابي' : null,
      onAction: !widget.isAuthenticated ? widget.onSignIn : null,
    ),
  )
```

- [ ] **Step 4: Make chapter tiles content-sized**

Change `ReadableChapterTile.onTap` to nullable and let `InkWell.onTap` receive it directly. Replace `height: 74` in readable/public/VIP rows with `ConstrainedBox(minHeight: 72)` plus vertical padding. Use two-line titles where needed. When a VIP row cannot open, set `onTap: null`, expose «مسار القراءة غير متاح حاليًا» visibly, and remove button semantics rather than relying on a snackbar after a misleading tap. Keep lists lazy and reuse the existing download action behavior.

- [ ] **Step 5: Verify GREEN and review**

```powershell
flutter test test/features/vip/vip_locked_chapters_integration_test.dart test/features/vip/vip_chapters_section_test.dart test/features/novel_details/readable_chapter_list_test.dart test/features/novel_details/novel_details_chapter_list_test.dart
flutter analyze --no-pub
```

Expected: PASS; merge/order/page-size tests remain unchanged. Request independent review.

---

### Task 3: Immersive, measured, and safe reader

**Interfaces:**

- Preserves local-first loading, `ReadingProgress`, `ReadingActivitySession`, previous/next navigation, settings, comments sheet, and `ReaderPreferences` persistence.
- `ReaderReadingColumn(paragraphStyle, textWidth, textScaler, child)` constrains text only; background and tap region still fill the viewport.
- `NativeReaderContent` receives the single source of truth `controlsVisible`, plus `onRetry` and `onControlsVisibilityChanged`; it no longer owns a second chrome boolean.

- [ ] **Step 1: Write failing reader behavior and layout tests**

Add tests for: tablet text column at 840/1200 within the calculated 65–75-character measure; initial chrome hidden, tap shows it, forward scroll hides it, reverse scroll shows it, and a chapter transition resets both AppBar and floating controls to hidden. Hidden chrome must be absent from hit testing and semantics. Assert progress copy equals «الفصل 2 من 10»; empty parsed content shows a safe retry state; a thrown `StateError('secret-path')` never paints `secret-path`; 320/200%, landscape, SafeArea, and `disableAnimations` produce no overflow/spatial transition.

For the measure, test every `ReaderTextWidth` with at least system, Amiri, and Cairo styles. Use a distinct long Arabic paragraph in the test, lay it out at the production max width, and read the first `TextPainter.getLineBoundary` end offset; assert the first line contains the target 65/70/75 characters within a two-character word-boundary tolerance. Do not calculate the expected width by calling the production helper.

- [ ] **Step 2: Verify RED**

```powershell
flutter test test/features/reader/reader_accessibility_test.dart test/features/reader/reader_screen_test.dart test/features/reader/native_reader_content_test.dart
```

Expected: FAIL on permanent AppBar, unlimited tablet width, `X / Y`, raw error details, and empty content.

- [ ] **Step 3: Add the measured reading column**

Create `reader_reading_column.dart` with a font-aware width function and a centered `ConstrainedBox`. Map `ReaderTextWidth.compact/comfortable/wide` to target character counts 65/70/75. Measure a fixed representative Arabic sample with the actual paragraph `TextStyle`, font family, and `TextScaler`; derive average shaped-character width and multiply it by the target. Clamp only to a safe tablet ceiling of 780; the parent constraint remains authoritative on narrower screens.

```dart
double readerMeasureWidth({
  required TextStyle paragraphStyle,
  required ReaderTextWidth textWidth,
  required TextScaler textScaler,
}) {
  const sample = 'في هدوء الليل تمتد الحكاية بين النجوم وتعود الكلمات إلى قارئها';
  final painter = TextPainter(
    text: TextSpan(text: sample, style: paragraphStyle),
    textDirection: TextDirection.rtl,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final target = switch (textWidth) {
    ReaderTextWidth.compact => 65,
    ReaderTextWidth.comfortable => 70,
    ReaderTextWidth.wide => 75,
  };
  final averageWidth = painter.width / sample.runes.length;
  return (averageWidth * target).clamp(0.0, 780.0).toDouble();
}
```

Wrap the lazy `ListView.builder` only; keep `ColoredBox`, gesture area, and floating controls full-width. Do not reparse HTML when chrome changes.

- [ ] **Step 4: Synchronize reader chrome and scroll direction**

Keep `_readerChromeVisible` only in `ReaderScreen`; reset it to false before every chapter load and pass it to `NativeReaderContent.controlsVisible`. Use `NotificationListener<UserScrollNotification>` in `NativeReaderContent`: forward requests false, reverse requests true, tap requests the inverse. `ReaderScreen` overlays AppBar and the content renders floating controls from the same value. Wrap hidden chrome in both `IgnorePointer(ignoring: true)` and `ExcludeSemantics(excluding: true)`; loading/error keep a normal AppBar. If `MediaQuery.disableAnimations` is true, duration is `Duration.zero` and no slide offset is used. Include top/bottom system padding and keyboard/view inset safety.

- [ ] **Step 5: Replace progress/error/empty copy**

Render `الفصل ${content.position} من ${content.total}`. Replace `_ReaderErrorView.details` with `AppAsyncState.error` fixed copy and retry. When the parser yields zero blocks, show `AppEmptyState(title: 'هذا الفصل فارغ الآن', actionLabel: 'إعادة المحاولة', onAction: onRetry)`.

- [ ] **Step 6: Make reader settings wrap at 200%**

Replace fixed rows/64px controls in `reader_settings_sheet.dart` and `reader_font_selector.dart` with `Wrap`, minimum heights, and scroll-safe content. Preserve every stored preference key/value and existing font families.

- [ ] **Step 7: Verify GREEN and review**

```powershell
flutter test test/features/reader/reader_accessibility_test.dart test/features/reader/reader_screen_test.dart test/features/reader/native_reader_content_test.dart test/features/reader/reader_display_controller_test.dart
flutter analyze --no-pub
```

Expected: PASS; parser-call-count and activity/history tests remain green. Request independent review.

---

### Task 4: Focused and accessible comments

**Interfaces:**

- Preserves controller sort/paging/submit/vote/reaction behavior and lazy loading.
- `CommentComposer` accepts an optional `FocusNode`; it owns none when supplied and disposes only an internally created node.
- `ChapterCommentsSheet` forwards the existing account navigation action; it never blocks reading.

- [ ] **Step 1: Write failing focus, guest, target-size, and semantics tests**

In `comments_accessibility_test.dart`, tap `comment-reply-<id>` from a scrolled list and assert `comments-content-field` becomes focused, is visible, and announces «رد على ...». Assert the guest CTA works in both novel and chapter surfaces. Measure vote/reply/reaction/sort controls ≥44×44. Inspect semantics for selected reactions/sort and `liveRegion` during sending, saved, failed, and interaction failure. Repeat at 320/200%; dynamically change `tester.view.viewInsets` after focus in both the novel `CustomScrollView` and the chapter `DraggableScrollableSheet`, then assert the composer is revealed again.

- [ ] **Step 2: Verify RED**

```powershell
flutter test test/features/comments/comments_accessibility_test.dart test/features/comments/comments_surfaces_test.dart test/features/comments/comment_item_test.dart
```

Expected: FAIL because reply does not focus/scroll, the chapter guest CTA is absent, and targets/live regions are incomplete.

- [ ] **Step 3: Move reply focus and scroll to the composer**

Own one `FocusNode` and one `GlobalKey` in `CommentsSliverSection` and register the state as `WidgetsBindingObserver`. On reply, set the target and request focus first; after `endOfFrame`, call `Scrollable.ensureVisible` so it uses the nearest active parent (`CustomScrollView` for novel details or the `DraggableScrollableSheet` controller for chapter comments). In `didChangeMetrics`, if the composer still has focus, schedule the same reveal again after the new `viewInsets` is applied. Pass the focus node into `CommentComposer`/`TextField`; dispose it and remove the observer in the section state.

```dart
void _replyTo(PublicComment comment) {
  setState(() => _replyTarget = comment);
  _composerFocus.requestFocus();
  _revealComposerAfterLayout();
}

Future<void> _revealComposerAfterLayout() async {
  await WidgetsBinding.instance.endOfFrame;
  if (!mounted) return;
  final targetContext = _composerKey.currentContext;
  if (targetContext == null) return;
  await Scrollable.ensureVisible(
    targetContext,
    alignment: 0.1,
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200),
    curve: Curves.easeOutCubic,
  );
}

@override
void didChangeMetrics() {
  if (_composerFocus.hasFocus) _revealComposerAfterLayout();
}
```

Use zero duration when animations are disabled.

- [ ] **Step 4: Add live announcements and 44px targets**

Keep a local submit announcement in the composer: «جارٍ إرسال التعليق»، «تم نشر تعليقك»، or the existing safe error. Wrap it and interaction errors in `Semantics(liveRegion: true)`. Remove `shrinkWrap`/32px vote targets; constrain vote, reply, reaction, and sort controls to 44×44. Keep `selected` on votes/reactions and label the sort control with its current value.

- [ ] **Step 5: Fix the chapter comments sheet**

Pass `onSignIn` from `ReaderScreen` to `ChapterCommentsSheet` using the existing account route. Wrap the sheet in route/dialog semantics, `SafeArea`, and animated bottom padding from `viewInsets`; retain `DraggableScrollableSheet`, pass its builder `scrollController` directly to the sheet's `CustomScrollView`, and retain deferred loading.

- [ ] **Step 6: Verify GREEN and review**

```powershell
flutter test test/features/comments/comments_accessibility_test.dart test/features/comments/comments_surfaces_test.dart test/features/comments/comment_item_test.dart test/features/reader/reader_screen_test.dart
flutter analyze --no-pub
```

Expected: PASS; guest reading remains mounted. Request independent review.

---

### Task 5: Keyboard-safe downloads and clear reward/progress states

**Interfaces:**

- Preserves `DownloadChaptersSheet(details, chapters, downloadsState, rewardsState, onStart)`, `DownloadManager`, point/limit rules, and rewarded-ad repository contracts.
- All new loading/error state is presentation-local around existing `load()` calls.

- [ ] **Step 1: Write failing sheet and progress accessibility tests**

At 320×568 and landscape, pump `DownloadChaptersSheet` with 200% text and `viewInsets.bottom = 240`; focus both range fields and assert the fields, close action, and start action can be scrolled into view without overflow. Assert dialog semantics, LTR numeric fields, live range/error copy, and every icon action ≥44. For `DownloadProgressOverlay`, assert modal semantics and live progress. Pump `DownloadActivityLayer` once normally and once with `MediaQuery(disableAnimations: true)`: inspect its `AnimatedSwitcher` and assert reduced motion uses `Duration.zero` and an opacity/no-spatial transition builder. For `DownloadsScreen`, distinguish loading, confirmed empty, failure/retry, pending rewarded ad, and exhausted daily limit copy.

- [ ] **Step 2: Verify RED**

```powershell
flutter test test/features/downloads/download_accessibility_test.dart test/features/downloads/download_chapters_sheet_test.dart test/features/downloads/download_progress_overlay_test.dart test/features/downloads/downloads_screen_test.dart
```

Expected: FAIL on the fixed 88% sheet, keyboard overlap, incomplete modal/live semantics, and ambiguous initial downloads state.

- [ ] **Step 3: Make the sheet viewport-derived**

Replace the fixed height and split `Column`/`Expanded` structure with one `SafeArea` + `AnimatedPadding(bottom: viewInsets.bottom)` + height-constrained `CustomScrollView`. Put the header/close control, quota summary, quick selections, range fields, validation notices, lazy `SliverList` of chapters, and start action in that single sliver sequence so every control is reachable at 320×568/200%/keyboard without a nested vertical scroll. Apply `viewInsets` once at the outer surface. Wrap it in `Semantics(scopesRoute: true, namesRoute: true, label: 'اختيار فصول التنزيل')`. Numeric range fields use `TextDirection.ltr` inside the Arabic layout.

- [ ] **Step 4: Add local async and live states**

Use `AppAsyncState`/`AppNotice` for loading, safe failure/retry, and confirmed empty in `DownloadsScreen` without changing `DownloadsRepository`. Mark range validation, start result, rewarded-ad pending/outcome, and overlay progress as live regions. When the daily rewarded limit is reached, show «تتاح مكافآت جديدة مع بداية اليوم التالي»; do not invent a countdown the model does not provide.

- [ ] **Step 5: Respect reduced motion in the overlay**

Use `Duration.zero` and opacity-only feedback when `disableAnimations` is true in both `download_progress_overlay.dart` and the `AnimatedSwitcher` inside `download_activity_layer.dart`; otherwise use the approved 150–200ms `easeOutCubic` transitions. Keep cancel/pause/resume/retry behavior unchanged.

- [ ] **Step 6: Verify GREEN and review**

```powershell
flutter test test/features/downloads/download_accessibility_test.dart test/features/downloads/download_chapters_sheet_test.dart test/features/downloads/download_progress_overlay_test.dart test/features/downloads/downloads_screen_test.dart test/features/downloads/download_manager_test.dart test/features/downloads/download_points_manager_test.dart
flutter analyze --no-pub
```

Expected: PASS; points/refunds/parallel-job rules stay green. Request independent review.

---

### Task 6: Collapsing, accessible, session-scoped reader ads

**Interfaces:**

- Preserves `ReaderAdRepository.initialize()` and `buildReaderBanner(BuildContext)` exactly, plus deferred shared AdMob initialization.
- `ReaderAdSessionPolicy.reserve(contentKey)` returns true only for the first non-empty key in one `ReaderScreen` lifetime; duplicate and later keys return false.
- `ReaderBannerAdSlot` sizes itself from its non-positioned child and reports close through `onClose`; it no longer resets from `contentKey`.

- [ ] **Step 1: Write failing collapse/policy/target tests**

Create `reader_ad_visibility_policy_test.dart`: empty key false, first eligible true, duplicate false, next chapter false, and a new policy instance true. Update banner tests so pending readiness and readiness false have zero height. Test the SDK-free `AdaptiveBannerFrame` directly with controlled collapsed/loaded/failed states and a fake child: collapsed/failed are zero, loaded uses the supplied dimensions. Pump that frame through `ReaderBannerAdSlot`: at zero size assert the close key, Tooltip, and Semantics «إغلاق الإعلان» are absent; after a nonzero size report assert they appear and the target is ≥44; after a later zero report assert they disappear again. Replace the old «returns when chapter changes» assertion with session suppression.

- [ ] **Step 2: Verify RED**

```powershell
flutter test test/features/ads/reader_ad_visibility_policy_test.dart test/features/ads/reader_banner_ad_slot_test.dart test/features/ads/admob_adaptive_banner_test.dart test/features/reader/reader_screen_test.dart
```

Expected: FAIL because the slot reserves 56px, close is 38px, and content-key changes restore it.

- [ ] **Step 3: Implement the session policy and reader integration**

Create the small stateful policy in the application layer. `ReaderScreen` owns one instance, calls `reserve(contentApi)` after a successful current chapter load, and stores `_showReaderAd`. Next/previous loads set it false when reserve fails. Do not add policy to `AppDependencies` or change repository interfaces.

```dart
class ReaderAdSessionPolicy {
  bool _reserved = false;

  bool reserve(String contentKey) {
    if (_reserved || contentKey.trim().isEmpty) return false;
    _reserved = true;
    return true;
  }
}
```

- [ ] **Step 4: Collapse the placement until a real banner is loaded**

Create `AdaptiveBannerFrame`, a pure SDK-free presentation widget with explicit `isLoaded`, nullable `Size`, and `child`; it returns `SizedBox.shrink()` unless loaded with a valid size. `AdMobAdaptiveBanner` uses this frame while readiness is pending/false, while the SDK banner is loading, and after `onAdFailedToLoad`; the loaded callback is the only path that supplies real dimensions and `AdWidget`. This is the controlled load/fail seam for widget tests and does not alter `ReaderAdRepository`.

`ReaderBannerAdSlot` wraps the child in a private render-size reporter (a small `RenderProxyBox` callback scheduled after layout). Its state renders only the child while measured height is zero; after a nonzero size notification it adds the positioned 44×44 close control with Tooltip/Semantics, and a later zero-size notification removes both close control and slot height. This makes pending→loaded→failed observable without an SDK mock. Closing calls `onClose`, and `ReaderScreen` removes the placement for the session.

- [ ] **Step 5: Add the phase-3 integration matrix**

Create `test/features/phase3/phase3_reading_surfaces_test.dart`. Pump the guest journey through the real app/fakes: Home latest → `NovelDetailsScreen` → read → `ReaderScreen`, open comments without unmounting reader, and open download/VIP surfaces. Run both themes at 320/600/840, 200% on 320, and one landscape reader case. Assert no auth gate, raw exception text, overflow, duplicate banner, or target under 44.

- [ ] **Step 6: Verify GREEN and review**

```powershell
flutter test test/features/ads/reader_ad_visibility_policy_test.dart test/features/ads/reader_banner_ad_slot_test.dart test/features/ads/admob_adaptive_banner_test.dart test/features/reader/reader_screen_test.dart test/features/phase3/phase3_reading_surfaces_test.dart test/widget_test.dart
flutter analyze --no-pub
```

Expected: PASS. Request final phase spec/code/test review and fix every Critical/Important finding with RED→GREEN coverage.

---

### Task 7: Phase-3 quality gate

- [ ] **Step 1: Format only phase-3 Dart files** with `dart format`; expected 0 unrelated changes.
- [ ] **Step 2: Run focused phase suites** for novel details, VIP, reader, comments, downloads, and ads; record exact passing count.
- [ ] **Step 3: Run `flutter analyze --no-pub`**; expected `No issues found!`.
- [ ] **Step 4: Run `flutter test --no-pub`**; expected all tests pass and record the new count.
- [ ] **Step 5: Run `flutter build apk --debug --no-pub`**; expected `build/app/outputs/flutter-apk/app-debug.apk`.
- [ ] **Step 6: Run `git diff --check`, `git diff --cached --check`, `git status --short`, and `git diff --stat`**; expected no whitespace errors and no staged implementation files.
- [ ] **Step 7: Install the fresh APK on a small-phone emulator and a tablet emulator when available**; verify details first viewport, reader measure/chrome, reply focus, keyboard-safe download sheet, VIP notice, and zero ad gap before load. If the emulator environment cannot boot, record that separately and rely on the exact widget layout matrix without claiming a manual visual pass.
- [ ] **Step 8: Request broad final review** with the plan, task reports, and full diff; do not close Phase 3 with any open Critical/Important finding.

## Self-Review Record

- Spec coverage: details 7.4, reader 7.5, comments 7.6, downloads 7.7, VIP/ads 7.10, data/error states, accessibility, performance, and the phase quality gate each map to a task.
- Preserved contracts: guest reading, latest→details, local-first reader, history/activity, lazy comments, VIP merge/page size, download points/limits, and AdMob repository APIs are explicit.
- Deliberately deferred to Phase 4: favorites/history visual polish, account/settings, drawer download shortcut, dynamic About version, privacy/Discord polish, and final golden suite.
- Placeholder scan: no TBD/TODO, generic «handle errors», or undefined future interface remains; each task names RED/GREEN commands and expected failure reason.
- Type consistency: new names are fixed as `ReaderReadingColumn`, `VipAccessNotice`, `AdaptiveBannerFrame`, and `ReaderAdSessionPolicy.reserve`; callback/auth ownership and nullable chapter taps are stated at producer and consumer.
- Risk controls: tasks run sequentially, no parallel edits to shared files, every test asserts observable behavior, and no SDK/network dependency is required in widget tests.
