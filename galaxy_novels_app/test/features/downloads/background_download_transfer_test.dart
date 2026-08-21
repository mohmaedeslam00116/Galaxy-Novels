import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_transfer.dart';
import 'package:galaxy_novels_app/features/downloads/data/background_download_transfer.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_models.dart';

void main() {
  late _FakeNativeDownloadClient client;
  late BackgroundDownloadTransfer transfer;

  setUp(() {
    client = _FakeNativeDownloadClient();
    transfer = BackgroundDownloadTransfer(client: client);
  });

  tearDown(() async {
    transfer.dispose();
    await client.close();
  });

  test(
    'initializes queue limits, free-space checks, and notifications',
    () async {
      await transfer.initialize();

      expect(
        client.globalConfig,
        containsAll([
          (Config.holdingQueue, (2, 2, 2)),
          (Config.checkAvailableSpace, 8),
        ]),
      );
      expect(
        client.androidConfig,
        contains((Config.runInForeground, Config.always)),
      );
      expect(client.notificationsConfigured, isTrue);
      expect(client.started, isTrue);
    },
  );

  test('maps chapter and cover requests to isolated native groups', () async {
    await transfer.initialize();

    await transfer.enqueue(
      DownloadTransferRequest(
        transferId: 'job-1',
        kind: DownloadTransferKind.chapter,
        url: Uri.parse('https://example.com/chapter/1'),
        headers: const {'Accept': 'application/json'},
        fileName: '../chapter-1.json',
        requiresWifi: true,
      ),
    );
    await transfer.enqueue(
      DownloadTransferRequest(
        transferId: 'cover:7',
        kind: DownloadTransferKind.cover,
        url: Uri.parse('https://example.com/cover.webp'),
        headers: const {},
        fileName: 'cover-7.webp',
        requiresWifi: false,
      ),
    );

    final chapter = client.enqueued[0];
    expect(chapter.taskId, 'job-1');
    expect(chapter.group, 'chapter-downloads');
    expect(chapter.directory, 'galaxy_downloads/tmp');
    expect(chapter.filename, 'chapter-1.json');
    expect(chapter.baseDirectory, BaseDirectory.applicationSupport);
    expect(chapter.updates, Updates.statusAndProgress);
    expect(chapter.allowPause, isTrue);
    expect(chapter.retries, 2);
    expect(chapter.requiresWiFi, isTrue);

    final cover = client.enqueued[1];
    expect(cover.group, 'download-covers');
    expect(cover.directory, 'galaxy_downloads/covers');
    expect(cover.requiresWiFi, isFalse);
  });

  test('maps a native enqueue error to transfer unavailable', () async {
    await transfer.initialize();
    client.enqueueError = PlatformException(code: 'unavailable');

    final operation = transfer.enqueue(
      DownloadTransferRequest(
        transferId: 'job-failed',
        kind: DownloadTransferKind.chapter,
        url: Uri.parse('https://example.com/chapter/1'),
        headers: const {},
        fileName: 'chapter-1.json',
        requiresWifi: false,
      ),
    );

    await expectLater(
      operation,
      throwsA(isA<DownloadTransferUnavailableException>()),
    );
  });

  test('maps native progress, completion, and authorization failure', () async {
    await transfer.initialize();
    final updates = <DownloadTransferUpdate>[];
    final subscription = transfer.updates.listen(updates.add);
    await transfer.enqueue(
      DownloadTransferRequest(
        transferId: 'job-1',
        kind: DownloadTransferKind.chapter,
        url: Uri.parse('https://example.com/chapter/1'),
        headers: const {},
        fileName: 'chapter-1.json',
        requiresWifi: false,
      ),
    );
    final task = client.enqueued.single;

    client.emit(TaskProgressUpdate(task, 0.4));
    client.emit(
      TaskStatusUpdate(task, TaskStatus.failed, null, null, null, 401),
    );
    await Future<void>.delayed(Duration.zero);

    expect(updates[0], isA<DownloadTransferProgress>());
    expect((updates[0] as DownloadTransferProgress).progressFraction, 0.4);
    expect(
      (updates[1] as DownloadTransferFailed).failure,
      DownloadFailure.unauthorized,
    );

    await subscription.cancel();
  });

  test('emits the resolved local file after native completion', () async {
    transfer.dispose();
    transfer = BackgroundDownloadTransfer(
      client: client,
      resolveFilePath: (task) async => '/support/${task.filename}',
    );
    await transfer.initialize();
    final finished = transfer.updates
        .where((update) => update is DownloadTransferFinished)
        .cast<DownloadTransferFinished>()
        .first;
    await transfer.enqueue(
      DownloadTransferRequest(
        transferId: 'job-finished',
        kind: DownloadTransferKind.chapter,
        url: Uri.parse('https://example.com/chapter/2'),
        headers: const {},
        fileName: 'chapter-2.json',
        requiresWifi: false,
      ),
    );

    client.emit(
      TaskStatusUpdate(
        client.enqueued.single,
        TaskStatus.complete,
        null,
        null,
        null,
        200,
        'application/json',
      ),
    );

    final update = await finished;
    expect(update.localPath, '/support/chapter-2.json');
    expect(update.statusCode, 200);
    expect(update.mimeType, 'application/json');
  });

  test('ignores updates owned by another downloader group', () async {
    await transfer.initialize();
    final updates = <DownloadTransferUpdate>[];
    final subscription = transfer.updates.listen(updates.add);

    client.emit(
      TaskProgressUpdate(
        DownloadTask(
          taskId: 'unrelated',
          url: 'https://example.com/other',
          group: 'another-feature',
        ),
        0.5,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(updates, isEmpty);
    await subscription.cancel();
  });
}

class _FakeNativeDownloadClient implements NativeDownloadClient {
  final controller = StreamController<TaskUpdate>.broadcast();
  final enqueued = <DownloadTask>[];
  dynamic globalConfig;
  dynamic androidConfig;
  bool notificationsConfigured = false;
  bool started = false;
  PlatformException? enqueueError;

  void emit(TaskUpdate update) => controller.add(update);
  Future<void> close() => controller.close();

  @override
  Stream<TaskUpdate> get updates => controller.stream;

  @override
  Future<List<(String, String)>> configure({
    dynamic globalConfig,
    dynamic androidConfig,
  }) async {
    this.globalConfig = globalConfig;
    this.androidConfig = androidConfig;
    return const [];
  }

  @override
  void configureNotifications() {
    notificationsConfigured = true;
  }

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Future<bool> enqueue(DownloadTask task) async {
    if (enqueueError case final error?) throw error;
    enqueued.add(task);
    return true;
  }

  @override
  Future<bool> pause(DownloadTask task) async => true;

  @override
  Future<bool> resume(DownloadTask task) async => true;

  @override
  Future<bool> cancelTaskWithId(String taskId) async => true;
}
