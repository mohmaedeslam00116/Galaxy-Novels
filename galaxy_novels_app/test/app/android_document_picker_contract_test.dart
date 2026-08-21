import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('document picker uses the FlutterActivity-compatible result API', () {
    final source = File(
      'android/app/src/main/kotlin/com/galaxynovels/app/MainActivity.kt',
    ).readAsStringSync();

    expect(source, isNot(contains('registerForActivityResult')));
    expect(source, contains('startActivityForResult'));
    expect(source, contains('override fun onActivityResult'));
  });
}
