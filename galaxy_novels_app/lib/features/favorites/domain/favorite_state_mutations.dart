import 'favorite_item.dart';

class FavoriteToggleMutation {
  const FavoriteToggleMutation({
    required this.items,
    required this.pendingChanges,
    required this.isFavorite,
  });

  final List<FavoriteItem> items;
  final Map<int, FavoriteChange> pendingChanges;
  final bool isFavorite;
}

FavoriteToggleMutation buildFavoriteToggleMutation({
  required List<FavoriteItem> currentItems,
  required Map<int, FavoriteChange> currentPendingChanges,
  required FavoriteItem candidate,
  required DateTime changedAt,
}) {
  final wasFavorite = currentItems.any(
    (favorite) => favorite.id == candidate.id,
  );
  final willBeFavorite = !wasFavorite;
  final normalizedCandidate = candidate.copyWith(
    manifestPath: candidate.manifestPath.isEmpty
        ? favoriteManifestPath(candidate.id)
        : candidate.manifestPath,
    addedAt: willBeFavorite ? changedAt : candidate.addedAt,
  );
  final nextItems = willBeFavorite
      ? sortFavoriteItems([
          normalizedCandidate,
          for (final favorite in currentItems)
            if (favorite.id != candidate.id) favorite,
        ])
      : currentItems
            .where((favorite) => favorite.id != candidate.id)
            .toList(growable: false);
  final nextPending = Map<int, FavoriteChange>.of(currentPendingChanges)
    ..[candidate.id] = FavoriteChange(
      novelId: candidate.id,
      action: willBeFavorite
          ? FavoriteChangeAction.add
          : FavoriteChangeAction.remove,
      changedAt: changedAt,
    );
  return FavoriteToggleMutation(
    items: nextItems,
    pendingChanges: Map.unmodifiable(nextPending),
    isFavorite: willBeFavorite,
  );
}

class FavoriteReconciliation {
  const FavoriteReconciliation({
    required this.items,
    required this.pendingChanges,
  });

  final List<FavoriteItem> items;
  final Map<int, FavoriteChange> pendingChanges;
}

FavoriteReconciliation reconcileFavoriteState({
  required List<FavoriteItem> remoteItems,
  required List<FavoriteItem> localItems,
  required Map<int, FavoriteChange> pendingChanges,
}) {
  final localById = {for (final favorite in localItems) favorite.id: favorite};
  final remoteById = <int, FavoriteItem>{
    for (final remote in remoteItems)
      remote.id: _preferLocalMetadata(remote, localById[remote.id]),
  };
  final unresolved = Map<int, FavoriteChange>.of(pendingChanges);
  for (final change in pendingChanges.values) {
    if (remoteById.containsKey(change.novelId) == change.shouldExist) {
      unresolved.remove(change.novelId);
    }
  }
  for (final change in unresolved.values) {
    if (change.shouldExist) {
      final localFavorite = localById[change.novelId];
      if (localFavorite != null) {
        remoteById[change.novelId] = localFavorite;
      }
    } else {
      remoteById.remove(change.novelId);
    }
  }
  return FavoriteReconciliation(
    items: sortFavoriteItems(remoteById.values.toList()),
    pendingChanges: Map.unmodifiable(unresolved),
  );
}

FavoriteItem _preferLocalMetadata(FavoriteItem remote, FavoriteItem? local) {
  if (local == null) {
    return remote;
  }
  return remote.copyWith(
    cover: remote.cover.isEmpty ? local.cover : remote.cover,
    manifestPath: local.manifestPath.isEmpty
        ? remote.manifestPath
        : local.manifestPath,
  );
}

List<FavoriteItem> sortFavoriteItems(List<FavoriteItem> favorites) {
  final sorted = [...favorites]
    ..sort((first, second) => second.addedAt.compareTo(first.addedAt));
  return List.unmodifiable(sorted);
}

List<FavoriteChange> sortFavoriteChanges(List<FavoriteChange> changes) {
  final sorted = [...changes]
    ..sort((first, second) => first.changedAt.compareTo(second.changedAt));
  return List.unmodifiable(sorted);
}
