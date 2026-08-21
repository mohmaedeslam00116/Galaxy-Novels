import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firebase template exposes safe reader interstitial controls', () {
    final template =
        jsonDecode(File('remoteconfig.template.json').readAsStringSync())
            as Map<String, dynamic>;
    final parameters = template['parameters'] as Map<String, dynamic>;

    expect(
      parameters['android_reader_interstitial_enabled']['defaultValue']['value'],
      'true',
    );
    expect(
      parameters['android_reader_interstitial_min_chapters']['defaultValue']['value'],
      '5',
    );
    expect(
      parameters['android_reader_interstitial_max_chapters']['defaultValue']['value'],
      '20',
    );
  });
}
