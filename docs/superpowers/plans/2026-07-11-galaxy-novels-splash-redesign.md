# Galaxy Novels Splash Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current theme-dependent startup screen with one polished cosmic splash using the supplied transparent brand mark, an original Arabic tagline, and a custom stellar loader before automatically opening the existing home shell.

**Architecture:** Keep `GalaxySplashGate` as the timer/transition owner and rewrite `GalaxySplashScreen` as one fixed brand surface independent of app themes. Process the supplied logo into a verified alpha PNG, render decoration and loading motion with deterministic CustomPainters, and preserve the existing injectable splash duration so widget tests can bypass or control startup timing.

**Tech Stack:** Flutter, Dart, Material 3, CustomPainter, AnimationController, flutter_test, built-in image editing, local chroma-key removal helper, PNG alpha assets.

## Global Constraints

- Work from `D:\Galaxy Novels`; run Flutter commands from `D:\Galaxy Novels\galaxy_novels_app`.
- The worktree contains unrelated user changes. Never reset, discard, stage, commit, or reformat unrelated files.
- Do not create a login, welcome, onboarding, guest-choice, or authentication gate.
- Keep account login/registration behavior inside the existing account feature unchanged.
- Use exactly one startup splash design regardless of selected theme.
- Use the exact title `مجرة الروايات` and exact approved line `كل حكاية تبدأ من نجمة`.
- Use the exact status copy `نُهيّئ لك عالماً من الحكايات...` when status text is shown.
- Startup duration in `main.dart` is exactly 1200 milliseconds; transition duration is exactly 240 milliseconds.
- Preserve `GalaxyNovelsApp.splashDuration` as an injectable test seam, with its existing zero-duration default.
- The final brand asset path is `assets/branding/galaxy_novels_splash_mark.png`.
- No launcher-icon change is included.
- Follow RED/GREEN for code behavior. Asset processing is verified by file inspection rather than a pre-generation unit test.
- In the current dirty worktree, use checkpoints rather than commits for overlapping app files. The isolated spec/plan documents may be committed separately.

---

### Task 1: Produce and Verify the Transparent Splash Mark

**Files:**

- Source: `C:\Users\Dell\.codex\attachments\29fa925f-2010-404d-908e-3674142168d9\image-1.webp`
- Create intermediate: `galaxy_novels_app\tmp\imagegen\galaxy_novels_splash_mark_chroma.png`
- Create final: `galaxy_novels_app\assets\branding\galaxy_novels_splash_mark.png`
- Modify: `galaxy_novels_app\pubspec.yaml`

**Interfaces:**

- Produces: a PNG with alpha at `assets/branding/galaxy_novels_splash_mark.png` for `Image.asset`.
- Preserves: the supplied Arabic letterform, open book, galaxy arcs, stars, blue/purple/gold colors, and original proportions.

- [ ] **Step 1: Edit only the source background with the built-in image tool**

  Use the supplied image as the edit target with this exact intent:

      Use case: background-extraction
      Asset type: Flutter startup splash brand mark
      Primary request: Replace only the white background with a perfectly flat solid #00ff00 chroma-key background for later removal.
      Input images: Image 1 is the edit target.
      Constraints: Preserve the exact logo artwork, Arabic letterform, book, galaxy arcs, stars, proportions, crop, and blue/purple/gold/cream colors. Change only the background. Keep crisp edges and generous existing padding.
      Avoid: No redesign, no new text, no watermark, no shadow, no reflection, no gradient or texture in the background, and no #00ff00 inside the logo.

  Save/copy the selected result to:

      galaxy_novels_app\tmp\imagegen\galaxy_novels_splash_mark_chroma.png

- [ ] **Step 2: Remove the chroma key into the project asset**

  Run from the repository root:

      New-Item -ItemType Directory -Force galaxy_novels_app\assets\branding | Out-Null
      python C:\Users\Dell\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py `
        --input galaxy_novels_app\tmp\imagegen\galaxy_novels_splash_mark_chroma.png `
        --out galaxy_novels_app\assets\branding\galaxy_novels_splash_mark.png `
        --auto-key border `
        --soft-matte `
        --transparent-threshold 12 `
        --opaque-threshold 220 `
        --despill

  If a green edge remains, rerun once with `--edge-contract 1`.

- [ ] **Step 3: Validate alpha and subject coverage**

  Inspect the result visually, then run:

      @'
      from PIL import Image
      p = r"galaxy_novels_app/assets/branding/galaxy_novels_splash_mark.png"
      im = Image.open(p)
      assert im.mode == "RGBA", im.mode
      a = im.getchannel("A")
      assert a.getpixel((0, 0)) == 0
      bbox = a.getbbox()
      assert bbox is not None
      coverage = sum(1 for px in a.getdata() if px > 16) / (im.width * im.height)
      assert 0.15 < coverage < 0.90, coverage
      print(im.size, im.mode, bbox, round(coverage, 4))
      '@ | python -

  Expected: RGBA, transparent corner, non-empty bounding box, plausible subject coverage, no visible green fringe, and the logo still matches the supplied mark.

- [ ] **Step 4: Register the asset**

  In `pubspec.yaml`, keep the existing launcher asset and add:

      assets:
        - assets/branding/galaxy_novels_play_icon_512.png
        - assets/branding/galaxy_novels_splash_mark.png

- [ ] **Step 5: Resolve the Flutter asset graph**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      flutter pub get

  Expected: dependency resolution succeeds and the new PNG appears in the generated asset manifest on the next test/build.

- [ ] **Step 6: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check -- galaxy_novels_app/pubspec.yaml
      git status --short -- galaxy_novels_app/assets/branding galaxy_novels_app/pubspec.yaml

  Do not stage or commit unrelated branding/user changes.

---

### Task 2: Replace the Splash Visual with One Cosmic Brand Surface

**Files:**

- Modify: `galaxy_novels_app/lib/features/startup/presentation/galaxy_splash_screen.dart`
- Modify: `galaxy_novels_app/test/app/galaxy_splash_screen_test.dart`

**Interfaces:**

- Produces: `const GalaxySplashScreen({Key? key})` with no theme-choice parameter.
- Produces keys: `galaxy-splash-screen`, `splash-background-pattern`, `splash-brand-mark`, `stellar-orbit-loader`, and `splash-status-copy`.
- Consumes: `assets/branding/galaxy_novels_splash_mark.png` from Task 1.

- [ ] **Step 1: Replace variant tests with the fixed-brand RED tests**

  Remove the tests that expect Deep Space/default variants. Add:

      testWidgets('renders the single approved splash composition', (
        tester,
      ) async {
        await tester.pumpWidget(
          _surface(
            theme: AppTheme.dark(),
            child: const GalaxySplashScreen(),
          ),
        );

        expect(
          find.byKey(const ValueKey('splash-background-pattern')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('splash-brand-mark')),
          findsOneWidget,
        );
        expect(find.text('مجرة الروايات'), findsOneWidget);
        expect(find.text('كل حكاية تبدأ من نجمة'), findsOneWidget);
        expect(
          find.text('نُهيّئ لك عالماً من الحكايات...'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('stellar-orbit-loader')),
          findsOneWidget,
        );
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.byKey(const ValueKey('splash-brand-frame')), findsNothing);
      });

  Add a second test that pumps `GalaxySplashScreen()` first with `AppTheme.deepSpaceTheme()` and then `AppTheme.light()`, asserting the same `galaxy-splash-screen` key and copy remain. This proves there is one brand design rather than variants.

- [ ] **Step 2: Run the visual tests and confirm RED**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      flutter test test/app/galaxy_splash_screen_test.dart --plain-name "renders the single approved splash composition"

  Expected: compilation fails because `choice` is currently required, or assertions fail because the stellar loader/new copy do not exist.

- [ ] **Step 3: Rewrite `GalaxySplashScreen` as a fixed surface**

  Remove `AppThemeChoice`, `_SplashVariant`, `_LogoOrbitPainter`, `_SplashProgressLine`, the logo frame/tag, and every variant key.

  Use one private palette:

      abstract final class _SplashPalette {
        static const background = Color(0xFF050714);
        static const deepBlue = Color(0xFF101A3B);
        static const violet = Color(0xFF25145B);
        static const blue = Color(0xFF5CA8FF);
        static const indigo = Color(0xFF6F5BFF);
        static const gold = Color(0xFFE7BD62);
        static const text = Color(0xFFF8FAFF);
        static const textMuted = Color(0xFFB6C0D8);
      }

  The public widget is:

      class GalaxySplashScreen extends StatefulWidget {
        const GalaxySplashScreen({super.key});

        @override
        State<GalaxySplashScreen> createState() =>
            _GalaxySplashScreenState();
      }

  Its Scaffold must use key `galaxy-splash-screen`, fixed dark system bars, a Stack containing `_CosmicBackdropPainter`, and a SafeArea/Center/SingleChildScrollView. Constrain content to maxWidth 420 and use responsive vertical spacing based on available height.

  Render the mark exactly as:

      Image.asset(
        'assets/branding/galaxy_novels_splash_mark.png',
        key: const ValueKey('splash-brand-mark'),
        width: markSize,
        height: markSize,
        fit: BoxFit.contain,
        semanticLabel: 'شعار مجرة الروايات',
        filterQuality: FilterQuality.high,
      )

  Use `El Messiri` for the title and preserve the exact approved/status copy.

- [ ] **Step 4: Implement deterministic background painting**

  `_CosmicBackdropPainter` draws:

  - one radial gradient glow centered at approximately `(0.5w, 0.34h)`;
  - two low-opacity elliptical arcs with blue/indigo strokes;
  - a fixed list of normalized star coordinates and radii, avoiding Random so golden/widget output is stable.

  `shouldRepaint` returns false because the backdrop is immutable.

- [ ] **Step 5: Implement the custom stellar loader**

  `_StellarOrbitLoader` is Stateful with a repeating 1400 millisecond AnimationController. It reads `MediaQuery.disableAnimations`; when disabled, pass progress `0.18` without starting visible rotation.

  `_StellarOrbitPainter` draws a faint 36×18 logical-pixel elliptical orbit, one gold core, and three points spaced by `2π/3`. Each point uses blue/indigo/gold plus a small blurred halo. The widget reserves a stable 56×40 box and has key `stellar-orbit-loader`.

  Dispose the controller. Paint only; do not animate layout dimensions or positions outside the canvas.

- [ ] **Step 6: Add reduced-motion and large-text tests**

  Add:

      testWidgets('keeps splash content visible with reduced motion', (
        tester,
      ) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(1.6),
            ),
            child: _surface(
              theme: AppTheme.dark(),
              child: const GalaxySplashScreen(),
            ),
          ),
        );

        expect(find.text('مجرة الروايات'), findsOneWidget);
        expect(find.text('كل حكاية تبدأ من نجمة'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

  Also pump inside `SizedBox(width: 320, height: 480)` and assert no exception.

- [ ] **Step 7: Run the visual suite GREEN**

      flutter test test/app/galaxy_splash_screen_test.dart

  Expected: fixed composition, theme invariance, reduced motion, small screen, and existing gate tests pass after Task 3 completes. During this task, only gate tests that still use the old constructor may remain red.

- [ ] **Step 8: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check -- galaxy_novels_app/lib/features/startup/presentation/galaxy_splash_screen.dart galaxy_novels_app/test/app/galaxy_splash_screen_test.dart

---

### Task 3: Simplify the Gate and Prove the Startup-to-Home Flow

**Files:**

- Modify: `galaxy_novels_app/lib/features/startup/presentation/galaxy_splash_screen.dart`
- Modify: `galaxy_novels_app/lib/app/galaxy_novels_app.dart`
- Modify: `galaxy_novels_app/lib/main.dart`
- Modify: `galaxy_novels_app/test/app/galaxy_splash_screen_test.dart`
- Modify: `galaxy_novels_app/test/widget_test.dart`

**Interfaces:**

- Produces: `GalaxySplashGate({required Duration duration, required Widget child, Key? key})`.
- Preserves: cancellable Timer, zero-duration bypass, first-frame scheduling, and `GalaxyNovelsApp.splashDuration` injection.
- Opens: existing `AppShell` at its existing home index.

- [ ] **Step 1: Update gate tests for the simplified interface**

  Remove every `choice:` argument. Keep the existing reveal and zero-duration tests. Add:

      testWidgets('cancels splash dismissal when the gate is disposed', (
        tester,
      ) async {
        await tester.pumpWidget(
          _surface(
            theme: AppTheme.dark(),
            child: const GalaxySplashGate(
              duration: Duration(milliseconds: 1200),
              child: Text('الرئيسية'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

- [ ] **Step 2: Run the focused lifecycle test and confirm RED if the old API remains**

      flutter test test/app/galaxy_splash_screen_test.dart --plain-name "cancels splash dismissal when the gate is disposed"

  Expected before the constructor change: compilation fails because the old gate requires `choice`.

- [ ] **Step 3: Simplify `GalaxySplashGate` without weakening lifecycle safety**

  Remove the `choice` field/argument. Keep the owned `Timer?`, dismissal generation, `endOfFrame` scheduling, and cancellation in dispose. Use:

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _showSplash
            ? const GalaxySplashScreen(
                key: ValueKey('galaxy-splash-screen'),
              )
            : KeyedSubtree(
                key: const ValueKey('galaxy-splash-child'),
                child: widget.child,
              ),
      );

  When duration is zero, return the child immediately and create no timer/controller work.

- [ ] **Step 4: Integrate the simplified gate into the app**

  In `GalaxyNovelsApp`, replace the existing call with:

      child: GalaxySplashGate(
        duration: widget.splashDuration,
        child: const AppShell(),
      ),

  Keep Arabic Directionality and all app dependencies unchanged.

  In `main.dart`, use:

      runApp(
        const GalaxyNovelsApp(
          splashDuration: Duration(milliseconds: 1200),
        ),
      );

- [ ] **Step 5: Add the app-level startup test**

  In `test/widget_test.dart`, reuse the existing full-app fake repository fixture and add:

      testWidgets('startup shows only splash then opens the home shell', (
        tester,
      ) async {
        final authRepository = FakeAuthRepository();
        addTearDown(authRepository.dispose);
        await tester.pumpWidget(
          GalaxyNovelsApp(
            splashDuration: const Duration(milliseconds: 1200),
            homeRepository: _TestHomeRepository(_homeData),
            catalogRepository: const _TestCatalogRepository(),
            novelRepository: const _TestNovelRepository(),
            searchRepository: const _TestSearchRepository.empty(),
            authRepository: authRepository,
            readerAdRepository: const NoopReaderAdRepository(),
            rewardedAdRepository: const NoopRewardedAdRepository(),
          ),
        );

        expect(
          find.byKey(const ValueKey('galaxy-splash-screen')),
          findsOneWidget,
        );
        expect(find.text('مجرة الروايات'), findsOneWidget);
        expect(find.text('الرئيسية'), findsNothing);
        expect(
          find.byKey(const ValueKey('login-submit')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('auth-show-register')),
          findsNothing,
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.pump(const Duration(milliseconds: 240));

        expect(
          find.byKey(const ValueKey('galaxy-splash-screen')),
          findsNothing,
        );
        expect(find.text('الرئيسية'), findsOneWidget);
      });

  This uses only existing test helpers/imports already present in `widget_test.dart`.

- [ ] **Step 6: Run gate and startup tests GREEN**

      flutter test test/app/galaxy_splash_screen_test.dart
      flutter test test/widget_test.dart --plain-name "startup shows only splash then opens the home shell"

  Expected: the splash is first, no auth entry appears, the timer is owned/cancelled, and the existing home title appears after 1440 milliseconds of pumped time.

- [ ] **Step 7: Checkpoint**

      Set-Location D:\Galaxy Novels
      git diff --check -- galaxy_novels_app/lib/features/startup/presentation/galaxy_splash_screen.dart galaxy_novels_app/lib/app/galaxy_novels_app.dart galaxy_novels_app/lib/main.dart galaxy_novels_app/test/app/galaxy_splash_screen_test.dart galaxy_novels_app/test/widget_test.dart

---

### Task 4: Remove Startup Alternatives and Run the Acceptance Gate

**Files:**

- Verify: `galaxy_novels_app/lib/main.dart`
- Verify: `galaxy_novels_app/lib/app/galaxy_novels_app.dart`
- Verify: `galaxy_novels_app/lib/features/startup/presentation/galaxy_splash_screen.dart`
- Verify: `galaxy_novels_app/assets/branding/galaxy_novels_splash_mark.png`
- Verify: `galaxy_novels_app/pubspec.yaml`
- Verify: splash/widget tests from Tasks 2–3

**Interfaces:**

- Acceptance output: one startup splash, automatic home transition, no auth gate, transparent mark, and clean Flutter verification.

- [ ] **Step 1: Format only touched Dart files**

      Set-Location D:\Galaxy Novels\galaxy_novels_app
      dart format lib/features/startup/presentation/galaxy_splash_screen.dart lib/app/galaxy_novels_app.dart lib/main.dart test/app/galaxy_splash_screen_test.dart test/widget_test.dart

- [ ] **Step 2: Search for removed alternatives and forbidden startup auth**

      rg -n "SplashVariant|splash-variant-|splash-brand-frame|SplashProgressLine|LogoOrbitPainter|GalaxySplashScreen\(.*choice|GalaxySplashGate\(.*choice" lib test
      rg -n "LoginAccountView|AuthEntryView|AccountSessionView" lib/main.dart lib/app lib/features/startup

  Expected: both commands return no matches. Account-feature files may still contain login widgets and are intentionally outside the startup search scope.

- [ ] **Step 3: Run focused tests**

      flutter test test/app/galaxy_splash_screen_test.dart
      flutter test test/features/account/login_account_view_test.dart
      flutter test test/widget_test.dart

  Expected: splash behavior passes and account login behavior remains unchanged.

- [ ] **Step 4: Run static analysis**

      dart analyze

  Expected: `No issues found!`.

- [ ] **Step 5: Run the complete Flutter suite**

      flutter test

  Expected: every test passes with no pending Timer or AnimationController errors.

- [ ] **Step 6: Build Android debug**

      flutter build apk --debug --no-pub

  Expected: debug APK builds successfully.

- [ ] **Step 7: Visually inspect the rendered splash**

  Run or render on a 375×812-equivalent viewport and verify:

  - transparent mark with no white/green square;
  - exact title/tagline/status copy;
  - balanced cosmic background;
  - loader rotates smoothly without shifting layout;
  - no clipping at 1.6× text scale or 320×480 viewport;
  - home appears automatically after the delay;
  - no login or welcome choice appears.

- [ ] **Step 8: Final dirty-worktree audit**

      Set-Location D:\Galaxy Novels
      git status --short
      git diff --check
      git diff --stat

  Inspect only the task's paths and confirm no unrelated user change was removed. Do not stage or commit the overlapping implementation files automatically.
