import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/comments/application/comments_controller.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_target.dart';
import 'package:galaxy_novels_app/features/comments/domain/comments_page.dart';
import 'package:galaxy_novels_app/features/comments/domain/public_comment.dart';

import '../../helpers/fake_comments_repository.dart';

void main() {
  test('loads once and merges the next page without duplicate ids', () async {
    final firstPage = Completer<CommentsPage>();
    final repository = FakeCommentsRepository(
      handler: (target, sort, page) {
        if (page == 1) {
          return firstPage.future;
        }
        return Future.value(
          _page(
            target: target,
            sort: sort,
            page: 2,
            totalPages: 2,
            comments: [_comment(2), _comment(1)],
          ),
        );
      },
    );
    final controller = CommentsController(
      repository: repository,
      target: CommentTarget.novel(42),
    );
    addTearDown(controller.dispose);

    final first = controller.loadInitial();
    final duplicate = controller.loadInitial();
    expect(repository.calls, hasLength(1));

    firstPage.complete(
      _page(
        target: CommentTarget.novel(42),
        sort: CommentsSort.newest,
        totalPages: 2,
        comments: [_comment(1)],
      ),
    );
    await Future.wait([first, duplicate]);
    await controller.loadMore();

    expect(repository.calls.map((call) => call.page), [1, 2]);
    expect(controller.value.comments.map((item) => item.id), [1, 2]);
    expect(controller.value.isLoadingMore, isFalse);
  });

  test('late sort response cannot replace the selected sort', () async {
    final newest = Completer<CommentsPage>();
    final top = Completer<CommentsPage>();
    final target = CommentTarget.novel(42);
    final repository = FakeCommentsRepository(
      handler: (_, sort, _) =>
          sort == CommentsSort.newest ? newest.future : top.future,
    );
    final controller = CommentsController(
      repository: repository,
      target: target,
    );
    addTearDown(controller.dispose);

    final first = controller.loadInitial();
    final second = controller.changeSort(CommentsSort.top);
    top.complete(_page(target: target, sort: CommentsSort.top));
    await second;
    newest.complete(_page(target: target, sort: CommentsSort.newest));
    await first;

    expect(controller.value.sort, CommentsSort.top);
    expect(controller.value.status, CommentsStatus.ready);
  });

  test('initial failure publishes a safe Arabic message', () async {
    final controller = CommentsController(
      repository: FakeCommentsRepository(
        handler: (_, _, _) => Future.error(const FormatException('bad json')),
      ),
      target: CommentTarget.chapter(9),
    );
    addTearDown(controller.dispose);

    await controller.loadInitial();

    expect(controller.value.status, CommentsStatus.failure);
    expect(controller.value.errorMessage, 'تعذر قراءة بيانات التعليقات.');
  });

  test('programming errors propagate instead of becoming loading failures', () {
    final controller = CommentsController(
      repository: FakeCommentsRepository(
        handler: (_, _, _) => Future.error(StateError('invalid state')),
      ),
      target: CommentTarget.chapter(9),
    );
    addTearDown(controller.dispose);

    expect(controller.loadInitial(), throwsStateError);
  });

  test('load more failure preserves the loaded page', () async {
    final target = CommentTarget.chapter(9);
    final repository = FakeCommentsRepository(
      handler: (_, sort, page) {
        if (page == 2) {
          return Future.error(Exception('offline'));
        }
        return Future.value(
          _page(
            target: target,
            sort: sort,
            totalPages: 2,
            comments: [_comment(1)],
          ),
        );
      },
    );
    final controller = CommentsController(
      repository: repository,
      target: target,
    );
    addTearDown(controller.dispose);
    await controller.loadInitial();

    await controller.loadMore();

    expect(controller.value.status, CommentsStatus.ready);
    expect(controller.value.comments.single.id, 1);
    expect(controller.value.page, 1);
    expect(controller.value.loadMoreErrorMessage, 'تعذر تحميل التعليقات الآن.');
  });
}

PublicComment _comment(int id) {
  return PublicComment(
    id: id,
    parentId: 0,
    rootId: 0,
    depth: 0,
    authorName: 'قارئ $id',
    authorRank: '',
    avatarUrl: '',
    replyToName: '',
    content: 'تعليق $id',
    isSpoiler: false,
    likeCount: 0,
    dislikeCount: 0,
    repliesCount: 0,
    score: 0,
    isPinned: false,
    createdLabel: '',
    createdAt: null,
    replies: const [],
  );
}

CommentsPage _page({
  required CommentTarget target,
  required CommentsSort sort,
  int page = 1,
  int totalPages = 1,
  List<PublicComment> comments = const [],
}) {
  return CommentsPage(
    version: 2,
    target: target,
    sort: sort,
    page: page,
    perPage: 20,
    totalComments: comments.length,
    totalRoots: comments.length,
    totalPages: totalPages,
    generated: 1,
    reactions: const {},
    comments: comments,
  );
}
