import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/novel_engagement/data/private_novel_engagement_repository.dart';

void main() {
  test(
    'prefers the per-novel account history for the continue chapter',
    () async {
      final requests = <PrivateRawRequest>[];
      final client = PrivateApiClient(
        config: const AppConfig(),
        requestSender: (request) async {
          requests.add(request);
          if (request.uri.path.endsWith('/me/novels/123')) {
            return const PrivateRawResponse(
              statusCode: 200,
              body: '''{
              "novel_id": 123,
              "favorite": false,
              "my_rating": 0,
              "last_read": {
                "chapter_id": 111,
                "chapter_url": "/chapter-111/",
                "progress": 20,
                "updated_at": "2026-06-18T10:00:00+00:00"
              },
              "vip": {"active": false, "can_read_private": false}
            }''',
            );
          }
          return const PrivateRawResponse(
            statusCode: 200,
            body: '''{
            "novelId": 123,
            "lastReadAt": "2026-06-25T12:30:00+00:00",
            "lastChapter": {
              "chapterId": 777,
              "chapterUrl": "/chapter-777/",
              "progress": 64,
              "readAt": "2026-06-25T12:29:00+00:00"
            }
          }''',
          );
        },
      )..updateAccessToken('wra_token_history');
      final repository = PrivateNovelEngagementRepository(client: client);

      final state = await repository.loadState(123);

      expect(requests.map((request) => request.uri.path), [
        contains('/me/novels/123'),
        contains('/me/history/novel/123'),
      ]);
      expect(state.lastRead.chapterId, 777);
      expect(state.lastRead.chapterUrl, '/chapter-777/');
      expect(state.lastRead.progress, 64);
      expect(state.lastRead.updatedAt, DateTime.parse('2026-06-25T12:30:00Z'));
    },
  );

  test(
    'keeps the novel state last read when per-novel history is unavailable',
    () async {
      final requests = <PrivateRawRequest>[];
      final client = PrivateApiClient(
        config: const AppConfig(),
        requestSender: (request) async {
          requests.add(request);
          if (request.uri.path.endsWith('/me/novels/123')) {
            return const PrivateRawResponse(
              statusCode: 200,
              body: '''{
              "novel_id": 123,
              "favorite": false,
              "my_rating": 0,
              "last_read": {
                "chapter_id": 111,
                "chapter_url": "/chapter-111/",
                "progress": 20,
                "updated_at": "2026-06-18T10:00:00+00:00"
              },
              "vip": {"active": false, "can_read_private": false}
            }''',
            );
          }
          return const PrivateRawResponse(
            statusCode: 404,
            body: '{"code":"rest_no_route","message":"missing"}',
          );
        },
      )..updateAccessToken('wra_token_history');
      final repository = PrivateNovelEngagementRepository(client: client);

      final state = await repository.loadState(123);

      expect(requests.map((request) => request.uri.path), [
        contains('/me/novels/123'),
        contains('/me/history/novel/123'),
      ]);
      expect(state.lastRead.chapterId, 111);
      expect(state.lastRead.chapterUrl, '/chapter-111/');
      expect(state.lastRead.progress, 20);
    },
  );

  test('loads state through the authenticated novel endpoint', () async {
    final requests = <PrivateRawRequest>[];
    final client = PrivateApiClient(
      config: const AppConfig(),
      requestSender: (request) async {
        requests.add(request);
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

    final stateRequest = requests.first;
    expect(stateRequest.method, 'GET');
    expect(stateRequest.uri.path, endsWith('/me/novels/123'));
    expect(stateRequest.headers['Authorization'], 'Bearer wra_token_1');
    expect(stateRequest.headers, isNot(contains('X-WP-Nonce')));
    expect(stateRequest.headers['Cache-Control'], 'no-store');
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
