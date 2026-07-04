import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_display_controller.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_preferences.dart';

void main() {
  test('applies immersive mode and manual screen brightness', () async {
    final calls = <MethodCall>[];
    final uiModes = <SystemUiMode>[];
    const channel = MethodChannel('test.reader.display');
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(() {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    final controller = ReaderDisplayController(
      channel: channel,
      setSystemUiMode: (mode) async => uiModes.add(mode),
    );

    await controller.apply(
      ReaderPreferences.defaults.copyWith(
        immersiveMode: true,
        brightnessMode: ReaderBrightnessMode.manual,
        screenBrightness: 0.72,
      ),
    );

    expect(uiModes, [SystemUiMode.immersiveSticky]);
    expect(calls.single.method, 'setScreenBrightness');
    expect(calls.single.arguments, {'value': 0.72});
  });

  test('restore clears reader display overrides', () async {
    final calls = <MethodCall>[];
    final uiModes = <SystemUiMode>[];
    const channel = MethodChannel('test.reader.display.restore');
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(() {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    final controller = ReaderDisplayController(
      channel: channel,
      setSystemUiMode: (mode) async => uiModes.add(mode),
    );

    await controller.restore();

    expect(uiModes, [SystemUiMode.edgeToEdge]);
    expect(calls.single.method, 'clearScreenBrightness');
  });
}
