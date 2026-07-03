import '../../../data/repositories/downloads_repository.dart';

abstract class DownloadProgressNotifier {
  const DownloadProgressNotifier();

  Future<void> showRunning(
    DownloadBatchProgress progress, {
    required bool isPaused,
  });

  Future<void> showCompleted(DownloadBatchProgress progress);

  Future<void> showFailed({
    required DownloadBatchProgress? progress,
    required String message,
  });

  Future<void> clear();
}

class NoopDownloadProgressNotifier implements DownloadProgressNotifier {
  const NoopDownloadProgressNotifier();

  @override
  Future<void> clear() async {}

  @override
  Future<void> showCompleted(DownloadBatchProgress progress) async {}

  @override
  Future<void> showFailed({
    required DownloadBatchProgress? progress,
    required String message,
  }) async {}

  @override
  Future<void> showRunning(
    DownloadBatchProgress progress, {
    required bool isPaused,
  }) async {}
}
