import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/history/data/account_reading_history_repository.dart';
import 'package:galaxy_novels_app/features/history/data/reading_history_remote_service.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  test('merges account history with newer local progress', () async {
    final local = _MemoryReadingHistoryRepository([
      _progress(
        novelId: 1,
        chapterId: 20,
        updatedAt: DateTime.utc(2026, 6, 23, 12),
        chapterPosition: 20,
        chaptersTotal: 100,
      ),
    ]);
    final harness = _HistoryHarness(
      localRepository: local,
      responseBody: _historyResponse(
        novelId: 1,
        chapterId: 19,
        readAt: '2026-06-23T11:00:00+00:00',
      ),
    );
    addTearDown(harness.dispose);

    final history = await harness.repository.load();

    expect(history, hasLength(1));
    expect(history.single.chapterId, 20);
    expect(history.single.completionPercent, 20);
  });

  test('falls back to local history when the account is offline', () async {
    final localProgress = _progress(
      novelId: 3,
      chapterId: 9,
      updatedAt: DateTime.utc(2026, 6, 23),
    );
    final harness = _HistoryHarness(
      localRepository: _MemoryReadingHistoryRepository([localProgress]),
      requestSender: (_) async => throw const PrivateApiException(
        code: 'network_unavailable',
        message: 'offline',
      ),
    );
    addTearDown(harness.dispose);

    final history = await harness.repository.load();

    expect(history, [localProgress]);
  });

  test('private history failure keeps the account session active', () async {
    final localProgress = _progress(
      novelId: 4,
      chapterId: 12,
      updatedAt: DateTime.utc(2026, 6, 23),
    );
    final authRepository = _TrackingAuthRepository(
      initialState: const AuthSessionState.authenticated(_firstUser),
    );
    final harness = _HistoryHarness(
      localRepository: _MemoryReadingHistoryRepository([localProgress]),
      auth: authRepository,
      requestSender: (_) async => const PrivateRawResponse(
        statusCode: 401,
        body: '{"code":"wor_reader_app_login_required"}',
      ),
    );
    addTearDown(harness.dispose);

    final history = await harness.repository.load();

    expect(history, [localProgress]);
    expect(authRepository.value.status, AuthSessionStatus.authenticated);
    expect(authRepository.restoreCalls, 0);
  });

  test('does not apply a late response from the previous account', () async {
    final firstResponse = Completer<PrivateRawResponse>();
    final firstRequestStarted = Completer<void>();
    var requestCount = 0;
    final harness = _HistoryHarness(
      localRepository: _MemoryReadingHistoryRepository(),
      requestSender: (_) {
        requestCount++;
        if (requestCount == 1) {
          firstRequestStarted.complete();
          return firstResponse.future;
        }
        return Future.value(
          PrivateRawResponse(
            statusCode: 200,
            body: _historyResponse(
              novelId: 22,
              chapterId: 220,
              readAt: '2026-06-23T13:00:00+00:00',
            ),
          ),
        );
      },
    );
    addTearDown(harness.dispose);

    final oldAccountLoad = harness.repository.load();
    await firstRequestStarted.future;
    harness.authRepository.value = const AuthSessionState.authenticated(
      _secondUser,
    );

    final newAccountHistory = await harness.repository.load().timeout(
      const Duration(seconds: 1),
    );
    firstResponse.complete(
      PrivateRawResponse(
        statusCode: 200,
        body: _historyResponse(
          novelId: 11,
          chapterId: 110,
          readAt: '2026-06-23T14:00:00+00:00',
        ),
      ),
    );
    await oldAccountLoad;
    final settledHistory = await harness.repository.load();

    expect(requestCount, 2);
    expect(newAccountHistory.single.novelId, 22);
    expect(settledHistory.single.novelId, 22);
  });

  test('keeps guest and account local histories isolated', () async {
    final guestProgress = _progress(
      novelId: 30,
      chapterId: 300,
      updatedAt: DateTime.utc(2026, 6, 23, 10),
    );
    final firstUserProgress = _progress(
      novelId: 31,
      chapterId: 310,
      updatedAt: DateTime.utc(2026, 6, 23, 11),
    );
    final secondUserProgress = _progress(
      novelId: 32,
      chapterId: 320,
      updatedAt: DateTime.utc(2026, 6, 23, 12),
    );
    final authRepository = FakeAuthRepository();
    final local = _MemoryReadingHistoryRepository.scoped({
      ReadingHistoryScope.guest: [guestProgress],
      ReadingHistoryScope.user(_firstUser.id): [firstUserProgress],
      ReadingHistoryScope.user(_secondUser.id): [secondUserProgress],
    });
    final harness = _HistoryHarness(
      localRepository: local,
      auth: authRepository,
    );
    addTearDown(harness.dispose);

    expect(await harness.repository.load(), [guestProgress]);

    authRepository.value = const AuthSessionState.authenticated(_firstUser);
    expect(await harness.repository.load(), [firstUserProgress]);

    authRepository.value = const AuthSessionState.authenticated(_secondUser);
    expect(await harness.repository.load(), [secondUserProgress]);
  });

  test(
    'does not expose user A local history after switching to user B',
    () async {
      final firstScope = ReadingHistoryScope.user(_firstUser.id);
      final secondScope = ReadingHistoryScope.user(_secondUser.id);
      final firstProgress = _progress(
        novelId: 41,
        chapterId: 410,
        updatedAt: DateTime.utc(2026, 6, 23, 11),
      );
      final secondProgress = _progress(
        novelId: 42,
        chapterId: 420,
        updatedAt: DateTime.utc(2026, 6, 23, 12),
      );
      final firstLoadGate = Completer<void>();
      final local =
          _MemoryReadingHistoryRepository.scoped({
              firstScope: [firstProgress],
              secondScope: [secondProgress],
            })
            ..loadStarted = Completer<ReadingHistoryScope>()
            ..loadGates[firstScope] = firstLoadGate;
      final harness = _HistoryHarness(localRepository: local);
      addTearDown(harness.dispose);

      final staleLoad = harness.repository.load();
      expect(await local.loadStarted!.future, firstScope);
      harness.authRepository.value = const AuthSessionState.authenticated(
        _secondUser,
      );

      final currentHistory = await harness.repository.load();
      firstLoadGate.complete();
      final staleHistory = await staleLoad;

      expect(currentHistory, [secondProgress]);
      expect(staleHistory, isEmpty);
    },
  );

  test(
    'record keeps the scope captured when the account changes mid-write',
    () async {
      final firstScope = ReadingHistoryScope.user(_firstUser.id);
      final secondScope = ReadingHistoryScope.user(_secondUser.id);
      final recordGate = Completer<void>();
      final local = _MemoryReadingHistoryRepository()
        ..recordStarted = Completer<ReadingHistoryScope>()
        ..recordGate = recordGate;
      final harness = _HistoryHarness(localRepository: local);
      addTearDown(harness.dispose);
      final progress = _progress(
        novelId: 50,
        chapterId: 500,
        updatedAt: DateTime.utc(2026, 6, 23, 13),
      );

      final record = harness.repository.record(progress);
      expect(await local.recordStarted!.future, firstScope);
      harness.authRepository.value = const AuthSessionState.authenticated(
        _secondUser,
      );
      recordGate.complete();
      await record;

      expect(local.itemsFor(firstScope), [progress]);
      expect(local.itemsFor(secondScope), isEmpty);
    },
  );
}

class _HistoryHarness {
  _HistoryHarness({
    required _MemoryReadingHistoryRepository localRepository,
    String responseBody = '{"items":[]}',
    PrivateRequestSender? requestSender,
    FakeAuthRepository? auth,
  }) : authRepository =
           auth ??
           FakeAuthRepository(
             initialState: const AuthSessionState.authenticated(_firstUser),
           ) {
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender:
          requestSender ??
          (_) async => PrivateRawResponse(statusCode: 200, body: responseBody),
    )..updateAccessToken('wra_test_token');
    repository = AccountReadingHistoryRepository(
      localRepository: localRepository,
      remoteService: ReadingHistoryRemoteService(client: client),
      authRepository: authRepository,
      remoteCacheDuration: const Duration(days: 1),
    );
  }

  final FakeAuthRepository authRepository;
  late final AccountReadingHistoryRepository repository;

  void dispose() {
    repository.dispose();
    authRepository.dispose();
  }
}

class _TrackingAuthRepository extends FakeAuthRepository {
  _TrackingAuthRepository({required super.initialState});

  int restoreCalls = 0;

  @override
  Future<void> restoreSession() async {
    restoreCalls++;
    await super.restoreSession();
  }
}

class _MemoryReadingHistoryRepository extends ChangeNotifier
    implements ScopedReadingHistoryRepository {
  _MemoryReadingHistoryRepository([List<ReadingProgress> items = const []])
    : _itemsByScope = {
        ReadingHistoryScope.user(_firstUser.id): [...items],
      };

  _MemoryReadingHistoryRepository.scoped(
    Map<ReadingHistoryScope, List<ReadingProgress>> itemsByScope,
  ) : _itemsByScope = {
        for (final entry in itemsByScope.entries) entry.key: [...entry.value],
      };

  final Map<ReadingHistoryScope, List<ReadingProgress>> _itemsByScope;
  final Map<ReadingHistoryScope, Completer<void>> loadGates = {};
  Completer<ReadingHistoryScope>? loadStarted;
  Completer<ReadingHistoryScope>? recordStarted;
  Completer<void>? recordGate;

  @override
  Future<List<ReadingProgress>> loadForScope(ReadingHistoryScope scope) async {
    final started = loadStarted;
    if (started != null && !started.isCompleted) {
      started.complete(scope);
    }
    final gate = loadGates[scope];
    if (gate != null) {
      await gate.future;
    }
    return List.unmodifiable(_itemsByScope[scope] ?? const []);
  }

  @override
  Future<void> recordForScope(
    ReadingHistoryScope scope,
    ReadingProgress progress,
  ) async {
    final started = recordStarted;
    if (started != null && !started.isCompleted) {
      started.complete(scope);
    }
    final gate = recordGate;
    if (gate != null) {
      await gate.future;
    }
    final items = _itemsByScope[scope] ?? const [];
    _itemsByScope[scope] = [
      progress,
      for (final item in items)
        if (item.novelId != progress.novelId) item,
    ];
    notifyListeners();
  }

  List<ReadingProgress> itemsFor(ReadingHistoryScope scope) {
    return List.unmodifiable(_itemsByScope[scope] ?? const []);
  }
}

ReadingProgress _progress({
  required int novelId,
  required int chapterId,
  required DateTime updatedAt,
  int chapterPosition = 0,
  int chaptersTotal = 0,
}) {
  return ReadingProgress(
    novelId: novelId,
    novelTitle: 'رواية $novelId',
    chapterId: chapterId,
    chapterTitle: 'الفصل $chapterId',
    contentApi: '/wp-json/wor-reader-app/v1/chapters/$chapterId',
    updatedAt: updatedAt,
    chapterPosition: chapterPosition,
    chaptersTotal: chaptersTotal,
  );
}

String _historyResponse({
  required int novelId,
  required int chapterId,
  required String readAt,
}) {
  return '''
    {"items":[{
      "novelId":$novelId,
      "title":"رواية $novelId",
      "lastReadAt":"$readAt",
      "lastChapter":{
        "chapterId":$chapterId,
        "label":"الفصل $chapterId",
        "readAt":"$readAt"
      }
    }]}
  ''';
}

const _firstUser = AuthUser(
  id: 7,
  displayName: 'القارئ الأول',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 1, display: ''),
  ),
);

const _secondUser = AuthUser(
  id: 8,
  displayName: 'القارئ الثاني',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 1, display: ''),
  ),
);
