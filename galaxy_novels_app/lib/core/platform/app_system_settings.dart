import 'package:flutter/services.dart';

class AppSystemSettings {
  const AppSystemSettings({
    MethodChannel channel = const MethodChannel('galaxy_novels/app_settings'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<bool> openNotificationSettings() async {
    return await _channel.invokeMethod<bool>('openNotificationSettings') ??
        false;
  }

  Future<bool> openTextToSpeechSettings() async {
    return await _channel.invokeMethod<bool>('openTextToSpeechSettings') ??
        false;
  }

  Future<bool> requestNotificationPermission() async {
    try {
      return await _channel.invokeMethod<bool>(
            'requestNotificationPermission',
          ) ??
          false;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return false;
    }
  }
}
