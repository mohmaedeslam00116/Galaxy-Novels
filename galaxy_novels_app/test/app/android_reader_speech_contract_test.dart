import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android declares the media playback service and TTS visibility', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.WAKE_LOCK'));
    expect(
      manifest,
      contains('android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK'),
    );
    expect(
      manifest,
      contains('com.ryanheise.audioservice.AudioService'),
    );
    expect(manifest, contains('android:foregroundServiceType="mediaPlayback"'));
    expect(
      manifest,
      contains('com.ryanheise.audioservice.MediaButtonReceiver'),
    );
    expect(manifest, contains('android.intent.action.TTS_SERVICE'));
  });

  test('custom activity retains channels while using AudioServiceActivity', () {
    final activity = File(
      'android/app/src/main/kotlin/com/galaxynovels/app/MainActivity.kt',
    ).readAsStringSync();

    expect(activity, contains('class MainActivity : AudioServiceActivity()'));
    expect(activity, contains('galaxy_novels/reader_display'));
    expect(activity, contains('galaxy_novels/document_picker'));
    expect(activity, contains('GoogleMobileAdsPlugin.registerNativeAdFactory'));
    expect(activity, contains('openTextToSpeechSettings'));
    expect(activity, contains('requestNotificationPermission'));
  });
}
