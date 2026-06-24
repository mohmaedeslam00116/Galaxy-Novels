import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/comments/data/public_comments_repository.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_target.dart';

void main() {
  test('loads a public novel comments page without a nonce', () async {
    late PrivateRawRequest sent;
    final repository = PublicCommentsRepository(
      client: PrivateApiClient(
        config: const AppConfig(),
        requestSender: (request) async {
          sent = request;
          return const PrivateRawResponse(
            statusCode: 200,
            body: '''{
              "version": 2,
              "object_type": "novel",
              "object_id": 42,
              "sort": "top",
              "page": 2,
              "per_page": 20,
              "total_comments": 21,
              "total_roots": 21,
              "total_pages": 2,
              "generated": 1,
              "reactions": {},
              "comments": []
            }''',
          );
        },
      ),
    );

    final page = await repository.loadPage(
      target: CommentTarget.novel(42),
      sort: CommentsSort.top,
      page: 2,
    );

    expect(sent.method, 'GET');
    expect(sent.uri.path, endsWith('/comments/novel/42'));
    expect(sent.uri.queryParameters, {'page': '2', 'sort': 'top'});
    expect(sent.headers.containsKey('X-WP-Nonce'), isFalse);
    expect(page.page, 2);
  });

  test('rejects a non-positive page before the network', () async {
    var requests = 0;
    final repository = PublicCommentsRepository(
      client: PrivateApiClient(
        config: const AppConfig(),
        requestSender: (_) async {
          requests++;
          throw StateError('The request must not run.');
        },
      ),
    );

    await expectLater(
      repository.loadPage(
        target: CommentTarget.chapter(7),
        sort: CommentsSort.newest,
        page: 0,
      ),
      throwsRangeError,
    );
    expect(requests, 0);
  });

  test('rejects a response belonging to another target', () async {
    final repository = PublicCommentsRepository(
      client: PrivateApiClient(
        config: const AppConfig(),
        requestSender: (_) async => const PrivateRawResponse(
          statusCode: 200,
          body: '''{
            "version": 2,
            "object_type": "chapter",
            "object_id": 42,
            "sort": "newest",
            "page": 1,
            "per_page": 20,
            "total_pages": 0,
            "comments": []
          }''',
        ),
      ),
    );

    await expectLater(
      repository.loadPage(
        target: CommentTarget.novel(42),
        sort: CommentsSort.newest,
        page: 1,
      ),
      throwsFormatException,
    );
  });
}
