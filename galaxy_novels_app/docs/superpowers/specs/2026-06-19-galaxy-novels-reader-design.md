# Galaxy Novels Reader Design

## Goal

Build the first public chapter reader for Galaxy Novels as a small, stable feature. The reader opens public chapter HTML from `galaxynovels.com` using the site's lightweight app reader mode.

## Scope

This phase includes:

- Opening a public chapter from the novel details screen.
- Adding `wr_app_reader=1` to chapter URLs while preserving existing query parameters.
- Rendering the chapter inside a Flutter WebView.
- Sending the configured app User-Agent to the WebView.
- Showing loading progress, retry, and a clear error state.

This phase does not include:

- Login-gated VIP chapters.
- Reading history sync.
- XP or activity tracking.
- Offline chapter storage.
- Native parsing of chapter HTML into Flutter widgets.
- Payment, comments, ratings, or account features.

## Architecture

The feature will use the current imperative navigation style. `NovelDetailsScreen` already receives chapter URLs from loaded public chapter packs, so it will push a new `ReaderScreen` instead of showing the current placeholder SnackBar.

Reader-specific URL handling will live in a small data/helper unit so it can be tested without WebView. The WebView widget will stay behind a thin presentation component to keep `ReaderScreen` testable.

## Data Flow

1. The user taps `ابدأ القراءة` or a chapter row on `NovelDetailsScreen`.
2. The details screen passes the chapter URL to `ReaderScreen`.
3. `ReaderScreen` resolves relative URLs with `AppConfig.resolve`.
4. The reader URL builder adds `wr_app_reader=1`.
5. The WebView loads the final URL with `AppConfig.userAgent`.

Example:

```text
/novel/example/chapter-1/
```

becomes:

```text
https://galaxynovels.com/novel/example/chapter-1/?wr_app_reader=1
```

If the original URL already has query parameters, `wr_app_reader=1` is appended without removing them.

## UX

The reader should feel quiet and fast:

- No bottom navigation inside the reader route.
- Simple app bar with the title `القارئ` and the current chapter label when available.
- Thin loading indicator while the page loads.
- Full-height WebView body.
- Retry action if the page fails to load.
- RTL app chrome remains consistent with the rest of the app.

The design avoids extra cards, gradients, decorative surfaces, or heavy controls. The chapter page itself is responsible for readable HTML content.

## Error Handling

The reader handles these cases:

- Invalid URL: show an error view and a back action.
- WebView load error: show a retry action.
- Loading progress below 100 percent: show a linear progress indicator.

External navigation should be conservative. The first implementation may allow same-host `galaxynovels.com` navigation and block unrelated external hosts to avoid turning the reader into a general browser.

## Testing

Tests should cover:

- Reader URL builder resolves relative URLs.
- Reader URL builder preserves existing query parameters.
- Reader URL builder replaces or normalizes an existing `wr_app_reader` value to `1`.
- Tapping `ابدأ القراءة` from details navigates to the reader route instead of showing the placeholder.
- `ReaderScreen` can render its app chrome with a fake WebView builder for widget tests.

## Future Work

Later phases can add:

- Previous and next chapter controls using reader page metadata or known chapter pack order.
- Local reading history.
- Batched `/reading/sync`.
- Reader settings for font size, line height, theme, and scroll mode.
- VIP chapter reader after authentication is implemented.
