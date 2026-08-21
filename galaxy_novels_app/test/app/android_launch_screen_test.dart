import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native Android launch screen never displays an app icon', () {
    final android12Theme = File(
      'android/app/src/main/res/values-v31/styles.xml',
    ).readAsStringSync();
    final legacyLaunchBackgrounds = [
      File('android/app/src/main/res/drawable/launch_background.xml'),
      File('android/app/src/main/res/drawable-v21/launch_background.xml'),
    ];

    expect(
      android12Theme,
      contains(
        '<item name="android:windowSplashScreenAnimatedIcon">'
        '@android:color/transparent</item>',
      ),
    );
    expect(android12Theme, isNot(contains('ic_launcher')));
    for (final background in legacyLaunchBackgrounds) {
      final xml = background.readAsStringSync();
      expect(xml, isNot(contains('<bitmap')));
      expect(xml, isNot(contains('ic_launcher')));
    }
  });

  test('native Android launch color matches the Flutter splash', () {
    final colors = File(
      'android/app/src/main/res/values/colors.xml',
    ).readAsStringSync();

    expect(
      colors,
      contains('<color name="native_splash_background">#050714</color>'),
    );
  });
}
