import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/downloads/data/secure_download_key_store.dart';

void main() {
  const storedKeyName = 'galaxy_novels_download_key_v1';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'creates one 256-bit key and reuses it across store instances',
    () async {
      const storage = FlutterSecureStorage();
      final firstStore = SecureDownloadKeyStore(storage: storage);

      final first = await firstStore.readOrCreate();
      final second = await SecureDownloadKeyStore(
        storage: storage,
      ).readOrCreate();

      expect(await first.extractBytes(), hasLength(32));
      expect(await second.extractBytes(), await first.extractBytes());
      expect(await storage.read(key: storedKeyName), isNotEmpty);
    },
  );

  test('rejects a malformed stored device key', () async {
    FlutterSecureStorage.setMockInitialValues({storedKeyName: 'not-base64'});

    expect(
      SecureDownloadKeyStore(
        storage: const FlutterSecureStorage(),
      ).readOrCreate,
      throwsA(isA<DownloadKeyStoreException>()),
    );
  });
}
