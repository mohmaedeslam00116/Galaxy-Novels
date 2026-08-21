# Firebase Ad And Screen Analytics Design

## Scope

Add privacy-safe Firebase measurement for the existing inline-native ad placements,
the browse interstitial lifecycle, and user-visible application screens. The change
must not alter ad cadence, VIP visibility, navigation behavior, or the existing
download analytics events.

## Architecture

- `AppAnalytics` is the application-wide measurement boundary. Production uses
  `FirebaseAppAnalytics`; tests and unsupported environments use
  `NoopAppAnalytics` or a recording fake.
- `AdAnalytics` translates typed ad lifecycle facts into stable Firebase event
  names. Ad widgets and repositories report facts only and never import Firebase.
- `AppAnalyticsNavigatorObserver` reports named `PageRoute` transitions. The
  persistent shell reports tab changes explicitly because `IndexedStack` changes
  do not create Navigator routes.
- Route names are stable constants in `AppScreenNames`; no novel, chapter, account,
  query, or free-text data is attached to events.

## Events

Ad lifecycle event names are `galaxy_ad_load_request`,
`galaxy_ad_load_success`, `galaxy_ad_load_failure`,
`galaxy_ad_impression`, `galaxy_ad_click`, `galaxy_ad_due`,
`galaxy_ad_show`, `galaxy_ad_dismiss`, and `galaxy_ad_show_failure`.
Parameters are limited to `format`, `placement`, and optional numeric
`error_code`.

Screen changes use Firebase's `screen_view` API with stable English names.
Dialogs, bottom sheets, placeholders, rebuilds, and repeated selection of the
active shell tab are not reported as screens.

## Reliability And Privacy

Analytics failures are swallowed at the Firebase boundary and never block ads,
navigation, downloads, or startup. Native ad callbacks report the event at most
once per lifecycle state for one ad instance. Interstitial dismissal is recorded
only after a successful show. No ad-unit IDs, error messages, content names, or
user identifiers are sent.

## Verification

Tests cover event schemas, error sanitization, screen-route filtering and
deduplication, persistent-shell screen changes, and repository wiring. Existing ad,
shell, and application tests must remain green, followed by `flutter analyze`.
