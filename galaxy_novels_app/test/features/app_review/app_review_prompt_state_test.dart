import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/app_review/domain/app_review_prompt_state.dart';

void main() {
  test('state round-trips without losing UTC timestamps', () {
    final state = AppReviewPromptState(
      firstOpenedAt: DateTime.utc(2026, 1, 1),
      completedChapterCount: 10,
      qualifyingSessionCount: 2,
      lastAutomaticAttemptAt: DateTime.utc(2026, 2, 1),
      automaticAttemptCount: 1,
      lastUnavailableAt: DateTime.utc(2026, 2, 2),
      lastManualStoreOpenAt: DateTime.utc(2026, 2, 3),
    );

    expect(AppReviewPromptState.tryFromMap(state.toJson()), state);
  });

  test('invalid counters and timestamps are rejected', () {
    expect(
      AppReviewPromptState.tryFromMap({
        'first_opened_at': 'not-a-date',
        'completed_chapter_count': 0,
        'qualifying_session_count': 0,
        'automatic_attempt_count': 0,
      }),
      isNull,
    );
    expect(
      AppReviewPromptState.tryFromMap({
        'first_opened_at': DateTime.utc(2026).toIso8601String(),
        'completed_chapter_count': -1,
        'qualifying_session_count': 0,
        'automatic_attempt_count': 0,
      }),
      isNull,
    );
  });
}
