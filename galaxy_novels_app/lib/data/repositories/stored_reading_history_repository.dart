import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/reading_progress.dart';
import 'reading_history_repository.dart';

abstract class ReadingHistoryStore {
  Future<String?> read(ReadingHistoryScope scope);

  Future<void> write(ReadingHistoryScope scope, String value);
}

class StoredReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository, ScopedReadingHistoryRepository {
  StoredReadingHistoryRepository({required ReadingHistoryStore store})
    : _store = store;

  final ReadingHistoryStore _store;
  final Map<ReadingHistoryScope, Future<void>> _mutationQueues = {};

  @override
  Future<List<ReadingProgress>> load() {
    return loadForScope(ReadingHistoryScope.guest);
  }

  @override
  Future<List<ReadingProgress>> loadForScope(ReadingHistoryScope scope) async {
    final raw = await _store.read(scope);
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
  Future<void> record(ReadingProgress progress) {
    return recordForScope(ReadingHistoryScope.guest, progress);
  }

  @override
  Future<void> recordForScope(
    ReadingHistoryScope scope,
    ReadingProgress progress,
  ) {
    if (progress.novelId == 0 || progress.contentApi.isEmpty) {
      return Future.value();
    }
    return _serializeMutation(scope, () => _recordNow(scope, progress));
  }

  Future<void> _recordNow(
    ReadingHistoryScope scope,
    ReadingProgress progress,
  ) async {
    final items = await loadForScope(scope);
    final next = <ReadingProgress>[
      progress,
      for (final item in items)
        if (item.novelId != progress.novelId) item,
    ];

    await _store.write(
      scope,
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> _serializeMutation(
    ReadingHistoryScope scope,
    Future<void> Function() mutation,
  ) {
    final previous = _mutationQueues[scope] ?? Future<void>.value();
    final operation = previous.then<void>(
      (_) => mutation(),
      onError: (Object _, StackTrace _) => mutation(),
    );

    late final Future<void> tail;
    tail = operation
        .then<void>((_) {}, onError: (Object _, StackTrace _) {})
        .whenComplete(() {
          if (identical(_mutationQueues[scope], tail)) {
            _mutationQueues.remove(scope);
          }
        });
    _mutationQueues[scope] = tail;
    return operation;
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
