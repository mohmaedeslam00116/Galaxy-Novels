# Compact Account Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Do not use subagents for this project. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the crowded account dashboard, guest landing, and authentication surfaces with one compact Stitch-informed visual language while preserving every existing account behavior.

**Architecture:** Keep `AuthRepository` and `AccountSessionView` as the state and routing boundaries. Replace presentation-only card grids with focused widgets: one profile header, one reading-stat table, and one account-action list; simplify guest and form chrome without changing credentials, callbacks, validation, or navigation.

**Tech Stack:** Flutter, Material 3, existing `AppThemeTokens`, widget tests, golden tests.

## Global Constraints

- Apply the redesign to guest, login, registration, authenticated, loading, and failure states.
- Use the local `stitch_/_1`, `stitch_/_2`, `stitch_/_3`, and `stitch_/deep_purple_night/DESIGN.md` as visual references.
- Keep the app's current font and `8px` standard radius; do not copy Stitch's oversized components or exaggerated rounding.
- Keep purple for primary actions and active state emphasis; use tonal surfaces and thin dividers instead of repeated cards and shadows.
- Keep all API, authentication, validation, session restoration, profile refresh, logout, and navigation behavior unchanged.
- Preserve RTL, dark/light themes, `320px`, `600px`, `840px`, `200%` text scaling, and short-landscape support.
- Do not add dependencies, account fields, shortcuts, settings, profile editing, or VIP purchasing.
- Do not use subagents.
- The account production and test files are already dirty from approved earlier work. Preserve all prior changes and do not stage or commit implementation files from this plan in the current worktree.

---

## File Map

### Create

- `lib/features/account/presentation/widgets/account_reading_stats.dart` — the single four-row reading activity table.
- `lib/features/account/presentation/widgets/account_action_list.dart` — the single three-row navigation list.
- `lib/features/account/presentation/widgets/account_loading_state.dart` — loading skeleton shaped like the redesigned account.
- `test/features/account/account_reading_stats_test.dart` — stats content, semantics, and responsive coverage.
- `test/features/account/account_action_list_test.dart` — action ordering, callbacks, semantics, and large-text coverage.
- `test/features/account/account_session_view_test.dart` — loading and failure-state behavior.

### Modify

- `lib/features/account/presentation/widgets/account_hero_panel.dart` — unified identity, level, membership, expiry, and refresh header.
- `lib/features/account/presentation/widgets/account_common_widgets.dart` — lightweight notice and logout row.
- `lib/features/account/presentation/widgets/signed_in_account_view.dart` — compose the new header, stat table, action list, notice, and logout row.
- `lib/features/account/presentation/widgets/guest_account_view.dart` — open guest landing with one primary button and one text link.
- `lib/features/account/presentation/widgets/login_account_view.dart` — flatten login chrome and convert switching actions to text links.
- `lib/features/account/presentation/widgets/register_account_view.dart` — align registration chrome and switching actions with login.
- `lib/features/account/presentation/widgets/account_session_view.dart` — use the shaped loading state and compact failure state.
- `test/features/account/signed_in_account_view_test.dart` — assert the unified authenticated structure and preserved interactions.
- `test/features/account/account_guest_view_test.dart` — assert the simplified guest and mode-switch structure.
- `test/features/account/login_account_view_test.dart` — assert flat forms while preserving credentials and field direction.
- `test/widget_test.dart` — preserve shell navigation and end-to-end account behavior.
- `test/goldens/phase4_surfaces_golden_test.dart` — cover signed-in account and refresh account baselines.

### Delete after references are removed

- `lib/features/account/presentation/widgets/account_membership_card.dart`
- `lib/features/account/presentation/widgets/account_stats_grid.dart`
- `lib/features/account/presentation/widgets/account_shortcuts.dart`
- `test/features/account/account_stats_grid_test.dart`
- `test/features/account/account_shortcuts_test.dart`

---

### Task 1: Build the Unified Profile Header

**Files:**
- Modify: `lib/features/account/presentation/widgets/account_hero_panel.dart`
- Modify: `test/features/account/signed_in_account_view_test.dart`

**Interfaces:**
- Consumes: `AuthUser`, `AuthVip`, `AuthXp`, and the existing `Future<void> Function()? onRefreshProfile` callback.
- Produces: `AccountHeroPanel({required AuthUser user, Future<void> Function()? onRefreshProfile})` with key `account-profile-header` and refresh key `account-refresh-profile`.

- [ ] **Step 1: Add failing header structure and refresh-state tests**

Add these assertions to `signed_in_account_view_test.dart` using the existing `_user` fixture:

```dart
testWidgets('unifies identity membership level and refresh in one header', (
  tester,
) async {
  var refreshCalls = 0;
  await _pumpSignedIn(
    tester,
    user: _user.copyWith(
      vip: AuthVip(
        active: true,
        tier: 'gold',
        label: 'VIP ذهبي',
        expiresAt: DateTime.utc(2026, 12, 31),
      ),
    ),
    onRefreshProfile: () async => refreshCalls += 1,
  );

  expect(find.byKey(const ValueKey('account-profile-header')), findsOneWidget);
  expect(find.text('قارئ الاختبار'), findsOneWidget);
  expect(find.text('قارئ جديد'), findsOneWidget);
  expect(find.text('المستوى 1'), findsOneWidget);
  expect(find.text('VIP ذهبي'), findsOneWidget);
  expect(find.textContaining('ينتهي'), findsOneWidget);
  expect(find.text('حالة العضوية'), findsNothing);

  await tester.tap(find.byKey(const ValueKey('account-refresh-profile')));
  await tester.pump();
  expect(refreshCalls, 1);
});
```

Add a delayed callback test that verifies the refresh button is disabled until its future completes:

```dart
testWidgets('profile refresh prevents duplicate requests', (tester) async {
  final refresh = Completer<void>();
  var refreshCalls = 0;
  await _pumpSignedIn(
    tester,
    user: _user,
    onRefreshProfile: () {
      refreshCalls += 1;
      return refresh.future;
    },
  );

  final action = find.byKey(const ValueKey('account-refresh-profile'));
  await tester.tap(action);
  await tester.pump();
  await tester.tap(action);
  await tester.pump();
  expect(refreshCalls, 1);

  refresh.complete();
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pump();
  expect(refreshCalls, 2);
});
```

Add this harness to the same test file and import `dart:async`:

```dart
Future<void> _pumpSignedIn(
  WidgetTester tester, {
  required AuthUser user,
  Future<void> Function()? onRefreshProfile,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SignedInAccountView(
            user: user,
            isSigningOut: false,
            onLogout: () async {},
            onRefreshProfile: onRefreshProfile,
          ),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 2: Run the focused tests and verify RED**

Run:

```powershell
flutter test test/features/account/signed_in_account_view_test.dart --plain-name "unifies identity membership level and refresh in one header"
```

Expected: FAIL because `account-profile-header` does not exist and membership still lives in its own card.

- [ ] **Step 3: Convert `AccountHeroPanel` into the unified stateful header**

Keep the public class name to reduce call-site churn. Add the callback and local in-flight state:

```dart
class AccountHeroPanel extends StatefulWidget {
  const AccountHeroPanel({
    required this.user,
    this.onRefreshProfile,
    super.key,
  });

  final AuthUser user;
  final Future<void> Function()? onRefreshProfile;

  @override
  State<AccountHeroPanel> createState() => _AccountHeroPanelState();
}

class _AccountHeroPanelState extends State<AccountHeroPanel> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    final refreshProfile = widget.onRefreshProfile;
    if (_refreshing || refreshProfile == null) return;
    setState(() => _refreshing = true);
    try {
      await refreshProfile();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }
}
```

Render one borderless/tonal header keyed `account-profile-header`: avatar and identity first, `Wrap` for rank level and membership labels, then a 44x44 refresh `IconButton`. Use `LayoutBuilder` plus text scale to stack only when `maxWidth < 300` or text scale is at least `1.6`. The refresh tooltip and semantic label must be `تحديث بيانات الحساب`.

Use these membership rules exactly:

```dart
String membershipLabel(AuthVip vip) {
  if (!vip.active) return 'حساب عادي';
  return vip.label.trim().isEmpty ? 'عضو VIP' : vip.label;
}

String? membershipExpiry(BuildContext context, AuthVip vip) {
  final expiresAt = vip.expiresAt;
  if (!vip.active || expiresAt == null) return null;
  final date = MaterialLocalizations.of(context).formatCompactDate(
    expiresAt.toLocal(),
  );
  return 'ينتهي في $date';
}
```

- [ ] **Step 4: Run header tests and verify GREEN**

Run:

```powershell
flutter test test/features/account/signed_in_account_view_test.dart --plain-name "profile"
```

Expected: the unified header and duplicate-refresh tests PASS.

- [ ] **Step 5: Inspect the task diff without committing dirty files**

Run:

```powershell
git diff --check -- lib/features/account/presentation/widgets/account_hero_panel.dart test/features/account/signed_in_account_view_test.dart
git diff -- lib/features/account/presentation/widgets/account_hero_panel.dart test/features/account/signed_in_account_view_test.dart
```

Expected: no whitespace errors; do not stage or commit these already-dirty files.

---

### Task 2: Replace the Statistics Grid with One Data Table

**Files:**
- Create: `lib/features/account/presentation/widgets/account_reading_stats.dart`
- Create: `test/features/account/account_reading_stats_test.dart`
- Modify: `lib/features/account/presentation/widgets/signed_in_account_view.dart`
- Delete: `lib/features/account/presentation/widgets/account_stats_grid.dart`
- Delete: `test/features/account/account_stats_grid_test.dart`

**Interfaces:**
- Consumes: `AuthUser user`.
- Produces: `AccountReadingStats({required AuthUser user})`, root key `account-reading-stats`, and row keys `account-stat-total-xp`, `account-stat-today-xp`, `account-stat-chapters`, `account-stat-time`.

- [ ] **Step 1: Write the failing table test**

Create `account_reading_stats_test.dart` with the existing account user values and these assertions:

```dart
testWidgets('renders four reading values as one continuous table', (
  tester,
) async {
  await tester.pumpWidget(_statsApp(textScale: 1));

  expect(find.byKey(const ValueKey('account-reading-stats')), findsOneWidget);
  for (final key in const [
    'account-stat-total-xp',
    'account-stat-today-xp',
    'account-stat-chapters',
    'account-stat-time',
  ]) {
    expect(find.byKey(ValueKey(key)), findsOneWidget);
  }
  expect(find.text('120'), findsOneWidget);
  expect(find.text('10'), findsOneWidget);
  expect(find.text('4'), findsOneWidget);
  expect(find.text('2س 1د'), findsOneWidget);
  expect(tester.takeException(), isNull);
});

testWidgets('reading table grows at 320 and 200 percent text', (tester) async {
  tester.view.physicalSize = const Size(320, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_statsApp(textScale: 2));

  expect(tester.takeException(), isNull);
  for (final label in const [
    'نقاط XP',
    'XP اليوم',
    'الفصول المقروءة',
    'وقت القراءة',
  ]) {
    expect(find.text(label), findsOneWidget);
  }
});
```

Define the test fixture and harness in the new file:

```dart
const _statsUser = AuthUser(
  id: 7,
  displayName: 'قارئ الاختبار',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 120,
    today: 10,
    secondsTotal: 7260,
    chaptersTotal: 4,
    rank: AuthRank(level: 3, display: 'قارئ مجري'),
  ),
);

Widget _statsApp({required double textScale}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: AccountReadingStats(user: _statsUser)),
      ),
    ),
  );
}
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```powershell
flutter test test/features/account/account_reading_stats_test.dart
```

Expected: FAIL because `AccountReadingStats` does not exist.

- [ ] **Step 3: Implement the continuous table**

Create a stat definition type and render a single bordered surface with dividers:

```dart
class _AccountStatDefinition {
  const _AccountStatDefinition({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.value,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final String value;
}
```

`AccountReadingStats.build` must derive exactly four definitions from `user.xp`, wrap the full section in `Semantics(container: true, label: 'نشاط القراءة')`, and render each row with:

```dart
Semantics(
  label: '${stat.label}: ${stat.value}',
  excludeSemantics: true,
  child: ConstrainedBox(
    key: ValueKey(stat.keyName),
    constraints: const BoxConstraints(minHeight: 56),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(stat.icon, size: 19, color: tokens.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(stat.label)),
          const SizedBox(width: 12),
          Flexible(child: Text(stat.value, textAlign: TextAlign.end)),
        ],
      ),
    ),
  ),
)
```

Retain the current reading-time rules: zero is `0د`, hours plus minutes are `$hoursس $minutesد`, hours only are `$hoursس`, and positive sub-minute activity is `1د`.

- [ ] **Step 4: Integrate the table into `SignedInAccountView`**

Replace the `ReadingStatsGrid` import and call with:

```dart
const AccountSectionTitle(title: 'نشاط القراءة'),
const SizedBox(height: 8),
AccountReadingStats(user: user),
```

Do not remove other signed-in sections yet.

- [ ] **Step 5: Run focused tests and verify GREEN**

Run:

```powershell
flutter test test/features/account/account_reading_stats_test.dart test/features/account/signed_in_account_view_test.dart
```

Expected: all stat and signed-in tests PASS after their old grid-shape assertions are updated to the continuous table.

- [ ] **Step 6: Remove the old grid files after confirming no references**

Run:

```powershell
rg "ReadingStatsGrid|account_stats_grid" lib test
```

Expected before deletion: only the old definition/test references. Delete the two old files, then run the command again and expect no matches.

---

### Task 3: Replace Shortcut Cards and the Logout Button with Rows

**Files:**
- Create: `lib/features/account/presentation/widgets/account_action_list.dart`
- Create: `test/features/account/account_action_list_test.dart`
- Modify: `lib/features/account/presentation/widgets/account_common_widgets.dart`
- Modify: `lib/features/account/presentation/widgets/signed_in_account_view.dart`
- Delete: `lib/features/account/presentation/widgets/account_shortcuts.dart`
- Delete: `test/features/account/account_shortcuts_test.dart`

**Interfaces:**
- Produces: `AccountActionList` with the same three nullable callbacks and keys `account-action-favorites`, `account-action-history`, and `account-action-settings`.
- Produces: `AccountLogoutRow({required bool isSigningOut, required Future<void> Function() onLogout})` with key `account-logout`.

- [ ] **Step 1: Write failing action-list tests**

Create `account_action_list_test.dart`:

```dart
testWidgets('renders account destinations as one ordered vertical list', (
  tester,
) async {
  final opened = <String>[];
  await tester.pumpWidget(
    _actionsApp(
      onFavorites: () => opened.add('favorites'),
      onHistory: () => opened.add('history'),
      onSettings: () => opened.add('settings'),
    ),
  );

  final favorites = find.byKey(const ValueKey('account-action-favorites'));
  final history = find.byKey(const ValueKey('account-action-history'));
  final settings = find.byKey(const ValueKey('account-action-settings'));
  expect(tester.getTopLeft(history).dy, greaterThan(tester.getTopLeft(favorites).dy));
  expect(tester.getTopLeft(settings).dy, greaterThan(tester.getTopLeft(history).dy));

  await tester.tap(favorites);
  await tester.tap(history);
  await tester.tap(settings);
  expect(opened, ['favorites', 'history', 'settings']);
});

testWidgets('account actions remain readable at 200 percent text', (
  tester,
) async {
  await tester.pumpWidget(_actionsApp(textScale: 2));
  expect(tester.takeException(), isNull);
  expect(find.text('الروايات المحفوظة'), findsOneWidget);
  expect(find.text('متابعة القراءة'), findsOneWidget);
  expect(find.text('المظهر وإعدادات القراءة'), findsOneWidget);
});
```

Add this harness to the new test file:

```dart
Widget _actionsApp({
  double textScale = 1,
  VoidCallback? onFavorites,
  VoidCallback? onHistory,
  VoidCallback? onSettings,
}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: AccountActionList(
            onOpenFavorites: onFavorites,
            onOpenHistory: onHistory,
            onOpenReaderSettings: onSettings,
          ),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```powershell
flutter test test/features/account/account_action_list_test.dart
```

Expected: FAIL because `AccountActionList` does not exist.

- [ ] **Step 3: Implement one bordered list with three rows**

Use a private immutable definition with icon, title, subtitle, key, and callback. Render the definitions in this exact order:

```dart
final actions = [
  _AccountAction(
    keyName: 'account-action-favorites',
    icon: Icons.bookmark_outline_rounded,
    title: 'المفضلة',
    subtitle: 'الروايات المحفوظة',
    onTap: onOpenFavorites,
  ),
  _AccountAction(
    keyName: 'account-action-history',
    icon: Icons.history_rounded,
    title: 'السجل',
    subtitle: 'متابعة القراءة',
    onTap: onOpenHistory,
  ),
  _AccountAction(
    keyName: 'account-action-settings',
    icon: Icons.settings_outlined,
    title: 'الإعدادات',
    subtitle: 'المظهر وإعدادات القراءة',
    onTap: onOpenReaderSettings,
  ),
];
```

Each row must use `Semantics(button: true, enabled: action.onTap != null, onTap: action.onTap, excludeSemantics: true, label: '${action.title}، ${action.subtitle}')`, a minimum height of 64, an `InkWell`, and a trailing chevron only when enabled. Put one low-contrast divider between adjacent rows.

- [ ] **Step 4: Replace the logout control**

Rename `LogoutButton` to `AccountLogoutRow`. Use a full-width `InkWell`/`ListTile`-style row with danger-colored icon and text, key `account-logout`, minimum height 56, and a progress spinner/text while `isSigningOut` is true. Keep `onLogout` unchanged and disable duplicate taps while signing out.

- [ ] **Step 5: Compose the final signed-in hierarchy**

Update `SignedInAccountView` to render this exact order inside its existing centered max-width column:

```dart
AccountHeroPanel(user: user, onRefreshProfile: onRefreshProfile),
if (noticeMessage case final message?) ...[
  const SizedBox(height: 10),
  AccountNotice(message: message),
],
const SizedBox(height: 18),
const AccountSectionTitle(title: 'نشاط القراءة'),
const SizedBox(height: 8),
AccountReadingStats(user: user),
const SizedBox(height: 18),
const AccountSectionTitle(title: 'حسابي'),
const SizedBox(height: 8),
AccountActionList(
  onOpenFavorites: onOpenFavorites,
  onOpenHistory: onOpenHistory,
  onOpenReaderSettings: onOpenReaderSettings,
),
const SizedBox(height: 14),
AccountLogoutRow(isSigningOut: isSigningOut, onLogout: onLogout),
```

Remove `AccountMembershipCard` and `_AccountSessionTools` from this file.

- [ ] **Step 6: Run tests and remove dead card/grid files**

Run:

```powershell
flutter test test/features/account/account_action_list_test.dart test/features/account/signed_in_account_view_test.dart
rg "AccountShortcutGrid|AccountMembershipCard|LogoutButton|account_shortcuts|account_membership_card" lib test
```

Expected: tests PASS. After removing obsolete files/imports, the `rg` command returns no matches.

---

### Task 4: Flatten Guest, Login, and Registration States

**Files:**
- Modify: `lib/features/account/presentation/widgets/guest_account_view.dart`
- Modify: `lib/features/account/presentation/widgets/login_account_view.dart`
- Modify: `lib/features/account/presentation/widgets/register_account_view.dart`
- Modify: `test/features/account/account_guest_view_test.dart`
- Modify: `test/features/account/login_account_view_test.dart`

**Interfaces:**
- Preserves every existing public constructor and callback.
- Preserves form and navigation keys: `auth-show-login`, `auth-show-register`, `login-back-to-guest`, `register-back-to-guest`, `login-submit`, `register-submit`, `register-show-login`, and all field keys.

- [ ] **Step 1: Add failing guest hierarchy assertions**

Update the guest test to assert one primary button and a text link:

```dart
final loginAction = find.byKey(const ValueKey('auth-show-login'));
final registerAction = find.byKey(const ValueKey('auth-show-register'));
expect(tester.widget(loginAction), isA<FilledButton>());
expect(tester.widget(registerAction), isA<TextButton>());
expect(find.text('تسجيل الدخول'), findsOneWidget);
expect(find.text('إنشاء حساب'), findsOneWidget);
expect(find.byType(DecoratedBox), findsNothing);
```

Retain the existing assertions that no form is submitted or shown before an explicit action.

- [ ] **Step 2: Add failing flat-form assertions**

Replace the old login-card expectations in `login_account_view_test.dart` with:

```dart
expect(find.text('مرحبًا بعودتك'), findsOneWidget);
expect(find.byKey(const ValueKey('login-account-benefits')), findsNothing);
expect(find.text('استخدم حساب موقع مجرة الروايات الحالي للدخول.'), findsOneWidget);
expect(
  find.ancestor(
    of: find.byKey(const ValueKey('auth-show-register')),
    matching: find.byType(TextButton),
  ),
  findsOneWidget,
);
```

Add equivalent registration assertions that `register-show-login` and `register-back-to-guest` are text actions and that the form remains centered at a maximum width of 520.

- [ ] **Step 3: Run guest/form tests and verify RED**

Run:

```powershell
flutter test test/features/account/account_guest_view_test.dart test/features/account/login_account_view_test.dart
```

Expected: FAIL because guest registration is still outlined and login still contains the hero card, benefit pills, and outlined switch button.

- [ ] **Step 4: Flatten the guest landing**

Keep the centered `ConstrainedBox(maxWidth: 520)` and `ListView`, but remove the outer `DecoratedBox`. Use `16px` phone margins, an icon no larger than 44, a short body, one `FilledButton` with key `auth-show-login`, and one `TextButton` with key `auth-show-register`. Use exact visible labels `تسجيل الدخول` and `إنشاء حساب`.

When `errorMessage` is present, render the existing message in a lightweight error-toned strip with icon and text; do not wrap the entire guest state in a card.

- [ ] **Step 5: Flatten login chrome without changing form behavior**

Replace `_LoginHero`, `_LoginModeBadge`, and `_BenefitPill` with an unboxed header containing the icon, `مرحبًا بعودتك`, and one short supporting sentence. Replace `_LoginScopeNotice` with a plain icon/text row. Change `auth-show-register` from `OutlinedButton.icon` to `TextButton`. Keep `_RememberSessionTile`, validation, controller disposal, LTR credential direction, autofill hints, and submit logic unchanged.

- [ ] **Step 6: Align registration chrome**

Keep all five fields, validators, checkbox, submit callback, and LTR rules unchanged. Keep the header unboxed, make both `register-show-login` and `register-back-to-guest` text actions, and match login's `20px`/`32px` responsive side padding and `520px` maximum content width.

- [ ] **Step 7: Run all auth-presentation tests and verify GREEN**

Run:

```powershell
flutter test test/features/account/account_guest_view_test.dart test/features/account/login_account_view_test.dart
```

Expected: all guest, mode persistence, validation, credential submission, keyboard inset, and direction tests PASS.

---

### Task 5: Shape Loading/Failure States and Complete Responsive Integration

**Files:**
- Create: `lib/features/account/presentation/widgets/account_loading_state.dart`
- Create: `test/features/account/account_session_view_test.dart`
- Modify: `lib/features/account/presentation/widgets/account_session_view.dart`
- Modify: `test/widget_test.dart`
- Modify: `test/goldens/phase4_surfaces_golden_test.dart`

**Interfaces:**
- Produces: `AccountLoadingState`, root key `account-loading-state`, using the shared `AppSkeleton`.
- Preserves `AccountSessionView` public interface and its `AuthSessionStatus` switch.

- [ ] **Step 1: Add a failing loading-structure test**

Create `account_session_view_test.dart` and add a focused test around `AccountSessionView` with a restoring repository state:

```dart
testWidgets('account loading mirrors the compact profile', (tester) async {
  final repository = FakeAuthRepository(
    initialState: const AuthSessionState.restoring(),
  );
  addTearDown(repository.dispose);
  await tester.pumpWidget(_sessionApp(repository));

expect(find.byKey(const ValueKey('account-loading-state')), findsOneWidget);
expect(find.byType(AppSkeleton), findsNWidgets(7));
expect(find.text('جارٍ تحميل الحساب...'), findsNothing);
});
```

Add a failure-state test that invokes `restoreSession` once:

```dart
testWidgets('account failure retries session restoration once', (tester) async {
  final repository = _RestoreCountingRepository();
  addTearDown(repository.dispose);
  await tester.pumpWidget(_sessionApp(repository));

  await tester.tap(find.text('إعادة المحاولة'));
  await tester.pump();
  expect(repository.restoreCalls, 1);
});

Widget _sessionApp(AuthRepository repository) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: AccountSessionView(repository: repository)),
    ),
  );
}

class _RestoreCountingRepository extends FakeAuthRepository {
  _RestoreCountingRepository()
    : super(initialState: const AuthSessionState.failure('تعذر التحقق.'));

  int restoreCalls = 0;

  @override
  Future<void> restoreSession() async {
    restoreCalls += 1;
  }
}
```

- [ ] **Step 2: Run the focused loading test and verify RED**

Run the exact new test name with:

```powershell
flutter test test/features/account/account_session_view_test.dart --plain-name "account loading mirrors the compact profile"
```

Expected: FAIL because the current loading state has no key and does not use `AppSkeleton`.

- [ ] **Step 3: Implement `AccountLoadingState`**

Create a `Semantics(liveRegion: true, label: 'جارٍ تحميل الحساب...', excludeSemantics: true)` wrapper around a centered, max-width 620 `ListView`. Use seven skeletons: one 88px header, one 20px section title, four connected 56px rows, and one 190px action-list surface. Use root key `account-loading-state`, 16px horizontal padding, and the same vertical gaps as signed-in content.

- [ ] **Step 4: Integrate loading and compact failure states**

Replace `_LoadingAccount` with `const AccountLoadingState()`. Keep `_AccountFailure` private or use the shared error surface, but preserve the exact retry text `إعادة المحاولة`, the supplied message, and the `repository.restoreSession` callback. Do not change the status switch or authenticated/guest routing.

- [ ] **Step 5: Add full viewport regression coverage**

Add a test matrix for authenticated and guest states with these cases:

```dart
const viewports = [
  (size: Size(320, 720), textScale: 1.0),
  (size: Size(600, 800), textScale: 1.0),
  (size: Size(840, 900), textScale: 1.0),
  (size: Size(840, 360), textScale: 1.0),
  (size: Size(320, 1100), textScale: 2.0),
];
```

For every case, pump the screen, scroll to the final action, assert `tester.takeException()` is null, and inspect all rendered `RenderParagraph` objects except decorative cover/avatar fallback text to ensure `didExceedMaxLines` is false.

- [ ] **Step 6: Update integration expectations**

Update account-related tests in `test/widget_test.dart` to expect:

```dart
expect(find.byKey(const ValueKey('account-profile-header')), findsOneWidget);
expect(find.byKey(const ValueKey('account-reading-stats')), findsOneWidget);
expect(find.byKey(const ValueKey('account-action-favorites')), findsOneWidget);
expect(find.byKey(const ValueKey('account-action-history')), findsOneWidget);
expect(find.byKey(const ValueKey('account-action-settings')), findsOneWidget);
expect(find.byKey(const ValueKey('account-logout')), findsOneWidget);
expect(find.text('حالة العضوية'), findsNothing);
expect(find.text('لوحة القارئ'), findsNothing);
```

Retain navigation, refresh, login, registration, and logout callback assertions.

- [ ] **Step 7: Extend the golden showcase**

Keep the existing guest account coverage in `_GoldenGroup.accountSettings`. Add `_GoldenGroup.signedInAccount`, treat it as authenticated in `_pumpGolden`, and render `const AccountScreen()` for that group. Use the existing `_goldenUser`, current dark/light themes, and widths 320/600/840. The guest redesign changes the six existing `accountSettings` baselines; the new signed-in group adds six more.

Run RED first:

```powershell
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name "signedInAccount"
```

Expected: FAIL because the six signed-in account baselines do not exist.

Generate only the new group:

```powershell
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name "signedInAccount" --update-goldens
```

Expected: six baselines are created and all six tests PASS.

Refresh the existing guest/account-settings baselines separately:

```powershell
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name "accountSettings" --update-goldens
```

Expected: the six existing guest/account-settings images are updated and all six tests PASS.

- [ ] **Step 8: Inspect representative golden images**

Inspect dark 320, dark 840, light 320, and light 840 images. Verify the header is compact, stats/actions are continuous lists, no old membership/stat/shortcut cards remain, the tablet column does not stretch excessively, and text is not clipped.

- [ ] **Step 9: Run final verification**

Run:

```powershell
dart format lib/features/account test/features/account test/widget_test.dart test/goldens/phase4_surfaces_golden_test.dart
flutter test test/features/account
flutter test test/widget_test.dart --plain-name "account"
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name "accountSettings"
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name "signedInAccount"
flutter analyze
flutter build apk --debug
git diff --check -- lib/features/account test/features/account test/widget_test.dart test/goldens/phase4_surfaces_golden_test.dart
```

Expected: formatter makes no further changes on the second pass; all focused tests and goldens PASS; analyze reports `No issues found`; APK is created at `build/app/outputs/flutter-apk/app-debug.apk`; diff check reports no whitespace errors.

- [ ] **Step 10: Review without staging implementation files**

Run:

```powershell
git status --short -- lib/features/account test/features/account test/widget_test.dart test/goldens/phase4_surfaces_golden_test.dart
git diff --stat -- lib/features/account test/features/account test/widget_test.dart test/goldens/phase4_surfaces_golden_test.dart
```

Expected: only intended account presentation/test/golden paths are reported in this task review. Do not stage or commit them because they overlap the user's pre-existing dirty work.
