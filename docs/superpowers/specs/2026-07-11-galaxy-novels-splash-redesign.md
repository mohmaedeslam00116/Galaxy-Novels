# Galaxy Novels Splash Redesign

## Goal

Replace the current multi-variant startup presentation with one polished cosmic splash screen that appears immediately when the Flutter app launches and then transitions automatically to the existing home shell. The splash is not an authentication screen and must not change guest or account behavior.

## Confirmed Product Decisions

- The feature is a splash screen, not a login, welcome, onboarding, or authentication gate.
- Users continue into the app without signing in.
- Account login remains available only from the existing account area.
- Exactly one startup splash design exists; there are no theme-specific startup variants.
- The splash automatically opens the existing home screen after a short delay.
- The approved brand line is: `كل حكاية تبدأ من نجمة`.
- Do not ask for additional product decisions before implementation.

## Visual Direction

The splash uses a fixed OLED-friendly cosmic composition inspired by the supplied reference without copying its old icon or layout literally:

- A near-black navy background with a restrained indigo radial glow behind the brand mark.
- A sparse static star field and two soft orbital arcs. Decoration remains subtle enough to keep the brand and text dominant.
- The supplied new Arabic-book galaxy mark is displayed without its white background, with its exact proportions preserved.
- The mark has a restrained blue/gold halo but no square card, rounded app-icon plate, or opaque frame behind it.
- The title `مجرة الروايات` appears below the mark in `El Messiri`, with the approved line `كل حكاية تبدأ من نجمة` beneath it in the regular app typography.
- A custom stellar loader appears below the line: three luminous points orbit a small central star. It replaces the current linear progress line and avoids a generic CircularProgressIndicator.
- The status copy under the loader is `نُهيّئ لك عالماً من الحكايات...` in a low-emphasis accessible color.

## Palette and Typography

The splash is brand-fixed and does not change with the selected in-app theme:

- Background: `#050714`.
- Elevated cosmic surface/glow: `#101A3B` and `#25145B` at low opacity.
- Primary blue: `#5CA8FF`.
- Indigo: `#6F5BFF`.
- Gold accent: `#E7BD62`.
- Primary text: `#F8FAFF`.
- Secondary text: `#B6C0D8`.

The title uses the bundled `El Messiri` family at a responsive 30–34 logical pixels and weight 700/800. Supporting copy uses the platform/app body type at 14–16 logical pixels. All text must remain readable at large text scale without clipping.

## Transparent Brand Asset

Use the supplied file:

`C:\Users\Dell\.codex\attachments\29fa925f-2010-404d-908e-3674142168d9\image-1.webp`

Treat it as the edit target. Preserve the logo artwork, colors, Arabic letterform, book shape, stars, and proportions. Change only the white background to a removable flat chroma background with the built-in image editing tool, remove that chroma locally, and save the verified alpha asset as:

`galaxy_novels_app/assets/branding/galaxy_novels_splash_mark.png`

The final PNG must have an alpha channel, transparent corners, no colored fringe, no watermark, and no newly generated text. Add it to the Flutter asset manifest. Do not replace the launcher icon unless separately requested.

## Component Architecture

Keep the existing feature boundary and replace its internal presentation:

- `GalaxySplashGate` owns the cancellable startup timer and the fade transition to its child.
- `GalaxySplashScreen` is the one fixed visual surface.
- `_CosmicBackdropPainter` draws the static star field and orbital arcs deterministically.
- `_StellarOrbitLoader` owns one animation controller and paints the orbital loading points.
- `_StellarOrbitPainter` renders the loader without layout-changing animation.

Remove `AppThemeChoice` and the `_SplashVariant` model from the splash API. The splash does not depend on the user's selected app theme. `GalaxyNovelsApp` continues to wrap the result in the existing Arabic Directionality and changes only the splash constructor call.

## Startup Flow

1. `main()` starts `GalaxyNovelsApp` with a startup duration of 1200 milliseconds.
2. The first rendered Flutter surface is `GalaxySplashScreen`.
3. Timer countdown starts only after the first frame, preserving a visible startup frame and test determinism.
4. At 1200 milliseconds, `GalaxySplashGate` switches to the existing `AppShell` with a 240 millisecond fade.
5. `AppShell` opens at its existing home index, so the destination remains `الرئيسية`.

No login, registration, guest-choice, welcome, onboarding, or account state is introduced into this flow.

## Motion and Accessibility

- Brand content enters with a single 220 millisecond fade-and-scale animation.
- The stellar loader uses a continuous rotation while animations are enabled.
- If `MediaQuery.disableAnimations` is true, the logo is fully visible immediately and the loader is rendered as a static three-point orbit.
- The splash timer still completes when animations are disabled.
- The logo has the semantic label `شعار مجرة الروايات`.
- Decorative stars and arcs are excluded from semantics.
- The layout uses SafeArea, SingleChildScrollView/FittedBox or constraint-aware spacing so it fits small phones, landscape, tablets, and large text.
- Text/background contrast must meet WCAG AA.

## Removal of Alternatives

- Delete the old theme-specific Deep Space/default splash variants.
- Delete the old logo frame, tag badge, orbit painter, and linear progress indicator.
- Keep no second startup or welcome screen in `main.dart`, `GalaxyNovelsApp`, or the startup feature.
- Existing account login/registration widgets remain unchanged because they are account functionality, not startup screens.

## Testing Strategy

Update focused widget tests to prove:

- the splash uses the new transparent brand asset;
- the approved title and brand line are visible;
- the stellar loader is present and the old linear indicator/tag variants are absent;
- the splash is identical regardless of selected app theme;
- the gate shows the splash before the child and reveals the child after 1200 milliseconds;
- zero duration still bypasses the splash in tests that explicitly request it;
- disposal cancels the timer without a pending-timer failure;
- reduced motion does not hide the content;
- a GalaxyNovelsApp startup test proves the splash is the first surface and `الرئيسية` appears after dismissal;
- no login/auth-entry widget appears during startup.

After focused tests, run `dart analyze`, the complete Flutter test suite, and `flutter build apk --debug --no-pub`.

## Acceptance Criteria

- The supplied new mark is visibly preserved and rendered from a transparent PNG.
- The first app surface is the one approved splash design.
- The splash contains `مجرة الروايات`, `كل حكاية تبدأ من نجمة`, and the stellar orbit loader.
- The splash automatically transitions to the existing home shell.
- No authentication or guest choice is required.
- No alternate startup/welcome screen remains reachable.
- Reduced-motion, small-screen, large-text, and timer lifecycle tests pass.
- Static analysis, all tests, and Android debug build pass.
