import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/app_update/application/app_update_snooze_store.dart';
import 'package:galaxy_novels_app/features/app_update/data/shared_preferences_app_update_snooze_store.dart';

void main() {
  test('snooze round-trips through persistent storage', () async {
    final persistence = _MemorySnoozePersistence();
    final store = SharedPreferencesAppUpdateSnoozeStore(
      persistence: persistence,
    );
    final snooze = AppUpdateSnooze(
      versionCode: 8,
      until: DateTime.utc(2026, 8, 11, 12),
    );

    await store.write(snooze);
    expect(await store.read(), isNotNull);
    expect((await store.read())!.versionCode, 8);
    expect((await store.read())!.until, DateTime.utc(2026, 8, 11, 12));

    await store.clear();
    expect(await store.read(), isNull);
  });

  test('corrupt snooze is ignored', () async {
    final persistence = _MemorySnoozePersistence()..value = '{broken';
    final store = SharedPreferencesAppUpdateSnoozeStore(
      persistence: persistence,
    );

    expect(await store.read(), isNull);
  });
}

class _MemorySnoozePersistence implements AppUpdateSnoozePersistence {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String encodedSnooze) async => value = encodedSnooze;
}
