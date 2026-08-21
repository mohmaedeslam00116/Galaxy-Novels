# Firebase Ad And Screen Analytics Implementation Plan

> **For agentic workers:** Implement inline in this session. Do not delegate or use subagents.

**Goal:** Measure ad delivery and logical screen navigation in Firebase without changing monetization or navigation behavior.

**Architecture:** Add a small application analytics boundary, a typed ad-event adapter, and a Navigator observer. Inject these into the existing AdMob repositories and persistent shell so production uses Firebase while tests remain SDK-independent.

**Tech Stack:** Flutter, Dart, `firebase_analytics`, `google_mobile_ads`, `flutter_test`.

## Global Constraints

- Do not send novel names, chapter data, account identifiers, search text, ad-unit IDs, or error messages.
- Do not change ad cadence, VIP rules, download quotas, routes, or screen layouts.
- Analytics failures must never block the user journey.
- Use tests-first for every new behavior.

---

### Task 1: Analytics contracts and Firebase adapter

**Files:**
- Create: `lib/core/analytics/app_analytics.dart`
- Create: `lib/core/analytics/firebase_app_analytics.dart`
- Create: `lib/features/ads/application/ad_analytics.dart`
- Test: `test/core/app_analytics_test.dart`
- Test: `test/features/ads/ad_analytics_test.dart`

**Interfaces:**
- `AppAnalytics.logEvent(String name, {Map<String, Object>? parameters})`
- `AppAnalytics.logScreenView(String screenName)`
- `AdAnalytics.record(AdAnalyticsEvent event)`

- [ ] Write tests proving stable names, allowed parameters, and sanitized failures.
- [ ] Run the focused tests and verify failure because the contracts do not exist.
- [ ] Implement the contracts, no-op adapter, Firebase adapter, and typed ad events.
- [ ] Run the focused tests and verify they pass.

### Task 2: Screen navigation measurement

**Files:**
- Create: `lib/core/analytics/app_analytics_navigator_observer.dart`
- Create: `lib/core/analytics/app_screen_names.dart`
- Modify: `lib/features/shell/presentation/adaptive_app_shell.dart`
- Modify: `lib/features/shell/presentation/app_shell.dart`
- Modify: `lib/app/galaxy_novels_app.dart`
- Modify: named route call sites under `lib/features/`
- Test: `test/core/app_analytics_navigator_observer_test.dart`
- Modify: `test/features/shell/adaptive_app_shell_test.dart`

**Interfaces:**
- `AppAnalyticsNavigatorObserver(analytics: AppAnalytics)`
- `AdaptiveAppShell(analytics: AppAnalytics)`

- [ ] Write tests for named page pushes, pop restoration, dialog filtering, deduplication, initial home, and shell tab changes.
- [ ] Run the focused tests and verify the expected failures.
- [ ] Implement the observer and shell reporting, then attach it to `MaterialApp.navigatorObservers`.
- [ ] Add stable `RouteSettings.name` values to user-visible page routes.
- [ ] Run the focused tests and verify they pass.

### Task 3: Native and interstitial lifecycle measurement

**Files:**
- Modify: `lib/features/ads/presentation/admob_inline_native_ad.dart`
- Modify: `lib/features/ads/data/admob_inline_native_ad_repository.dart`
- Modify: `lib/features/ads/data/admob_full_screen_ad_repository.dart`
- Modify: `lib/app/galaxy_novels_app.dart`
- Modify: `test/features/ads/inline_native_ad_repository_test.dart`
- Modify: `test/features/ads/admob_ad_repositories_test.dart`

**Interfaces:**
- Native placements report load request/success/failure, impression, and click.
- Browse interstitial reports due, load request/success/failure, show, dismiss, and show failure.

- [ ] Write failing tests for dependency wiring and lifecycle-to-event mapping.
- [ ] Run the focused tests and verify the failures.
- [ ] Inject `AdAnalytics` and connect Google Mobile Ads callbacks.
- [ ] Run the focused tests and verify they pass.

### Task 4: Regression and release-readiness verification

**Files:**
- Modify only files required by failures attributable to this feature.

- [ ] Run analytics, ads, shell, navigation, and app widget tests.
- [ ] Run the complete non-golden test suite.
- [ ] Run `flutter analyze` and resolve feature-related diagnostics.
- [ ] Inspect changed files for accidental identifiers, free text, duplicated events, and unrelated edits.
