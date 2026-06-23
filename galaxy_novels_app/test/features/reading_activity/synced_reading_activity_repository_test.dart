import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/reading_activity/data/reading_activity_remote_service.dart';
import 'package:galaxy_novels_app/features/reading_activity/data/reading_activity_store.dart';
import 'package:galaxy_novels_app/features/reading_activity/data/synced_reading_activity_repository.dart';
import 'package:galaxy_novels_app/features/reading_activity/domain/reading_activity_event.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  test('guest chapter sessions are not created', () {
    final harness = _Harness(authState: const AuthSessionState.guest());
    addTearDown(harness.dispose);

    final session = harness.repository.startChapter(
      novelId: 42,
      chapterId: 501,
    );

    expect(session, isNull);
  });

  test('authenticated chapter checkpoint is persisted for its owner', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    final session = harness.repository.startChapter(
      novelId: 42,
      chapterId: 501,
    );
    addTearDown(session!.finish);

    session.recordInteraction(35);
    await session.checkpoint();

    final queued = await harness.store.read(7);
    expect(queued, hasLength(1));
    expect(queued.single.ownerUserId, 7);
    expect(queued.single.chapterId, 501);
    expect(queued.single.progress, 35);
  });

  test('chapter session stays bound to the account that started it', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    final session = harness.repository.startChapter(
      novelId: 42,
      chapterId: 501,
    );
    addTearDown(session!.finish);
    harness.auth.value = const AuthSessionState.authenticated(_secondUser);

    session.recordInteraction(40);
    await session.checkpoint();

    expect(await harness.store.read(7), hasLength(1));
    expect(await harness.store.read(8), isEmpty);
  });

  test('successful sync removes only the sent fifty events', () async {
    final harness = _Harness(events: List.generate(55, _eventAt));
    addTearDown(harness.dispose);

    await harness.repository.syncPending();

    expect(harness.server.batchSizes, [50]);
    expect(await harness.store.read(7), hasLength(5));
  });

  test('network failure keeps the complete batch for retry', () async {
    final harness = _Harness(events: [_eventAt(1)], offline: true);
    addTearDown(harness.dispose);

    await harness.repository.syncPending();

    expect(await harness.store.read(7), hasLength(1));
  });

  test('unauthorized sync keeps the queue and restores the session', () async {
    final harness = _Harness(events: [_eventAt(1)], unauthorized: true);
    addTearDown(harness.dispose);

    await harness.repository.syncPending();

    expect(await harness.store.read(7), hasLength(1));
    expect(harness.auth.restoreCalls, 1);
  });

  test('account switch never uploads the previous account queue', () async {
    final harness = _Harness(
      eventsByUser: {
        7: [_eventAt(7)],
        8: [_eventAt(8, ownerUserId: 8)],
      },
    );
    addTearDown(harness.dispose);
    harness.auth.value = const AuthSessionState.authenticated(_secondUser);

    await harness.repository.syncPending();

    expect(harness.server.chapterIds, [8]);
    expect(await harness.store.read(7), hasLength(1));
    expect(await harness.store.read(8), isEmpty);
  });
}

class _Harness {
  _Harness({
    AuthSessionState authState = const AuthSessionState.authenticated(
      _firstUser,
    ),
    List<ReadingActivityEvent> events = const [],
    Map<int, List<ReadingActivityEvent>> eventsByUser = const {},
    bool offline = false,
    bool unauthorized = false,
  }) : auth = _CountingAuthRepository(initialState: authState),
       store = _MemoryReadingActivityStore(
         eventsByUser.isEmpty ? {7: events} : eventsByUser,
       ) {
    server.offline = offline;
    server.unauthorized = unauthorized;
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: server.send,
    )..updateNonce('test-nonce');
    repository = SyncedReadingActivityRepository(
      store: store,
      remoteService: ReadingActivityRemoteService(client: client),
      authRepository: auth,
      syncDelay: const Duration(days: 1),
    );
  }

  final _CountingAuthRepository auth;
  final _MemoryReadingActivityStore store;
  final _FakeReadingActivityServer server = _FakeReadingActivityServer();
  late final SyncedReadingActivityRepository repository;

  void dispose() {
    repository.dispose();
    auth.dispose();
  }
}

class _MemoryReadingActivityStore implements ReadingActivityStore {
  _MemoryReadingActivityStore([
    Map<int, List<ReadingActivityEvent>> initial = const {},
  ]) : queues = {
         for (final entry in initial.entries) entry.key: [...entry.value],
       };

  final Map<int, List<ReadingActivityEvent>> queues;

  @override
  Future<List<ReadingActivityEvent>> read(int userId) async {
    return List.unmodifiable(queues[userId] ?? const []);
  }

  @override
  Future<void> write(int userId, List<ReadingActivityEvent> events) async {
    queues[userId] = [...events];
  }
}

class _FakeReadingActivityServer {
  bool offline = false;
  bool unauthorized = false;
  final List<int> batchSizes = [];
  final List<int> chapterIds = [];

  Future<PrivateRawResponse> send(PrivateRawRequest request) async {
    if (offline) {
      throw const PrivateApiException(
        code: 'network_unavailable',
        message: 'offline',
      );
    }
    if (unauthorized) {
      return const PrivateRawResponse(
        statusCode: 401,
        body: '{"code":"wor_reader_app_login_required"}',
      );
    }
    final body = jsonDecode(request.body!) as Map<String, dynamic>;
    final items = (body['items'] as List).cast<Map<String, dynamic>>();
    batchSizes.add(items.length);
    chapterIds.addAll(items.map((item) => item['object_id'] as int));
    return PrivateRawResponse(
      statusCode: 200,
      body: jsonEncode({
        'success': true,
        'accepted': items.length,
        'duplicates': 0,
      }),
    );
  }
}

class _CountingAuthRepository extends FakeAuthRepository {
  _CountingAuthRepository({required super.initialState});

  int restoreCalls = 0;

  @override
  Future<void> restoreSession() async {
    restoreCalls++;
    await super.restoreSession();
  }
}

ReadingActivityEvent _eventAt(int index, {int ownerUserId = 7}) {
  return ReadingActivityEvent(
    ownerUserId: ownerUserId,
    eventId: 'event-$ownerUserId-$index',
    novelId: 42,
    chapterId: index,
    activeSeconds: 10,
    openSeconds: 12,
    progress: 20,
    completed: false,
    views: 0,
    readAt: DateTime.utc(2026, 6, 23),
  );
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
