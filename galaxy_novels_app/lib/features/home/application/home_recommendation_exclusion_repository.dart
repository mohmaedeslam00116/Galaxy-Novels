import 'package:flutter/foundation.dart';

import '../../../data/repositories/reading_history_repository.dart';

abstract class HomeRecommendationExclusionRepository extends Listenable {
  Future<Set<int>> load();

  Future<void> hide(int novelId);

  Future<void> restore(int novelId);

  Future<void> clear();
}

abstract class HomeRecommendationExclusionStore {
  Future<String?> read(ReadingHistoryScope scope);

  Future<void> write(ReadingHistoryScope scope, String value);
}
