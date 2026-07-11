# Galaxy Novels Privacy and Discord Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an in-app Arabic privacy policy and an external Discord community link at the bottom of the app drawer.

**Architecture:** Keep the legal copy in one focused `PrivacyPolicyScreen`, route internal drawer destinations through `Navigator`, and route web/community links through one injectable `ExternalUriLauncher` boundary backed by `url_launcher`. Render the Discord brand mark with the free Font Awesome brand glyph in Discord Blurple so the icon remains local and crisp.

**Tech Stack:** Flutter, Dart, `url_launcher: ^6.3.2`, `font_awesome_flutter: ^11.0.0`, flutter_test.

## Global Constraints

- The privacy page must not mention account data, comments, ratings, favorites, reading-history synchronization, or the previous app.
- Remove all visible references to `Markaz Riwayat`, `مركز الروايات`, and `support@markazriwayat.com`.
- Contact URL: `https://galaxynovels.com/contact/`.
- Discord URL: `https://discord.gg/fD7U7zbCgM`.
- Drawer order in the «مجرة الروايات» section: About, Privacy Policy, Discord Community.
- External launch failure must produce an Arabic SnackBar instead of throwing.
- Page layout must remain usable at 320×480 and with text scale 1.6.

---

### Task 1: External URI Boundary and Dependencies

**Files:**
- Create: `galaxy_novels_app/lib/core/navigation/external_uri_launcher.dart`
- Modify: `galaxy_novels_app/pubspec.yaml`
- Modify: `galaxy_novels_app/pubspec.lock`

**Interfaces:**
- Produces: `typedef ExternalUriLauncher = Future<bool> Function(Uri uri)`.
- Produces: `Future<bool> launchExternalUri(Uri uri)` using `LaunchMode.externalApplication`.

- [ ] **Step 1: Add the dependencies**

Add under `dependencies:`:

```yaml
  font_awesome_flutter: ^11.0.0
  url_launcher: ^6.3.2
```

- [ ] **Step 2: Resolve packages**

Run: `flutter pub get`

Expected: exit code 0 and both packages appear in `pubspec.lock`.

- [ ] **Step 3: Add the launcher boundary**

```dart
import 'package:url_launcher/url_launcher.dart';

typedef ExternalUriLauncher = Future<bool> Function(Uri uri);

Future<bool> launchExternalUri(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
```

- [ ] **Step 4: Run analysis**

Run: `flutter analyze lib/core/navigation/external_uri_launcher.dart`

Expected: `No issues found!`.

---

### Task 2: Privacy Policy Screen

**Files:**
- Create: `galaxy_novels_app/lib/features/privacy/presentation/privacy_policy_screen.dart`
- Create: `galaxy_novels_app/test/features/privacy/privacy_policy_screen_test.dart`

**Interfaces:**
- Consumes: `ExternalUriLauncher` and `launchExternalUri` from Task 1.
- Produces: `PrivacyPolicyScreen({ExternalUriLauncher uriLauncher = launchExternalUri})`.

- [ ] **Step 1: Write failing composition and narrow-layout tests**

Create widget tests that pump `PrivacyPolicyScreen`, then assert:

```dart
expect(find.text('سياسة الخصوصية'), findsOneWidget);
expect(find.text('سياسة الخصوصية لتطبيق مجرة الروايات'), findsOneWidget);
expect(find.text('1. المعلومات التي نجمعها'), findsOneWidget);
expect(find.text('3. الإعلانات وجمع البيانات'), findsOneWidget);
expect(find.text('10. الامتثال للقوانين'), findsOneWidget);
expect(find.textContaining('مركز الروايات'), findsNothing);
expect(find.textContaining('support@markazriwayat.com'), findsNothing);
expect(tester.takeException(), isNull);
```

Set the surface to `Size(320, 480)` with `TextScaler.linear(1.6)` for the layout case.

- [ ] **Step 2: Run the tests and verify RED**

Run: `flutter test test/features/privacy/privacy_policy_screen_test.dart`

Expected: FAIL because `privacy_policy_screen.dart` and `PrivacyPolicyScreen` do not exist.

- [ ] **Step 3: Implement the responsive policy page**

Create a `Scaffold` with an RTL `ListView`, max-width 720 content, section headings, body paragraphs, bullet lists, three external link cards, and a final acceptance card. Use these exact section titles:

```dart
const sectionTitles = [
  '1. المعلومات التي نجمعها',
  '2. استخدام معلوماتك',
  '3. الإعلانات وجمع البيانات',
  '4. خياراتك وحقوقك',
  '5. تخزين البيانات',
  '6. الأطفال',
  '7. الأمان',
  '8. التغييرات على سياسة الخصوصية',
  '9. اتصل بنا',
  '10. الامتثال للقوانين',
];
```

The external cards use these URIs:

```dart
Uri.parse('https://policies.google.com/technologies/partner-sites?hl=ar');
Uri.parse('https://adssettings.google.com/');
Uri.parse('https://galaxynovels.com/contact/');
```

Capture `ScaffoldMessenger.of(context)` before awaiting the launcher and show `تعذر فتح الرابط الآن.` when it returns false.

- [ ] **Step 4: Run the privacy tests and verify GREEN**

Run: `flutter test test/features/privacy/privacy_policy_screen_test.dart`

Expected: all privacy tests pass.

---

### Task 3: Drawer Privacy Route and Discord Link

**Files:**
- Modify: `galaxy_novels_app/lib/features/shell/presentation/app_drawer.dart`
- Modify: `galaxy_novels_app/lib/features/shell/presentation/app_drawer_widgets.dart`
- Create: `galaxy_novels_app/test/features/shell/app_drawer_test.dart`
- Modify: `galaxy_novels_app/test/widget_test.dart`

**Interfaces:**
- Consumes: `PrivacyPolicyScreen`, `ExternalUriLauncher`, `launchExternalUri`.
- Adds destinations: `_DrawerDestination.privacy` and `_DrawerDestination.discord`.
- Adds `AppDrawer({ExternalUriLauncher uriLauncher = launchExternalUri})`.

- [ ] **Step 1: Write failing drawer tests**

Pump a `Scaffold(drawer: AppDrawer(uriLauncher: fakeLauncher))`, open the drawer, and assert:

```dart
expect(find.byKey(const ValueKey('drawer-destination-privacy')), findsOneWidget);
expect(find.byKey(const ValueKey('drawer-destination-discord')), findsOneWidget);
expect(find.byKey(const ValueKey('discord-brand-mark')), findsOneWidget);
```

Tap privacy and expect one `PrivacyPolicyScreen`. Tap Discord in a fresh pump and expect the fake launcher to receive exactly `Uri.parse('https://discord.gg/fD7U7zbCgM')`. Add a failure case where the fake returns false and assert the SnackBar text `تعذر فتح رابط Discord الآن.`.

- [ ] **Step 2: Run the drawer tests and verify RED**

Run: `flutter test test/features/shell/app_drawer_test.dart`

Expected: FAIL because the destinations, injected launcher, privacy route, and Discord mark are absent.

- [ ] **Step 3: Implement the two drawer entries**

Add imports for `dart:async`, Font Awesome, the launcher boundary, and privacy screen. Append these entries after About:

```dart
_DrawerEntry(
  destination: _DrawerDestination.privacy,
  label: 'سياسة الخصوصية',
  icon: Icons.privacy_tip_outlined,
  selectedIcon: Icons.privacy_tip_rounded,
),
_DrawerEntry(
  destination: _DrawerDestination.discord,
  label: 'مجتمع Discord',
  icon: Icons.forum_outlined,
  selectedIcon: Icons.forum_rounded,
  usesDiscordMark: true,
),
```

Render the brand entry with:

```dart
const FaIcon(
  FontAwesomeIcons.discord,
  key: ValueKey('discord-brand-mark'),
  color: Color(0xFF5865F2),
  size: 20,
)
```

For privacy, push `PrivacyPolicyScreen(uriLauncher: uriLauncher)`. For Discord, pop the drawer, call the injected launcher with the exact invite URI, and show the failure SnackBar when false.

- [ ] **Step 4: Extend the app integration test**

Update the existing drawer test in `test/widget_test.dart` to assert the two new labels and to tap Privacy Policy, then assert `find.byType(PrivacyPolicyScreen)`.

- [ ] **Step 5: Run drawer and integration tests**

Run:

```powershell
flutter test test/features/shell/app_drawer_test.dart
flutter test test/widget_test.dart --plain-name "drawer exposes only working destinations and opens about"
```

Expected: both focused tests pass.

---

### Task 4: Quality Gates and Android Verification

**Files:**
- Review all files changed by Tasks 1–3.

- [ ] **Step 1: Format changed Dart files**

Run:

```powershell
dart format lib/core/navigation/external_uri_launcher.dart lib/features/privacy/presentation/privacy_policy_screen.dart lib/features/shell/presentation/app_drawer.dart lib/features/shell/presentation/app_drawer_widgets.dart test/features/privacy/privacy_policy_screen_test.dart test/features/shell/app_drawer_test.dart test/widget_test.dart
```

Expected: exit code 0.

- [ ] **Step 2: Scan forbidden copy and stale references**

Run:

```powershell
rg -n "Markaz Riwayat|مركز الروايات|support@markazriwayat.com" lib test
```

Expected: no production matches; test-only negative assertions are allowed.

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze`

Expected: `No issues found!`.

- [ ] **Step 4: Run the full suite**

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 5: Build Android debug APK**

Run: `flutter build apk --debug --no-pub`

Expected: `Built build\\app\\outputs\\flutter-apk\\app-debug.apk`.

- [ ] **Step 6: Check the scoped diff**

Run: `git diff --check` on the files changed by this plan.

Expected: no whitespace errors.
