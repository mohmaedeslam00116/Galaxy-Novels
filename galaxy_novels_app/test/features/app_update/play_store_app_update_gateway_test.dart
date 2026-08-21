import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/app_update/data/play_store_app_update_gateway.dart';

void main() {
  test('store launcher falls back from market app to HTTPS', () async {
    final openedUris = <Uri>[];
    final gateway = PlayStoreAppUpdateGateway(
      uriLauncher: (uri) async {
        openedUris.add(uri);
        return uri.scheme == 'https';
      },
    );

    expect(await gateway.openStore(), isTrue);
    expect(openedUris, hasLength(2));
    expect(openedUris.first.scheme, 'market');
    expect(openedUris.last.host, 'play.google.com');
    expect(openedUris.last.queryParameters['id'], 'com.galaxynovels.app');
  });

  test(
    'store launcher safely reports failure when both targets fail',
    () async {
      final gateway = PlayStoreAppUpdateGateway(
        uriLauncher: (uri) async => throw Exception('unavailable'),
      );

      expect(await gateway.openStore(), isFalse);
    },
  );
}
