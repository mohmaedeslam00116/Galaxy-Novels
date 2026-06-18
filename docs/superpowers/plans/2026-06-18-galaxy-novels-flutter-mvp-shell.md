# Galaxy Novels Flutter MVP Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the first Flutter project shell for Galaxy Novels with RTL Arabic UI, black/blue dark identity, cool light theme, four bottom tabs, and an account drawer.

**Architecture:** Start with a clean Flutter app under `galaxy_novels_app`. Keep the first phase UI-only with mock content and clear feature folders so later API work can attach to `GALAXY_NOVELS_APP_API.md` without reshaping the app.

**Tech Stack:** Flutter, Material 3, Dart, no backend connection in this phase.

---

## File Structure

- Create: `galaxy_novels_app/` using `flutter create`.
- Modify: `galaxy_novels_app/pubspec.yaml` to set app metadata.
- Replace: `galaxy_novels_app/lib/main.dart` with a small entry point.
- Create: `galaxy_novels_app/lib/app/galaxy_novels_app.dart` for MaterialApp and RTL setup.
- Create: `galaxy_novels_app/lib/app/app_theme.dart` for semantic light/dark theme tokens.
- Create: `galaxy_novels_app/lib/features/shell/presentation/app_shell.dart` for Scaffold, bottom navigation, and drawer.
- Create: `galaxy_novels_app/lib/features/shell/presentation/app_drawer.dart` for account drawer.
- Create: `galaxy_novels_app/lib/features/home/presentation/home_screen.dart`.
- Create: `galaxy_novels_app/lib/features/catalog/presentation/catalog_screen.dart`.
- Create: `galaxy_novels_app/lib/features/history/presentation/history_screen.dart`.
- Create: `galaxy_novels_app/lib/features/rankings/presentation/rankings_screen.dart`.
- Create: `galaxy_novels_app/lib/features/account/presentation/account_screen.dart`.
- Create: `galaxy_novels_app/lib/shared/widgets/section_header.dart`.
- Create: `galaxy_novels_app/lib/shared/widgets/novel_list_tile.dart`.
- Create: `.gitignore` at repository root to ignore build outputs and the temporary inspection folder.

---

### Task 1: Repository Hygiene

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: Add root `.gitignore`**

Create `.gitignore` with:

```gitignore
# Local worktrees and temporary inspection output
.worktrees
.worktrees/
_codex_wor_reader_inspect/

# Flutter and Dart
.dart_tool/
.packages
.pub-cache/
.pub/
build/
coverage/

# Android
*.apk
*.aab
*.jks
key.properties

# iOS/macOS generated output for future use
ios/Flutter/Generated.xcconfig
ios/Flutter/flutter_export_environment.sh
ios/Flutter/App.framework
ios/Flutter/Flutter.framework
ios/Pods/
ios/Podfile.lock
macos/Flutter/GeneratedPluginRegistrant.swift

# IDE
.idea/
.vscode/
*.iml

# OS
Thumbs.db
.DS_Store
```

- [ ] **Step 2: Verify Git ignores temporary inspection folder**

Run:

```powershell
git status --short
```

Expected: `_codex_wor_reader_inspect/` is not listed after `.gitignore` is saved.

---

### Task 2: Create Flutter Project

**Files:**
- Create: `galaxy_novels_app/`

- [ ] **Step 1: Create app skeleton**

Run:

```powershell
flutter create --project-name galaxy_novels_app --org com.galaxynovels --platforms android,ios galaxy_novels_app
```

Expected: Flutter creates the project under `galaxy_novels_app/`.

- [ ] **Step 2: Verify Flutter project exists**

Run:

```powershell
Test-Path .\galaxy_novels_app\pubspec.yaml
```

Expected: `True`.

---

### Task 3: Configure App Metadata

**Files:**
- Modify: `galaxy_novels_app/pubspec.yaml`

- [ ] **Step 1: Set project description**

Update the top metadata to:

```yaml
name: galaxy_novels_app
description: "تطبيق مجرة الروايات لقراءة الروايات العربية."
publish_to: 'none'
version: 0.1.0+1
```

- [ ] **Step 2: Keep dependencies minimal**

For the first shell phase, keep Flutter's default dependencies only:

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
```

Do not add HTTP, storage, state management, or WebView packages in this phase.

---

### Task 4: App Entry and Theme

**Files:**
- Replace: `galaxy_novels_app/lib/main.dart`
- Create: `galaxy_novels_app/lib/app/galaxy_novels_app.dart`
- Create: `galaxy_novels_app/lib/app/app_theme.dart`

- [ ] **Step 1: Replace `main.dart`**

Use:

```dart
import 'package:flutter/material.dart';

import 'app/galaxy_novels_app.dart';

void main() {
  runApp(const GalaxyNovelsApp());
}
```

- [ ] **Step 2: Create `galaxy_novels_app.dart`**

Use:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/shell/presentation/app_shell.dart';
import 'app_theme.dart';

class GalaxyNovelsApp extends StatelessWidget {
  const GalaxyNovelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مجرة الروايات',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AppShell(),
      ),
    );
  }
}
```

- [ ] **Step 3: Add Flutter localization dependency if missing**

Ensure `pubspec.yaml` contains:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  cupertino_icons: ^1.0.8
```

- [ ] **Step 4: Create `app_theme.dart`**

Use:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static const _darkBackground = Color(0xFF020617);
  static const _darkSurface = Color(0xFF0F172A);
  static const _darkSurfaceAlt = Color(0xFF1E293B);
  static const _darkPrimary = Color(0xFF2563EB);
  static const _darkTextPrimary = Color(0xFFF8FAFC);
  static const _darkTextSecondary = Color(0xFFCBD5E1);
  static const _darkBorder = Color(0xFF334155);

  static const _lightBackground = Color(0xFFF8FAFC);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceAlt = Color(0xFFEEF2F7);
  static const _lightPrimary = Color(0xFF1D4ED8);
  static const _lightTextPrimary = Color(0xFF0F172A);
  static const _lightTextSecondary = Color(0xFF475569);
  static const _lightBorder = Color(0xFFCBD5E1);

  static ThemeData light() {
    return _base(
      brightness: Brightness.light,
      background: _lightBackground,
      surface: _lightSurface,
      surfaceAlt: _lightSurfaceAlt,
      primary: _lightPrimary,
      textPrimary: _lightTextPrimary,
      textSecondary: _lightTextSecondary,
      border: _lightBorder,
    );
  }

  static ThemeData dark() {
    return _base(
      brightness: Brightness.dark,
      background: _darkBackground,
      surface: _darkSurface,
      surfaceAlt: _darkSurfaceAlt,
      primary: _darkPrimary,
      textPrimary: _darkTextPrimary,
      textSecondary: _darkTextSecondary,
      border: _darkBorder,
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color primary,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      surface: surface,
      background: background,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'sans',
      dividerColor: border,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        showUnselectedLabels: true,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        scrimColor: Colors.black.withOpacity(0.55),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run dependency resolution**

Run:

```powershell
Set-Location .\galaxy_novels_app
flutter pub get
```

Expected: exits successfully.

---

### Task 5: Shared UI Widgets

**Files:**
- Create: `galaxy_novels_app/lib/shared/widgets/section_header.dart`
- Create: `galaxy_novels_app/lib/shared/widgets/novel_list_tile.dart`

- [ ] **Step 1: Create `section_header.dart`**

Use:

```dart
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create `novel_list_tile.dart`**

Use:

```dart
import 'package:flutter/material.dart';

class NovelListTile extends StatelessWidget {
  const NovelListTile({
    required this.title,
    required this.subtitle,
    required this.meta,
    this.rank,
    super.key,
  });

  final String title;
  final String subtitle;
  final String meta;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                rank != null ? '#$rank' : 'غلاف',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Task 6: App Shell and Drawer

**Files:**
- Create: `galaxy_novels_app/lib/features/shell/presentation/app_shell.dart`
- Create: `galaxy_novels_app/lib/features/shell/presentation/app_drawer.dart`

- [ ] **Step 1: Create `app_drawer.dart`**

Use:

```dart
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مجرة الروايات',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'حسابك وإعدادات القراءة',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.person_outline,
              title: 'حسابي',
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.favorite_border,
              title: 'المفضلة',
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.tune,
              title: 'إعدادات القراءة',
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.workspace_premium_outlined,
              title: 'الاشتراك و VIP',
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.info_outline,
              title: 'حول التطبيق',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 2: Create `app_shell.dart`**

Use:

```dart
import 'package:flutter/material.dart';

import '../../catalog/presentation/catalog_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../rankings/presentation/rankings_screen.dart';
import 'app_drawer.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    CatalogScreen(),
    HistoryScreen(),
    RankingsScreen(),
  ];

  static const _titles = [
    'الرئيسية',
    'المكتبة',
    'السجل',
    'الترتيب',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(_titles[_index]),
      ),
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_library_outlined),
            activeIcon: Icon(Icons.local_library),
            label: 'المكتبة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'السجل',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: 'الترتيب',
          ),
        ],
      ),
    );
  }
}
```

---

### Task 7: Feature Screens

**Files:**
- Create: `galaxy_novels_app/lib/features/home/presentation/home_screen.dart`
- Create: `galaxy_novels_app/lib/features/catalog/presentation/catalog_screen.dart`
- Create: `galaxy_novels_app/lib/features/history/presentation/history_screen.dart`
- Create: `galaxy_novels_app/lib/features/rankings/presentation/rankings_screen.dart`
- Create: `galaxy_novels_app/lib/features/account/presentation/account_screen.dart`

- [ ] **Step 1: Create `home_screen.dart`**

Use:

```dart
import 'package:flutter/material.dart';

import '../../../shared/widgets/novel_list_tile.dart';
import '../../../shared/widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        SectionHeader(title: 'أكمل القراءة'),
        NovelListTile(
          title: 'ظلال المجرة',
          subtitle: 'آخر قراءة: الفصل 24',
          meta: 'تقدم القراءة 68%',
        ),
        SectionHeader(title: 'أحدث الفصول'),
        NovelListTile(
          title: 'حارس النجوم',
          subtitle: 'الفصل 82 متاح الآن',
          meta: 'منذ 12 دقيقة',
        ),
        NovelListTile(
          title: 'مدن الرماد',
          subtitle: 'الفصل 41 متاح الآن',
          meta: 'منذ ساعة',
        ),
        SectionHeader(title: 'روايات محدثة'),
        NovelListTile(
          title: 'بوابة الشمال',
          subtitle: 'خيال، أكشن، مغامرة',
          meta: '126 فصل',
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Create `catalog_screen.dart`**

Use:

```dart
import 'package:flutter/material.dart';

import '../../../shared/widgets/novel_list_tile.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: const [
        TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'ابحث عن رواية أو مؤلف',
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(label: Text('الكل'), selected: true, onSelected: null),
            FilterChip(label: Text('مستمرة'), selected: false, onSelected: null),
            FilterChip(label: Text('مكتملة'), selected: false, onSelected: null),
            FilterChip(label: Text('الأحدث'), selected: false, onSelected: null),
          ],
        ),
        SizedBox(height: 12),
        NovelListTile(
          title: 'حارس النجوم',
          subtitle: 'أكشن، خيال علمي',
          meta: '82 فصل - مستمرة',
        ),
        NovelListTile(
          title: 'مدن الرماد',
          subtitle: 'دراما، بقاء',
          meta: '41 فصل - مستمرة',
        ),
        NovelListTile(
          title: 'بوابة الشمال',
          subtitle: 'مغامرة، فانتازيا',
          meta: '126 فصل - مكتملة',
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Create `history_screen.dart`**

Use:

```dart
import 'package:flutter/material.dart';

import '../../../shared/widgets/novel_list_tile.dart';
import '../../../shared/widgets/section_header.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        SectionHeader(title: 'آخر القراءات'),
        NovelListTile(
          title: 'ظلال المجرة',
          subtitle: 'الفصل 24',
          meta: '68% - اليوم',
        ),
        NovelListTile(
          title: 'بوابة الشمال',
          subtitle: 'الفصل 7',
          meta: '31% - أمس',
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Create `rankings_screen.dart`**

Use:

```dart
import 'package:flutter/material.dart';

import '../../../shared/widgets/novel_list_tile.dart';
import '../../../shared/widgets/section_header.dart';

class RankingsScreen extends StatelessWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        SectionHeader(title: 'ترتيب الشهر'),
        NovelListTile(
          rank: 1,
          title: 'حارس النجوم',
          subtitle: 'الأكثر قراءة هذا الشهر',
          meta: '82 فصل',
        ),
        NovelListTile(
          rank: 2,
          title: 'مدن الرماد',
          subtitle: 'صعود سريع في القراءة',
          meta: '41 فصل',
        ),
        NovelListTile(
          rank: 3,
          title: 'بوابة الشمال',
          subtitle: 'رواية مكتملة',
          meta: '126 فصل',
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Create `account_screen.dart`**

Use:

```dart
import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'سجّل الدخول لمزامنة القراءة والمفضلة و XP.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {},
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}
```

---

### Task 8: Format, Analyze, and Verify

**Files:**
- Verify all Dart files under `galaxy_novels_app/lib/`

- [ ] **Step 1: Format Dart files**

Run:

```powershell
Set-Location .\galaxy_novels_app
dart format lib
```

Expected: formatter exits successfully.

- [ ] **Step 2: Analyze**

Run:

```powershell
flutter analyze
```

Expected: no errors.

- [ ] **Step 3: Run default widget test**

Run:

```powershell
flutter test
```

Expected: tests pass or only the default template test needs updating if it still expects the old counter app.

- [ ] **Step 4: If default test fails because of template counter text, replace it**

Modify `galaxy_novels_app/test/widget_test.dart` to:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/galaxy_novels_app.dart';

void main() {
  testWidgets('shows Galaxy Novels Arabic shell', (tester) async {
    await tester.pumpWidget(const GalaxyNovelsApp());

    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('المكتبة'), findsOneWidget);
    expect(find.text('السجل'), findsOneWidget);
    expect(find.text('الترتيب'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Re-run tests**

Run:

```powershell
flutter test
```

Expected: all tests pass.

---

### Task 9: Commit MVP Shell

**Files:**
- Add all created/modified files except ignored files.

- [ ] **Step 1: Review status**

Run:

```powershell
git status --short
```

Expected: app files, docs, and `.gitignore` are listed; `_codex_wor_reader_inspect/` is ignored.

- [ ] **Step 2: Commit**

Run:

```powershell
git add .gitignore GALAXY_NOVELS_APP_API.md docs galaxy_novels_app message.txt "قواعد كلود فلير"
git commit -m "feat: scaffold galaxy novels flutter shell"
```

Expected: commit succeeds.

Do not commit the ZIP unless the project intentionally wants to version the original theme archive. If preserving the ZIP is required, add it in a separate commit with a message like `docs: archive wor reader v2470 source package`.
