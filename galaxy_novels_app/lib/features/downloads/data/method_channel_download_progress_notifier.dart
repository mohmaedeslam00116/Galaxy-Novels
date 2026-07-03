import 'package:flutter/services.dart';

import '../../../data/repositories/downloads_repository.dart';
import '../application/download_progress_notifier.dart';

class MethodChannelDownloadProgressNotifier
    implements DownloadProgressNotifier {
  const MethodChannelDownloadProgressNotifier({
    MethodChannel channel = const MethodChannel(
      'galaxy_novels/download_notifications',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<void> clear() {
    return _invoke('clear');
  }

  @override
  Future<void> showCompleted(DownloadBatchProgress progress) {
    return _invoke('complete', _payloadFor(progress));
  }

  @override
  Future<void> showFailed({
    required DownloadBatchProgress? progress,
    required String message,
  }) {
    return _invoke('fail', {
      if (progress != null) ..._payloadFor(progress),
      'message': message,
    });
  }

  @override
  Future<void> showRunning(
    DownloadBatchProgress progress, {
    required bool isPaused,
  }) {
    return _invoke('startOrUpdate', {
      ..._payloadFor(progress),
      'isPaused': isPaused,
    });
  }

  Future<void> _invoke(String method, [Map<String, Object?>? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Map<String, Object?> _payloadFor(DownloadBatchProgress progress) {
    return {
      'novelTitle': progress.novelTitle,
      'novelCover': progress.novelCover,
      'total': progress.total,
      'completed': progress.completed,
      'failed': progress.failed,
    };
  }
}
