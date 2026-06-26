import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/account/data/secure_auth_session_store.dart';

void main() {
  const storageKey = 'galaxy_novels_private_session_v1';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('stores only the app bearer session snapshot', () async {
    const platformStorage = FlutterSecureStorage();
    final store = SecureAuthSessionStore(storage: platformStorage);

    await store.write(
      const PrivateSessionSnapshot(
        accessToken: 'wra_access_token',
        tokenType: 'Bearer',
      ),
    );

    final restored = await store.read();
    final encoded = await platformStorage.read(key: storageKey);
    expect(restored?.accessToken, 'wra_access_token');
    expect(restored?.tokenType, 'Bearer');
    expect(encoded, isNot(contains('password')));
    expect(encoded, isNot(contains('display_name')));
    expect(encoded, isNot(contains('wordpress_logged_in')));
    expect(encoded, isNot(contains('nonce')));
  });

  test('deletes malformed stored session data', () async {
    const platformStorage = FlutterSecureStorage();
    await platformStorage.write(key: storageKey, value: 'not-json');
    final store = SecureAuthSessionStore(storage: platformStorage);

    final restored = await store.read();

    expect(restored, isNull);
    expect(await platformStorage.read(key: storageKey), isNull);
  });
}
