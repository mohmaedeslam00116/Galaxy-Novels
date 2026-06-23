import 'package:flutter/foundation.dart';

import '../domain/favorite_item.dart';

enum FavoritesLoadStatus { idle, loading, ready }

class FavoritesState {
  FavoritesState({
    required this.status,
    required this.userId,
    List<FavoriteItem> items = const [],
    this.pendingCount = 0,
    this.isSyncing = false,
    this.errorMessage,
  }) : items = List.unmodifiable(items);

  FavoritesState.idle() : this(status: FavoritesLoadStatus.idle, userId: null);

  final FavoritesLoadStatus status;
  final int? userId;
  final List<FavoriteItem> items;
  final int pendingCount;
  final bool isSyncing;
  final String? errorMessage;

  static const maxFavorites = 300;

  bool contains(int novelId) => items.any((item) => item.id == novelId);
}

enum FavoriteToggleResult {
  added,
  removed,
  signInRequired,
  limitReached,
  failed,
}

abstract class FavoritesRepository implements ValueListenable<FavoritesState> {
  Future<void> load();

  Future<void> refresh();

  Future<void> syncPending();

  Future<FavoriteToggleResult> toggle(FavoriteItem item);

  void dispose();
}
