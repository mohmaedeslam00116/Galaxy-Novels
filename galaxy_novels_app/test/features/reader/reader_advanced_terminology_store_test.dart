import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/data/file_reader_advanced_terminology_state_store.dart';
import 'package:galaxy_novels_app/features/reader/data/shared_preferences_reader_advanced_terminology_access_store.dart';

void main() {
  test('file store writes, restores, and clears terminology state', () async {
    final directory = await Directory.systemTemp.createTemp(
      'galaxy-reader-terms-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = FileReaderAdvancedTerminologyStateStore(
      directoryProvider: () async => directory,
    );

    expect(await store.read(), isNull);
    await store.write('{"version":1}');
    expect(await store.read(), '{"version":1}');
    await store.clear();
    expect(await store.read(), isNull);
  });

  test(
    'access store keeps a fallback value when plugins are unavailable',
    () async {
      final store = SharedPreferencesReaderAdvancedTerminologyAccessStore();

      await store.write(true);

      expect(await store.read(), isTrue);
    },
  );
}
