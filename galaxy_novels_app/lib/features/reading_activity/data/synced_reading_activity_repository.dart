import 'dart:async';

import '../../../core/network/private_api_types.dart';
import '../../account/application/auth_repository.dart';
import '../../account/domain/auth_session.dart';
import '../application/reading_activity_recorder.dart';
import '../application/tracked_reading_activity_session.dart';
import '../domain/reading_activity_event.dart';
import 'reading_activity_remote_service.dart';
import 'reading_activity_store.dart';

class SyncedReadingActivityRepository implements ReadingActivityRecorder {
  SyncedReadingActivityRepository({
    required ReadingActivityStore store,
    required ReadingActivityRemoteService remoteService,
    required AuthRepository authRepository,
    Duration syncDelay = const Duration(seconds: 21),
  }) : _store = store,
       _remoteService = remoteService,
       _authRepository = authRepository,
       _syncDelay = syncDelay {
    _authRepository.addListener(_handleAuthChanged);
  }

  final ReadingActivityStore _store;
  final ReadingActivityRemoteService _remoteService;
  final AuthRepository _authRepository;
  final Duration _syncDelay;

  final Map<int, Timer> _syncTimers = {};
  final Map<int, Future<void>> _syncs = {};
  Future<void> _mutationQueue = Future.value();
  bool _disposed = false;

  @override
  ReadingActivitySession? startChapter({
    required int novelId,
    required int chapterId,
  }) {
    final userId = _authenticatedUserId;
    if (userId == null || novelId <= 0 || chapterId <= 0) {
      return null;
    }
    _scheduleSync(userId);
    return TrackedReadingActivitySession(
      ownerUserId: userId,
      novelId: novelId,
      chapterId: chapterId,
      now: () => DateTime.now().toUtc(),
      enqueue: _recordEvent,
    );
  }

  @override
  Future<void> syncPending() {
    final userId = _authenticatedUserId;
    if (userId == null || _disposed) {
      return Future.value();
    }
    final pendingSync = _syncs[userId];
    if (pendingSync != null) {
      return pendingSync;
    }
    final sync = _synchronizeUser(userId);
    _syncs[userId] = sync;
    return sync.whenComplete(() {
      if (identical(_syncs[userId], sync)) {
        _syncs.remove(userId);
      }
    });
  }

  int? get _authenticatedUserId {
    final session = _authRepository.value;
    return session.status == AuthSessionStatus.authenticated
        ? session.user?.id
        : null;
  }

  Future<void> _recordEvent(ReadingActivityEvent event) async {
    if (_disposed) {
      return;
    }
    try {
      await _serializeMutation(() async {
        final current = await _store.read(event.ownerUserId);
        if (current.any((stored) => stored.eventId == event.eventId)) {
          return;
        }
        await _store.write(event.ownerUserId, [...current, event]);
      });
    } on ReadingActivityStoreException {
      return;
    }
    if (_authenticatedUserId == event.ownerUserId) {
      _scheduleSync(event.ownerUserId);
    }
  }

  Future<void> _synchronizeUser(int userId) async {
    _syncTimers.remove(userId)?.cancel();
    final List<ReadingActivityEvent> batch;
    try {
      batch = await _serializeMutation(() async {
        final queued = await _store.read(userId);
        return queued.take(50).toList(growable: false);
      });
    } on ReadingActivityStoreException {
      return;
    }
    if (batch.isEmpty || _authenticatedUserId != userId) {
      return;
    }

    try {
      await _remoteService.sync(batch);
    } on PrivateApiException catch (error) {
      if (error.statusCode == 401 && _authenticatedUserId == userId) {
        await _authRepository.restoreSession();
      } else if (error.statusCode == 429 && _authenticatedUserId == userId) {
        _scheduleSync(userId);
      }
      return;
    }

    try {
      final remainingCount = await _serializeMutation(() async {
        final sentIds = batch.map((event) => event.eventId).toSet();
        final latest = await _store.read(userId);
        final remaining = latest
            .where((event) => !sentIds.contains(event.eventId))
            .toList(growable: false);
        await _store.write(userId, remaining);
        return remaining.length;
      });
      if (remainingCount > 0 && _authenticatedUserId == userId) {
        _scheduleSync(userId);
      }
    } on ReadingActivityStoreException {
      return;
    }
  }

  Future<T> _serializeMutation<T>(Future<T> Function() mutation) {
    final result = _mutationQueue.then((_) => mutation());
    _mutationQueue = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  void _scheduleSync(int userId) {
    if (_disposed || _authenticatedUserId != userId) {
      return;
    }
    _syncTimers.remove(userId)?.cancel();
    _syncTimers[userId] = Timer(_syncDelay, () => unawaited(syncPending()));
  }

  void _handleAuthChanged() {
    final userId = _authenticatedUserId;
    for (final timer in _syncTimers.values) {
      timer.cancel();
    }
    _syncTimers.clear();
    if (userId != null) {
      _scheduleSync(userId);
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final timer in _syncTimers.values) {
      timer.cancel();
    }
    _syncTimers.clear();
    _authRepository.removeListener(_handleAuthChanged);
  }
}
