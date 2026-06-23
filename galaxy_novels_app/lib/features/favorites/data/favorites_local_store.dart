import '../domain/favorite_item.dart';

abstract class FavoritesLocalStore {
  Future<FavoriteLocalSnapshot> read(int userId);

  Future<void> write(int userId, FavoriteLocalSnapshot snapshot);
}

class FavoritesStoreException implements Exception {
  const FavoritesStoreException();
}
