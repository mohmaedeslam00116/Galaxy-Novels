# Compact Catalog Redesign

## Goal

Redesign the Library screen so it belongs to the same visual system as the approved Home, Novel Details, and Reader screens while keeping controls and novel cards compact. Preserve the existing catalog data flow and discovery behavior.

## Approved Direction

Use a compact poster grid. Do not add a list mode or a list/grid toggle. Remove the large Rankings shortcut because Rankings already has its own primary shell destination.

The redesign must reuse the app's semantic theme roles. Dark mode follows the approved Deep Purple Night palette; light mode continues to use its existing semantic `ColorScheme` rather than copying dark colors.

## Screen Hierarchy

The shell app bar already displays `المكتبة`, so the catalog content must not repeat a large `مكتبة الروايات` heading.

The content order is:

1. Compact search field.
2. One compact row containing Category and Sort controls.
3. Active-filter chips, only when filters are active.
4. A quiet result count such as `24 رواية`.
5. Adaptive compact novel grid.
6. Background loading or retry status when applicable.

The removed Rankings shortcut must not leave an empty spacer or placeholder.

## Controls

The search field keeps the current search debounce, clear action, and Arabic hint. Its visual height targets 48 pixels.

Category and Sort remain separate controls so their current values are readable. Each target is at least 44 pixels high. At normal text scale they share one row; at 200% text they may wrap vertically instead of clipping or overflowing.

The existing filter bottom sheet remains the only place for status and genre selection. Active search, status, genre, and non-default sort values remain individually removable through compact chips. The all-filters clear action remains available when more than one filter is active.

The result count becomes a small text treatment above the grid, not a prominent card or large pill.

## Novel Grid and Cards

The grid uses two columns on compact phones and adapts through three, four, and five columns as usable width increases. Cards should normally remain around 140–176 pixels wide. On very wide displays, center the grid inside a 900-pixel maximum content width so cards do not become oversized; do not exceed five columns.

Each card contains only:

- A fixed-ratio cover with moderate rounded corners.
- The novel title, limited to two lines.
- A small status badge.
- The chapter count in the same compact metadata row.

Views are removed from catalog cards. Cards do not use large inner padding, strong shadows, decorative glows, or oversized status elements. A subtle tonal surface and low-contrast border may be used where needed to separate the card from the background.

Tapping a card with a valid manifest continues to open the existing Novel Details screen. A card without a manifest remains visibly present but non-interactive.

## Data and Behavior

No repository, model, endpoint, cache, or API behavior changes are part of this redesign. `CatalogScreen` continues to consume `CatalogRepository` and `SearchRepository`, apply `CatalogQuery`, and preserve:

- Debounced local or search-index lookup.
- Genre and status filtering.
- Latest, title, views, and chapters sorting options.
- Background multipart loading.
- Retry after initial or background load failures.
- Navigation to Novel Details.

The obsolete in-screen Rankings callback and fallback route are removed with the shortcut. Rankings remains available from `ShellDestination.rankings`.

## Loading, Empty, and Error States

Initial loading uses a compact grid skeleton whose dimensions resemble the final poster cards. It must not switch to an unrelated list skeleton.

Initial error and empty-catalog states keep the controls visible where useful and show the existing retry or empty message in the remaining space. An empty filtered result keeps `مسح البحث والفلاتر`. A background load error keeps already loaded novels visible and presents a compact retry row below the grid.

## Responsive and Accessibility Requirements

- RTL is the primary layout direction.
- Required verification widths: 320, 600, and 840 pixels.
- Required text scaling: 100% and 200%.
- Interactive controls remain at least 44 by 44 pixels.
- Titles and metadata use explicit line limits and ellipsis.
- Controls wrap rather than overflow at narrow widths or large text.
- The existing shell navigation determines the usable catalog width; grid column calculation must use the actual sliver constraints.
- Dark and light themes must both remain legible.

## Component Boundaries

Keep `CatalogScreen` responsible for repository state, query state, and navigation. Extract or retain focused presentation widgets for:

- Compact catalog controls.
- Search field.
- Filter and sort row.
- Active filters.
- Result summary.
- Compact novel card.
- Grid skeleton and state messages.

Do not introduce a new state-management layer, configuration flag, display-mode enum, or repository abstraction for this visual change.

## Verification

Widget tests must cover:

- Search, filtering, sorting, clearing, and detail navigation still work.
- The Rankings shortcut and fallback route are absent from the Library screen.
- Cards show title, status, and chapter count but not views.
- Two-column compact layout and adaptive wider layouts use compact card widths.
- Controls fit at 320 pixels with 200% text.
- Loading skeleton uses the new grid shape.
- Empty, initial-error, background-error, and retry paths remain functional.
- No overflow occurs in RTL at 320, 600, or 840 pixels.

Add dark and light golden coverage for the Library screen at 320, 600, and 840 pixels. Run the focused catalog tests, relevant shell tests, golden tests, static analysis, and an Android debug build before delivery.

## Out of Scope

- Restoring downloads.
- Changing Rankings.
- Adding recommendations, featured novels, tabs, view-mode switching, pagination controls, or new server data.
- Redesigning Novel Details or the global shell.
