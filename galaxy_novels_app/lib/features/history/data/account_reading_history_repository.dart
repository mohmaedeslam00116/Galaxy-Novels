import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/private_api_types.dart';
import '../../../data/models/reading_progress.dart';
import '../../../data/repositories/reading_history_repository.dart';
import '../../account/application/auth_repository.dart';
import '../../account/domain/auth_session.dart';
import '../domain/reading_history_merge.dart';
import 'reading_history_remote_service.dart';

class AccountReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  AccountReadingHistoryRepository({
    required ReadingHistoryRepository localRepository,
    required ReadingHistoryRemoteService remoteService,
    required AuthRepository authRepository,
    Duration remoteCacheDuration = const Duration(minutes: 3),
  }) : _localRepository = localRepository,
       _remoteService = remoteService,
       _authRepository = authRepository,
       _remoteCacheDuration = remoteCacheDuration {
    _authRepository.addListener(_handleAuthChanged);
  }

  final ReadingHistoryRepository _localRepository;
  final ReadingHistoryRemoteService _remoteService;
  final AuthRepository _authRepository;
  final Duration _remoteCacheDuration;

  List<ReadingProgress> _remoteHistory = const [];
  int? _activeUserId;
  DateTime? _lastRemoteAttempt;
  final Map<int, Future<void>> _remoteLoads = {};
  bool _disposed = false;

  @override
  Future<List<ReadingProgress>> load() async {
    final localHistory = await _localRepository.load();
    final userId = _authenticatedUserId;
    if (userId == null) {
      return localHistory;
    }
    _activateUser(userId);
    await _loadRemoteIfStale(userId);
    return mergeReadingHistory(localHistory, _remoteHistory);
  }

  @override
  Future<void> record(ReadingProgress progress) async {
    await _localRepository.record(progress);
    notifyListeners();
  }

  int? get _authenticatedUserId {
    final session = _authRepository.value;
    return session.status == AuthSessionStatus.authenticated
        ? session.user?.id
        : null;
  }

  void _activateUser(int userId) {
    if (_activeUserId == userId) {
      return;
    }
    _activeUserId = userId;
    _remoteHistory = const [];
    _lastRemoteAttempt = null;
  }

  Future<void> _loadRemoteIfStale(int userId) {
    final lastAttempt = _lastRemoteAttempt;
    if (lastAttempt != null &&
        DateTime.now().difference(lastAttempt) < _remoteCacheDuration) {
      return Future.value();
    }
    final pendingLoad = _remoteLoads[userId];
    if (pendingLoad != null) {
      return pendingLoad;
    }
    final remoteLoad = _fetchRemoteHistory(userId);
    _remoteLoads[userId] = remoteLoad;
    return remoteLoad.whenComplete(() {
      if (identical(_remoteLoads[userId], remoteLoad)) {
        _remoteLoads.remove(userId);
      }
    });
  }

  Future<void> _fetchRemoteHistory(int userId) async {
    try {
      final remoteHistory = await _remoteService.fetchHistory();
      if (_activeUserId == userId && _authenticatedUserId == userId) {
        _remoteHistory = List.unmodifiable(remoteHistory);
      }
    } on PrivateApiException {
      // Background history sync must not demote a valid local account session.
    } finally {
      if (_activeUserId == userId) {
        _lastRemoteAttempt = DateTime.now();
      }
    }
  }

  void _handleAuthChanged() {
    final userId = _authenticatedUserId;
    if (userId == _activeUserId) {
      return;
    }
    _activeUserId = userId;
    _remoteHistory = const [];
    _lastRemoteAttempt = null;
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _authRepository.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
