import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/account/data/session_auth_repository.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';

import '../../helpers/fake_auth_session_store.dart';

void main() {
  test('restores a guest and clears an obsolete saved session', () async {
    final sessionStore = FakeAuthSessionStore()
      ..session = const PrivateSessionSnapshot(
        nonce: 'old-nonce',
        cookieHeader: 'wordpress_logged_in_test=old-cookie',
      );
    final harness = _AuthHarness(
      responses: [
        const PrivateRawResponse(statusCode: 200, body: '{"logged_in":false}'),
      ],
      sessionStore: sessionStore,
    );
    addTearDown(harness.repository.dispose);

    await harness.repository.restoreSession();

    expect(harness.repository.value.status, AuthSessionStatus.guest);
    expect(sessionStore.session, isNull);
    expect(sessionStore.clearCount, 1);
  });

  test('restores a saved account and refreshes its persisted nonce', () async {
    final sessionStore = FakeAuthSessionStore()
      ..session = const PrivateSessionSnapshot(
        nonce: 'old-nonce',
        cookieHeader: 'wordpress_logged_in_test=saved-cookie',
      );
    final harness = _AuthHarness(
      responses: [_authenticatedResponse(nonce: 'fresh-nonce')],
      sessionStore: sessionStore,
    );
    addTearDown(harness.repository.dispose);

    await harness.repository.restoreSession();

    expect(harness.repository.value.status, AuthSessionStatus.authenticated);
    expect(harness.repository.value.user?.displayName, 'قارئ المجرة');
    expect(harness.requests.single.headers['Cookie'], contains('saved-cookie'));
    expect(sessionStore.session?.nonce, 'fresh-nonce');
    expect(sessionStore.writeCount, 1);
  });

  test(
    'login persists cookies only when remember session is enabled',
    () async {
      final rememberedStore = FakeAuthSessionStore();
      final remembered = _AuthHarness(
        responses: [_authenticatedResponse(setCookie: true)],
        sessionStore: rememberedStore,
      );
      addTearDown(remembered.repository.dispose);

      await remembered.repository.login(
        const LoginCredentials(
          username: 'reader',
          password: 'secret-value',
          rememberSession: true,
        ),
      );

      final body = jsonDecode(remembered.requests.single.body!);
      expect(body, {
        'username': 'reader',
        'password': 'secret-value',
        'remember': true,
      });
      expect(rememberedStore.writeCount, 1);
      expect(rememberedStore.session?.cookieHeader, contains('session-cookie'));

      final temporaryStore = FakeAuthSessionStore();
      final temporary = _AuthHarness(
        responses: [_authenticatedResponse(setCookie: true)],
        sessionStore: temporaryStore,
      );
      addTearDown(temporary.repository.dispose);
      await temporary.repository.login(
        const LoginCredentials(
          username: 'reader',
          password: 'secret-value',
          rememberSession: false,
        ),
      );

      expect(
        temporary.repository.value.status,
        AuthSessionStatus.authenticated,
      );
      expect(temporaryStore.writeCount, 0);
      expect(temporaryStore.session, isNull);
    },
  );

  test(
    'invalid credentials return to the login form with a safe error',
    () async {
      final harness = _AuthHarness(
        responses: [
          const PrivateRawResponse(
            statusCode: 401,
            body: '{"message":"raw server message"}',
          ),
        ],
      );
      addTearDown(harness.repository.dispose);

      await harness.repository.login(
        const LoginCredentials(
          username: 'reader',
          password: 'wrong',
          rememberSession: true,
        ),
      );

      expect(harness.repository.value.status, AuthSessionStatus.guest);
      expect(harness.repository.value.errorMessage, contains('غير صحيحة'));
      expect(harness.repository.value.errorMessage, isNot(contains('raw')));
    },
  );

  test('logout refreshes an expired nonce once before retrying', () async {
    final sessionStore = FakeAuthSessionStore();
    final harness = _AuthHarness(
      responses: [
        _authenticatedResponse(setCookie: true, nonce: 'old-nonce'),
        const PrivateRawResponse(
          statusCode: 403,
          body: '''
            {"code":"wor_reader_app_bad_nonce","message":"expired"}
          ''',
        ),
        _authenticatedResponse(nonce: 'fresh-nonce'),
        const PrivateRawResponse(statusCode: 200, body: '{"logged_in":false}'),
      ],
      sessionStore: sessionStore,
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: true,
      ),
    );

    await harness.repository.logout();

    expect(harness.repository.value.status, AuthSessionStatus.guest);
    expect(harness.requests, hasLength(4));
    expect(harness.requests[1].headers['X-WP-Nonce'], 'old-nonce');
    expect(harness.requests[2].uri.path, endsWith('/session'));
    expect(harness.requests[3].headers['X-WP-Nonce'], 'fresh-nonce');
    expect(sessionStore.session, isNull);
  });

  test('logout treats a server 401 as an expired local session', () async {
    final sessionStore = FakeAuthSessionStore();
    final harness = _AuthHarness(
      responses: [
        _authenticatedResponse(setCookie: true),
        const PrivateRawResponse(
          statusCode: 401,
          body: '''{"code":"wor_reader_app_login_required"}''',
        ),
      ],
      sessionStore: sessionStore,
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: true,
      ),
    );

    await harness.repository.logout();

    expect(harness.repository.value.status, AuthSessionStatus.guest);
    expect(sessionStore.session, isNull);
  });

  test('maps restore network failures to a retryable state', () async {
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async {
        throw const PrivateApiException(
          code: 'network_unavailable',
          message: 'offline',
        );
      },
    );
    final repository = SessionAuthRepository(
      client: client,
      sessionStore: FakeAuthSessionStore(),
    );
    addTearDown(repository.dispose);

    await repository.restoreSession();

    expect(repository.value.status, AuthSessionStatus.failure);
    expect(repository.value.errorMessage, contains('اتصال'));
  });

  test('deduplicates concurrent session restoration', () async {
    final response = Completer<PrivateRawResponse>();
    var requestCount = 0;
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) {
        requestCount += 1;
        return response.future;
      },
    );
    final repository = SessionAuthRepository(
      client: client,
      sessionStore: FakeAuthSessionStore(),
    );
    addTearDown(repository.dispose);

    final first = repository.restoreSession();
    final second = repository.restoreSession();
    response.complete(
      const PrivateRawResponse(statusCode: 200, body: '{"logged_in":false}'),
    );
    await Future.wait([first, second]);

    expect(requestCount, 1);
  });
}

class _AuthHarness {
  _AuthHarness({
    required List<PrivateRawResponse> responses,
    FakeAuthSessionStore? sessionStore,
  }) : responses = [...responses],
       sessionStore = sessionStore ?? FakeAuthSessionStore() {
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async {
        requests.add(request);
        return this.responses.removeAt(0);
      },
    );
    repository = SessionAuthRepository(
      client: client,
      sessionStore: this.sessionStore,
    );
  }

  final List<PrivateRawResponse> responses;
  final FakeAuthSessionStore sessionStore;
  final List<PrivateRawRequest> requests = [];
  late final SessionAuthRepository repository;
}

PrivateRawResponse _authenticatedResponse({
  String nonce = 'new-nonce',
  bool setCookie = false,
}) {
  return PrivateRawResponse(
    statusCode: 200,
    setCookieHeaders: setCookie
        ? const [
            'wordpress_logged_in_test=session-cookie; Path=/; Secure; HttpOnly',
          ]
        : const [],
    body:
        '''
      {
        "logged_in": true,
        "nonce": "$nonce",
        "user": {
          "id": 7,
          "display_name": "قارئ المجرة",
          "avatar": "https://example.com/avatar.jpg",
          "vip": {"active": true, "tier": "gold", "label": "ذهبي"},
          "xp": {
            "total": 320,
            "today": 20,
            "seconds_total": 900,
            "chapters_total": 14,
            "rank": {"level": 3, "display": "مستكشف"}
          }
        }
      }
    ''',
  );
}
