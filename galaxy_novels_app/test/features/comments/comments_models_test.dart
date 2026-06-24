import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_target.dart';
import 'package:galaxy_novels_app/features/comments/domain/comments_page.dart';

void main() {
  final target = CommentTarget.novel(42);

  test('parses a public comments page and nested replies', () {
    final page = CommentsPage.fromJson(
      {
        'version': 2,
        'object_type': 'novel',
        'object_id': 42,
        'sort': 'newest',
        'page': 1,
        'per_page': 20,
        'total_comments': 2,
        'total_roots': 1,
        'total_pages': 1,
        'generated': 1782324555,
        'reactions': {'like': 3, 'love': 2},
        'comments': [
          {
            'id': 7,
            'parent_id': 0,
            'root_id': 0,
            'depth': 0,
            'author_name': 'قارئ أول',
            'author_rank': 'قارئ فضي',
            'avatar_url': '/avatar.webp',
            'reply_to_name': '',
            'content': 'تعليق رئيسي',
            'is_spoiler': 1,
            'like_count': 4,
            'dislike_count': 1,
            'replies_count': 1,
            'score': 3,
            'is_pinned': 1,
            'created_at': '24 يونيو 2026 10:00',
            'created_iso': '2026-06-24T10:00:00+03:00',
            'replies': [
              {
                'id': 8,
                'parent_id': 7,
                'root_id': 7,
                'depth': 1,
                'author_name': 'قارئ ثان',
                'content': 'رد',
                'created_at': '24 يونيو 2026 10:05',
              },
            ],
          },
        ],
      },
      expectedTarget: target,
      expectedSort: CommentsSort.newest,
      expectedPage: 1,
    );

    expect(page.target, target);
    expect(page.totalComments, 2);
    expect(page.reactions['like'], 3);
    expect(page.comments.single.isSpoiler, isTrue);
    expect(page.comments.single.isPinned, isTrue);
    expect(page.comments.single.createdAt, isNotNull);
    expect(page.comments.single.replies.single.content, 'رد');
  });

  test('accepts the empty live response shape', () {
    final page = CommentsPage.fromJson(
      {
        'version': 2,
        'object_type': 'novel',
        'object_id': 42,
        'sort': 'newest',
        'page': 1,
        'per_page': 20,
        'total_comments': 0,
        'total_roots': 0,
        'total_pages': 0,
        'generated': 1782324555,
        'reactions': <String, int>{},
        'comments': <Object>[],
      },
      expectedTarget: target,
      expectedSort: CommentsSort.newest,
      expectedPage: 1,
    );

    expect(page.comments, isEmpty);
    expect(page.hasNextPage, isFalse);
  });

  test('rejects a response for another object', () {
    expect(
      () => CommentsPage.fromJson(
        {
          'version': 2,
          'object_type': 'chapter',
          'object_id': 42,
          'sort': 'newest',
          'page': 1,
          'per_page': 20,
          'total_pages': 0,
          'comments': <Object>[],
        },
        expectedTarget: target,
        expectedSort: CommentsSort.newest,
        expectedPage: 1,
      ),
      throwsFormatException,
    );
  });

  test('rejects invalid targets before building a request path', () {
    expect(() => CommentTarget.chapter(0), throwsRangeError);
    expect(CommentTarget.chapter(9).pathSegment, 'chapter/9');
  });
}
