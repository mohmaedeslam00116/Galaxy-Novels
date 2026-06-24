import '../domain/favorite_item.dart';
import 'favorites_remote_service.dart';

class FavoritesSyncOutcome {
  const FavoritesSyncOutcome({
    required this.acceptedChanges,
    required this.remoteItems,
  });

  final List<FavoriteChange> acceptedChanges;
  final List<FavoriteItem> remoteItems;
}

class FavoritesSyncRunner {
  const FavoritesSyncRunner(this._remoteService);

  static const _maxBatchSize = 50;

  final FavoritesRemoteService _remoteService;

  Future<FavoritesSyncOutcome> synchronize(
    List<FavoriteChange> pendingChanges,
  ) async {
    final acceptedChanges = <FavoriteChange>[];
    for (
      var offset = 0;
      offset < pendingChanges.length;
      offset += _maxBatchSize
    ) {
      final end = (offset + _maxBatchSize).clamp(0, pendingChanges.length);
      final batch = pendingChanges.sublist(offset, end);
      final acceptedCount = await _remoteService.syncChanges(batch);
      if (acceptedCount != batch.length) {
        break;
      }
      acceptedChanges.addAll(batch);
    }
    final remoteItems = await _remoteService.fetchFavorites();
    return FavoritesSyncOutcome(
      acceptedChanges: List.unmodifiable(acceptedChanges),
      remoteItems: remoteItems,
    );
  }
}
