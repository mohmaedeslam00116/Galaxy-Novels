import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android declares the download foreground service contract', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(
      manifest,
      contains('android.permission.FOREGROUND_SERVICE_DATA_SYNC'),
    );
    expect(
      manifest,
      contains('androidx.work.impl.foreground.SystemForegroundService'),
    );
    expect(manifest, contains('android:foregroundServiceType="dataSync"'));
  });
}
