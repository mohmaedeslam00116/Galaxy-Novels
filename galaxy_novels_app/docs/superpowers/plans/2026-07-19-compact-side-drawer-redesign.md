# Compact Side Drawer Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Do not use subagents; the user explicitly prohibited them.

**Goal:** Replace the current card-heavy drawer with a compact RTL assistance menu containing two grouped panels, five destinations, and a dynamically loaded app-version label.

**Architecture:** Keep navigation ownership in `AppDrawer` and reuse the existing `AppVersionLoader` abstraction from the About feature. Keep presentation helpers in the existing `part` file, but turn the footer into a small stateful version label so package metadata is loaded once and failures remain local to the footer.

**Tech Stack:** Flutter, Dart, Material, `package_info_plus`, `flutter_test`, golden tests.

## Global Constraints

- Do not use subagents.
- Do not restore an account or downloads destination in the drawer.
- Preserve the existing destination behavior: close the drawer, then open the same screen or external Discord URI.
- Keep every interactive row at least 44×44 logical pixels.
- Use `AppThemeTokens` for semantic dark/light colors; keep Discord's official brand color limited to its icon.
- Keep the drawer scrollable and safe at widths 320, 600, and 840 pixels and under enlarged text.
- Preserve unrelated dirty-worktree changes. Before every commit, inspect the staged diff and skip the commit if it would capture unrelated pre-existing edits.

---

## File Map

- Modify `lib/features/shell/presentation/app_drawer.dart`: remove the account destination, define the two approved groups, inject the version loader, and pass stable section IDs to presentation widgets.
- Modify `lib/features/shell/presentation/app_drawer_widgets.dart`: compact the header, render each group as one bordered panel with dividers, compact destination rows, and replace the decorative footer with an asynchronous version label.
- Modify `test/features/shell/app_drawer_test.dart`: lock the content hierarchy, panel structure, touch targets, version success/failure behavior, and existing navigation behavior.
- Modify `test/features/phase4/phase4_personal_surfaces_test.dart`: extend the responsive matrix assertion so account and downloads remain absent and the approved groups remain visible.
- Modify `test/goldens/phase4_surfaces_golden_test.dart`: inject a deterministic version loader into the drawer showcase.
- Update `test/goldens/goldens/phase4_support_{galaxyNoir,starlightPaper}_{320,600,840}.png`: approve the compact drawer appearance in both themes and all supported widths.

### Task 1: Lock the approved drawer contract with failing widget tests

**Files:**
- Modify: `test/features/shell/app_drawer_test.dart`

**Interfaces:**
- Consumes: `AppVersionInfo`, `AppVersionLoader`, and the current `AppDrawer` constructor.
- Produces: test expectations for `drawer-section-library`, `drawer-section-about`, `drawer-app-version`, and the five retained destination keys.

- [ ] **Step 1: Add the version abstraction import and injectable test surface**

Add this import beside the other feature imports:

```dart
import 'package:galaxy_novels_app/features/about/application/app_version_info.dart';
```

Change the surface helper to accept a loader and inject it into the drawer:

```dart
Widget _surface({
  required ExternalUriLauncher uriLauncher,
  AppVersionLoader versionLoader = _successfulVersionLoader,
}) {
  return AppDependencies(
    config: const AppConfig(),
    homeRepository: const FakeHomeRepository(),
    catalogRepository: const FakeCatalogRepository(),
    novelRepository: const FakeNovelRepository(result: null),
    readerRepository: const _TestReaderRepository(),
    rankingsRepository: const FakeRankingsRepository(),
    searchRepository: const FakeSearchRepository(),
    readingHistoryRepository: const _TestReadingHistoryRepository(),
    readerPreferencesRepository: FakeReaderPreferencesRepository(),
    authRepository: FakeAuthRepository(),
    commentsRepository: FakeCommentsRepository.empty(),
    favoritesRepository: FakeFavoritesRepository(),
    novelEngagementRepository: FakeNovelEngagementRepository(),
    vipRepository: const FakeVipRepository(),
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        drawer: AppDrawer(
          uriLauncher: uriLauncher,
          versionLoader: versionLoader,
        ),
        body: Builder(
          builder: (context) => IconButton(
            key: const ValueKey('open-drawer'),
            onPressed: Scaffold.of(context).openDrawer,
            icon: const Icon(Icons.menu),
          ),
        ),
      ),
    ),
  );
}

Future<AppVersionInfo> _successfulVersionLoader() async {
  return const AppVersionInfo(version: '9.8.7', buildNumber: '42');
}
```

- [ ] **Step 2: Replace the old six-destination row test with the approved content and grouping test**

Use these assertions:

```dart
testWidgets('shows only the approved assistance destinations in two groups', (
  tester,
) async {
  await tester.pumpWidget(_surface(uriLauncher: (_) async => true));
  await _openDrawer(tester);

  expect(find.text('المكتبة والتفضيلات'), findsOneWidget);
  expect(find.text('عن التطبيق'), findsOneWidget);
  expect(
    find.byKey(const ValueKey('drawer-section-library')),
    findsOneWidget,
  );
  expect(
    find.byKey(const ValueKey('drawer-section-about')),
    findsOneWidget,
  );

  for (final destination in <String>[
    'favorites',
    'settings',
    'about',
    'privacy',
    'discord',
  ]) {
    expect(
      find.byKey(ValueKey('drawer-destination-$destination')),
      findsOneWidget,
    );
  }

  expect(
    find.byKey(const ValueKey('drawer-destination-account')),
    findsNothing,
  );
  expect(
    find.byKey(const ValueKey('drawer-destination-downloads')),
    findsNothing,
  );
  expect(find.text('حسابي'), findsNothing);
  expect(find.text('التنزيلات'), findsNothing);
  expect(find.text('قراءة عربية، تجربة كونية'), findsNothing);
});
```

- [ ] **Step 3: Add touch-target and version-state tests**

Add these tests:

```dart
testWidgets('keeps every compact destination accessible and at least 44px', (
  tester,
) async {
  final semantics = tester.ensureSemantics();
  await tester.pumpWidget(_surface(uriLauncher: (_) async => true));
  await _openDrawer(tester);

  for (final destination in <String>[
    'favorites',
    'settings',
    'about',
    'privacy',
    'discord',
  ]) {
    final row = find.byKey(ValueKey('drawer-destination-$destination'));
    expect(tester.getSize(row).height, greaterThanOrEqualTo(44));
    expect(tester.getSemantics(row).label, isNotEmpty);
  }
  semantics.dispose();
});

testWidgets('shows the injected package version in the compact footer', (
  tester,
) async {
  await tester.pumpWidget(_surface(uriLauncher: (_) async => true));
  await _openDrawer(tester);

  expect(
    find.byKey(const ValueKey('drawer-app-version')),
    findsOneWidget,
  );
  expect(find.text('الإصدار 9.8.7 (42)'), findsOneWidget);
});

testWidgets('shows a safe version fallback when package metadata fails', (
  tester,
) async {
  await tester.pumpWidget(
    _surface(
      uriLauncher: (_) async => true,
      versionLoader: () async => throw Exception('metadata failed'),
    ),
  );
  await _openDrawer(tester);

  expect(tester.takeException(), isNull);
  expect(find.text('الإصدار غير متاح'), findsOneWidget);
});
```

- [ ] **Step 4: Run the focused tests and confirm the new contract fails**

Run:

```powershell
flutter test test/features/shell/app_drawer_test.dart
```

Expected: FAIL because `AppDrawer.versionLoader`, the new section keys, the new group titles, and the version footer do not exist yet, and the account destination still renders.

- [ ] **Step 5: Commit the red tests only if the staged diff is isolated**

Run:

```powershell
git add -- test/features/shell/app_drawer_test.dart
git diff --cached --check
git diff --cached --name-only
git commit -m "test: define compact drawer contract"
```

Expected: only `test/features/shell/app_drawer_test.dart` is staged. If the file contains unrelated pre-existing edits that cannot be separated safely, unstage it and continue without this commit.

### Task 2: Implement the compact grouped drawer and version footer

**Files:**
- Modify: `lib/features/shell/presentation/app_drawer.dart`
- Modify: `lib/features/shell/presentation/app_drawer_widgets.dart`

**Interfaces:**
- Consumes: `AppVersionLoader loadPackageVersionInfo()` and `_DrawerDestination` navigation behavior.
- Produces: `AppDrawer({ExternalUriLauncher uriLauncher, AppVersionLoader versionLoader, Key? key})`, two keyed grouped panels, and `_DrawerVersionLabel`.

- [ ] **Step 1: Remove account and inject the version loader**

In `app_drawer.dart`, remove the account-screen import and `_DrawerDestination.account`. Add:

```dart
import '../../about/application/app_version_info.dart';
```

Use this constructor and field:

```dart
const AppDrawer({
  this.uriLauncher = launchExternalUri,
  this.versionLoader = loadPackageVersionInfo,
  super.key,
});

final ExternalUriLauncher uriLauncher;
final AppVersionLoader versionLoader;
```

Define only the approved groups:

```dart
static const _libraryEntries = [
  _DrawerEntry(
    destination: _DrawerDestination.favorites,
    label: 'المفضلة',
    icon: Icons.bookmark_outline_rounded,
  ),
  _DrawerEntry(
    destination: _DrawerDestination.settings,
    label: 'الإعدادات',
    icon: Icons.tune_rounded,
  ),
];

static const _aboutEntries = [
  _DrawerEntry(
    destination: _DrawerDestination.about,
    label: 'حول التطبيق',
    icon: Icons.info_outline_rounded,
  ),
  _DrawerEntry(
    destination: _DrawerDestination.privacy,
    label: 'سياسة الخصوصية',
    icon: Icons.privacy_tip_outlined,
  ),
  _DrawerEntry(
    destination: _DrawerDestination.discord,
    label: 'مجتمع Discord',
    icon: Icons.forum_outlined,
    iconType: _DrawerIconType.discord,
  ),
];
```

Remove the account switch branch so the switch remains exhaustive.

- [ ] **Step 2: Build the approved compact hierarchy**

Replace the drawer `ListView` children with:

```dart
children: [
  const _DrawerHeader(),
  const SizedBox(height: 16),
  _DrawerSection(
    id: 'library',
    title: 'المكتبة والتفضيلات',
    entries: _libraryEntries,
    onOpen: (destination) =>
        unawaited(_openDestination(context, destination)),
  ),
  const SizedBox(height: 16),
  _DrawerSection(
    id: 'about',
    title: 'عن التطبيق',
    entries: _aboutEntries,
    onOpen: (destination) =>
        unawaited(_openDestination(context, destination)),
  ),
  const SizedBox(height: 14),
  _DrawerVersionLabel(versionLoader: versionLoader),
],
```

Keep the `ListView` padding compact at `EdgeInsets.fromLTRB(12, 12, 12, 16)`.

- [ ] **Step 3: Compact the header and render section panels with dividers**

In `app_drawer_widgets.dart`, keep `_DrawerHeader` as a bordered `DecoratedBox`, but use `EdgeInsets.all(12)`, a 44×44 logo, an 10-pixel gap, `titleMedium` for the app name, and `bodySmall` for the tagline.

Extend `_DrawerSection` with a stable ID:

```dart
const _DrawerSection({
  required this.id,
  required this.title,
  required this.entries,
  required this.onOpen,
});

final String id;
```

After the small title row, render the entries inside one panel:

```dart
DecoratedBox(
  key: ValueKey('drawer-section-$id'),
  decoration: BoxDecoration(
    color: tokens.surfaceRaised,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: tokens.border),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0)
            Divider(
              key: ValueKey('drawer-divider-$id-$index'),
              height: 1,
              thickness: 1,
              indent: 12,
              endIndent: 12,
              color: tokens.border.withValues(alpha: 0.72),
            ),
          _DrawerTile(
            entry: entries[index],
            onTap: () => onOpen(entries[index].destination),
          ),
        ],
      ],
    ),
  ),
),
```

- [ ] **Step 4: Compact the row and icon without shrinking accessibility**

Keep `_DrawerTile` semantic wrapping and transparent `Material`. Use:

```dart
child: ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 48),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    child: Row(
      children: [
        _DrawerIcon(icon: entry.icon, iconType: entry.iconType),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            entry.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_left_rounded,
          size: 20,
          color: tokens.textSecondary,
        ),
      ],
    ),
  ),
),
```

Set the icon container to 30×30 and both Material/Discord icons to 18 pixels. Keep Discord at `Color(0xFF5865F2)` and use `tokens.primary` for all other icons.

- [ ] **Step 5: Replace the decorative footer with a once-loaded version label**

Replace `_DrawerFooter` with:

```dart
class _DrawerVersionLabel extends StatefulWidget {
  const _DrawerVersionLabel({required this.versionLoader});

  final AppVersionLoader versionLoader;

  @override
  State<_DrawerVersionLabel> createState() => _DrawerVersionLabelState();
}

class _DrawerVersionLabelState extends State<_DrawerVersionLabel> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    var value = 'غير متاح';
    try {
      final loaded = (await widget.versionLoader()).displayLabel.trim();
      if (loaded.isNotEmpty) value = loaded;
    } on Exception {
      value = 'غير متاح';
    }
    if (mounted) setState(() => _version = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final label = _version == null ? 'الإصدار …' : 'الإصدار $_version';

    return Semantics(
      label: label,
      child: Align(
        alignment: Alignment.center,
        child: Text(
          label,
          key: const ValueKey('drawer-app-version'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Format and run focused tests**

Run:

```powershell
dart format lib/features/shell/presentation/app_drawer.dart lib/features/shell/presentation/app_drawer_widgets.dart test/features/shell/app_drawer_test.dart
flutter test test/features/shell/app_drawer_test.dart
```

Expected: all drawer tests PASS, including privacy navigation and both Discord failure paths.

- [ ] **Step 7: Commit implementation only if the staged diff is isolated**

Run:

```powershell
git add -- lib/features/shell/presentation/app_drawer.dart lib/features/shell/presentation/app_drawer_widgets.dart test/features/shell/app_drawer_test.dart
git diff --cached --check
git diff --cached --name-only
git commit -m "feat: redesign compact side drawer"
```

Expected: only the three drawer files are staged. If their pre-existing changes cannot be separated safely, unstage them and continue without this commit.

### Task 3: Verify responsive behavior and approve golden output

**Files:**
- Modify: `test/features/phase4/phase4_personal_surfaces_test.dart`
- Modify: `test/goldens/phase4_surfaces_golden_test.dart`
- Modify: `test/goldens/goldens/phase4_support_galaxyNoir_320.png`
- Modify: `test/goldens/goldens/phase4_support_galaxyNoir_600.png`
- Modify: `test/goldens/goldens/phase4_support_galaxyNoir_840.png`
- Modify: `test/goldens/goldens/phase4_support_starlightPaper_320.png`
- Modify: `test/goldens/goldens/phase4_support_starlightPaper_600.png`
- Modify: `test/goldens/goldens/phase4_support_starlightPaper_840.png`

**Interfaces:**
- Consumes: `AppDrawer.versionLoader`, the approved group keys, and the existing phase-4 matrix/golden harness.
- Produces: deterministic visual baselines for both themes and all supported widths.

- [ ] **Step 1: Extend the phase-4 responsive contract**

After opening the drawer in `phase4_personal_surfaces_test.dart`, add:

```dart
expect(
  find.byKey(const ValueKey('drawer-destination-account')),
  findsNothing,
);
expect(
  find.byKey(const ValueKey('drawer-section-library')),
  findsOneWidget,
);
expect(
  find.byKey(const ValueKey('drawer-section-about')),
  findsOneWidget,
);
```

Keep the existing downloads absence check and `_expectSurfaceContract(tester)` call.

- [ ] **Step 2: Make the golden drawer version deterministic**

Change `_supportShowcase` to construct the drawer with the existing fixed golden loader:

```dart
const drawer = AppDrawer(
  uriLauncher: _goldenLauncher,
  versionLoader: _goldenVersion,
);
```

- [ ] **Step 3: Run the responsive matrix before updating images**

Run:

```powershell
dart format test/features/phase4/phase4_personal_surfaces_test.dart test/goldens/phase4_surfaces_golden_test.dart
flutter test test/features/phase4/phase4_personal_surfaces_test.dart
```

Expected: all dark/light size and text-scale matrix cases PASS with no overflow exception.

- [ ] **Step 4: Regenerate only the six support golden images**

Run:

```powershell
flutter test --update-goldens test/goldens/phase4_surfaces_golden_test.dart --plain-name support
```

Expected: exactly the six `phase4_support_*` PNG files change.

- [ ] **Step 5: Inspect the dark and light compact outputs**

Open these representative images and verify that the header is compact, each group is one bordered panel, dividers are visible but subdued, all five rows fit, and the version appears without clipping:

```text
test/goldens/goldens/phase4_support_galaxyNoir_320.png
test/goldens/goldens/phase4_support_starlightPaper_840.png
```

Expected: no account row, no downloads row, no decorative footer card, no overflow, and correct RTL chevrons.

- [ ] **Step 6: Run final verification**

Run:

```powershell
flutter test test/features/shell/app_drawer_test.dart test/features/phase4/phase4_personal_surfaces_test.dart
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name support
flutter analyze
```

Expected: all tests PASS, all six support goldens match, and `flutter analyze` reports `No issues found!`.

- [ ] **Step 7: Commit verification artifacts only if the staged diff is isolated**

Run:

```powershell
git add -- test/features/phase4/phase4_personal_surfaces_test.dart test/goldens/phase4_surfaces_golden_test.dart test/goldens/goldens/phase4_support_galaxyNoir_320.png test/goldens/goldens/phase4_support_galaxyNoir_600.png test/goldens/goldens/phase4_support_galaxyNoir_840.png test/goldens/goldens/phase4_support_starlightPaper_320.png test/goldens/goldens/phase4_support_starlightPaper_600.png test/goldens/goldens/phase4_support_starlightPaper_840.png
git diff --cached --check
git diff --cached --name-only
git commit -m "test: approve compact drawer surfaces"
```

Expected: only the two harness files and six support PNGs are staged. If any file contains unrelated pre-existing work that cannot be separated safely, unstage it and report the skipped commit.
