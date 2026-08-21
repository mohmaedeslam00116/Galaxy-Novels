import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('download store avoids UPSERT syntax missing from Android 10', () {
    final storeSource = File(
      'lib/features/downloads/data/sqflite_download_store.dart',
    ).readAsStringSync();

    expect(
      storeSource,
      isNot(
        contains(
          RegExp(
            r'ON\s+CONFLICT\s*\([^)]*\)\s+DO\s+UPDATE',
            caseSensitive: false,
          ),
        ),
      ),
    );
  });
}
