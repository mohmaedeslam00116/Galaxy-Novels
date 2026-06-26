import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/private_api_client.dart';
import '../../account/application/auth_repository.dart';
import '../../account/domain/auth_session.dart';
import '../application/favorites_repository.dart';
import '../domain/favorite_item.dart';
import '../domain/favorite_state_mutations.dart';
import 'favorites_error_messages.dart';
import 'favorites_local_store.dart';
import 'favorites_remote_service.dart';
import 'favorites_sync_runner.dart';

class SyncedFavoritesRepository extends ChangeNotifier
    implements FavoritesRepository {
  SyncedFavoritesRepository({
    required FavoritesRemoteService remoteService,
    required FavoritesLocalStore localStore,
    required AuthRepository authRepository,
    Duration syncDelay = const Duration(milliseconds: 700),
  }) : _syncRunner = FavoritesSyncRunner(remoteService),
       _localStore = localStore,
       _authRepository = authRepository,
       _syncDelay = syncDelay {
    _authRepository.addListener(_handleAuthChanged);
  }

  final FavoritesSyncRunner _syncRunner;
  final FavoritesLocalStore _localStore;
  final AuthRepository _authRepository;
  final Duration _syncDelay;
  FavoritesState _value = FavoritesState.idle();
  List<FavoriteItem> _items = const [];
  Map<int, FavoriteChange> _pending = const {};
  int? _activeUserId;
  int _generation = 0;
  int _pendingVersion = 0;
  bool _loaded = false;
  bool _isSyncing = false;
  bool _disposed = false;
  String? _errorMessage;
  Timer? _syncTimer;
  Future<void>? _loadFuture;
  Future<void>? _syncFuture;
  Future<void> _mutationQueue = Future.value();

  @override
  FavoritesState get value => _value;

  @override
  Future<void> load() {
    final userId = _authenticatedUserId;
    if (userId == null) {
      _deactivateUser();
      return Future.value();
    }
    if (_activeUserId == userId && _loaded) {
      return Future.value();
    }
    final pendingLoad = _loadFuture;
    if (pendingLoad != null && _activeUserId == userId) {
      return pendingLoad;
    }

    final loadFuture = _activateUser(userId);
    _loadFuture = loadFuture;
    return loadFuture.whenComplete(() {
      if (identical(_loadFuture, loadFuture)) {
        _loadFuture = null;
      }
    });
  }

  @override
  Future<void> refresh() async {
    await load();
    await _synchronize();
  }

  @override
  Future<void> syncPending() async {
    await load();
    await _synchronize();
  }

  @override
  Future<FavoriteToggleResult> toggle(FavoriteItem item) async {
    final userId = _authenticatedUserId;
    if (userId == null || item.id <= 0) {
      return FavoriteToggleResult.signInRequired;
    }
    await load();
    if (_activeUserId != userId) {
      return FavoriteToggleResult.signInRequired;
    }
    final alreadyFavorite = _items.any((favorite) => favorite.id == item.id);
    if (!alreadyFavorite && _items.length >= FavoritesState.maxFavorites) {
      _errorMessage = 'وصلت إلى الحد الأقصى: 300 رواية مفضلة.';
      _emit();
      return FavoriteToggleResult.limitReached;
    }

    try {
      return await _serializeMutation(() async {
        final mutation = buildFavoriteToggleMutation(
          currentItems: _items,
          currentPendingChanges: _pending,
          candidate: item,
          changedAt: DateTime.now().toUtc(),
        );
        await _writeSnapshot(userId, mutation.items, mutation.pendingChanges);
        _items = mutation.items;
        _pending = mutation.pendingChanges;
        _pendingVersion++;
        _errorMessage = null;
        _emit();
        _scheduleSync();
        return mutation.isFavorite
            ? FavoriteToggleResult.added
            : FavoriteToggleResult.removed;
      });
    } on FavoritesStoreException {
      _errorMessage = 'تعذر حفظ تغييرات المفضلة على الجهاز.';
      _emit();
      return FavoriteToggleResult.failed;
    }
  }

  int? get _authenticatedUserId {
    final session = _authRepository.value;
    return session.status == AuthSessionStatus.authenticated ||
            session.status == AuthSessionStatus.signingOut
        ? session.user?.id
        : null;
  }

  Future<void> _activateUser(int userId) async {
    final generation = ++_generation;
    _syncTimer?.cancel();
    _activeUserId = userId;
    _loaded = false;
    _isSyncing = false;
    _items = const [];
    _pending = const {};
    _errorMessage = null;
    _emit(status: FavoritesLoadStatus.loading);

    try {
      final snapshot = await _localStore.read(userId);
      if (!_isCurrent(userId, generation)) {
        return;
      }
      _items = sortFavoriteItems(snapshot.items);
      _pending = {
        for (final change in snapshot.pendingChanges) change.novelId: change,
      };
      _loaded = true;
      _emit();
      _synchronizeAfterCurrentRun(userId, generation);
    } on FavoritesStoreException {
      if (!_isCurrent(userId, generation)) {
        return;
      }
      _loaded = true;
      _errorMessage = 'تعذر قراءة المفضلة المحفوظة على الجهاز.';
      _emit();
    }
  }

  Future<void> _synchronize() {
    final userId = _activeUserId;
    if (userId == null || !_loaded || _authenticatedUserId != userId) {
      return Future.value();
    }
    final pendingSync = _syncFuture;
    if (pendingSync != null) {
      return pendingSync;
    }

    final generation = _generation;
    final syncFuture = _performSynchronization(userId, generation);
    _syncFuture = syncFuture;
    return syncFuture.whenComplete(() {
      if (identical(_syncFuture, syncFuture)) {
        _syncFuture = null;
      }
    });
  }

  Future<void> _performSynchronization(int userId, int generation) async {
    _syncTimer?.cancel();
    _isSyncing = true;
    _errorMessage = null;
    _emit();

    try {
      final startingVersion = _pendingVersion;
      final outcome = await _syncRunner.synchronize(_orderedPending());
      if (!_isCurrent(userId, generation)) {
        return;
      }
      await _applySyncOutcome(userId, outcome);
      _isSyncing = false;
      _errorMessage = null;
      _emit();
      if (_pendingVersion != startingVersion && _pending.isNotEmpty) {
        _scheduleSync();
      }
    } on PrivateApiException catch (error) {
      if (!_isCurrent(userId, generation)) {
        return;
      }
      _isSyncing = false;
      _errorMessage = favoritesSyncMessage(error);
      _emit();
    } on FavoritesStoreException {
      if (!_isCurrent(userId, generation)) {
        return;
      }
      _isSyncing = false;
      _errorMessage = 'تعذر حفظ تغييرات المفضلة على الجهاز.';
      _emit();
    }
  }

  Future<void> _applySyncOutcome(int userId, FavoritesSyncOutcome outcome) {
    return _serializeMutation(() async {
      final pendingAfterAccepted = Map<int, FavoriteChange>.of(_pending);
      for (final accepted in outcome.acceptedChanges) {
        final current = pendingAfterAccepted[accepted.novelId];
        if (current != null && current.isSameOperation(accepted)) {
          pendingAfterAccepted.remove(accepted.novelId);
        }
      }
      final reconciled = reconcileFavoriteState(
        remoteItems: outcome.remoteItems,
        localItems: _items,
        pendingChanges: pendingAfterAccepted,
      );
      await _writeSnapshot(userId, reconciled.items, reconciled.pendingChanges);
      _items = reconciled.items;
      _pending = reconciled.pendingChanges;
      _emit();
    });
  }

  Future<void> _writeSnapshot(
    int userId,
    List<FavoriteItem> items,
    Map<int, FavoriteChange> pending,
  ) {
    return _localStore.write(
      userId,
      FavoriteLocalSnapshot(
        items: items,
        pendingChanges: sortFavoriteChanges(pending.values.toList()),
      ),
    );
  }

  Future<T> _serializeMutation<T>(Future<T> Function() mutation) {
    final result = _mutationQueue.then((_) => mutation());
    _mutationQueue = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(_syncDelay, () => unawaited(_synchronize()));
  }

  void _synchronizeAfterCurrentRun(int userId, int generation) {
    final currentSync = _syncFuture;
    if (currentSync == null) {
      unawaited(_synchronize());
      return;
    }
    unawaited(
      currentSync.whenComplete(() {
        if (_isCurrent(userId, generation)) {
          scheduleMicrotask(() => unawaited(_synchronize()));
        }
      }),
    );
  }

  void _handleAuthChanged() {
    final userId = _authenticatedUserId;
    if (userId == null) {
      _deactivateUser();
      return;
    }
    if (_activeUserId != userId) {
      unawaited(load());
    }
  }

  void _deactivateUser() {
    if (_activeUserId == null && _value.status == FavoritesLoadStatus.idle) {
      return;
    }
    _generation++;
    _syncTimer?.cancel();
    _activeUserId = null;
    _loaded = false;
    _items = const [];
    _pending = const {};
    _isSyncing = false;
    _errorMessage = null;
    _emit(status: FavoritesLoadStatus.idle);
  }

  bool _isCurrent(int userId, int generation) {
    return !_disposed && _activeUserId == userId && _generation == generation;
  }

  List<FavoriteChange> _orderedPending() {
    return sortFavoriteChanges(_pending.values.toList());
  }

  void _emit({FavoritesLoadStatus status = FavoritesLoadStatus.ready}) {
    if (_disposed) {
      return;
    }
    _value = FavoritesState(
      status: status,
      userId: _activeUserId,
      items: _items,
      pendingCount: _pending.length,
      isSyncing: _isSyncing,
      errorMessage: _errorMessage,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _syncTimer?.cancel();
    _authRepository.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
