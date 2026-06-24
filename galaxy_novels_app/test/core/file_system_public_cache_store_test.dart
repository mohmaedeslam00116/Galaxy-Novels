import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/network/file_system_public_cache_store.dart';

void main() {
  test('writes and reads cached JSON by public URL key', () async {
    final temp = await Directory.systemTemp.createTemp(
      'galaxy-public-cache-test-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final store = FileSystemPublicCacheStore(
      directoryProvider: () async => temp,
    );

    await store.write('https://example.com/app/packs/home.json', '{"ok":true}');

    expect(
      await store.read('https://example.com/app/packs/home.json'),
      '{"ok":true}',
    );
    expect(
      await store.read('https://example.com/app/packs/other.json'),
      isNull,
    );
  });
}
