# Stitch Reader Screen Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the loaded reader chrome from Stitch `_1` while preserving reader preferences, chapter navigation, comments, progress tracking, and tap-to-toggle behavior.

**Architecture:** Extract visual chrome into `reader_stitch_chrome.dart` and resolve its colors through a small `ReaderChromePalette`. `ReaderScreen` owns the top bar and settings action; `NativeReaderContent` owns the reading canvas, progress calculation, and bottom pill.

**Tech Stack:** Flutter, Dart, Material, flutter_test, existing reader repositories and preferences.

## Global Constraints

- Execute inline in this session; the user explicitly prohibited subagents.
- Keep the chapter title in the top bar and inside the reading content as it works now.
- Remove the chapter-list icon without replacement.
- Keep a thin progress bar and `الفصل X من Y` inside the bottom pill.
- Keep tap-to-show/hide; do not add scroll-driven auto-hide.
- Preserve every current reader palette, font, line-height, width, comments, navigation, history, and reading-activity behavior.
- Keep hidden chrome excluded from semantics and pointer input.
- Support 320/600/840 widths, short landscape, reduced motion, and 200% text.
- Do not add or restore downloads.
- Preserve unrelated dirty-worktree changes and do not stage overlapping files.

---

### Task 1: Define and test reader chrome colors

**Files:**
- Create: `lib/features/reader/presentation/reader_chrome_palette.dart`
- Create: `test/features/reader/reader_chrome_palette_test.dart`

**Interfaces:**
- Consumes: `ColorScheme`, `ReaderPaletteMode`.
- Produces: `ReaderChromePalette.resolve({required ColorScheme scheme, required ReaderPaletteMode paletteMode})`.

- [ ] **Step 1: Write the failing palette tests**

```dart
test('system dark reader chrome uses the approved Stitch colors', () {
  final palette = ReaderChromePalette.resolve(
    scheme: const ColorScheme.dark(),
    paletteMode: ReaderPaletteMode.system,
  );
  expect(palette.background, const Color(0xFF201F1F));
  expect(palette.foreground, const Color(0xFFECEBE9));
  expect(palette.border, const Color(0xFF4D4353));
  expect(palette.primary, const Color(0xFF9D4EDD));
});

test('custom reader palettes keep their own semantic colors', () {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF60A5FA),
    brightness: Brightness.dark,
  ).copyWith(
    surface: const Color(0xFF07111F),
    onSurface: const Color(0xFFE6F0FF),
    primary: const Color(0xFF60A5FA),
    outlineVariant: const Color(0xFF1E3A5F),
  );
  final palette = ReaderChromePalette.resolve(
    scheme: scheme,
    paletteMode: ReaderPaletteMode.nightBlue,
  );
  expect(palette.background, scheme.surface);
  expect(palette.foreground, scheme.onSurface);
  expect(palette.primary, scheme.primary);
});
```

- [ ] **Step 2: Run the test and verify red**

Run: `flutter test --no-pub test/features/reader/reader_chrome_palette_test.dart`

Expected: FAIL because `reader_chrome_palette.dart` and `ReaderChromePalette` do not exist.

- [ ] **Step 3: Implement the immutable palette**

```dart
@immutable
class ReaderChromePalette {
  const ReaderChromePalette({
    required this.background,
    required this.foreground,
    required this.border,
    required this.primary,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Color primary;

  static ReaderChromePalette resolve({
    required ColorScheme scheme,
    required ReaderPaletteMode paletteMode,
  }) {
    final usesStitchDark = scheme.brightness == Brightness.dark &&
        (paletteMode == ReaderPaletteMode.system ||
            paletteMode == ReaderPaletteMode.dark);
    if (usesStitchDark) {
      return const ReaderChromePalette(
        background: Color(0xFF201F1F),
        foreground: Color(0xFFECEBE9),
        border: Color(0xFF4D4353),
        primary: Color(0xFF9D4EDD),
      );
    }
    return ReaderChromePalette(
      background: scheme.surface,
      foreground: scheme.onSurface,
      border: scheme.outlineVariant,
      primary: scheme.primary,
    );
  }
}
```

- [ ] **Step 4: Run the palette tests**

Run: `flutter test --no-pub test/features/reader/reader_chrome_palette_test.dart`

Expected: PASS.

---

### Task 2: Lock the approved top bar and one-row bottom pill contract

**Files:**
- Modify: `test/features/reader/reader_screen_test.dart`
- Modify: `test/features/reader/native_reader_content_test.dart`

**Interfaces:**
- Consumes: existing `ReaderScreen`, `NativeReaderContent`, and stable control keys.
- Produces: stable keys `reader-floating-pill`, `reader-progress-indicator`, and `reader-settings-button`; verifies the absence of `reader-chapters-button`.

- [ ] **Step 1: Add the loaded chrome structure assertions**

```dart
await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
await tester.pumpAndSettle();

final appBar = find.byKey(const ValueKey('reader-app-bar'));
expect(
  find.descendant(
    of: appBar,
    matching: find.byKey(const ValueKey('reader-settings-button')),
  ),
  findsOneWidget,
);
expect(find.byKey(const ValueKey('reader-floating-pill')), findsOneWidget);
expect(find.byKey(const ValueKey('reader-progress-indicator')), findsOneWidget);
expect(find.byKey(const ValueKey('reader-chapters-button')), findsNothing);
```

- [ ] **Step 2: Assert the narrow pill stays one row**

```dart
final previousY = tester.getCenter(find.text('السابق')).dy;
final commentsY = tester
    .getCenter(find.byKey(const ValueKey('reader-comments-button')))
    .dy;
final nextY = tester.getCenter(find.text('التالي')).dy;
expect(previousY, closeTo(commentsY, 1));
expect(nextY, closeTo(commentsY, 1));
expect(tester.takeException(), isNull);
```

- [ ] **Step 3: Assert chapter title and progress copy remain**

```dart
expect(
  find.descendant(of: appBar, matching: find.text('عنوان الفصل')),
  findsOneWidget,
);
expect(find.text('الفصل 1 من 2'), findsOneWidget);
```

- [ ] **Step 4: Run the focused tests and verify red**

Run: `flutter test --no-pub test/features/reader/reader_screen_test.dart test/features/reader/native_reader_content_test.dart`

Expected: FAIL because the settings action is still in the bottom controls, the pill key does not exist, and the 320 layout still uses two rows.

---

### Task 3: Build the Stitch top bar and floating pill

**Files:**
- Create: `lib/features/reader/presentation/reader_stitch_chrome.dart`
- Modify: `lib/features/reader/presentation/reader_screen.dart`
- Modify: `lib/features/reader/presentation/native_reader_content.dart`

**Interfaces:**
- Consumes: `ReaderChromePalette`, chapter title, progress, availability flags, and callbacks.
- Produces: `ReaderStitchTopBar` and `ReaderStitchBottomPill`.

- [ ] **Step 1: Create the top bar**

```dart
class ReaderStitchTopBar extends StatelessWidget {
  const ReaderStitchTopBar({
    required this.title,
    required this.palette,
    required this.onSettings,
    super.key,
  });

  final String title;
  final ReaderChromePalette palette;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      key: const ValueKey('reader-app-bar'),
      toolbarHeight: 64,
      centerTitle: true,
      backgroundColor: palette.background.withValues(alpha: 0.97),
      foregroundColor: palette.foreground,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: palette.border.withValues(alpha: 0.5))),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          key: const ValueKey('reader-settings-button'),
          tooltip: 'إعدادات القراءة',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Create the bottom pill**

```dart
class ReaderStitchBottomPill extends StatelessWidget {
  const ReaderStitchBottomPill({
    required this.palette,
    required this.progressLabel,
    required this.progressValue,
    required this.onPrevious,
    required this.onNext,
    required this.onComments,
    super.key,
  });

  final ReaderChromePalette palette;
  final String progressLabel;
  final double progressValue;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onComments;
```

Its `build` returns a `Container` keyed `reader-floating-pill`, clipped to `BorderRadius.circular(999)`, with `palette.background` at 94% opacity, a border, and a shadow. Inside it, use a `Column` containing the progress row and this single navigation row:

```dart
Row(
  children: [
    Expanded(
      child: _ReaderNavButton(
        tooltip: 'الفصل السابق',
        label: 'السابق',
        icon: Icons.chevron_right_rounded,
        onPressed: onPrevious,
      ),
    ),
    const SizedBox(width: 8),
    IconButton(
      key: const ValueKey('reader-comments-button'),
      tooltip: 'تعليقات الفصل',
      onPressed: onComments,
      icon: const Icon(Icons.chat_bubble_outline_rounded),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: _ReaderNavButton(
        tooltip: 'الفصل التالي',
        label: 'التالي',
        icon: Icons.chevron_left_rounded,
        onPressed: onNext,
        primary: true,
      ),
    ),
  ],
)
```

The progress row uses `LinearProgressIndicator(key: ValueKey('reader-progress-indicator'), minHeight: 3, value: progressValue)` and the existing progress label. It is omitted only when `progressLabel` is empty.

- [ ] **Step 3: Move settings ownership to `ReaderScreen`**

Resolve `readerScheme` and `chromePalette` in `_loadedReaderScaffold`. Replace the inline `AppBar` with:

```dart
ReaderStitchTopBar(
  title: _chapterTitle ?? 'القارئ',
  palette: chromePalette,
  onSettings: _openReaderSettings,
)
```

Remove `onOpenSettings` from `NativeReaderContent` and its constructor call.

- [ ] **Step 4: Replace the legacy controls in `NativeReaderContent`**

Resolve `ReaderChromePalette` from `readerScheme` and `widget.preferences.paletteMode`. Replace `_ReaderFloatingControls` with:

```dart
ReaderStitchBottomPill(
  palette: chromePalette,
  progressLabel: content.total > 0
      ? 'الفصل ${content.position} من ${content.total}'
      : '',
  progressValue: content.total > 0
      ? (content.position / content.total).clamp(0.0, 1.0)
      : 0,
  onPrevious: hasPrevious
      ? () => widget.onOpenChapter(content.navigation.previousApi, 'الفصل السابق')
      : null,
  onNext: hasNext
      ? () => widget.onOpenChapter(content.navigation.nextApi, 'الفصل التالي')
      : null,
  onComments: widget.onOpenComments,
)
```

Delete `_ReaderFloatingControls` and `_ReaderNavButton` from `native_reader_content.dart` after moving their replacement into the new file.

- [ ] **Step 5: Format and run the focused reader tests**

Run: `dart format lib/features/reader/presentation/reader_chrome_palette.dart lib/features/reader/presentation/reader_stitch_chrome.dart lib/features/reader/presentation/reader_screen.dart lib/features/reader/presentation/native_reader_content.dart test/features/reader/reader_chrome_palette_test.dart test/features/reader/reader_screen_test.dart test/features/reader/native_reader_content_test.dart`

Run: `flutter test --no-pub test/features/reader`

Expected: all reader tests pass with no overflow or semantics failures.

---

### Task 4: Visual, integration, documentation, and build verification

**Files:**
- Modify: `test/features/phase3/phase3_reading_surfaces_test.dart`
- Modify: `docs/manual_test_plan.md`

**Interfaces:**
- Consumes: the completed reader chrome.
- Produces: responsive integration coverage and verified documentation.

- [ ] **Step 1: Extend the existing phase-3 responsive journey assertion**

```dart
expect(find.byKey(const ValueKey('reader-floating-pill')), findsOneWidget);
expect(find.byKey(const ValueKey('reader-progress-indicator')), findsOneWidget);
expect(find.byKey(const ValueKey('reader-chapters-button')), findsNothing);
```

Keep the existing 320/600/840 dark/light loop and landscape test; do not duplicate those variants.

- [ ] **Step 2: Update the reader section in the manual test plan**

Replace the loaded-reader chrome expectation with:

```markdown
- عند الضغط على النص يظهر شريط علوي يعرض عنوان الفصل وزر إعدادات القراءة، وتظهر كبسولة سفلية في صف واحد.
- تعرض الكبسولة `السابق` وتعليقات الفصل و`التالي`، ويظهر فوقها شريط تقدم رفيع مع `الفصل X من Y`.
- لا يظهر زر قائمة فصول داخل القارئ، وتختفي الأدوات كلها عند الضغط على النص مرة أخرى.
```

- [ ] **Step 3: Run static and integration verification**

Run: `flutter analyze --no-pub`

Run: `flutter test --no-pub test/features/reader test/features/phase3/phase3_reading_surfaces_test.dart test/widget_test.dart`

Expected: analyzer clean and all selected tests pass.

- [ ] **Step 4: Verify removed and forbidden UI**

Run: `rg -n "reader-chapters-button|format_list_bulleted|Icons\\.download" lib/features/reader`

Expected: no matches.

Run: `git diff --check`

Expected: exit code 0.

- [ ] **Step 5: Build Android**

Run: `flutter build apk --debug --no-pub`

Expected: `build/app/outputs/flutter-apk/app-debug.apk` is produced successfully.
