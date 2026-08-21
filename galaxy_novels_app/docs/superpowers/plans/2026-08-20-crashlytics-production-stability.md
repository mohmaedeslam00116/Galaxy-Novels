# Crashlytics Production Stability Implementation Plan

> **For agentic workers:** Implement inline in this session. Use tests-first and preserve all pre-existing workspace changes.

**Goal:** Eliminate the root causes behind the 15 open Crashlytics issues observed in production version 3.2.1, while keeping expected connectivity and temporary availability failures visible as non-fatal diagnostics.

**Architecture:** Keep Crashlytics as the single reporting sink, add a small fatality policy at the application boundary, and repair lifecycle, database ownership, navigation callback, and file cleanup races at their source. Each production fix receives a focused regression test before implementation.

**Tech Stack:** Flutter, Dart, Firebase Crashlytics, sqflite, Workmanager, `flutter_test`.

## Global Constraints

- Do not close production issues until the corrected build has been released and observed.
- Do not hide programming errors: only typed temporary availability failures, timeouts, and I/O failures become non-fatal.
- Do not alter download product rules, onboarding flow, reader behavior, or navigation destinations.
- Do not commit or reset because the worktree contains user-owned uncommitted changes.
- Use tests-first for every behavior that can be reproduced deterministically.

---

### Task 1: Crash reporting severity policy

**Files:**
- Modify: `lib/core/crash_reporting/app_crash_reporter.dart`
- Modify: `lib/core/crash_reporting/crash_reporting_bootstrap.dart`
- Modify: `lib/core/crash_reporting/firebase_app_crash_reporter.dart`
- Create: `lib/core/crash_reporting/app_recoverable_exception.dart`
- Modify: `lib/features/downloads/domain/download_repository.dart`
- Modify: `test/core/crash_reporting_bootstrap_test.dart`

**Interfaces:**
- `AppCrashReporter.recordFlutterError(..., {required bool fatal})`
- `AppCrashReporter.recordPlatformError(..., {required bool fatal})`
- `isFatalAppError(Object error)`

- [x] Add tests proving programming errors remain fatal and network, timeout, and typed availability failures are non-fatal.
- [x] Run the focused test and verify it fails against the old always-fatal contract.
- [x] Implement the policy and Firebase adapter mapping.
- [x] Run the focused test and verify it passes.

### Task 2: Download database and offline lookup safety

**Files:**
- Modify: `lib/features/downloads/data/sqflite_download_store.dart`
- Modify: `lib/features/downloads/application/download_background_entrypoint.dart`
- Modify: `lib/features/downloads/data/stored_download_repository.dart`
- Modify: `test/features/downloads/sqflite_download_store_test.dart`
- Modify: `test/features/downloads/stored_download_repository_test.dart`

**Interfaces:**
- `SqfliteDownloadStore.open(..., bool singleInstance = true)`
- Background worker opens a private connection with `singleInstance: false`.
- Stale offline URIs throw `DownloadUnavailableException` instead of `StateError`.

- [x] Add a test proving closing the worker connection does not close the foreground store.
- [x] Add a test proving a stale chapter URI yields a typed recoverable error.
- [x] Run both tests and verify the expected failures.
- [x] Implement isolated database ownership and explicit lookup validation.
- [x] Run both tests and verify they pass.

### Task 3: Reader and onboarding lifecycle races

**Files:**
- Modify: `lib/features/reader/presentation/native_reader_content.dart`
- Modify: `lib/features/onboarding/presentation/app_onboarding_screen.dart`
- Modify: `test/features/reader/native_reader_content_test.dart`
- Modify: `test/features/onboarding/app_onboarding_screen_test.dart`

- [x] Add lifecycle regression coverage for delayed auto-scroll resumption after unmount.
- [x] Add a rapid double-navigation test for onboarding.
- [x] Run the focused tests; use production sample stacks as evidence for races the deterministic test scheduler cannot reproduce.
- [x] Guard disposed reader state and serialize onboarding page transitions.
- [x] Run the focused tests and verify they pass.

### Task 4: Snackbar actions must not retain disposed state

**Files:**
- Modify: `lib/features/novel_details/presentation/widgets/novel_chapters_section.dart`
- Modify: `lib/features/catalog/presentation/library_customization_screen.dart`
- Modify: `lib/features/home/presentation/home_customization_screen.dart`
- Modify: `lib/features/novel_details/presentation/novel_details_screen.dart`
- Modify focused widget tests under `test/features/`.

- [x] Add regression tests that invoke each relevant Snackbar action after its originating route is disposed.
- [x] Run focused tests and verify the stale-context failures.
- [x] Capture durable dependencies and navigator state, or safely ignore actions that require disposed screen-owned state.
- [x] Run focused tests and verify they pass.

### Task 5: Idempotent temporary-file cleanup

**Files:**
- Modify: `lib/features/downloads/data/downloaded_chapter_file_store.dart`
- Modify: `lib/features/downloads/data/stored_download_repository.dart`
- Modify: `test/features/downloads/downloaded_chapter_file_store_test.dart`

- [x] Add a test proving cleanup succeeds when the temporary file was already removed.
- [x] Run the test and verify it fails against the missing cleanup operation.
- [x] Implement deletion that ignores only `PathNotFoundException` and use it at both transfer exit paths.
- [x] Run the focused test and verify it passes.

### Task 6: Release-readiness verification and report

**Files:**
- Modify only files required by failures attributable to these fixes.

- [x] Run all focused Crashlytics regression tests.
- [x] Run `flutter analyze` and resolve diagnostics introduced by this work.
- [x] Run the complete non-golden test suite when practical.
- [x] Run clean-code review and an independent code-review pass.
- [x] Produce an Arabic report with issue counts, root causes, fixes, verification, and the release/monitoring limitation.
