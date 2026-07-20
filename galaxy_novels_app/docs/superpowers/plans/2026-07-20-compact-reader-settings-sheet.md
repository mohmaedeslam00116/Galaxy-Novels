# Compact Reader Settings Sheet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Inline execution is mandatory because the user explicitly prohibited subagents.

**Goal:** Rebuild the in-reader bottom settings sheet as a compact, fixed-header tabbed surface that follows the Stitch dark-purple visual language without changing reader preferences behavior.

**Architecture:** Keep `ReaderPreferences` and the repository callback flow unchanged. Restructure the existing presentation widgets so the bottom sheet owns a fixed header, fixed tab selector, scrollable active panel, and quiet reset footer; reuse the same control widgets from the full settings screen so its behavior remains intact.

**Tech Stack:** Flutter, Material 3, `AppThemeTokens`, widget tests, Flutter golden tests.

## Global Constraints

- Modify only the bottom sheet presentation and shared reader-setting controls required by it; do not redesign `ReaderSettingsScreen`.
- Keep the tabs «النص»، «الألوان»، and «الشاشة» and preserve every existing preference and key.
- Keep immediate updates through `ValueChanged<ReaderPreferences>`; do not add storage, network, or navigation behavior.
- Use an approximately 82% sheet height, 8–12 px radii, 16 px phone margins, and minimum 44×44 px tap targets.
- Use purple only for active states and `AppThemeTokens`/theme colors for dark and light compatibility.
- Support widths 320, 600, and 840, 200% text, and short landscape.
- Do not spawn subagents.
- Do not stage or commit production/test files that contained pre-existing user changes; verification evidence replaces per-task implementation commits in this shared dirty worktree.

---

### Task 1: Fixed sheet frame and tab navigation

**Files:**
- Create: `test/features/reader/reader_settings_sheet_layout_test.dart`
- Modify: `lib/features/reader/presentation/reader_settings_sheet.dart`

**Interfaces:**
- Consumes: `ReaderSettingsSheet({required ReaderPreferences preferences, required ValueChanged<ReaderPreferences> onChanged})` and `ReaderPreferences.defaults`.
- Produces: keys `reader-settings-shell`, `reader-settings-header`, `reader-settings-tabs`, `reader-settings-panel-scroll`, and the existing `reader-settings-reset`.

- [ ] **Step 1: Write the failing frame test**

```dart
testWidgets('reader sheet keeps navigation and reset outside panel scrolling', (
  tester,
) async {
  await _pumpSheet(tester, const Size(320, 720));

  expect(find.byKey(const ValueKey('reader-settings-shell')), findsOneWidget);
  expect(find.byKey(const ValueKey('reader-settings-header')), findsOneWidget);
  expect(find.byKey(const ValueKey('reader-settings-tabs')), findsOneWidget);
  expect(
    find.byKey(const ValueKey('reader-settings-panel-scroll')),
    findsOneWidget,
  );
  expect(find.byKey(const ValueKey('reader-settings-reset')), findsOneWidget);
});
```

Use this harness so tests observe the real callback without a repository mock:

```dart
Future<_SheetHarness> _pumpSheet(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
  ReaderPreferences preferences = ReaderPreferences.defaults,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final harness = _SheetHarness(preferences);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: ReaderSettingsSheet(
              preferences: preferences,
              onChanged: (next) => harness.preferences = next,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

class _SheetHarness {
  _SheetHarness(this.preferences);
  ReaderPreferences preferences;
}
```

- [ ] **Step 2: Run the frame test and verify RED**

Run:

```powershell
flutter test test/features/reader/reader_settings_sheet_layout_test.dart --plain-name "reader sheet keeps navigation"
```

Expected: FAIL because `reader-settings-shell` and the fixed-region keys do not exist.

- [ ] **Step 3: Implement the fixed sheet structure**

Change `ReaderSettingsSheet` to render an 82%-height `SafeArea` sheet with this structure:

```dart
SizedBox(
  key: const ValueKey('reader-settings-shell'),
  height: MediaQuery.sizeOf(context).height * 0.82,
  child: Column(
    children: [
      _ReaderSettingsHeader(onClose: () => Navigator.maybePop(context)),
      _ReaderSettingsPanelSelector(
        key: const ValueKey('reader-settings-tabs'),
        selected: _panel,
        onChanged: (panel) => setState(() => _panel = panel),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: SingleChildScrollView(
          key: const ValueKey('reader-settings-panel-scroll'),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildPanel(_preferences),
        ),
      ),
      _ReaderSettingsResetBar(
        enabled: _preferences != ReaderPreferences.defaults,
        onReset: () => _update(ReaderPreferences.defaults),
      ),
    ],
  ),
)
```

The header uses a compact title and a 44 px close `IconButton`. The sheet state owns `_ReaderSettingsPanel _panel = _ReaderSettingsPanel.text`; updates still call the supplied callback immediately.

- [ ] **Step 4: Replace independent chips with a connected tab surface**

Render the selector inside one bordered `Material`. At normal scale each tab is `Expanded`; at text scale ≥1.5 or width <280 use a vertical `Column`. Each tab retains its existing key and exposes `Semantics(button: true, selected: selected == option.value)`.

- [ ] **Step 5: Run the focused and existing settings tests**

```powershell
flutter test test/features/reader/reader_settings_sheet_layout_test.dart
flutter test test/features/reader/reader_screen_test.dart --plain-name "reader settings"
flutter test test/features/reader/reader_accessibility_test.dart --plain-name "reader settings remain"
```

Expected: all tests PASS with no overflow warnings.

### Task 2: Compact text settings groups

**Files:**
- Modify: `test/features/reader/reader_settings_sheet_layout_test.dart`
- Modify: `lib/features/reader/presentation/reader_settings_sheet.dart`
- Modify: `lib/features/reader/presentation/reader_font_selector.dart`

**Interfaces:**
- Consumes: `ReaderPreferences.increaseFont`, `decreaseFont`, `increaseLineHeight`, `decreaseLineHeight`, `copyWith`, and `ReaderFontSelector`.
- Produces: compact surfaces keyed `reader-font-grid`, `reader-text-stepper-table`, and `reader-text-width-selector`; preserves all existing interaction keys.

- [ ] **Step 1: Write failing structure and interaction tests**

```dart
testWidgets('text tab groups typography controls without changing behavior', (
  tester,
) async {
  final harness = await _pumpSheet(tester, const Size(320, 720));

  expect(find.byKey(const ValueKey('reader-font-grid')), findsOneWidget);
  expect(
    find.byKey(const ValueKey('reader-text-stepper-table')),
    findsOneWidget,
  );
  expect(
    find.byKey(const ValueKey('reader-text-width-selector')),
    findsOneWidget,
  );

  await tester.tap(find.byKey(const ValueKey('reader-font-increase')));
  await tester.pump();
  expect(harness.preferences.fontScale, 1.1);
});
```

- [ ] **Step 2: Run and verify RED**

Run the new test. Expected: FAIL because the three grouping keys do not exist.

- [ ] **Step 3: Build the connected typography table**

Replace the two standalone `_StepperRow` columns with one bordered surface containing two `_ReaderValueRow` children separated by a thin divider. Each row has label, current value, and decrease/increase controls in one responsive row; at 200% text it stacks the label above the control group.

```dart
_ReaderValueTable(
  key: const ValueKey('reader-text-stepper-table'),
  rows: [
    _ReaderValueDefinition(
      label: 'حجم الخط',
      value: '${(preferences.fontScale * 100).round()}%',
      decreaseKey: const ValueKey('reader-font-decrease'),
      increaseKey: const ValueKey('reader-font-increase'),
      onDecrease: () => onChanged(preferences.decreaseFont()),
      onIncrease: () => onChanged(preferences.increaseFont()),
    ),
    _ReaderValueDefinition(
      label: 'تباعد الأسطر',
      value: preferences.lineHeight.toStringAsFixed(2),
      decreaseKey: const ValueKey('reader-line-decrease'),
      increaseKey: const ValueKey('reader-line-increase'),
      onDecrease: () => onChanged(preferences.decreaseLineHeight()),
      onIncrease: () => onChanged(preferences.increaseLineHeight()),
    ),
  ],
)
```

- [ ] **Step 4: Compact the font and text-width selectors**

Add `reader-font-grid` to the font `Wrap`, reduce font tile minimum height from 88 to 72, retain the label/sample/check hierarchy, and make font tiles full width when text scale is ≥1.5. Wrap the text-width choices in one bordered connected surface keyed `reader-text-width-selector`, retaining `reader-width-compact`, `reader-width-comfortable`, and `reader-width-wide`.

- [ ] **Step 5: Run text-control tests**

```powershell
flutter test test/features/reader/reader_settings_sheet_layout_test.dart --plain-name "text tab"
flutter test test/features/reader/reader_screen_test.dart --plain-name "reader settings"
```

Expected: PASS; font, size, line height, and width callbacks retain current values.

### Task 3: Palette and screen settings surfaces

**Files:**
- Modify: `test/features/reader/reader_settings_sheet_layout_test.dart`
- Modify: `lib/features/reader/presentation/reader_settings_sheet.dart`

**Interfaces:**
- Consumes: `ReaderPaletteMode`, `ReaderBrightnessMode`, `ReaderPreferences.copyWith`.
- Produces: `reader-palette-grid`, `reader-screen-settings-surface`, and `reader-brightness-mode-selector`; preserves existing palette, immersive, brightness mode, and slider keys.

- [ ] **Step 1: Write failing palette and screen structure tests**

```dart
testWidgets('color and screen tabs use compact grouped surfaces', (
  tester,
) async {
  await _pumpSheet(tester, const Size(320, 720));

  await tester.tap(find.byKey(const ValueKey('reader-settings-tab-colors')));
  await tester.pump();
  expect(find.byKey(const ValueKey('reader-palette-grid')), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('reader-settings-tab-screen')));
  await tester.pump();
  expect(
    find.byKey(const ValueKey('reader-screen-settings-surface')),
    findsOneWidget,
  );
  expect(
    find.byKey(const ValueKey('reader-brightness-mode-selector')),
    findsOneWidget,
  );
});
```

- [ ] **Step 2: Run and verify RED**

Expected: FAIL because the grouping keys are absent.

- [ ] **Step 3: Restyle the palette grid**

Key the `Wrap` as `reader-palette-grid`, keep two columns below 520 and three above, and use a 72 px minimum tile height. Use theme surface colors, a 1 px inactive border, a 1.5 px primary active border, and the existing swatch/check semantics.

- [ ] **Step 4: Group screen controls**

Wrap immersive mode and brightness controls in a single bordered `Material` keyed `reader-screen-settings-surface`, separated by a divider. Replace the two brightness chips with a connected selector keyed `reader-brightness-mode-selector`. Preserve `reader-immersive-toggle`, `reader-brightness-system`, `reader-brightness-manual`, and `reader-brightness-slider`.

- [ ] **Step 5: Verify interaction behavior**

```powershell
flutter test test/features/reader/reader_settings_sheet_layout_test.dart --plain-name "color and screen"
flutter test test/features/reader/reader_screen_test.dart --plain-name "reader settings controls immersive"
```

Expected: PASS; the slider is disabled in system mode and enabled after selecting manual mode.

### Task 4: Responsive, accessibility, and integration coverage

**Files:**
- Modify: `test/features/reader/reader_settings_sheet_layout_test.dart`
- Modify: `test/features/reader/reader_accessibility_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: production keys from Tasks 1–3.
- Produces: regression coverage for 320/600/840 widths, 200% text, short landscape, reset, and repository persistence.

- [ ] **Step 1: Add viewport regression cases**

Test `Size(320, 720)`, `Size(600, 800)`, `Size(840, 900)`, `Size(840, 360)`, and `Size(320, 1100)` with 200% text. For every case open all tabs, scroll to the last control, assert it is hit-testable, and assert `tester.takeException()` is null.

- [ ] **Step 2: Add semantics and tap-size checks**

Assert the three tabs expose selected semantics correctly, the close/reset actions are at least 44×44 px, and all seven palette choices remain reachable at 200% text.

- [ ] **Step 3: Add reset behavior test**

Start with non-default preferences, tap `reader-settings-reset`, and assert the callback receives `ReaderPreferences.defaults`; rebuild with defaults and assert the reset semantics are disabled.

- [ ] **Step 4: Run reader and shell integration tests**

```powershell
flutter test test/features/reader
flutter test test/widget_test.dart --plain-name "settings screen opens reader settings"
```

Expected: all tests PASS and repository values persist after closing and reopening the settings route.

### Task 5: Golden coverage and final verification

**Files:**
- Modify: `test/goldens/phase4_surfaces_golden_test.dart`
- Create: `test/goldens/goldens/phase4_readerSettingsSheet_galaxyNoir_320.png`
- Create: `test/goldens/goldens/phase4_readerSettingsSheet_galaxyNoir_600.png`
- Create: `test/goldens/goldens/phase4_readerSettingsSheet_galaxyNoir_840.png`
- Create: `test/goldens/goldens/phase4_readerSettingsSheet_starlightPaper_320.png`
- Create: `test/goldens/goldens/phase4_readerSettingsSheet_starlightPaper_600.png`
- Create: `test/goldens/goldens/phase4_readerSettingsSheet_starlightPaper_840.png`

**Interfaces:**
- Consumes: `ReaderSettingsSheet(preferences: ReaderPreferences.defaults, onChanged: _ignoreReaderPreferences)` where `_ignoreReaderPreferences(ReaderPreferences preferences) {}` is a top-level golden callback.
- Produces: deterministic dark/light visual baselines for compact and wide layouts.

- [ ] **Step 1: Add the golden group and verify RED**

Add `_GoldenGroup.readerSettingsSheet` and render:

```dart
_GoldenGroup.readerSettingsSheet => Scaffold(
  body: ReaderSettingsSheet(
    preferences: ReaderPreferences.defaults,
    onChanged: _ignoreReaderPreferences,
  ),
),
```

Run:

```powershell
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name readerSettingsSheet
```

Expected: FAIL because the baseline PNG files do not exist.

- [ ] **Step 2: Generate and inspect goldens**

```powershell
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name readerSettingsSheet --update-goldens
```

Inspect dark/light 320 and 840 images for clipped Arabic, oversized components, inconsistent borders, and incorrect active-purple hierarchy.

- [ ] **Step 3: Run the final verification suite**

```powershell
dart format lib/features/reader test/features/reader test/widget_test.dart test/goldens/phase4_surfaces_golden_test.dart
flutter test test/features/reader
flutter test test/widget_test.dart --plain-name "reader settings"
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name readerSettingsSheet
flutter analyze
flutter build apk --debug
```

Expected: formatting produces no remaining changes, all tests and goldens pass, analysis reports `No issues found!`, and the APK is created at `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 4: Review only the scoped diff**

```powershell
git diff --check -- lib/features/reader/presentation/reader_settings_sheet.dart lib/features/reader/presentation/reader_font_selector.dart test/features/reader/reader_settings_sheet_layout_test.dart test/features/reader/reader_accessibility_test.dart test/widget_test.dart test/goldens/phase4_surfaces_golden_test.dart
git status --short
```

Confirm no download feature, full reader settings screen, preference domain, or repository behavior was changed.
