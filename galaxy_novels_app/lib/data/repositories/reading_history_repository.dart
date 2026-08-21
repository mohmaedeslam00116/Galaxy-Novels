import 'package:flutter/foundation.dart';

import '../models/reading_progress.dart';

abstract class ReadingHistoryRepository extends Listenable {
  Future<List<ReadingProgress>> load();

  Future<void> record(ReadingProgress progress);
}

final class ReadingHistoryScope {
  const ReadingHistoryScope._(this.storageSuffix);

  static const guest = ReadingHistoryScope._('guest');

  factory ReadingHistoryScope.user(int userId) {
    if (userId <= 0) {
      throw ArgumentError.value(userId, 'userId', 'must be positive');
    }
    return ReadingHistoryScope._('user.${userId.toString()}');
  }

  final String storageSuffix;

  @override
  bool operator ==(Object other) {
    return other is ReadingHistoryScope && other.storageSuffix == storageSuffix;
  }

  @override
  int get hashCode => storageSuffix.hashCode;
}

abstract class ScopedReadingHistoryRepository extends Listenable {
  Future<List<ReadingProgress>> loadForScope(ReadingHistoryScope scope);

  Future<void> recordForScope(
    ReadingHistoryScope scope,
    ReadingProgress progress,
  );
}
