import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';

void main() {
  test(
    'keeps session cookies and nonce inside authenticated requests',
    () async {
      final requests = <PrivateRawRequest>[];
      final responses = <PrivateRawResponse>[
        const PrivateRawResponse(
          statusCode: 200,
          body: '{"logged_in":true,"nonce":"fresh-nonce"}',
          setCookieHeaders: [
            'wordpress_logged_in_test=session-token; Path=/; Secure; HttpOnly',
          ],
        ),
        const PrivateRawResponse(statusCode: 200, body: '{"user":{}}'),
      ];
      final client = PrivateApiClient(
        config: const AppConfig(siteBaseUrl: 'https://example.com/'),
        requestSender: (request) async {
          requests.add(request);
          return responses.removeAt(0);
        },
      );

      await client.getPublic('session');
      await client.getAuthenticated('me');

      expect(requests.first.uri.path, '/wp-json/wor-reader-app/v1/session');
      expect(requests.first.headers['Accept'], 'application/json');
      expect(requests.first.headers['User-Agent'], 'WorReaderApp/1.0 Android');
      expect(requests.first.headers['Cache-Control'], 'no-store');
      expect(requests.first.headers['Pragma'], 'no-cache');
      expect(requests.first.headers, isNot(contains('Cookie')));
      expect(requests.last.headers['X-WP-Nonce'], 'fresh-nonce');
      expect(
        requests.last.headers['Cookie'],
        'wordpress_logged_in_test=session-token',
      );
    },
  );

  test('encodes JSON posts and sends nonce only when required', () async {
    late PrivateRawRequest request;
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (outgoing) async {
        request = outgoing;
        return const PrivateRawResponse(statusCode: 200, body: '{}');
      },
    )..updateNonce('nonce-value');

    await client.postAuthenticated(
      'me/favorites/sync',
      body: {
        'novel_ids': [1, 2],
      },
    );

    expect(request.method, 'POST');
    expect(request.headers['X-WP-Nonce'], 'nonce-value');
    expect(request.headers['Content-Type'], 'application/json; charset=utf-8');
    expect(jsonDecode(request.body!), {
      'novel_ids': [1, 2],
    });
  });

  test('exports and imports a complete in-memory session snapshot', () async {
    final responses = <PrivateRawResponse>[
      const PrivateRawResponse(
        statusCode: 200,
        body: '{"logged_in":true,"nonce":"persisted-nonce"}',
        setCookieHeaders: [
          'wordpress_logged_in_test=persisted-cookie; Path=/; Secure; HttpOnly',
        ],
      ),
    ];
    final source = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async => responses.removeAt(0),
    );
    await source.getPublic('session');
    final snapshot = source.exportSessionSnapshot();

    late PrivateRawRequest restoredRequest;
    final restored = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async {
        restoredRequest = request;
        return const PrivateRawResponse(statusCode: 200, body: '{}');
      },
    )..importSessionSnapshot(snapshot!);
    await restored.getAuthenticated('me');

    expect(restoredRequest.headers['X-WP-Nonce'], 'persisted-nonce');
    expect(restoredRequest.headers['Cookie'], contains('persisted-cookie'));
  });

  test(
    'fails before the network when an authenticated nonce is missing',
    () async {
      var requestCount = 0;
      final client = PrivateApiClient(
        config: const AppConfig(siteBaseUrl: 'https://example.com/'),
        requestSender: (request) async {
          requestCount += 1;
          return const PrivateRawResponse(statusCode: 200, body: '{}');
        },
      );

      await expectLater(
        client.getAuthenticated('me'),
        throwsA(
          isA<PrivateApiException>().having(
            (error) => error.code,
            'code',
            'missing_nonce',
          ),
        ),
      );
      expect(requestCount, 0);
    },
  );

  test('rejects private requests outside the configured HTTPS host', () async {
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async {
        return const PrivateRawResponse(statusCode: 200, body: '{}');
      },
    );

    await expectLater(
      client.getPublic('https://attacker.example/session'),
      throwsA(
        isA<PrivateApiException>().having(
          (error) => error.code,
          'code',
          'unsafe_endpoint',
        ),
      ),
    );
  });

  test('rejects paths that escape the private API namespace', () async {
    final client = PrivateApiClient(
      config: const AppConfig(siteBaseUrl: 'https://example.com/'),
      requestSender: (request) async {
        return const PrivateRawResponse(statusCode: 200, body: '{}');
      },
    );

    await expectLater(
      client.getPublic('../wp/v2/users'),
      throwsA(
        isA<PrivateApiException>().having(
          (error) => error.code,
          'code',
          'unsafe_endpoint',
        ),
      ),
    );
  });

  test(
    'preserves the server status without exposing response bodies',
    () async {
      final client = PrivateApiClient(
        config: const AppConfig(siteBaseUrl: 'https://example.com/'),
        requestSender: (request) async {
          return const PrivateRawResponse(
            statusCode: 429,
            body: '{"message":"حاول لاحقًا","code":"rate_limited"}',
          );
        },
      );

      await expectLater(
        client.postPublic(
          'auth/login',
          body: {'username': 'reader', 'password': 'not-logged'},
        ),
        throwsA(
          isA<PrivateApiException>()
              .having((error) => error.statusCode, 'statusCode', 429)
              .having((error) => error.code, 'code', 'rate_limited')
              .having((error) => error.message, 'message', 'حاول لاحقًا'),
        ),
      );
    },
  );
}
