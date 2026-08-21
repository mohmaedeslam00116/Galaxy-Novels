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

  test('reports cache bytes and clears only the cache directory', () async {
    final temp = await Directory.systemTemp.createTemp(
      'galaxy-public-cache-maintenance-test-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final cacheDirectory = Directory('${temp.path}/public_json_cache_v1');
    final preservedFile = File('${temp.path}/downloaded-chapter.bin');
    await preservedFile.writeAsBytes([1, 2, 3, 4]);
    final store = FileSystemPublicCacheStore(
      directoryProvider: () async => cacheDirectory,
    );

    await store.write('home', '12345');
    await store.write('catalog', '678');

    expect(await store.cacheSizeBytes(), 8);

    await store.clearTemporaryCache();

    expect(await store.cacheSizeBytes(), 0);
    expect(await preservedFile.readAsBytes(), [1, 2, 3, 4]);
  });
}
