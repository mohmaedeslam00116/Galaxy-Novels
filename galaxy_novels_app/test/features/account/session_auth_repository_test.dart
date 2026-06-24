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
    'refreshes an authenticated profile without publishing restoring',
    () async {
      final harness = _AuthHarness(
        responses: [
          _authenticatedResponse(nonce: 'profile-nonce'),
          _profileResponse(totalXp: 1840, todayXp: 35),
        ],
      );
      addTearDown(harness.repository.dispose);
      await harness.repository.login(
        const LoginCredentials(
          username: 'reader',
          password: 'secret',
          rememberSession: false,
        ),
      );
      final publishedStatuses = <AuthSessionStatus>[];
      void recordStatus() {
        publishedStatuses.add(harness.repository.value.status);
      }

      harness.repository.addListener(recordStatus);
      addTearDown(() => harness.repository.removeListener(recordStatus));

      await harness.repository.refreshProfile();

      expect(harness.repository.value.user?.xp.total, 1840);
      expect(harness.repository.value.user?.xp.today, 35);
      expect(harness.requests, hasLength(2));
      expect(harness.requests[1].method, 'GET');
      expect(harness.requests[1].uri.path, endsWith('/me'));
      expect(harness.requests[1].headers['X-WP-Nonce'], 'profile-nonce');
      expect(publishedStatuses, isNot(contains(AuthSessionStatus.restoring)));
    },
  );

  test('deduplicates concurrent profile refreshes', () async {
    final profileResponse = Completer<PrivateRawResponse>();
    final harness = _AuthHarness(
      responses: const [],
      responseHandler: (request) {
        if (request.uri.path.endsWith('/auth/login')) {
          return Future.value(_authenticatedResponse(nonce: 'profile-nonce'));
        }
        if (request.uri.path.endsWith('/me')) {
          return profileResponse.future;
        }
        throw StateError('Unexpected request: ${request.uri.path}');
      },
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: false,
      ),
    );

    final firstRefresh = harness.repository.refreshProfile();
    final secondRefresh = harness.repository.refreshProfile();
    profileResponse.complete(_profileResponse(totalXp: 1840, todayXp: 35));
    await Future.wait([firstRefresh, secondRefresh]);

    expect(
      harness.requests.where((request) => request.uri.path.endsWith('/me')),
      hasLength(1),
    );
  });

  test('coalesces profile refreshes during the cooldown', () async {
    final harness = _AuthHarness(
      responses: [
        _authenticatedResponse(nonce: 'profile-nonce'),
        _profileResponse(totalXp: 1840, todayXp: 35),
        _profileResponse(totalXp: 1900, todayXp: 40),
      ],
      profileRefreshCooldown: const Duration(milliseconds: 30),
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: false,
      ),
    );
    await harness.repository.refreshProfile();

    await Future.wait([
      harness.repository.refreshProfile(),
      harness.repository.refreshProfile(),
      harness.repository.refreshProfile(),
    ]);

    expect(_profileRequestCount(harness), 1);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(_profileRequestCount(harness), 2);
  });

  test('immediate refresh cancels the expired deferred timer', () async {
    late _ControlledTimer deferredTimer;
    var profileRequests = 0;
    final harness = _AuthHarness(
      responses: const [],
      responseHandler: (request) async {
        if (request.uri.path.endsWith('/auth/login')) {
          return _authenticatedResponse(nonce: 'profile-nonce');
        }
        if (request.uri.path.endsWith('/me')) {
          profileRequests += 1;
          return _profileResponse(totalXp: 1800 + profileRequests, todayXp: 35);
        }
        throw StateError('Unexpected request: ${request.uri.path}');
      },
      profileRefreshCooldown: const Duration(milliseconds: 20),
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: false,
      ),
    );
    await harness.repository.refreshProfile();
    await runZoned(
      harness.repository.refreshProfile,
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, duration, callback) {
          deferredTimer = _ControlledTimer(callback);
          return deferredTimer;
        },
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 40));
    await harness.repository.refreshProfile();
    deferredTimer.fire();
    await Future<void>.delayed(Duration.zero);

    expect(deferredTimer.isActive, isFalse);
    expect(_profileRequestCount(harness), 2);
  });

  test('same-user relogin cancels a deferred profile refresh', () async {
    var profileRequests = 0;
    final harness = _AuthHarness(
      responses: const [],
      responseHandler: (request) async {
        if (request.uri.path.endsWith('/auth/login')) {
          return _authenticatedResponse(nonce: 'profile-nonce');
        }
        if (request.uri.path.endsWith('/auth/logout')) {
          return const PrivateRawResponse(
            statusCode: 200,
            body: '{"logged_in":false}',
          );
        }
        if (request.uri.path.endsWith('/me')) {
          profileRequests += 1;
          return _profileResponse(totalXp: 1800 + profileRequests, todayXp: 35);
        }
        throw StateError('Unexpected request: ${request.uri.path}');
      },
      profileRefreshCooldown: const Duration(milliseconds: 100),
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: false,
      ),
    );
    await harness.repository.refreshProfile();
    await harness.repository.refreshProfile();

    await harness.repository.logout();
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'new-secret',
        rememberSession: false,
      ),
    );
    await harness.repository.refreshProfile();

    expect(_profileRequestCount(harness), 2);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    expect(_profileRequestCount(harness), 2);
  });

  test('dispose cancels a deferred profile refresh', () async {
    Timer? deferredTimer;
    var repositoryDisposed = false;
    late bool timerWasActiveAfterDispose;
    final harness = _AuthHarness(
      responses: [
        _authenticatedResponse(nonce: 'profile-nonce'),
        _profileResponse(totalXp: 1840, todayXp: 35),
      ],
      profileRefreshCooldown: const Duration(seconds: 1),
    );

    try {
      await runZoned(
        () async {
          await harness.repository.login(
            const LoginCredentials(
              username: 'reader',
              password: 'secret',
              rememberSession: false,
            ),
          );
          await harness.repository.refreshProfile();
          await harness.repository.refreshProfile();
        },
        zoneSpecification: ZoneSpecification(
          createTimer: (self, parent, zone, duration, callback) {
            final timer = parent.createTimer(zone, duration, callback);
            deferredTimer = timer;
            return timer;
          },
        ),
      );

      harness.repository.dispose();
      repositoryDisposed = true;
      timerWasActiveAfterDispose = deferredTimer!.isActive;
    } finally {
      deferredTimer?.cancel();
      if (!repositoryDisposed) {
        harness.repository.dispose();
      }
    }

    expect(timerWasActiveAfterDispose, isFalse);
    expect(_profileRequestCount(harness), 1);
  });

  test('new session refresh remains in flight after old completion', () async {
    final oldProfileResponse = Completer<PrivateRawResponse>();
    final newProfileResponse = Completer<PrivateRawResponse>();
    var profileRequests = 0;
    final harness = _AuthHarness(
      responses: const [],
      responseHandler: (request) async {
        if (request.uri.path.endsWith('/auth/login')) {
          return _authenticatedResponse(nonce: 'profile-nonce');
        }
        if (request.uri.path.endsWith('/auth/logout')) {
          return const PrivateRawResponse(
            statusCode: 200,
            body: '{"logged_in":false}',
          );
        }
        if (request.uri.path.endsWith('/me')) {
          profileRequests += 1;
          return profileRequests == 1
              ? oldProfileResponse.future
              : newProfileResponse.future;
        }
        throw StateError('Unexpected request: ${request.uri.path}');
      },
      profileRefreshCooldown: Duration.zero,
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: false,
      ),
    );

    final oldRefresh = harness.repository.refreshProfile();
    await harness.repository.logout();
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'new-secret',
        rememberSession: false,
      ),
    );
    final newRefresh = harness.repository.refreshProfile();
    final requestCountAfterNewRefresh = _profileRequestCount(harness);

    oldProfileResponse.complete(_profileResponse(totalXp: 9999, todayXp: 999));
    await oldRefresh;
    final sharedNewRefresh = harness.repository.refreshProfile();
    final requestCountAfterOldCompletion = _profileRequestCount(harness);

    newProfileResponse.complete(_profileResponse(totalXp: 1900, todayXp: 40));
    await Future.wait([newRefresh, sharedNewRefresh]);

    expect(requestCountAfterNewRefresh, 2);
    expect(requestCountAfterOldCompletion, 2);
    expect(harness.repository.value.user?.xp.total, 1900);
  });

  test('restore cancels a deferred profile refresh', () async {
    late _ControlledTimer deferredTimer;
    var profileRequests = 0;
    final harness = _AuthHarness(
      responses: const [],
      responseHandler: (request) async {
        if (request.uri.path.endsWith('/auth/login')) {
          return _authenticatedResponse(nonce: 'login-nonce');
        }
        if (request.uri.path.endsWith('/session')) {
          return _authenticatedResponse(nonce: 'restored-nonce');
        }
        if (request.uri.path.endsWith('/me')) {
          profileRequests += 1;
          return _profileResponse(totalXp: 1800 + profileRequests, todayXp: 35);
        }
        throw StateError('Unexpected request: ${request.uri.path}');
      },
      profileRefreshCooldown: const Duration(seconds: 1),
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: false,
      ),
    );
    await harness.repository.refreshProfile();
    await runZoned(
      harness.repository.refreshProfile,
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, duration, callback) {
          deferredTimer = _ControlledTimer(callback);
          return deferredTimer;
        },
      ),
    );

    expect(deferredTimer.isActive, isTrue);

    await harness.repository.restoreSession();
    final oldTimerWasActiveAfterRestore = deferredTimer.isActive;
    await harness.repository.refreshProfile();

    expect(oldTimerWasActiveAfterRestore, isFalse);
    expect(_profileRequestCount(harness), 2);
    deferredTimer.fire();
    await Future<void>.delayed(Duration.zero);
    expect(_profileRequestCount(harness), 2);
  });

  test('profile refresh retries with a fresh session nonce', () async {
    final harness = _AuthHarness(
      responses: [
        _authenticatedResponse(nonce: 'old-nonce'),
        const PrivateRawResponse(
          statusCode: 403,
          body: '{"code":"wor_reader_app_bad_nonce"}',
        ),
        _authenticatedResponse(nonce: 'fresh-nonce'),
        _profileResponse(totalXp: 1840, todayXp: 35),
      ],
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: false,
      ),
    );

    await harness.repository.refreshProfile();

    expect(harness.requests, hasLength(4));
    expect(harness.requests[1].uri.path, endsWith('/me'));
    expect(harness.requests[1].headers['X-WP-Nonce'], 'old-nonce');
    expect(harness.requests[2].uri.path, endsWith('/session'));
    expect(harness.requests[3].uri.path, endsWith('/me'));
    expect(harness.requests[3].headers['X-WP-Nonce'], 'fresh-nonce');
    expect(harness.repository.value.user?.xp.total, 1840);
    expect(harness.repository.value.user?.xp.today, 35);
  });

  test(
    'stale profile refresh success cannot overwrite a same-user relogin',
    () async {
      final staleProfile = Completer<PrivateRawResponse>();
      var loginRequests = 0;
      final harness = _AuthHarness(
        responses: const [],
        responseHandler: (request) async {
          if (request.uri.path.endsWith('/auth/login')) {
            loginRequests += 1;
            return _authenticatedResponse(
              nonce: loginRequests == 1 ? 'old-nonce' : 'new-nonce',
            );
          }
          if (request.uri.path.endsWith('/me')) {
            return staleProfile.future;
          }
          if (request.uri.path.endsWith('/auth/logout')) {
            return const PrivateRawResponse(
              statusCode: 200,
              body: '{"logged_in":false}',
            );
          }
          throw StateError('Unexpected request: ${request.uri.path}');
        },
      );
      addTearDown(harness.repository.dispose);
      await harness.repository.login(
        const LoginCredentials(
          username: 'reader',
          password: 'secret',
          rememberSession: false,
        ),
      );

      final staleRefresh = harness.repository.refreshProfile();
      expect(harness.requests.last.uri.path, endsWith('/me'));
      await harness.repository.logout();
      await harness.repository.login(
        const LoginCredentials(
          username: 'reader',
          password: 'new-secret',
          rememberSession: false,
        ),
      );
      final reloggedUser = harness.repository.value.user;

      staleProfile.complete(_profileResponse(totalXp: 9999, todayXp: 999));
      await staleRefresh;

      expect(harness.repository.value.status, AuthSessionStatus.authenticated);
      expect(harness.repository.value.user, same(reloggedUser));
      expect(harness.repository.value.user?.xp.total, 320);
    },
  );

  test(
    'stale profile refresh 401 cannot restore a same-user relogin',
    () async {
      final staleProfile = Completer<PrivateRawResponse>();
      var loginRequests = 0;
      final harness = _AuthHarness(
        responses: const [],
        responseHandler: (request) async {
          if (request.uri.path.endsWith('/auth/login')) {
            loginRequests += 1;
            return _authenticatedResponse(
              nonce: loginRequests == 1 ? 'old-nonce' : 'new-nonce',
            );
          }
          if (request.uri.path.endsWith('/me')) {
            return staleProfile.future;
          }
          if (request.uri.path.endsWith('/auth/logout')) {
            return const PrivateRawResponse(
              statusCode: 200,
              body: '{"logged_in":false}',
            );
          }
          if (request.uri.path.endsWith('/session')) {
            return const PrivateRawResponse(
              statusCode: 200,
              body: '{"logged_in":false}',
            );
          }
          throw StateError('Unexpected request: ${request.uri.path}');
        },
      );
      addTearDown(harness.repository.dispose);
      await harness.repository.login(
        const LoginCredentials(
          username: 'reader',
          password: 'secret',
          rememberSession: false,
        ),
      );

      final staleRefresh = harness.repository.refreshProfile();
      expect(harness.requests.last.uri.path, endsWith('/me'));
      await harness.repository.logout();
      await harness.repository.login(
        const LoginCredentials(
          username: 'reader',
          password: 'new-secret',
          rememberSession: false,
        ),
      );
      final reloggedUser = harness.repository.value.user;

      staleProfile.complete(
        const PrivateRawResponse(
          statusCode: 401,
          body: '{"code":"wor_reader_app_login_required"}',
        ),
      );
      await staleRefresh;

      expect(harness.repository.value.status, AuthSessionStatus.authenticated);
      expect(harness.repository.value.user, same(reloggedUser));
      expect(
        harness.requests.where(
          (request) => request.uri.path.endsWith('/session'),
        ),
        isEmpty,
      );
    },
  );

  test('network failure retains the authenticated profile', () async {
    final harness = _AuthHarness(
      responses: const [],
      responseHandler: (request) async {
        if (request.uri.path.endsWith('/auth/login')) {
          return _authenticatedResponse(nonce: 'profile-nonce');
        }
        throw const PrivateApiException(
          code: 'network_unavailable',
          message: 'offline',
        );
      },
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: false,
      ),
    );
    final originalUser = harness.repository.value.user;

    await expectLater(harness.repository.refreshProfile(), completes);

    expect(harness.repository.value.status, AuthSessionStatus.authenticated);
    expect(harness.repository.value.user, same(originalUser));
  });

  test('server failure retains the authenticated profile', () async {
    final harness = _AuthHarness(
      responses: [
        _authenticatedResponse(nonce: 'profile-nonce'),
        const PrivateRawResponse(
          statusCode: 503,
          body: '{"code":"service_unavailable"}',
        ),
      ],
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: false,
      ),
    );
    final originalUser = harness.repository.value.user;

    await expectLater(harness.repository.refreshProfile(), completes);

    expect(harness.repository.value.status, AuthSessionStatus.authenticated);
    expect(harness.repository.value.user, same(originalUser));
  });

  for (final scenario in {
    'invalid raw JSON': const PrivateRawResponse(
      statusCode: 200,
      body: '{not-json',
    ),
    'rate-limited': const PrivateRawResponse(
      statusCode: 429,
      body: '{"code":"rate_limited"}',
    ),
  }.entries) {
    test(
      '${scenario.key} background profile refresh retains the user',
      () async {
        final harness = _AuthHarness(
          responses: [
            _authenticatedResponse(nonce: 'profile-nonce'),
            scenario.value,
          ],
        );
        addTearDown(harness.repository.dispose);
        await harness.repository.login(
          const LoginCredentials(
            username: 'reader',
            password: 'secret',
            rememberSession: false,
          ),
        );
        final originalUser = harness.repository.value.user;

        await expectLater(harness.repository.refreshProfile(), completes);

        expect(
          harness.repository.value.status,
          AuthSessionStatus.authenticated,
        );
        expect(harness.repository.value.user, same(originalUser));
      },
    );
  }

  test('unsafe endpoint background profile refresh propagates', () async {
    final harness = _AuthHarness(
      responses: const [],
      responseHandler: (request) async {
        if (request.uri.path.endsWith('/auth/login')) {
          return _authenticatedResponse(nonce: 'profile-nonce');
        }
        throw const PrivateApiException(
          code: 'unsafe_endpoint',
          message: 'unsafe',
        );
      },
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: false,
      ),
    );

    await expectLater(
      harness.repository.refreshProfile(),
      throwsA(
        isA<PrivateApiException>().having(
          (error) => error.code,
          'code',
          'unsafe_endpoint',
        ),
      ),
    );
  });

  for (final scenario in {
    'malformed': const PrivateRawResponse(statusCode: 200, body: '{}'),
    'mismatched': _profileResponse(totalXp: 1840, todayXp: 35, userId: 8),
  }.entries) {
    test('${scenario.key} profile retains the authenticated user', () async {
      final harness = _AuthHarness(
        responses: [
          _authenticatedResponse(nonce: 'profile-nonce'),
          scenario.value,
        ],
      );
      addTearDown(harness.repository.dispose);
      await harness.repository.login(
        const LoginCredentials(
          username: 'reader',
          password: 'secret',
          rememberSession: false,
        ),
      );
      final originalUser = harness.repository.value.user;

      await expectLater(harness.repository.refreshProfile(), completes);

      expect(harness.repository.value.status, AuthSessionStatus.authenticated);
      expect(harness.repository.value.user, same(originalUser));
    });
  }

  test('unauthorized profile refresh restores the session to guest', () async {
    final harness = _AuthHarness(
      responses: [
        _authenticatedResponse(nonce: 'profile-nonce'),
        const PrivateRawResponse(
          statusCode: 401,
          body: '{"code":"wor_reader_app_login_required"}',
        ),
        const PrivateRawResponse(statusCode: 200, body: '{"logged_in":false}'),
      ],
    );
    addTearDown(harness.repository.dispose);
    await harness.repository.login(
      const LoginCredentials(
        username: 'reader',
        password: 'secret',
        rememberSession: false,
      ),
    );

    await harness.repository.refreshProfile();

    expect(harness.repository.value.status, AuthSessionStatus.guest);
    expect(harness.requests, hasLength(3));
    expect(harness.requests[1].uri.path, endsWith('/me'));
    expect(harness.requests[2].uri.path, endsWith('/session'));
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

class _ControlledTimer implements Timer {
  _ControlledTimer(this._callback);

  final void Function() _callback;
  bool _isActive = true;
  int _tick = 0;

  void fire() {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    _tick = 1;
    _callback();
  }

  @override
  void cancel() {
    _isActive = false;
  }

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _tick;
}

class _AuthHarness {
  _AuthHarness({
    required List<PrivateRawResponse> responses,
    FakeAuthSessionStore? sessionStore,
    PrivateRequestSender? responseHandler,
    Duration profileRefreshCooldown = const Duration(seconds: 60),
  }) : responses = [...responses],
       sessionStore = sessionStore ?? FakeAuthSessionStore() {
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async {
        requests.add(request);
        if (responseHandler != null) {
          return responseHandler(request);
        }
        return this.responses.removeAt(0);
      },
    );
    repository = SessionAuthRepository(
      client: client,
      sessionStore: this.sessionStore,
      profileRefreshCooldown: profileRefreshCooldown,
    );
  }

  final List<PrivateRawResponse> responses;
  final FakeAuthSessionStore sessionStore;
  final List<PrivateRawRequest> requests = [];
  late final SessionAuthRepository repository;
}

int _profileRequestCount(_AuthHarness harness) {
  return harness.requests
      .where((request) => request.uri.path.endsWith('/me'))
      .length;
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

PrivateRawResponse _profileResponse({
  required int totalXp,
  required int todayXp,
  int userId = 7,
}) {
  return PrivateRawResponse(
    statusCode: 200,
    body:
        '''
      {
        "user": {
          "id": $userId,
          "display_name": "قارئ المجرة",
          "avatar": "https://example.com/avatar.jpg",
          "vip": {"active": true, "tier": "gold", "label": "ذهبي"},
          "xp": {
            "total": $totalXp,
            "today": $todayXp,
            "seconds_total": 7200,
            "chapters_total": 42,
            "rank": {"level": 5, "display": "مستكشف"}
          }
        }
      }
    ''',
  );
}
