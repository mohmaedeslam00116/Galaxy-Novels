import '../domain/reading_activity_event.dart';

abstract interface class ReadingActivityStore {
  Future<List<ReadingActivityEvent>> read(int userId);

  Future<void> write(int userId, List<ReadingActivityEvent> events);
}

class ReadingActivityStoreException implements Exception {
  const ReadingActivityStoreException();
}
