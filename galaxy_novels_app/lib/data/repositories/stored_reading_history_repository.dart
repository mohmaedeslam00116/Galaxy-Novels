import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/reading_progress.dart';
import 'reading_history_repository.dart';

abstract class ReadingHistoryStore {
  Future<String?> read();

  Future<void> write(String value);
}

class StoredReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  StoredReadingHistoryRepository({required ReadingHistoryStore store})
    : _store = store;

  final ReadingHistoryStore _store;

  @override
  Future<List<ReadingProgress>> load() async {
    final raw = await _store.read();
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    final items = decoded
        .whereType<Map>()
        .map((item) => ReadingProgress.fromJson(_asMap(item)))
        .where((item) => item.novelId != 0 && item.contentApi.isNotEmpty)
        .toList(growable: false);
    return _sortByRecency(items);
  }

  @override
  Future<void> record(ReadingProgress progress) async {
    if (progress.novelId == 0 || progress.contentApi.isEmpty) {
      return;
    }

    final items = await load();
    final next = <ReadingProgress>[
      progress,
      for (final item in items)
        if (item.novelId != progress.novelId) item,
    ];

    await _store.write(jsonEncode(next.map((item) => item.toJson()).toList()));
    notifyListeners();
  }
}

List<ReadingProgress> _sortByRecency(List<ReadingProgress> items) {
  final sorted = [...items];
  sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return sorted;
}

Map<String, dynamic> _asMap(Map value) {
  return value.map((key, value) => MapEntry(key.toString(), value));
}
