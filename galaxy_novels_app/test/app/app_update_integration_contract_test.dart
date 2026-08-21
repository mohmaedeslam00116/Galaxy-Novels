import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter declares Remote Config and Google Play update packages', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('firebase_remote_config: ^6.5.6'));
    expect(pubspec, contains('in_app_update: ^4.2.5'));
  });

  test('deployed Remote Config template starts with a safe build floor', () {
    final template =
        jsonDecode(File('remoteconfig.template.json').readAsStringSync())
            as Map<String, Object?>;
    final parameters = template['parameters'] as Map<String, Object?>;
    final minimum =
        parameters['android_min_supported_build'] as Map<String, Object?>;
    final defaultValue = minimum['defaultValue'] as Map<String, Object?>;

    expect(defaultValue['value'], '0');
    expect(
      parameters.keys,
      containsAll(<String>{
        'android_update_system_enabled',
        'android_optional_update_enabled',
        'android_optional_update_title_ar',
        'android_optional_update_message_ar',
        'android_required_update_title_ar',
        'android_required_update_message_ar',
      }),
    );
  });
}
