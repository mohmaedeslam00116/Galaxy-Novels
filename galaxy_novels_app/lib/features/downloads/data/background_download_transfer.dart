import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as path;

import '../application/download_transfer.dart';
import '../domain/download_models.dart';

class BackgroundDownloadTransfer implements DownloadTransfer {
  BackgroundDownloadTransfer({
    NativeDownloadClient? client,
    Future<String> Function(Task task)? resolveFilePath,
  }) : _client = client ?? FileDownloaderNativeClient(),
       _resolveFilePath = resolveFilePath ?? _defaultResolveFilePath;

  final NativeDownloadClient _client;
  final Future<String> Function(Task task) _resolveFilePath;
  final _controller = StreamController<DownloadTransferUpdate>.broadcast();
  final _tasks = <String, DownloadTask>{};
  StreamSubscription<TaskUpdate>? _subscription;
  bool _initialized = false;

  @override
  Stream<DownloadTransferUpdate> get updates => _controller.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _client.configure(
      globalConfig: [
        (Config.holdingQueue, (2, 2, 2)),
        (Config.checkAvailableSpace, 8),
      ],
      androidConfig: [(Config.runInForeground, Config.always)],
    );
    _client.configureNotifications();
    _subscription = _client.updates.listen(_handleNativeUpdate);
    await _client.start();
    _initialized = true;
  }

  @override
  Future<bool> enqueue(DownloadTransferRequest request) async {
    _requireInitialized();
    final fileName = path.basename(request.fileName.trim());
    if (fileName.isEmpty || fileName == '.' || fileName == '..') {
      throw ArgumentError.value(request.fileName, 'fileName');
    }
    final isChapter = request.kind == DownloadTransferKind.chapter;
    final task = DownloadTask(
      taskId: request.transferId,
      url: request.url.toString(),
      filename: fileName,
      headers: Map.unmodifiable(request.headers),
      directory: isChapter ? 'galaxy_downloads/tmp' : 'galaxy_downloads/covers',
      baseDirectory: BaseDirectory.applicationSupport,
      group: isChapter ? 'chapter-downloads' : 'download-covers',
      updates: Updates.statusAndProgress,
      requiresWiFi: request.requiresWifi,
      retries: 2,
      allowPause: true,
      metaData: request.kind.name,
    );
    _tasks[request.transferId] = task;
    final accepted = await _client.enqueue(task);
    if (!accepted) _tasks.remove(request.transferId);
    return accepted;
  }

  @override
  Future<bool> pause(String transferId) async {
    _requireInitialized();
    final task = _tasks[transferId];
    if (task == null) return false;
    return _client.pause(task);
  }

  @override
  Future<bool> resume(String transferId) async {
    _requireInitialized();
    final task = _tasks[transferId];
    if (task == null) return false;
    return _client.resume(task);
  }

  @override
  Future<bool> cancel(String transferId) async {
    _requireInitialized();
    final canceled = await _client.cancelTaskWithId(transferId);
    if (canceled) _tasks.remove(transferId);
    return canceled;
  }

  void _handleNativeUpdate(TaskUpdate update) {
    if (update.task is! DownloadTask ||
        (update.task.group != 'chapter-downloads' &&
            update.task.group != 'download-covers')) {
      return;
    }
    final transferId = update.task.taskId;
    _tasks[transferId] = update.task as DownloadTask;
    if (update is TaskProgressUpdate && update.progress >= 0) {
      _controller.add(DownloadTransferProgress(transferId, update.progress));
      return;
    }
    if (update is! TaskStatusUpdate) return;
    switch (update.status) {
      case TaskStatus.complete:
        _emitCompletion(update);
      case TaskStatus.paused:
        _controller.add(DownloadTransferPaused(transferId));
      case TaskStatus.notFound:
      case TaskStatus.failed:
        _tasks.remove(transferId);
        _controller.add(
          DownloadTransferFailed(
            transferId,
            update.responseStatusCode == 401 || update.responseStatusCode == 403
                ? DownloadFailure.unauthorized
                : DownloadFailure.network,
          ),
        );
      case TaskStatus.canceled:
        _tasks.remove(transferId);
        _controller.add(
          DownloadTransferFailed(transferId, DownloadFailure.canceled),
        );
      case TaskStatus.enqueued:
      case TaskStatus.running:
      case TaskStatus.waitingToRetry:
        break;
    }
  }

  Future<void> _emitCompletion(TaskStatusUpdate update) async {
    final transferId = update.task.taskId;
    try {
      final localPath = await _resolveFilePath(update.task);
      _controller.add(
        DownloadTransferFinished(
          transferId,
          localPath: localPath,
          statusCode: update.responseStatusCode ?? 200,
          mimeType: update.mimeType,
        ),
      );
    } on Object {
      _controller.add(
        DownloadTransferFailed(transferId, DownloadFailure.unknown),
      );
    } finally {
      _tasks.remove(transferId);
    }
  }

  void _requireInitialized() {
    if (!_initialized) {
      throw StateError('Background download transfer is not initialized.');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }

  static Future<String> _defaultResolveFilePath(Task task) => task.filePath();
}

abstract interface class NativeDownloadClient {
  Stream<TaskUpdate> get updates;
  Future<List<(String, String)>> configure({
    dynamic globalConfig,
    dynamic androidConfig,
  });
  void configureNotifications();
  Future<void> start();
  Future<bool> enqueue(DownloadTask task);
  Future<bool> pause(DownloadTask task);
  Future<bool> resume(DownloadTask task);
  Future<bool> cancelTaskWithId(String taskId);
}

class FileDownloaderNativeClient implements NativeDownloadClient {
  FileDownloaderNativeClient({FileDownloader? downloader})
    : _downloader = downloader ?? FileDownloader();

  final FileDownloader _downloader;

  @override
  Stream<TaskUpdate> get updates => _downloader.updates;

  @override
  Future<List<(String, String)>> configure({
    dynamic globalConfig,
    dynamic androidConfig,
  }) {
    return _downloader.configure(
      globalConfig: globalConfig,
      androidConfig: androidConfig,
    );
  }

  @override
  void configureNotifications() {
    _downloader.configureNotificationForGroup(
      'chapter-downloads',
      running: const TaskNotification(
        'تنزيل الفصول',
        '{numFinished} من {numTotal} · {progress}',
      ),
      complete: const TaskNotification(
        'اكتمل التنزيل',
        'تم حفظ {numTotal} فصلًا',
      ),
      error: const TaskNotification(
        'توقف التنزيل',
        'تعذر تنزيل {numFailed} فصل',
      ),
      paused: const TaskNotification('التنزيل متوقف', 'اضغط للاستئناف'),
      progressBar: true,
      groupNotificationId: 'galaxy-chapter-downloads',
    );
  }

  @override
  Future<void> start() => _downloader.start();

  @override
  Future<bool> enqueue(DownloadTask task) => _downloader.enqueue(task);

  @override
  Future<bool> pause(DownloadTask task) => _downloader.pause(task);

  @override
  Future<bool> resume(DownloadTask task) => _downloader.resume(task);

  @override
  Future<bool> cancelTaskWithId(String taskId) {
    return _downloader.cancelTaskWithId(taskId);
  }
}
