import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/account/data/secure_auth_session_store.dart';

void main() {
  const storageKey = 'galaxy_novels_private_session_v1';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('stores only the private session snapshot', () async {
    const platformStorage = FlutterSecureStorage();
    final store = SecureAuthSessionStore(storage: platformStorage);

    await store.write(
      const PrivateSessionSnapshot(
        nonce: 'nonce-value',
        cookieHeader: 'wordpress_logged_in_test=cookie-value',
      ),
    );

    final restored = await store.read();
    final encoded = await platformStorage.read(key: storageKey);
    expect(restored?.nonce, 'nonce-value');
    expect(restored?.cookieHeader, contains('cookie-value'));
    expect(encoded, isNot(contains('password')));
    expect(encoded, isNot(contains('display_name')));
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
