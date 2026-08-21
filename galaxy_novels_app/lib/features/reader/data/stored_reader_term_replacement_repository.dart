import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../application/reader_term_replacement_repository.dart';
import '../domain/reader_term_replacement.dart';

abstract class ReaderTermReplacementStore {
  Future<String?> read();

  Future<void> write(String value);
}

class StoredReaderTermReplacementRepository extends ChangeNotifier
    implements ReaderTermReplacementRepository {
  StoredReaderTermReplacementRepository({
    required ReaderTermReplacementStore store,
  }) : _store = store;

  final ReaderTermReplacementStore _store;
  List<ReaderTermReplacement> _value = const [];
  Future<void>? _loadOperation;
  Future<void> _pendingWrite = Future.value();
  bool _didLoad = false;
  int _revision = 0;

  @override
  List<ReaderTermReplacement> get value => _value;

  @override
  Future<void> load() {
    if (_didLoad) return Future.value();
    return _loadOperation ??= _loadFromStore();
  }

  @override
  Future<void> save(
    ReaderTermReplacement replacement, {
    ReaderTermReplacement? replacing,
  }) {
    final updated = [..._value];
    if (replacing != null) updated.remove(replacing);
    updated.removeWhere((rule) => _sameTarget(rule, replacement));
    updated.add(replacement);
    return _commit(updated);
  }

  @override
  Future<void> remove(ReaderTermReplacement replacement) {
    return _commit(_value.where((rule) => rule != replacement).toList());
  }

  Future<void> _commit(List<ReaderTermReplacement> replacements) {
    _value = List.unmodifiable(replacements);
    _revision += 1;
    notifyListeners();
    final encoded = jsonEncode(_value.map((rule) => rule.toJson()).toList());
    _pendingWrite = _pendingWrite
        .catchError((Object _) {})
        .then((_) => _store.write(encoded));
    return _pendingWrite;
  }

  Future<void> _loadFromStore() async {
    final revisionBeforeLoad = _revision;
    try {
      final raw = await _store.read();
      if (raw == null || raw.isEmpty || revisionBeforeLoad != _revision) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final replacements = decoded
          .whereType<Map>()
          .map(
            (entry) => ReaderTermReplacement.fromJson(
              entry.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .whereType<ReaderTermReplacement>()
          .toList();
      if (!listEquals(_value, replacements)) {
        _value = List.unmodifiable(replacements);
        notifyListeners();
      }
    } catch (_) {
      // Invalid local data must not prevent the reader from opening.
    } finally {
      _didLoad = true;
    }
  }
}

bool _sameTarget(ReaderTermReplacement first, ReaderTermReplacement second) {
  return first.source == second.source &&
      first.scope == second.scope &&
      first.novelId == second.novelId;
}
