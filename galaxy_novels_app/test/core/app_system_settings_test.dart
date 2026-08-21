import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/platform/app_system_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'opens Android notification settings through the platform channel',
    () async {
      const channel = MethodChannel('galaxy_novels/app_settings_test');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final settings = AppSystemSettings(channel: channel);

      expect(await settings.openNotificationSettings(), isTrue);
      expect(calls.single.method, 'openNotificationSettings');
    },
  );

  test(
    'returns false when the platform cannot open notification settings',
    () async {
      const channel = MethodChannel('galaxy_novels/app_settings_test');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => false);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      expect(
        await AppSystemSettings(channel: channel).openNotificationSettings(),
        isFalse,
      );
    },
  );

  test('opens Android text-to-speech settings', () async {
    const channel = MethodChannel('galaxy_novels/app_settings_test');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final opened = await AppSystemSettings(
      channel: channel,
    ).openTextToSpeechSettings();

    expect(opened, isTrue);
    expect(calls.single.method, 'openTextToSpeechSettings');
  });

  test('requests Android notification permission for media playback', () async {
    const channel = MethodChannel('galaxy_novels/app_settings_test');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final allowed = await AppSystemSettings(
      channel: channel,
    ).requestNotificationPermission();

    expect(allowed, isTrue);
    expect(calls.single.method, 'requestNotificationPermission');
  });
}
