import '../domain/app_review_prompt_state.dart';

abstract interface class AppReviewPromptStore {
  Future<AppReviewPromptState?> read();

  Future<void> write(AppReviewPromptState state);
}

class MemoryAppReviewPromptStore implements AppReviewPromptStore {
  AppReviewPromptState? _value;

  @override
  Future<AppReviewPromptState?> read() async => _value;

  @override
  Future<void> write(AppReviewPromptState state) async => _value = state;
}
