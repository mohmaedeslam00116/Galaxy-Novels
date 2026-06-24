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
}

class _HistoryHarness {
  _HistoryHarness({
    required _MemoryReadingHistoryRepository localRepository,
    String responseBody = '{"items":[]}',
    PrivateRequestSender? requestSender,
  }) : authRepository = FakeAuthRepository(
         initialState: const AuthSessionState.authenticated(_firstUser),
       ) {
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender:
          requestSender ??
          (_) async => PrivateRawResponse(statusCode: 200, body: responseBody),
    )..updateNonce('test-nonce');
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

class _MemoryReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  _MemoryReadingHistoryRepository([List<ReadingProgress> items = const []])
    : _items = [...items];

  List<ReadingProgress> _items;

  @override
  Future<List<ReadingProgress>> load() async => List.unmodifiable(_items);

  @override
  Future<void> record(ReadingProgress progress) async {
    _items = [
      progress,
      for (final item in _items)
        if (item.novelId != progress.novelId) item,
    ];
    notifyListeners();
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
