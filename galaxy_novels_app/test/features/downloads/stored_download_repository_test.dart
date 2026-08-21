import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_resume_scheduler.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_repository.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_transfer.dart';
import 'package:galaxy_novels_app/features/downloads/data/downloaded_chapter_file_store.dart';
import 'package:galaxy_novels_app/features/downloads/data/secure_download_key_store.dart';
import 'package:galaxy_novels_app/features/downloads/data/sqflite_download_store.dart';
import 'package:galaxy_novels_app/features/downloads/data/stored_download_repository.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_models.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_entitlement.dart';
import 'package:galaxy_novels_app/features/account/application/auth_session_store.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late SqfliteDownloadStore store;
  late _FakeTransfer transfer;
  late StoredDownloadRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('stored_downloads_');
    store = await SqfliteDownloadStore.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    transfer = _FakeTransfer();
    repository = StoredDownloadRepository(
      store: store,
      transfer: transfer,
      fileStore: DownloadedChapterFileStore(
        rootDirectory: Directory('${directory.path}/chapters'),
        keyStore: _MemoryKeyStore(),
      ),
      scheduler: _FakeScheduler(),
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      clock: () => DateTime(2026, 7, 20, 9),
    );
    await repository.initialize();
  });

  tearDown(() async {
    await repository.shutdown();
    await store.close();
    await transfer.close();
    await directory.delete(recursive: true);
  });

  test(
    'charges only after a valid chapter is stored and reads it offline',
    () async {
      final enqueued = await repository.enqueue(
        novel: const DownloadNovelRequest(
          novelId: 7,
          title: 'رواية الاختبار',
          coverUrl: '',
        ),
        chapters: const [
          DownloadChapterRequest(
            chapterKey: 'public:71',
            chapterId: 71,
            label: 'الفصل 71',
            contentApi: '/chapter/71',
            isVip: false,
          ),
        ],
      );

      expect(enqueued.acceptedChapterKeys, ['public:71']);
      expect(transfer.requests, hasLength(1));
      expect(repository.value.allowance.remaining, 99);
      expect(repository.value.novels.single.chapters, isEmpty);

      final temporaryResponse = File('${directory.path}/chapter-71.json');
      await temporaryResponse.writeAsString(_serverResponse(_chapterContent));
      transfer.emit(
        DownloadTransferFinished(
          transfer.requests.single.transferId,
          localPath: temporaryResponse.path,
          statusCode: 200,
          mimeType: 'application/json',
        ),
      );
      await _waitUntil(
        () => repository.value.novels.single.chapters.isNotEmpty,
      );

      expect(repository.value.allowance.remaining, 99);
      expect(repository.value.novels.single.chapters.single.chapterId, 71);
      expect(temporaryResponse.existsSync(), isFalse);
      final offline = await repository.loadOffline(
        offlineChapterUri('public:71'),
      );
      expect(offline.contentHtml, _chapterContent.contentHtml);
    },
  );

  test('invalid response releases the reservation without charging', () async {
    await repository.enqueue(
      novel: const DownloadNovelRequest(
        novelId: 7,
        title: 'رواية الاختبار',
        coverUrl: '',
      ),
      chapters: const [
        DownloadChapterRequest(
          chapterKey: 'public:71',
          chapterId: 71,
          label: 'الفصل 71',
          contentApi: '/chapter/71',
          isVip: false,
        ),
      ],
    );
    final invalid = File('${directory.path}/invalid.json');
    await invalid.writeAsString('{broken');

    transfer.emit(
      DownloadTransferFinished(
        transfer.requests.single.transferId,
        localPath: invalid.path,
        statusCode: 200,
        mimeType: 'application/json',
      ),
    );
    await _waitUntil(
      () =>
          repository.value.groups.single.jobs.single.status ==
          DownloadJobStatus.failed,
    );

    expect(repository.value.allowance.remaining, 100);
    expect(repository.value.novels.single.chapters, isEmpty);
  });

  test(
    'native enqueue failure is surfaced and releases the reservation',
    () async {
      transfer.enqueueError = const DownloadTransferUnavailableException();

      final operation = repository.enqueue(
        novel: const DownloadNovelRequest(
          novelId: 7,
          title: 'رواية الاختبار',
          coverUrl: '',
        ),
        chapters: const [
          DownloadChapterRequest(
            chapterKey: 'public:71',
            chapterId: 71,
            label: 'الفصل 71',
            contentApi: '/chapter/71',
            isVip: false,
          ),
        ],
      );

      await expectLater(
        operation,
        throwsA(isA<DownloadUnavailableException>()),
      );
      expect(repository.value.allowance.remaining, 100);
      expect(
        repository.value.groups.single.jobs.single.status,
        DownloadJobStatus.failed,
      );
    },
  );

  test('a stale offline URI is reported as temporarily unavailable', () async {
    await expectLater(
      repository.loadOffline(offlineChapterUri('public:missing')),
      throwsA(isA<DownloadUnavailableException>()),
    );
  });

  test('manual retry requeues a failed job without charging it', () async {
    await repository.enqueue(
      novel: const DownloadNovelRequest(
        novelId: 7,
        title: 'رواية الاختبار',
        coverUrl: '',
      ),
      chapters: const [
        DownloadChapterRequest(
          chapterKey: 'public:71',
          chapterId: 71,
          label: 'الفصل 71',
          contentApi: '/chapter/71',
          isVip: false,
        ),
      ],
    );
    final jobId = transfer.requests.single.transferId;
    transfer.emit(DownloadTransferFailed(jobId, DownloadFailure.network));
    await _waitUntil(
      () =>
          repository.value.groups.single.jobs.single.status ==
          DownloadJobStatus.failed,
    );

    await repository.retryJob(jobId);

    expect(transfer.requests, hasLength(2));
    expect(repository.value.allowance.remaining, 99);
  });

  test(
    'pause and resume persist group state and control queued work',
    () async {
      final enqueued = await repository.enqueue(
        novel: const DownloadNovelRequest(
          novelId: 7,
          title: 'رواية الاختبار',
          coverUrl: '',
        ),
        chapters: const [
          DownloadChapterRequest(
            chapterKey: 'public:71',
            chapterId: 71,
            label: 'الفصل 71',
            contentApi: '/chapter/71',
            isVip: false,
          ),
          DownloadChapterRequest(
            chapterKey: 'public:72',
            chapterId: 72,
            label: 'الفصل 72',
            contentApi: '/chapter/72',
            isVip: false,
          ),
          DownloadChapterRequest(
            chapterKey: 'public:73',
            chapterId: 73,
            label: 'الفصل 73',
            contentApi: '/chapter/73',
            isVip: false,
          ),
        ],
      );
      expect(transfer.requests, hasLength(2));

      await repository.pauseGroup(enqueued.groupId!);

      expect(repository.value.groups.single.status, DownloadGroupStatus.paused);
      expect(transfer.pausedIds, hasLength(2));

      final firstResponse = File('${directory.path}/chapter-71-paused.json');
      await firstResponse.writeAsString(_serverResponse(_chapterContent));
      transfer.emit(
        DownloadTransferFinished(
          transfer.requests.first.transferId,
          localPath: firstResponse.path,
          statusCode: 200,
          mimeType: 'application/json',
        ),
      );
      await _waitUntil(
        () => repository.value.novels.single.chapters.isNotEmpty,
      );
      expect(transfer.requests, hasLength(2));

      await repository.resumeGroup(enqueued.groupId!);

      expect(
        repository.value.groups.single.status,
        DownloadGroupStatus.running,
      );
      expect(transfer.resumedIds, isNotEmpty);
      expect(transfer.requests, hasLength(3));
    },
  );

  test(
    'cancel removes the queue and permits selecting the chapter again',
    () async {
      final enqueued = await repository.enqueue(
        novel: const DownloadNovelRequest(
          novelId: 7,
          title: 'رواية الاختبار',
          coverUrl: '',
        ),
        chapters: const [
          DownloadChapterRequest(
            chapterKey: 'public:71',
            chapterId: 71,
            label: 'الفصل 71',
            contentApi: '/chapter/71',
            isVip: false,
          ),
        ],
      );

      await repository.cancelGroup(enqueued.groupId!);

      expect(repository.value.groups, isEmpty);
      expect(transfer.canceledIds, isNotEmpty);
      final redownload = await repository.enqueue(
        novel: const DownloadNovelRequest(
          novelId: 7,
          title: 'رواية الاختبار',
          coverUrl: '',
        ),
        chapters: const [
          DownloadChapterRequest(
            chapterKey: 'public:71',
            chapterId: 71,
            label: 'الفصل 71',
            contentApi: '/chapter/71',
            isVip: false,
          ),
        ],
      );
      expect(redownload.acceptedChapterKeys, ['public:71']);
    },
  );

  test('restores active reservations after repository recreation', () async {
    await repository.shutdown();
    await store.enqueue(
      novel: const DownloadNovelRequest(
        novelId: 7,
        title: 'رواية الاختبار',
        coverUrl: '',
      ),
      chapters: const [
        DownloadChapterRequest(
          chapterKey: 'public:71',
          chapterId: 71,
          label: 'الفصل 71',
          contentApi: '/chapter/71',
          isVip: false,
        ),
      ],
    );
    final reservation = await store.reserveNext(
      plan: DownloadPlan.forTier(DownloadMembershipTier.regular),
      now: DateTime(2026, 7, 20, 9),
    );
    expect(reservation, isNotNull);

    repository = StoredDownloadRepository(
      store: store,
      transfer: transfer,
      fileStore: DownloadedChapterFileStore(
        rootDirectory: Directory('${directory.path}/chapters'),
        keyStore: _MemoryKeyStore(),
      ),
      scheduler: _FakeScheduler(),
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      clock: () => DateTime(2026, 7, 20, 9),
    );
    await repository.initialize();

    final response = File('${directory.path}/chapter-71-restored.json');
    await response.writeAsString(_serverResponse(_chapterContent));
    transfer.emit(
      DownloadTransferFinished(
        reservation!.jobId,
        localPath: response.path,
        statusCode: 200,
        mimeType: 'application/json',
      ),
    );

    await _waitUntil(() => repository.value.novels.single.chapters.isNotEmpty);
    expect(repository.value.novels.single.chapters.single.chapterId, 71);
  });

  test(
    'VIP download never falls back to a public request without a session',
    () async {
      await repository.shutdown();
      repository = StoredDownloadRepository(
        store: store,
        transfer: transfer,
        fileStore: DownloadedChapterFileStore(
          rootDirectory: Directory('${directory.path}/chapters'),
          keyStore: _MemoryKeyStore(),
        ),
        scheduler: _FakeScheduler(),
        sessionStore: _MemorySessionStore(),
        config: const AppConfig(siteBaseUrl: 'https://example.com/'),
        clock: () => DateTime(2026, 7, 20, 9),
      );
      await repository.initialize();

      await repository.enqueue(
        novel: const DownloadNovelRequest(
          novelId: 7,
          title: 'رواية الاختبار',
          coverUrl: '',
        ),
        chapters: const [
          DownloadChapterRequest(
            chapterKey: 'vip:72',
            chapterId: 72,
            label: 'الفصل 72',
            contentApi: '/vip/chapter/72',
            isVip: true,
          ),
        ],
      );

      expect(transfer.requests, isEmpty);
      expect(
        repository.value.groups.single.jobs.single.lastError,
        DownloadFailure.vipRequired,
      );
      expect(repository.value.allowance.remaining, 100);
    },
  );

  test('offline navigation stays between downloaded chapters', () async {
    await repository.enqueue(
      novel: const DownloadNovelRequest(
        novelId: 7,
        title: 'رواية الاختبار',
        coverUrl: '',
      ),
      chapters: const [
        DownloadChapterRequest(
          chapterKey: 'public:71',
          chapterId: 71,
          label: 'الفصل 71',
          contentApi: '/chapter/71',
          isVip: false,
        ),
        DownloadChapterRequest(
          chapterKey: 'public:72',
          chapterId: 72,
          label: 'الفصل 72',
          contentApi: '/chapter/72',
          isVip: false,
        ),
      ],
    );
    for (var index = 0; index < transfer.requests.length; index++) {
      final chapterId = 71 + index;
      final response = File('${directory.path}/chapter-$chapterId.json');
      await response.writeAsString(_serverResponse(_contentFor(chapterId)));
      transfer.emit(
        DownloadTransferFinished(
          transfer.requests[index].transferId,
          localPath: response.path,
          statusCode: 200,
          mimeType: 'application/json',
        ),
      );
    }
    await _waitUntil(() => repository.value.novels.single.chapters.length == 2);

    final first = await repository.loadOffline(offlineChapterUri('public:71'));
    final second = await repository.loadOffline(first.navigation.nextApi);

    expect(second.id, 72);
    expect(first.navigation.previousApi, isEmpty);
    expect(second.navigation.nextApi, isEmpty);
  });

  test(
    'transient auth restoration preserves the last verified VIP access',
    () async {
      const membership = DownloadMembershipSnapshot(
        userId: 7,
        active: true,
        tier: DownloadMembershipTier.vip2,
        verifiedAtUtcMs: 1000,
        expiresAtUtcMs: null,
      );
      await store.saveMembership(membership);

      await repository.refreshMembership(const AuthSessionState.restoring());

      final storedMembership = (await store.snapshot()).membership;
      expect(storedMembership.active, isTrue);
      expect(storedMembership.tier, DownloadMembershipTier.vip2);
      expect(storedMembership.verifiedAtUtcMs, 1000);
    },
  );
}

class _FakeTransfer implements DownloadTransfer {
  final controller = StreamController<DownloadTransferUpdate>.broadcast();
  final requests = <DownloadTransferRequest>[];
  final pausedIds = <String>[];
  final resumedIds = <String>[];
  final canceledIds = <String>[];
  Object? enqueueError;

  void emit(DownloadTransferUpdate update) => controller.add(update);
  Future<void> close() => controller.close();

  @override
  Stream<DownloadTransferUpdate> get updates => controller.stream;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> enqueue(DownloadTransferRequest request) async {
    if (enqueueError case final error?) throw error;
    requests.add(request);
    return true;
  }

  @override
  Future<bool> cancel(String transferId) async {
    canceledIds.add(transferId);
    return true;
  }

  @override
  Future<bool> pause(String transferId) async {
    pausedIds.add(transferId);
    return true;
  }

  @override
  Future<bool> resume(String transferId) async {
    resumedIds.add(transferId);
    return true;
  }

  @override
  void dispose() {}
}

class _FakeScheduler implements DownloadResumeScheduler {
  @override
  Future<void> scheduleNextMidnight(DateTime now) async {}
}

class _MemoryKeyStore implements DownloadKeyStore {
  @override
  Future<SecretKey> readOrCreate() async => SecretKey(List<int>.filled(32, 7));
}

class _MemorySessionStore implements AuthSessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<PrivateSessionSnapshot?> read() async => null;

  @override
  Future<void> write(PrivateSessionSnapshot session) async {}
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for repository state.');
}

String _serverResponse(ReaderChapterContent chapter) {
  return jsonEncode({
    'schema': 3,
    'generated': 1784574132,
    'data': {
      'id': chapter.id,
      'novel_id': chapter.novelId,
      'label': chapter.label,
      'title': chapter.title,
      'display_title': chapter.displayTitle,
      'position': chapter.position,
      'total': chapter.total,
      'content_html': chapter.contentHtml,
      'navigation': {
        'previous_api': chapter.navigation.previousApi,
        'next_api': chapter.navigation.nextApi,
        'previous_id': chapter.navigation.previousId,
        'next_id': chapter.navigation.nextId,
      },
    },
  });
}

const _chapterContent = ReaderChapterContent(
  id: 71,
  novelId: 7,
  label: 'الفصل 71',
  title: '',
  displayTitle: 'الفصل 71',
  position: 71,
  total: 100,
  contentHtml: '<p>المحتوى</p>',
  navigation: ReaderChapterNavigation(
    previousApi: '',
    nextApi: '',
    previousId: 0,
    nextId: 0,
  ),
);

ReaderChapterContent _contentFor(int id) => ReaderChapterContent(
  id: id,
  novelId: 7,
  label: 'الفصل $id',
  title: '',
  displayTitle: 'الفصل $id',
  position: id,
  total: 100,
  contentHtml: '<p>المحتوى $id</p>',
  navigation: const ReaderChapterNavigation(
    previousApi: '/online/previous',
    nextApi: '/online/next',
    previousId: 70,
    nextId: 73,
  ),
);
