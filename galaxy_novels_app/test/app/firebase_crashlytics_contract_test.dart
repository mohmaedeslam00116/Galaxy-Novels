import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter and Android declare the Crashlytics integration', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final settings = File('android/settings.gradle.kts').readAsStringSync();
    final appGradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(pubspec, contains('firebase_crashlytics: ^5.2.7'));
    expect(
      settings,
      contains(
        'id("com.google.firebase.crashlytics") version "3.0.7" apply false',
      ),
    );
    expect(appGradle, contains('id("com.google.firebase.crashlytics")'));
  });

  test('Crashlytics is configured after Firebase and before Workmanager', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final firebaseIndex = mainSource.indexOf('Firebase.initializeApp()');
    final crashlyticsIndex = mainSource.indexOf('CrashReportingBootstrap(');
    final workmanagerIndex = mainSource.indexOf('Workmanager().initialize(');

    expect(firebaseIndex, greaterThanOrEqualTo(0));
    expect(crashlyticsIndex, greaterThan(firebaseIndex));
    expect(workmanagerIndex, greaterThan(crashlyticsIndex));
  });

  test('Android disables native Crashlytics collection only in debug', () {
    final debugManifest = File(
      'android/app/src/debug/AndroidManifest.xml',
    ).readAsStringSync();
    final profileManifest = File(
      'android/app/src/profile/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      debugManifest,
      contains('android:name="firebase_crashlytics_collection_enabled"'),
    );
    expect(debugManifest, contains('android:value="false"'));
    expect(
      profileManifest,
      isNot(contains('firebase_crashlytics_collection_enabled')),
    );
  });
}
