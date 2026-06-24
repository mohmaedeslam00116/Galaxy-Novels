abstract interface class ReadingActivitySession {
  void recordInteraction(int progress);

  Future<void> checkpoint();

  Future<void> pause();

  void resume();

  Future<void> finish();
}

abstract interface class ReadingActivityRecorder {
  ReadingActivitySession? startChapter({
    required int novelId,
    required int chapterId,
  });

  Future<void> syncPending();

  void dispose();
}

class NoopReadingActivityRecorder implements ReadingActivityRecorder {
  const NoopReadingActivityRecorder();

  @override
  ReadingActivitySession? startChapter({
    required int novelId,
    required int chapterId,
  }) => null;

  @override
  Future<void> syncPending() => Future.value();

  @override
  void dispose() {}
}
