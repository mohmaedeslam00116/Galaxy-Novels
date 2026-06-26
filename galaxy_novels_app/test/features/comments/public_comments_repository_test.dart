import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/comments/data/public_comments_repository.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_interaction.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_target.dart';

void main() {
  test('loads a public novel comments page without auth headers', () async {
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
    expect(sent.headers.containsKey('Authorization'), isFalse);
    expect(sent.headers.containsKey('X-WP-Nonce'), isFalse);
    expect(page.page, 2);
  });

  test(
    'submits an authenticated comment and parses the saved payload',
    () async {
      late PrivateRawRequest sent;
      final client = PrivateApiClient(
        config: const AppConfig(),
        requestSender: (request) async {
          sent = request;
          return const PrivateRawResponse(
            statusCode: 201,
            body: '''{
            "comment": {
              "id": 88,
              "parent_id": 0,
              "root_id": 88,
              "depth": 0,
              "author_name": "قارئ مسجل",
              "author_rank": "قارئ ذهبي",
              "avatar_url": "",
              "reply_to_name": "",
              "content": "تعليق جديد",
              "is_spoiler": true,
              "like_count": 0,
              "dislike_count": 0,
              "replies_count": 0,
              "score": 0,
              "is_pinned": false,
              "created_at": "الآن",
              "created_iso": "2026-06-25T10:00:00Z",
              "replies": []
            }
          }''',
          );
        },
      )..updateAccessToken('wra_token_1');
      final repository = PublicCommentsRepository(client: client);

      final comment = await repository.submitComment(
        target: CommentTarget.novel(42),
        content: ' تعليق جديد ',
        parentId: 0,
        isSpoiler: true,
      );

      expect(sent.method, 'POST');
      expect(sent.uri.path, endsWith('/comments/novel/42'));
      expect(sent.headers['Authorization'], 'Bearer wra_token_1');
      expect(sent.headers, isNot(contains('X-WP-Nonce')));
      expect(
        sent.body,
        '{"content":"تعليق جديد","parent_id":0,"is_spoiler":true}',
      );
      expect(comment.id, 88);
      expect(comment.content, 'تعليق جديد');
      expect(comment.isSpoiler, isTrue);
    },
  );

  test('rejects an empty submitted comment before the network', () async {
    var requests = 0;
    final repository = PublicCommentsRepository(
      client: PrivateApiClient(
        config: const AppConfig(),
        requestSender: (_) async {
          requests++;
          throw StateError('The request must not run.');
        },
      )..updateAccessToken('wra_token_1'),
    );

    await expectLater(
      repository.submitComment(
        target: CommentTarget.chapter(7),
        content: '   ',
      ),
      throwsArgumentError,
    );
    expect(requests, 0);
  });

  test(
    'votes on an authenticated comment and parses returned counts',
    () async {
      late PrivateRawRequest sent;
      final client = PrivateApiClient(
        config: const AppConfig(),
        requestSender: (request) async {
          sent = request;
          return const PrivateRawResponse(
            statusCode: 200,
            body: '''{
            "success": true,
            "comment_id": 55,
            "vote": "like",
            "counts": {
              "like_count": 4,
              "dislike_count": 1,
              "score": 3
            }
          }''',
          );
        },
      )..updateAccessToken('wra_token_1');
      final repository = PublicCommentsRepository(client: client);

      final result = await repository.voteComment(
        commentId: 55,
        vote: CommentVote.like,
      );

      expect(sent.method, 'POST');
      expect(sent.uri.path, endsWith('/comments/55/vote'));
      expect(sent.headers['Authorization'], 'Bearer wra_token_1');
      expect(sent.headers, isNot(contains('X-WP-Nonce')));
      expect(sent.body, '{"vote":"like"}');
      expect(result.commentId, 55);
      expect(result.vote, CommentVote.like);
      expect(result.likeCount, 4);
      expect(result.dislikeCount, 1);
      expect(result.score, 3);
    },
  );

  test(
    'reacts to an authenticated comments target and parses counts',
    () async {
      late PrivateRawRequest sent;
      final client = PrivateApiClient(
        config: const AppConfig(),
        requestSender: (request) async {
          sent = request;
          return const PrivateRawResponse(
            statusCode: 200,
            body: '''{
            "success": true,
            "reaction": "love",
            "counts": {
              "like": 3,
              "laugh": 0,
              "love": 5,
              "wow": 1,
              "angry": 0,
              "sad": 0
            }
          }''',
          );
        },
      )..updateAccessToken('wra_token_1');
      final repository = PublicCommentsRepository(client: client);

      final result = await repository.reactToTarget(
        target: CommentTarget.chapter(7),
        reaction: CommentReaction.love,
      );

      expect(sent.method, 'POST');
      expect(sent.uri.path, endsWith('/comments/chapter/7/reaction'));
      expect(sent.headers['Authorization'], 'Bearer wra_token_1');
      expect(sent.headers, isNot(contains('X-WP-Nonce')));
      expect(sent.body, '{"reaction":"love"}');
      expect(result.reaction, CommentReaction.love);
      expect(result.counts[CommentReaction.love], 5);
      expect(result.counts[CommentReaction.wow], 1);
    },
  );

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
