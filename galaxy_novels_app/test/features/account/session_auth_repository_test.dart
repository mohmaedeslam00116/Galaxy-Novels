import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/account/data/session_auth_repository.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';

void main() {
  test('restores a guest session', () async {
    final repository = _repositoryFor(
      const PrivateRawResponse(statusCode: 200, body: '{"logged_in":false}'),
    );
    addTearDown(repository.dispose);

    await repository.restoreSession();

    expect(repository.value.status, AuthSessionStatus.guest);
    expect(repository.value.user, isNull);
  });

  test('restores the authenticated user and server-owned XP', () async {
    final repository = _repositoryFor(
      const PrivateRawResponse(
        statusCode: 200,
        body: '''
          {
            "logged_in": true,
            "nonce": "new-nonce",
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
      ),
    );
    addTearDown(repository.dispose);

    await repository.restoreSession();

    expect(repository.value.status, AuthSessionStatus.authenticated);
    expect(repository.value.user?.displayName, 'قارئ المجرة');
    expect(repository.value.user?.vip.active, isTrue);
    expect(repository.value.user?.xp.total, 320);
    expect(repository.value.user?.xp.rank.display, 'مستكشف');
  });

  test('maps network failures to a retryable state', () async {
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async {
        throw const PrivateApiException(
          code: 'network_unavailable',
          message: 'offline',
        );
      },
    );
    final repository = SessionAuthRepository(client: client);
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
    final repository = SessionAuthRepository(client: client);
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

SessionAuthRepository _repositoryFor(PrivateRawResponse response) {
  final client = PrivateApiClient(
    config: const AppConfig(siteBaseUrl: 'https://example.com/'),
    requestSender: (request) async => response,
  );
  return SessionAuthRepository(client: client);
}
