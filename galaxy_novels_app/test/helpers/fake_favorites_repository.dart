import 'package:flutter/foundation.dart';
import 'package:galaxy_novels_app/features/favorites/application/favorites_repository.dart';
import 'package:galaxy_novels_app/features/favorites/domain/favorite_item.dart';

class FakeFavoritesRepository extends ValueNotifier<FavoritesState>
    implements FavoritesRepository {
  FakeFavoritesRepository({
    List<FavoriteItem> items = const [],
    int? userId,
    FavoritesLoadStatus status = FavoritesLoadStatus.ready,
  }) : super(FavoritesState(status: status, userId: userId, items: items));

  int loadCalls = 0;
  int refreshCalls = 0;
  int syncCalls = 0;

  @override
  Future<void> load() async {
    loadCalls++;
  }

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }

  @override
  Future<void> syncPending() async {
    syncCalls++;
  }

  @override
  Future<FavoriteToggleResult> toggle(FavoriteItem item) async {
    final isFavorite = value.contains(item.id);
    final nextItems = isFavorite
        ? value.items.where((candidate) => candidate.id != item.id).toList()
        : [item, ...value.items];
    value = FavoritesState(
      status: FavoritesLoadStatus.ready,
      userId: value.userId,
      items: nextItems,
    );
    return isFavorite
        ? FavoriteToggleResult.removed
        : FavoriteToggleResult.added;
  }
}
