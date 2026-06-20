import 'package:flutter/foundation.dart';

import '../models/reading_progress.dart';

abstract class ReadingHistoryRepository extends Listenable {
  Future<List<ReadingProgress>> load();

  Future<void> record(ReadingProgress progress);
}
