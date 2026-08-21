# Galaxy Novels Personal Library and Polish Phase 4 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the approved personal-library and supporting-surface redesign without changing server contracts or making authentication mandatory.

**Architecture:** Keep presentation behavior in focused widgets and inject navigation/package-info seams instead of coupling screens to the shell or platform plugins. Reuse the existing repositories and shared async/empty components; only the favorites repository supplies safe undo, while history remains non-destructive because the server contract has no delete operation. Add deterministic responsive and golden harnesses after the functional tasks are green.

**Tech Stack:** Flutter 3.41.7, Dart 3.11.5, Material 3, `package_info_plus: ^8.3.1`, Flutter widget/golden tests.

## Global Constraints

- Guest discovery and reading remain fully available; account actions are optional.
- Splash remains automatic and latest updates continue to open novel details.
- Android is the only release target in this cycle; do not add or change iOS release work.
- Keep the existing API, authentication, favorites, and reading-history repository contracts.
- Only Galaxy Noir and Starlight Paper are user-selectable themes; legacy stored values migrate to one of them.
- Privacy copy remains unchanged and must not gain account, comment, rating, favorite, history, or synchronization data sections.
- Drawer legal/community order remains About, Privacy, Discord; Discord remains `https://discord.gg/fD7U7zbCgM` with the brand mark.
- Touch targets are at least 44×44; support RTL, landscape, and 200% text scale.
- Preserve the dirty working tree and do not stage or commit implementation files.

---

### Task 1: Personal library empty, error, and safe undo states

**Files:**
- Modify: `galaxy_novels_app/lib/features/favorites/presentation/favorites_screen.dart`
- Modify: `galaxy_novels_app/lib/features/favorites/presentation/widgets/favorite_novel_row.dart`
- Modify: `galaxy_novels_app/lib/features/history/presentation/history_screen.dart`
- Modify: `galaxy_novels_app/lib/features/shell/presentation/app_shell.dart`
- Create: `galaxy_novels_app/test/features/favorites/favorites_screen_test.dart`
- Modify: `galaxy_novels_app/test/features/favorites/favorites_integration_test.dart`
- Modify: `galaxy_novels_app/test/features/history/history_screen_test.dart`

**Interfaces:**

- `FavoritesScreen({bool embedded = false, VoidCallback? onOpenLibrary, Key? key})`.
- `HistoryScreen({VoidCallback? onOpenLibrary, Key? key})`.
- `FavoritesRepository.toggle(FavoriteItem)` remains the only mutation API.
- History receives no delete action: a local-only delete would reappear after account history merge and is therefore not a safe undo.

- [ ] **Step 1: Write failing personal-library behavior tests**

Add tests proving that empty favorites/history expose a 44×44 `فتح المكتبة` action, history failure exposes `إعادة المحاولة`, successful favorite removal exposes `تراجع`, undo restores the same item, failure never exposes undo, and an already-restored item is not toggled off again. Add a controlled pending-toggle case: change the authenticated account before completion and assert that the old operation cannot show a SnackBar or offer undo in the new session.

```dart
expect(find.text('فتح المكتبة'), findsOneWidget);
await tester.tap(find.text('فتح المكتبة'));
expect(openLibraryCount, 1);

await tester.tap(find.byKey(const ValueKey('remove-favorite-99')));
expect(find.text('تراجع'), findsOneWidget);
await tester.tap(find.text('تراجع'));
expect(repository.value.contains(99), isTrue);
```

- [ ] **Step 2: Verify RED**

```powershell
flutter test --no-pub test/features/favorites/favorites_screen_test.dart test/features/favorites/favorites_integration_test.dart test/features/history/history_screen_test.dart
```

Expected: FAIL because empty states have no action, history has no retry, and favorite removal has no undo.

- [ ] **Step 3: Implement shared states and shell callbacks**

Use `AppAsyncState.empty/error/loading` and pass shell navigation without importing `ShellDestination` into the screens:

```dart
FavoritesScreen(
  embedded: true,
  onOpenLibrary: () => select(ShellDestination.library),
)

HistoryScreen(
  onOpenLibrary: () => select(ShellDestination.library),
)
```

On `FavoriteToggleResult.removed`, replace the previous SnackBar, show a short Arabic SnackBar with `SnackBarAction(label: 'تراجع')`, and undo only if the same repository/session still owns the item and it is still absent. Hide any old SnackBar when auth changes. Use safe messages for all other results.

- [ ] **Step 4: Make populated rows responsive and accessible**

Allow the favorite details cue, history subheading/count, and progress line to wrap or stack below 360 logical pixels and at 200% text. Preserve the row open action, the separate remove action, Arabic labels, and 44×44 minimum targets.

- [ ] **Step 5: Verify GREEN and review**

```powershell
flutter test --no-pub test/features/favorites test/features/history test/features/shell/adaptive_app_shell_test.dart
flutter analyze --no-pub
```

Expected: all pass and no analyzer issues. Request an independent Task 1 spec/code/test review and close every Critical/Important finding with RED→GREEN coverage.

---

### Task 2: Optional guest account landing, LTR fields, flexible stats, and two theme choices

**Files:**
- Create: `galaxy_novels_app/lib/features/account/presentation/widgets/guest_account_view.dart`
- Modify: `galaxy_novels_app/lib/features/account/presentation/widgets/auth_entry_view.dart`
- Modify: `galaxy_novels_app/lib/features/account/presentation/widgets/login_account_view.dart`
- Modify: `galaxy_novels_app/lib/features/account/presentation/widgets/register_account_view.dart`
- Modify: `galaxy_novels_app/lib/features/account/presentation/widgets/account_stats_grid.dart`
- Modify: `galaxy_novels_app/lib/app/app_theme_controller.dart`
- Modify: `galaxy_novels_app/lib/app/galaxy_novels_app.dart`
- Modify: `galaxy_novels_app/lib/features/settings/presentation/settings_screen.dart`
- Create: `galaxy_novels_app/test/features/account/account_guest_view_test.dart`
- Create: `galaxy_novels_app/test/features/account/account_stats_grid_test.dart`
- Modify: `galaxy_novels_app/test/features/account/login_account_view_test.dart`
- Modify: `galaxy_novels_app/test/features/settings/settings_screen_test.dart`
- Modify: `galaxy_novels_app/test/app/app_theme_controller_test.dart`
- Modify: `galaxy_novels_app/test/app/app_theme_test.dart`
- Modify: `galaxy_novels_app/test/widget_test.dart`

**Interfaces:**

- `GuestAccountView({required VoidCallback onShowLogin, required VoidCallback onShowRegister, String? errorMessage, Key? key})`.
- `AuthEntryView` keeps its existing public constructor and owns an internal guest/login/register mode.
- `LoginAccountView` and `RegisterAccountView` gain `VoidCallback? onBackToGuest` without changing credential callbacks.
- `AppThemeChoice` becomes `{galaxyNoir, starlightPaper}`; unknown/null legacy values resolve to Galaxy Noir.

- [ ] **Step 1: Write failing guest/LTR/flexible-layout tests**

Prove the account initially says `تتصفح كزائر`, shows optional login/register choices, contains no login form before selection, returns to guest, and invokes no auth mutation merely by rendering. Inspect every username/email/password `EditableText` for LTR + left alignment while leaving display name natural. At 320/200%, prove account stats grow beyond a fixed 92px when required and do not truncate labels.

- [ ] **Step 2: Write failing two-theme migration tests**

Assert settings renders exactly `galaxyNoir` and `starlightPaper`, selection semantics update, null/unknown storage maps to `galaxyNoir`, all legacy dark aliases map to `galaxyNoir`, and `desertAstronaut` maps to `starlightPaper`. Add a store fake whose `read()` throws and prove controller loading remains on Galaxy Noir without surfacing the exception.

- [ ] **Step 3: Verify RED**

```powershell
flutter test --no-pub test/features/account/account_guest_view_test.dart test/features/account/account_stats_grid_test.dart test/features/account/login_account_view_test.dart test/features/settings/settings_screen_test.dart test/app/app_theme_controller_test.dart test/app/app_theme_test.dart
```

Expected: FAIL on direct login rendering, RTL editable text, fixed stat height, and the third system theme card.

- [ ] **Step 4: Implement the guest-first account surface**

Introduce an internal enum and switch only within `AuthEntryView`:

```dart
enum _AuthEntryMode { guest, login, register }
```

The guest surface explicitly explains that reading remains available without an account. Login/register forms appear only after a CTA, are centered with `maxWidth: 520`, remain keyboard-scrollable, and can return to guest. Do not add a route-level auth gate.

- [ ] **Step 5: Normalize LTR inputs and flexible account cards**

Apply `textDirection: TextDirection.ltr` and `textAlign: TextAlign.left` to username, email, password, and confirmation inputs only. Replace stat `SizedBox(height: 92)` with a minimum-height constraint and choose 1/2/4 columns from available width and text scale; labels may wrap to two lines.

- [ ] **Step 6: Restrict stored/user theme choices to two**

Remove the system enum case and its settings card. Default and failed/unknown storage use Galaxy Noir. Keep the two existing `ThemeData` definitions and update app switch expressions so Galaxy Noir is dark and Starlight Paper is light.

- [ ] **Step 7: Verify GREEN and review**

```powershell
flutter test --no-pub test/features/account test/features/settings test/app test/widget_test.dart
flutter analyze --no-pub
```

Expected: all pass. Request independent review, especially for guest optionality, credential direction, storage migration, and 200% text.

---

### Task 3: Drawer download shortcut, simple rows, dynamic About version, and support polish

**Files:**
- Modify: `galaxy_novels_app/pubspec.yaml`
- Modify: `galaxy_novels_app/pubspec.lock`
- Modify: `galaxy_novels_app/lib/features/shell/presentation/app_drawer.dart`
- Modify: `galaxy_novels_app/lib/features/shell/presentation/app_drawer_widgets.dart`
- Create: `galaxy_novels_app/lib/features/about/application/app_version_info.dart`
- Modify: `galaxy_novels_app/lib/features/about/presentation/about_screen.dart`
- Modify: `galaxy_novels_app/test/features/shell/app_drawer_test.dart`
- Create: `galaxy_novels_app/test/features/about/about_screen_test.dart`
- Modify: `galaxy_novels_app/test/features/privacy/privacy_policy_screen_test.dart`
- Modify: `galaxy_novels_app/test/widget_test.dart`

**Interfaces:**

- Add `package_info_plus: ^8.3.1`; this is compatible with the existing Android Gradle setup and avoids a build-system upgrade.
- `AppVersionInfo({required String version, required String buildNumber})` exposes `displayLabel`.
- `typedef AppVersionLoader = Future<AppVersionInfo> Function()`.
- `AboutScreen({AppVersionLoader versionLoader = loadPackageVersionInfo, Key? key})`.
- Drawer adds `_DrawerDestination.downloads` and keeps the final three entries in their approved order.
- Downloads opens inside a standalone `Scaffold(appBar: AppBar(title: Text('التنزيلات')), body: DownloadsScreen())`; `DownloadsScreen` itself remains an embeddable body.

- [ ] **Step 1: Write failing drawer tests**

Assert the downloads row exists, closes the drawer, opens a standalone page whose AppBar title is `التنزيلات`, exposes a working back button, all destination targets are at least 44px, drawer rows have no independent outline/card border, and the final positions remain About → Privacy → Discord.

- [ ] **Step 2: Write failing About/package tests**

Use injected loaders to prove `9.8.7` + `42` displays `الإصدار 9.8.7 (42)`, an empty build number has no empty parentheses, the loader runs once across rebuilds, plugin failure shows safe fallback without a raw exception, and the loaded label is supplied to the license page.

- [ ] **Step 3: Expand privacy behavior tests**

Test both external Google links, link failure feedback, 44px targets, both themes, 320/600/840, 320 at 200%, and landscape. Do not change the approved policy text.

- [ ] **Step 4: Verify RED**

```powershell
flutter test --no-pub test/features/shell/app_drawer_test.dart test/features/about/about_screen_test.dart test/features/privacy/privacy_policy_screen_test.dart
```

Expected: FAIL because downloads and dynamic version do not exist and drawer rows are still outlined cards.

- [ ] **Step 5: Implement support surfaces**

Add the download destination in the application section and open `DownloadsScreen` inside a `Scaffold` with an AppBar titled `التنزيلات`, matching the existing standalone wrapper used from the account surface. Convert `_DrawerTile` to a simple transparent `InkWell` row while preserving its key, label, brand icon, directional chevron, and minimum height.

Load `PackageInfo.fromPlatform()` once in `AboutScreen.initState`, map it through `AppVersionInfo`, and collapse plugin/platform failures to a safe `الإصدار غير متاح` label. Use the same resolved value for `showLicensePage`.

- [ ] **Step 6: Verify GREEN and review**

```powershell
flutter test --no-pub test/features/shell test/features/about test/features/privacy test/widget_test.dart
flutter analyze --no-pub
flutter build apk --debug --no-pub
```

Expected: tests/analyze/build pass. Request independent review of drawer ordering, URI contract, plugin failure handling, and package compatibility.

---

### Task 4: Final responsive and golden matrix

**Files:**
- Create: `galaxy_novels_app/test/features/phase4/phase4_personal_surfaces_test.dart`
- Create: `galaxy_novels_app/test/goldens/phase4_surfaces_golden_test.dart`
- Create: `galaxy_novels_app/test/goldens/goldens/phase4_*.png` through the approved Flutter golden update command

**Interfaces:**

- Use real presentation widgets with immutable fakes and injected package/URI seams.
- Use Flutter's built-in `matchesGoldenFile`; add no golden test dependency.
- Load the bundled Cairo font, set device pixel ratio 1, disable animations, and use stable fixture dates/version strings.

- [ ] **Step 1: Add the functional responsive matrix**

Cover guest account, authenticated account, empty/populated favorites, empty/populated history, settings, drawer, About, and Privacy in both themes at 320/600/840, plus 320 at 200% and landscape. Assert no raw exception, overflow, clipped interactive label, target under 44, or unexpected login gate.

- [ ] **Step 2: Verify the integrated acceptance matrix**

```powershell
flutter test --no-pub test/features/phase4/phase4_personal_surfaces_test.dart
```

Expected: PASS because each production behavior was already driven RED→GREEN in Tasks 1–3. If this integrated journey exposes a cross-screen regression, preserve it as a failing test and fix production before continuing.

- [ ] **Step 3: Add deterministic golden cases**

Create paired Galaxy Noir/Starlight Paper images at 320, 600, and 840 for the personal library, account/settings, and supporting drawer/About/Privacy surfaces. Keep 200% and landscape as dedicated accessibility goldens or functional matrix cases when the full page scroll height would make a golden misleading.

- [ ] **Step 4: Generate and inspect goldens**

```powershell
flutter test --update-goldens test/goldens/phase4_surfaces_golden_test.dart
flutter test --no-pub test/goldens/phase4_surfaces_golden_test.dart
```

Open every generated PNG and inspect RTL order, whitespace, contrast, clipping, row rhythm, and both theme identities. Fix production with RED→GREEN coverage before regenerating any baseline.

- [ ] **Step 5: Review Task 4**

Request independent review of the matrix assertions and golden stability. Reject tests that merely snapshot a broken state or rely on plugin/network availability.

---

### Task 5: Phase 4 and redesign quality gate

- [ ] **Step 1: Format only Phase 4 Dart files** with `dart format`; expected no unrelated changes.
- [ ] **Step 2: Run focused suites** for favorites, history, account, settings, shell, About, Privacy, Phase 4, and goldens; record the exact passing count.
- [ ] **Step 3: Run `flutter analyze --no-pub`**; expected `No issues found!`.
- [ ] **Step 4: Run `flutter test --no-pub`**; expected all tests pass and record the exact count.
- [ ] **Step 5: Run `flutter build apk --debug --no-pub`**; expected a fresh `build/app/outputs/flutter-apk/app-debug.apk`.
- [ ] **Step 6: Run `git diff --check`, `git diff --cached --check`, `git status --short`, and `git diff --stat`**; expected no whitespace errors and no staged implementation files.
- [ ] **Step 7: Attempt the approved small-phone/tablet visual gate**. If disk space still prevents the AVD from booting or no tablet AVD exists, record the environment limitation and rely on the inspected goldens plus exact 320/600/840 matrix without claiming a manual device pass.
- [ ] **Step 8: Request broad final redesign review** against the approved design, all four phase reports, full diff, and final artifacts; do not close with any Critical/Important finding.

## Self-Review Record

- Spec coverage: design sections 7.7, 7.8, 7.9, 10, 11, 12, 13 Phase 4, and final acceptance each map to a task.
- Preserved contracts: guest access, latest→details, repository/API boundaries, privacy exclusions, Discord URL/order, and Android-only release scope are explicit.
- Placeholder scan: no TBD/TODO, undefined future interface, or generic error-handling step remains.
- Type consistency: callbacks, `AppVersionInfo`, `AppVersionLoader`, and the two `AppThemeChoice` cases are named at producers and consumers.
- Risk controls: safe undo is limited to favorites; history is deliberately non-destructive until a server delete/tombstone contract exists; plugin/network dependencies are injected in tests.
