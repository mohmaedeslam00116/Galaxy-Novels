# Obsidian Violet Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use test-driven development while executing this focused plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Galaxy Noir's blue-cyan visual tokens with the approved charcoal-and-violet Obsidian Violet palette.

**Architecture:** `AppThemeTokens` is the semantic boundary used by the application. Change only the Galaxy Noir constants in `AppTheme`; no widgets, routes, dependencies, or selector values need to change.

**Tech Stack:** Flutter 3.41.7, Dart 3.11.5, Material 3, flutter_test.

## Global Constraints

- Preserve the two selectable themes and their existing identifiers.
- Keep Starlight Paper unchanged.
- Keep WCAG AA checks for primary/secondary text and text on the brand action.
- Do not change guest access, navigation, API contracts, privacy copy, or iOS.
- Preserve the dirty working tree; do not stage or commit files.

---

### Task 1: Define and verify Obsidian Violet tokens

**Files:**

- Modify: `galaxy_novels_app/test/app/app_theme_test.dart`
- Modify: `galaxy_novels_app/lib/app/app_theme.dart`

- [x] **Step 1: Write the failing palette expectation**

Replace the Galaxy Noir assertions with the approved semantic values:

```dart
expect(tokens.canvas, const Color(0xFF121014));
expect(tokens.surface, const Color(0xFF1B1720));
expect(tokens.surfaceRaised, const Color(0xFF26202E));
expect(tokens.brand, const Color(0xFFB9A6FF));
expect(tokens.onBrand, const Color(0xFF21152D));
```

- [x] **Step 2: Verify RED**

Run `flutter test --no-pub test/app/app_theme_test.dart`.

Expected: the Galaxy Noir semantic-palette test fails because it still contains the former blue-cyan constants.

- [x] **Step 3: Implement the approved semantic constants**

Update only the `AppTheme.galaxyNoir` token constants to the approved values:

```dart
canvas: Color(0xFF121014),
surface: Color(0xFF1B1720),
surfaceRaised: Color(0xFF26202E),
contentPrimary: Color(0xFFEEE9F2),
contentSecondary: Color(0xFFC9C1D0),
brand: Color(0xFFB9A6FF),
onBrand: Color(0xFF21152D),
brandContainer: Color(0xFF35264A),
onBrandContainer: Color(0xFFE8DEFF),
outline: Color(0xFF393240),
warning: Color(0xFFE8C77D),
```

- [x] **Step 4: Verify GREEN**

Run `flutter test --no-pub test/app/app_theme_test.dart` then `flutter analyze --no-pub`.

Expected: all tests pass and analysis reports no issues.

- [x] **Step 5: Format and inspect the exact diff**

Run `dart format lib/app/app_theme.dart test/app/app_theme_test.dart` then `git diff --check -- lib/app/app_theme.dart test/app/app_theme_test.dart`.

Expected: no whitespace errors and no unrelated code changes.
