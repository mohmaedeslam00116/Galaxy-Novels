import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/data/repositories/shared_preferences_reading_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('stores guest and account history in isolated v2 keys', () async {
    final preferences = SharedPreferencesAsync();
    final store = SharedPreferencesReadingHistoryStore(
      preferences: preferences,
    );

    await store.write(ReadingHistoryScope.guest, 'guest-history');
    await store.write(ReadingHistoryScope.user(7), 'account-history');

    expect(
      await preferences.getString('reading_history.v2.guest'),
      'guest-history',
    );
    expect(
      await preferences.getString('reading_history.v2.user.7'),
      'account-history',
    );
    expect(await store.read(ReadingHistoryScope.guest), 'guest-history');
    expect(await store.read(ReadingHistoryScope.user(7)), 'account-history');
  });

  test(
    'migrates reading_history.v1 only when the guest scope is read',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'reading_history.v1': 'legacy-history',
          });
      final preferences = SharedPreferencesAsync();
      final store = SharedPreferencesReadingHistoryStore(
        preferences: preferences,
      );

      final restored = await store.read(ReadingHistoryScope.guest);

      expect(restored, 'legacy-history');
      expect(
        await preferences.getString('reading_history.v2.guest'),
        'legacy-history',
      );
      expect(await preferences.getString('reading_history.v1'), isNull);
    },
  );

  test(
    'does not expose legacy guest history through an account scope',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'reading_history.v1': 'legacy-history',
          });
      final preferences = SharedPreferencesAsync();
      final store = SharedPreferencesReadingHistoryStore(
        preferences: preferences,
      );

      final restored = await store.read(ReadingHistoryScope.user(7));

      expect(restored, isNull);
      expect(
        await preferences.getString('reading_history.v1'),
        'legacy-history',
      );
      expect(await preferences.getString('reading_history.v2.user.7'), isNull);
    },
  );
}
