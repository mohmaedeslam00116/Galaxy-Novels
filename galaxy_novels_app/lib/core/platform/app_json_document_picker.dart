import 'package:flutter/services.dart';

abstract class AppJsonDocumentPicker {
  Future<Uint8List?> pickJson();
}

class AppJsonDocumentPickerException implements Exception {
  const AppJsonDocumentPickerException([this.code = 'unavailable']);

  final String code;
}

class MethodChannelAppJsonDocumentPicker implements AppJsonDocumentPicker {
  const MethodChannelAppJsonDocumentPicker({
    MethodChannel channel = const MethodChannel(
      'galaxy_novels/document_picker',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<Uint8List?> pickJson() async {
    try {
      final value = await _channel.invokeMethod<Object?>('pickJsonDocument');
      if (value == null) return null;
      if (value is Uint8List) return value;
      if (value is List) return Uint8List.fromList(value.cast<int>());
      throw const AppJsonDocumentPickerException('invalid_result');
    } on MissingPluginException {
      throw const AppJsonDocumentPickerException();
    } on PlatformException catch (error) {
      throw AppJsonDocumentPickerException(error.code);
    } on TypeError {
      throw const AppJsonDocumentPickerException('invalid_result');
    }
  }
}
