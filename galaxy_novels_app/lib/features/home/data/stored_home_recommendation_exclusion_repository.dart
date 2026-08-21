import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/reading_history_repository.dart';
import '../../account/application/auth_repository.dart';
import '../../account/domain/auth_session.dart';
import '../application/home_recommendation_exclusion_repository.dart';

class StoredHomeRecommendationExclusionRepository extends ChangeNotifier
    implements HomeRecommendationExclusionRepository {
  StoredHomeRecommendationExclusionRepository({
    required HomeRecommendationExclusionStore store,
    required AuthRepository authRepository,
  }) : _store = store,
       _authRepository = authRepository {
    _authRepository.addListener(_authChanged);
  }

  final HomeRecommendationExclusionStore _store;
  final AuthRepository _authRepository;
  final Map<ReadingHistoryScope, Future<void>> _mutationQueues = {};

  @override
  Future<Set<int>> load() async {
    final raw = await _store.read(_activeScope);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const {};
      return Set.unmodifiable(
        decoded
            .map((value) => int.tryParse(value.toString()))
            .whereType<int>()
            .where((id) => id > 0),
      );
    } on FormatException {
      return const {};
    }
  }

  @override
  Future<void> hide(int novelId) => _mutate((ids) => ids..add(novelId));

  @override
  Future<void> restore(int novelId) => _mutate((ids) => ids..remove(novelId));

  @override
  Future<void> clear() => _mutate((ids) => ids..clear());

  Future<void> _mutate(Set<int> Function(Set<int>) update) {
    final scope = _activeScope;
    return _serialize(scope, () async {
      final current = await _loadScope(scope);
      final next = update({...current});
      await _store.write(scope, jsonEncode(next.toList()..sort()));
      if (scope == _activeScope) notifyListeners();
    });
  }

  Future<Set<int>> _loadScope(ReadingHistoryScope scope) async {
    final raw = await _store.read(scope);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const {};
      return decoded
          .map((value) => int.tryParse(value.toString()))
          .whereType<int>()
          .where((id) => id > 0)
          .toSet();
    } on FormatException {
      return const {};
    }
  }

  Future<void> _serialize(
    ReadingHistoryScope scope,
    Future<void> Function() mutation,
  ) {
    final previous = _mutationQueues[scope] ?? Future<void>.value();
    final operation = previous.then((_) => mutation());
    late final Future<void> tail;
    tail = operation.whenComplete(() {
      if (identical(_mutationQueues[scope], tail)) {
        _mutationQueues.remove(scope);
      }
    });
    _mutationQueues[scope] = tail;
    return operation;
  }

  ReadingHistoryScope get _activeScope {
    final session = _authRepository.value;
    final userId = session.status == AuthSessionStatus.authenticated
        ? session.user?.id
        : null;
    return userId == null
        ? ReadingHistoryScope.guest
        : ReadingHistoryScope.user(userId);
  }

  void _authChanged() => notifyListeners();

  @override
  void dispose() {
    _authRepository.removeListener(_authChanged);
    super.dispose();
  }
}
