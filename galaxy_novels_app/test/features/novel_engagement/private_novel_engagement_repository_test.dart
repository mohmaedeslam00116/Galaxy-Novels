import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/novel_engagement/data/private_novel_engagement_repository.dart';

void main() {
  test('loads state through the authenticated novel endpoint', () async {
    late PrivateRawRequest sent;
    final client = PrivateApiClient(
      config: const AppConfig(),
      requestSender: (request) async {
        sent = request;
        return const PrivateRawResponse(
          statusCode: 200,
          body: '''{
            "novel_id": 123,
            "favorite": true,
            "my_rating": 4,
            "last_read": {
              "chapter_id": 555,
              "chapter_url": "/chapter-555/",
              "progress": 96,
              "updated_at": "2026-06-18T10:00:00+00:00"
            },
            "vip": {"active": false, "can_read_private": false}
          }''',
        );
      },
    )..updateAccessToken('wra_token_1');
    final repository = PrivateNovelEngagementRepository(client: client);

    final state = await repository.loadState(123);

    expect(sent.method, 'GET');
    expect(sent.uri.path, endsWith('/me/novels/123'));
    expect(sent.headers['Authorization'], 'Bearer wra_token_1');
    expect(sent.headers, isNot(contains('X-WP-Nonce')));
    expect(sent.headers['Cache-Control'], 'no-store');
    expect(state.novelId, 123);
    expect(state.myRating, 4);
  });

  test('submits a validated rating and trusts the server value', () async {
    late PrivateRawRequest sent;
    final client = PrivateApiClient(
      config: const AppConfig(),
      requestSender: (request) async {
        sent = request;
        return const PrivateRawResponse(
          statusCode: 200,
          body: '{"rating":5,"message":"saved"}',
        );
      },
    )..updateAccessToken('wra_token_2');
    final repository = PrivateNovelEngagementRepository(client: client);

    final rating = await repository.submitRating(novelId: 123, rating: 4);

    expect(sent.method, 'POST');
    expect(sent.uri.path, endsWith('/ratings/novel/123'));
    expect(sent.headers['Authorization'], 'Bearer wra_token_2');
    expect(sent.headers, isNot(contains('X-WP-Nonce')));
    expect(jsonDecode(sent.body!), {'rating': 4});
    expect(rating, 5);
  });

  test('rejects ratings outside one to five without a request', () async {
    var calls = 0;
    final repository = PrivateNovelEngagementRepository(
      client: PrivateApiClient(
        config: const AppConfig(),
        requestSender: (_) async {
          calls++;
          throw StateError('The request must not run.');
        },
      )..updateAccessToken('wra_token'),
    );

    await expectLater(
      repository.submitRating(novelId: 123, rating: 0),
      throwsRangeError,
    );
    await expectLater(
      repository.submitRating(novelId: 123, rating: 6),
      throwsRangeError,
    );
    expect(calls, 0);
  });

  test('rejects an invalid rating returned by the server', () async {
    final repository = PrivateNovelEngagementRepository(
      client: PrivateApiClient(
        config: const AppConfig(),
        requestSender: (_) async =>
            const PrivateRawResponse(statusCode: 200, body: '{"rating":9}'),
      )..updateAccessToken('wra_token'),
    );

    await expectLater(
      repository.submitRating(novelId: 123, rating: 4),
      throwsFormatException,
    );
  });
}
