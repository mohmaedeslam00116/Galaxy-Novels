import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/favorites/application/favorites_repository.dart';
import 'package:galaxy_novels_app/features/favorites/data/favorites_local_store.dart';
import 'package:galaxy_novels_app/features/favorites/data/favorites_remote_service.dart';
import 'package:galaxy_novels_app/features/favorites/data/synced_favorites_repository.dart';
import 'package:galaxy_novels_app/features/favorites/domain/favorite_item.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  test('loads the authenticated user favorites from the server', () async {
    final server = _FakeFavoritesServer()..favoriteIds.add(12);
    final harness = _FavoritesHarness(server: server);
    addTearDown(harness.dispose);

    await harness.repository.refresh();

    expect(harness.repository.value.status, FavoritesLoadStatus.ready);
    expect(harness.repository.value.items.single.id, 12);
    expect(
      harness.repository.value.items.single.manifestPath,
      favoriteManifestPath(12),
    );
    expect(harness.repository.value.pendingCount, 0);
  });

  test('batches more than fifty local changes before refreshing', () async {
    final server = _FakeFavoritesServer();
    final harness = _FavoritesHarness(server: server);
    addTearDown(harness.dispose);
    await harness.repository.refresh();

    for (var id = 1; id <= 55; id++) {
      await harness.repository.toggle(_favorite(id));
    }
    expect(harness.repository.value.pendingCount, 55);

    await harness.repository.syncPending();

    expect(server.syncBatchSizes, [50, 5]);
    expect(server.favoriteIds, hasLength(55));
    expect(harness.repository.value.pendingCount, 0);
    expect(harness.repository.value.items, hasLength(55));
  });

  test('rejects a new favorite after the server limit is reached', () async {
    final server = _FakeFavoritesServer()
      ..favoriteIds.addAll(
        List.generate(FavoritesState.maxFavorites, (index) => index + 1),
      );
    final harness = _FavoritesHarness(server: server);
    addTearDown(harness.dispose);
    await harness.repository.refresh();

    final toggleResult = await harness.repository.toggle(_favorite(301));

    expect(toggleResult, FavoriteToggleResult.limitReached);
    expect(harness.repository.value.items, hasLength(300));
    expect(harness.repository.value.pendingCount, 0);
  });

  test('keeps an offline toggle and uploads it on the next run', () async {
    final store = _FakeFavoritesLocalStore();
    final offlineServer = _FakeFavoritesServer()..offline = true;
    final offline = _FavoritesHarness(server: offlineServer, store: store);
    await offline.repository.load();
    await offline.repository.syncPending();

    final result = await offline.repository.toggle(_favorite(41));
    expect(result, FavoriteToggleResult.added);
    expect(offline.repository.value.pendingCount, 1);
    expect((await store.read(7)).pendingChanges.single.novelId, 41);
    offline.dispose();

    final onlineServer = _FakeFavoritesServer();
    final online = _FavoritesHarness(server: onlineServer, store: store);
    addTearDown(online.dispose);
    await online.repository.refresh();

    expect(onlineServer.favoriteIds, contains(41));
    expect(online.repository.value.contains(41), isTrue);
    expect(online.repository.value.pendingCount, 0);
  });

  test('private sync failure keeps the account session active', () async {
    final server = _FakeFavoritesServer()..unauthorized = true;
    final authRepository = _TrackingAuthRepository(
      initialState: const AuthSessionState.authenticated(_user),
    );
    final harness = _FavoritesHarness(server: server, auth: authRepository);
    addTearDown(harness.dispose);

    await harness.repository.refresh();

    expect(harness.repository.value.status, FavoritesLoadStatus.ready);
    expect(
      harness.authRepository.value.status,
      AuthSessionStatus.authenticated,
    );
    expect(authRepository.restoreCalls, 0);
  });

  test('sends a bearer token with private favorites sync', () async {
    final requests = <PrivateRawRequest>[];
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async {
        requests.add(request);
        return const PrivateRawResponse(
          statusCode: 200,
          body: '{"accepted":1}',
        );
      },
    )..updateAccessToken('wra_old_token');
    final service = FavoritesRemoteService(client: client);

    final accepted = await service.syncChanges([
      FavoriteChange(
        novelId: 9,
        action: FavoriteChangeAction.add,
        changedAt: DateTime.utc(2026, 6, 23),
      ),
    ]);

    expect(accepted, 1);
    expect(requests, hasLength(1));
    expect(requests.single.headers['Authorization'], 'Bearer wra_old_token');
    expect(requests.single.headers, isNot(contains('X-WP-Nonce')));
  });

  test('account switch during sync starts the new user refresh', () async {
    final firstResponse = Completer<PrivateRawResponse>();
    final secondRequestStarted = Completer<void>();
    var requestCount = 0;
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) {
        requestCount++;
        if (requestCount == 1) {
          return firstResponse.future;
        }
        secondRequestStarted.complete();
        return Future.value(
          const PrivateRawResponse(
            statusCode: 200,
            body: '''
              {"items":[{
                "id":88,
                "title":"مفضلة الحساب الجديد",
                "url":"/novel/88/",
                "cover":"",
                "added_at":"2026-06-23T12:00:00+00:00"
              }]}
            ''',
          ),
        );
      },
    )..updateAccessToken('wra_test_token');
    final authRepository = FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_user),
    );
    final repository = SyncedFavoritesRepository(
      remoteService: FavoritesRemoteService(client: client),
      localStore: _FakeFavoritesLocalStore(),
      authRepository: authRepository,
      syncDelay: const Duration(days: 1),
    );
    addTearDown(() {
      repository.dispose();
      authRepository.dispose();
    });

    await repository.load();
    await Future<void>.delayed(Duration.zero);
    authRepository.value = const AuthSessionState.authenticated(_secondUser);
    await Future<void>.delayed(Duration.zero);
    firstResponse.complete(
      const PrivateRawResponse(statusCode: 200, body: '{"items":[]}'),
    );

    await secondRequestStarted.future.timeout(const Duration(seconds: 1));
    await repository.syncPending();

    expect(repository.value.userId, 8);
    expect(repository.value.items.single.title, 'مفضلة الحساب الجديد');
    expect(requestCount, 2);
  });
}

class _FavoritesHarness {
  _FavoritesHarness({
    required _FakeFavoritesServer server,
    _FakeFavoritesLocalStore? store,
    FakeAuthRepository? auth,
  }) : store = store ?? _FakeFavoritesLocalStore(),
       authRepository =
           auth ??
           FakeAuthRepository(
             initialState: const AuthSessionState.authenticated(_user),
           ) {
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: server.send,
    )..updateAccessToken('wra_test_token');
    repository = SyncedFavoritesRepository(
      remoteService: FavoritesRemoteService(client: client),
      localStore: this.store,
      authRepository: authRepository,
      syncDelay: const Duration(days: 1),
    );
  }

  final _FakeFavoritesLocalStore store;
  final FakeAuthRepository authRepository;
  late final SyncedFavoritesRepository repository;

  void dispose() {
    repository.dispose();
    authRepository.dispose();
  }
}

class _FakeFavoritesServer {
  final Set<int> favoriteIds = {};
  final List<int> syncBatchSizes = [];
  bool offline = false;
  bool unauthorized = false;

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
    if (request.uri.path.endsWith('/me/favorites/sync')) {
      final body = jsonDecode(request.body!) as Map<String, dynamic>;
      final changes = (body['changes'] as List).cast<Map<String, dynamic>>();
      syncBatchSizes.add(changes.length);
      for (final change in changes) {
        final id = change['novel_id'] as int;
        if (change['action'] == 'add') {
          favoriteIds.add(id);
        } else {
          favoriteIds.remove(id);
        }
      }
      return PrivateRawResponse(
        statusCode: 200,
        body: jsonEncode({'accepted': changes.length}),
      );
    }

    final items = favoriteIds
        .map(
          (id) => {
            'id': id,
            'title': 'رواية $id',
            'url': '/novel/$id/',
            'cover': '/cover/$id.jpg',
            'added_at': '2026-06-23T12:00:00+00:00',
          },
        )
        .toList();
    return PrivateRawResponse(
      statusCode: 200,
      body: jsonEncode({'items': items}),
    );
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

class _FakeFavoritesLocalStore implements FavoritesLocalStore {
  final Map<int, FavoriteLocalSnapshot> snapshots = {};

  @override
  Future<FavoriteLocalSnapshot> read(int userId) async {
    return snapshots[userId] ?? FavoriteLocalSnapshot();
  }

  @override
  Future<void> write(int userId, FavoriteLocalSnapshot snapshot) async {
    snapshots[userId] = FavoriteLocalSnapshot(
      items: snapshot.items,
      pendingChanges: snapshot.pendingChanges,
    );
  }
}

FavoriteItem _favorite(int id) {
  return FavoriteItem(
    id: id,
    title: 'رواية $id',
    url: '/novel/$id/',
    cover: '/cover/$id.jpg',
    manifestPath: favoriteManifestPath(id),
    addedAt: DateTime.utc(2026, 6, 23),
  );
}

const _user = AuthUser(
  id: 7,
  displayName: 'قارئ المفضلة',
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
  displayName: 'قارئ آخر',
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
