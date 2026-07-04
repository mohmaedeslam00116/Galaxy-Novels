import 'package:flutter/services.dart';

import '../domain/reader_preferences.dart';

typedef SystemUiModeSetter = Future<void> Function(SystemUiMode mode);

class ReaderDisplayController {
  const ReaderDisplayController({
    MethodChannel channel = const MethodChannel('galaxy_novels/reader_display'),
    SystemUiModeSetter? setSystemUiMode,
  }) : _channel = channel,
       _setSystemUiMode =
           setSystemUiMode ?? SystemChrome.setEnabledSystemUIMode;

  final MethodChannel _channel;
  final SystemUiModeSetter _setSystemUiMode;

  Future<void> apply(ReaderPreferences preferences) async {
    await _setSystemUiMode(
      preferences.immersiveMode
          ? SystemUiMode.immersiveSticky
          : SystemUiMode.edgeToEdge,
    );

    if (preferences.brightnessMode == ReaderBrightnessMode.manual) {
      await _invokeBrightness('setScreenBrightness', {
        'value': preferences.screenBrightness,
      });
      return;
    }

    await _invokeBrightness('clearScreenBrightness');
  }

  Future<void> restore() async {
    await _setSystemUiMode(SystemUiMode.edgeToEdge);
    await _invokeBrightness('clearScreenBrightness');
  }

  Future<void> _invokeBrightness(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // Desktop, web, and test surfaces can read normally without native hooks.
    }
  }
}
