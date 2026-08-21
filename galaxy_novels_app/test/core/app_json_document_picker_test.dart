import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/platform/app_json_document_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/json_picker');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('returns selected JSON bytes from the platform channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'pickJsonDocument');
          return Uint8List.fromList([123, 125]);
        });
    final picker = MethodChannelAppJsonDocumentPicker(channel: channel);

    expect(await picker.pickJson(), Uint8List.fromList([123, 125]));
  });

  test('returns null when the user cancels the picker', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    final picker = MethodChannelAppJsonDocumentPicker(channel: channel);

    expect(await picker.pickJson(), isNull);
  });

  test('maps platform failures to a stable picker exception', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'file_too_large');
        });
    final picker = MethodChannelAppJsonDocumentPicker(channel: channel);

    expect(picker.pickJson, throwsA(isA<AppJsonDocumentPickerException>()));
  });
}
