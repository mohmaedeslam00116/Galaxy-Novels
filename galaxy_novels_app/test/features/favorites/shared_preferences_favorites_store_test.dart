import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/favorites/data/shared_preferences_favorites_store.dart';
import 'package:galaxy_novels_app/features/favorites/domain/favorite_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('keeps favorites and pending changes isolated per user', () async {
    final store = SharedPreferencesFavoritesStore();
    await store.write(
      7,
      FavoriteLocalSnapshot(
        items: [_favorite(10, 'مفضلة الحساب الأول')],
        pendingChanges: [
          FavoriteChange(
            novelId: 10,
            action: FavoriteChangeAction.add,
            changedAt: DateTime.utc(2026, 6, 23, 10),
          ),
        ],
      ),
    );
    await store.write(
      8,
      FavoriteLocalSnapshot(items: [_favorite(20, 'مفضلة الحساب الثاني')]),
    );

    final first = await store.read(7);
    final second = await store.read(8);

    expect(first.items.single.title, 'مفضلة الحساب الأول');
    expect(first.pendingChanges.single.novelId, 10);
    expect(second.items.single.title, 'مفضلة الحساب الثاني');
    expect(second.pendingChanges, isEmpty);
  });

  test(
    'deletes a malformed snapshot instead of exposing partial data',
    () async {
      SharedPreferences.setMockInitialValues({
        'favorites.v1.user.7': '{not-json',
      });
      final store = SharedPreferencesFavoritesStore();

      final snapshot = await store.read(7);

      expect(snapshot.items, isEmpty);
      expect(snapshot.pendingChanges, isEmpty);
      expect(await store.read(7).then((value) => value.items), isEmpty);
    },
  );
}

FavoriteItem _favorite(int id, String title) {
  return FavoriteItem(
    id: id,
    title: title,
    url: '/novel/$id/',
    cover: '/cover/$id.jpg',
    manifestPath: favoriteManifestPath(id),
    addedAt: DateTime.utc(2026, 6, 23),
  );
}
