# Comment Votes And Reactions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Execute inline in this session. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add authenticated voting on comments and authenticated target reactions for novel/chapter comment surfaces.

**Architecture:** Keep comment interactions inside the existing comments feature. The repository owns REST calls and response parsing, the controller owns optimistic-safe state transitions, and widgets only render state and send user intents upward.

**Tech Stack:** Flutter, ChangeNotifier/ValueListenableBuilder, existing `PrivateApiClient`, existing comments repositories and fakes.

## Global Constraints

- No WebView or new heavy dependency.
- No local guessing of server counters after success; apply `counts` returned by the API.
- Guest users can see actions but cannot submit; they receive an Arabic sign-in message.
- Use TDD: each production behavior starts with a failing test.
- Keep UI lightweight: icon buttons, small chips, no heavy animation.

---

## File Structure

- `lib/features/comments/domain/comment_vote.dart`: vote and reaction enums plus server keys and labels.
- `lib/features/comments/domain/public_comment.dart`: add immutable `myVote` and vote count copying.
- `lib/features/comments/domain/comments_page.dart`: add immutable `myReaction` and reaction count copying.
- `lib/features/comments/application/comments_repository.dart`: add interaction methods.
- `lib/features/comments/data/public_comments_repository.dart`: POST vote/reaction and parse result payloads.
- `lib/features/comments/application/comments_controller.dart`: add interaction status and update state from server responses.
- `lib/features/comments/presentation/widgets/comment_item.dart`: show like/dislike actions.
- `lib/features/comments/presentation/comments_sliver_section.dart`: show reaction strip for the current target.
- `test/helpers/fake_comments_repository.dart`: fake interaction calls.
- `test/features/comments/*`: repository, controller, and widget interaction tests.

## Task 1: Repository Contract

- [ ] Write failing repository tests for `POST /comments/{id}/vote` and `POST /comments/{type}/{id}/reaction`.
- [ ] Add domain result types and repository interface methods.
- [ ] Implement `PublicCommentsRepository` parsing for:
  - vote response: `{ success, comment_id, vote, counts: { like_count, dislike_count, score } }`
  - reaction response: `{ success, reaction, counts: { like, laugh, love, wow, angry, sad } }`
- [ ] Run `flutter test test/features/comments/public_comments_repository_test.dart --reporter compact`.

## Task 2: Controller State

- [ ] Write failing controller tests for guest blocking, authenticated vote update, and authenticated reaction update.
- [ ] Add `voteComment` and `reactToTarget` commands.
- [ ] Prevent duplicate in-flight actions per comment/target.
- [ ] Refresh auth session on 401/403 and keep current comments visible on failure.
- [ ] Run `flutter test test/features/comments/comments_controller_test.dart --reporter compact`.

## Task 3: UI Surface

- [ ] Write failing widget test for pressing a comment like button and a target reaction chip.
- [ ] Add compact like/dislike actions to root comments and replies without card nesting.
- [ ] Add reaction strip under the comments toolbar.
- [ ] Keep labels Arabic and keys stable for tests.
- [ ] Run `flutter test test/features/comments/comments_surfaces_test.dart --reporter compact`.

## Task 4: Verification And Docs

- [ ] Update `docs/app_api_gap_audit.md` to mark comment voting/reactions complete.
- [ ] Run `dart format` on changed Dart files.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test --reporter compact`.
- [ ] Run `flutter build apk --debug`.
- [ ] Commit with a structured message.
