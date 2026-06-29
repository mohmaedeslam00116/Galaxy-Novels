# Galaxy Novels UI/UX Standards

This document is the working UI/UX standard for Galaxy Novels. It combines the current app decisions with checks from `ui-ux-pro-max`, `impeccable`, and the project direction already approved by the team.

## Current Verdict

The current implementation mostly follows the intended standards, but it is not final-launch perfect yet.

Audit health score: **16/20, Good**

| Dimension | Score | Finding |
|---|---:|---|
| Accessibility | 3/4 | Good contrast direction and Material controls, but cover images need semantic labels and text-scale/landscape checks need more coverage. |
| Performance | 3/4 | No heavy animation or gradients. Network cover loading is simple and should later add cache/lazy policy. |
| Responsive design | 3/4 | Stable cover dimensions and ellipsis strategy are in place. Tablet/landscape behavior still needs a dedicated pass. |
| Theming | 4/4 | `AppThemeTokens` and presets are in place. Most UI color decisions flow through tokens. |
| Anti-patterns | 3/4 | No gradients, no glassmorphism, no nested cards. Some legacy shared widgets remain and should not be used for new UI. |

## Non-Negotiables

- The app is Arabic-first and RTL-first.
- The default dark theme is `Galaxy Noir`.
- The light preset is `Starlight Paper`.
- No gradients in app UI.
- No heavy animation, parallax, decorative blur, or continuous motion.
- No card-inside-card layouts.
- No decorative or repeated identical card grids.
- Cards and framed surfaces use radius `8`.
- Novel covers are the main visual richness.
- Reader screens stay calmer and simpler than browsing screens.
- All new colors must come from `AppThemeTokens` or `ColorScheme`.

## Theme Rules

All app colors must route through:

- `AppTheme.galaxyNoir`
- `AppTheme.starlightPaper`
- `AppThemeTokens`
- `Theme.of(context).colorScheme`

Allowed hardcoded colors:

- Token definitions in `app_theme.dart`.
- Pure platform colors needed by Material states, such as transparent, black scrim, or white on primary.

Avoid:

- `Color(0x...)` inside screens or widgets.
- `Colors.blue`, `Colors.grey`, or similar raw styling in feature widgets.
- Creating one-off surface colors because a single screen "needs something different".

## Color Strategy

Galaxy Noir:

- Background: near-black with a blue cast.
- Surfaces: deep navy layers.
- Primary: electric blue for active state, links, primary accents, and selected navigation.
- Gold: restrained highlight for rating, VIP, featured, or selected editorial emphasis only.
- Error/success: semantic only, not decorative.

Starlight Paper:

- Light neutral background.
- White/blue-tinted surfaces.
- Strong readable ink.
- Blue primary preserved for identity continuity.
- Gold remains restrained.

## Typography

- Use Material text roles through `ThemeData.textTheme`.
- Do not create display-scale type inside dense app surfaces.
- Titles may be bold, but text must not feel shouted.
- Body text line height should stay around `1.5` to `1.65`.
- Reader paragraph line height is controlled by reader preferences.
- Long titles in rows use one line with ellipsis.
- Poster titles may use two lines with ellipsis.
- Chapter update titles use one line with ellipsis.

Future recommendation:

- Add Noto Sans Arabic or Noto Naskh Arabic as an app font when packaging size and licensing are reviewed.

## Layout And Spacing

- Use an 8dp rhythm for major spacing.
- Page horizontal padding defaults to `16`.
- Section spacing should feel tiered: small component gaps, medium section gaps, larger screen breaks.
- Avoid arbitrary widths unless they represent stable component dimensions.
- Fixed-format elements must have stable dimensions:
  - Poster cover: `112 x 160`.
  - List cover: `64 x 92`.
  - Detail cover: `154 x 230`.
- Use `Expanded` only inside bounded Row/Column contexts.
- Avoid nested scrollable areas unless a bottom sheet requires it.
- Bottom navigation and floating reader controls must not hide content.

## Components

Prefer shared widgets:

- `NovelCover`
- `NovelPosterTile`
- `NovelListRow`
- `SectionTitle`
- `StatusBadge`
- `StatChip`

Do not add new local versions of cover, badge, stat, or section-header widgets unless the difference is truly feature-specific.

Legacy widgets:

- `NovelListTile` and `SectionHeader` are older patterns. Do not use them for new screens. Replace gradually when touching old surfaces.

## Home Screen

Required order:

1. Continue reading when history exists.
2. Updated novels.
3. Latest chapter updates.

Rules:

- Do not duplicate `recent_novels` in a separate featured shelf unless the API later provides a distinct editorial/featured data source.
- Keep the list/grid toggle visible and labeled by tooltip.
- Grid mode uses stable poster dimensions.
- List mode shows novel title on one line.
- Keep chapter/date rows compact.
- Do not show full long titles stacked across many lines in latest updates.

## Library Screen

Rules:

- Search remains at the top.
- Filters and sort stay compact.
- Result count is visible.
- Filter sheet uses chips and a clear Apply action.
- List rows show cover, title, status, genres, and meta without becoming crowded.
- Empty and failed states must include readable Arabic copy and a recovery action when possible.

## Novel Details

Rules:

- Header should show cover, title, status, metadata, and compact stats.
- Use `StatChip` for counts, views, and rating.
- Summary uses comfortable line height and expandable behavior when long.
- Chapters should be dense enough for long lists.
- Start-reading CTA is the main action and should remain obvious.

Current risk:

- The details header is horizontally rich. It needs a later landscape/small-device visual pass with real long titles.

## History

Rules:

- Treat history as "Continue reading", not a generic log.
- Each row opens the reader directly.
- Show novel title, chapter title, and reading state.
- Empty state should explain that history appears after reading.

## Reader

Rules:

- Reader content is native, not WebView.
- Tap toggles floating controls.
- Floating controls use a short fade/slide around `180ms`.
- No decorative motion in reading mode.
- Reader settings must remain reachable from floating controls.
- Font scale, line height, and palette settings must keep working after theme changes.

## Motion

Allowed:

- `AnimatedSwitcher` for list/grid switching.
- Short fade/slide for reader floating controls.
- Native Material pressed states.
- Bottom sheet Material motion.

Limits:

- Duration: `150ms` to `220ms`.
- Do not animate layout dimensions.
- Do not animate during scroll.
- Do not add repeated entrance animation to every list item.
- No bounce, elastic, shimmer overuse, or decorative loops.

## Accessibility

Required:

- Text contrast should meet WCAG AA.
- Interactive controls must be at least `44 x 44`.
- Icon-only controls need tooltip or semantic label.
- Color must not be the only indicator of state.
- Text must not overflow its parent.
- Reader text must support scaling without layout collapse.
- Bottom sheets and drawers must be safe-area aware.

Known follow-up:

- Add semantic labels for `NovelCover` images and fallbacks.
- Add widget tests for large text scale.
- Add visual checks for small phones, large phones, and landscape.

## Performance

Rules:

- No blur/glass decoration.
- No full-screen animated backgrounds.
- No heavy shadows on repeated list items.
- Prefer `ListView.builder` for long lists.
- Avoid expensive work inside item builders.
- Keep image dimensions reserved before network images load.

Known follow-up:

- Define an image cache and loading policy for covers.
- Consider `loadingBuilder` or cached image package only after measuring actual scrolling behavior.

## Audit Findings

### Positive Findings

- Theme tokens exist and support future presets.
- Material 3 navigation is used.
- No gradients were found in app UI.
- No WebView reader dependency exists for chapter reading.
- Cover dimensions are stable through shared widgets.
- Latest update titles use one-line ellipsis.
- Tests cover home, catalog, details, reader, history, theme tokens, and shared components.

### P1 Major

1. Cover images lack explicit semantic labels.
   - Location: `lib/shared/widgets/novel_cover.dart`
   - Impact: screen readers may not understand the cover meaning.
   - Recommendation: wrap cover output with `Semantics(label: 'غلاف رواية ...')` and mark decorative fallback clearly.
   - Suggested command: `$impeccable harden NovelCover`

2. Responsive verification is not broad enough.
   - Location: app-wide
   - Impact: long Arabic titles may still create bad layouts on landscape or extreme text scale.
   - Recommendation: add widget tests for text scale and inspect on small phone, large phone, and landscape.
   - Suggested command: `$impeccable adapt app shell`

### P2 Minor

1. Some old shared widgets still exist.
   - Location: `lib/shared/widgets/novel_list_tile.dart`, `lib/shared/widgets/section_header.dart`
   - Impact: future work might accidentally reintroduce the older visual language.
   - Recommendation: mark as deprecated or migrate remaining usage.
   - Suggested command: `$impeccable distill shared widgets`

2. Cover network loading is basic.
   - Location: `lib/shared/widgets/novel_cover.dart`
   - Impact: scrolling can feel less polished when many covers load.
   - Recommendation: define a measured caching/loading approach after testing real data volume.
   - Suggested command: `$impeccable optimize cover loading`

### P3 Polish

1. Typography can improve further with Arabic fonts.
   - Location: app-wide theme
   - Impact: current Material default is usable but not as refined for Arabic reading.
   - Recommendation: evaluate Noto Sans Arabic or Noto Naskh Arabic.
   - Suggested command: `$impeccable typeset app typography`

## Required Checks Before UI Work Is Considered Done

Run:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

For visual UI changes, also check:

- Main screen on a small phone.
- Main screen on a large phone.
- Library search/filter sheet.
- Novel details with a long Arabic title.
- Reader controls visible and hidden.
- Text scale above default.
- Landscape orientation when practical.

## Decision

The app currently follows the intended UI/UX direction well enough for the current stage. It should not be considered final visual QA complete until semantics, responsive stress tests, and cover loading behavior are addressed.
