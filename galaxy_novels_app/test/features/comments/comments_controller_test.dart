import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/comments/application/comments_controller.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_interaction.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_target.dart';
import 'package:galaxy_novels_app/features/comments/domain/comments_page.dart';
import 'package:galaxy_novels_app/features/comments/domain/public_comment.dart';

import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_auth_repository.dart';

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

  test('guest cannot submit a comment', () async {
    final repository = FakeCommentsRepository.empty();
    final controller = CommentsController(
      repository: repository,
      target: CommentTarget.novel(42),
      authRepository: FakeAuthRepository(),
    );
    addTearDown(controller.dispose);

    final outcome = await controller.submitComment(content: 'تعليق جديد');

    expect(outcome.status, CommentSubmitStatus.signInRequired);
    expect(repository.submitCalls, isEmpty);
    expect(controller.value.submitErrorMessage, 'سجل الدخول لكتابة تعليق.');
  });

  test('expired submit session shows a clear sign-in message', () async {
    final repository = FakeCommentsRepository(
      handler: (_, sort, _) =>
          Future.value(_page(target: CommentTarget.novel(42), sort: sort)),
      submitHandler: (_, _, _, _) => Future.error(
        const PrivateApiException(statusCode: 401, message: 'expired'),
      ),
    );
    final controller = CommentsController(
      repository: repository,
      target: CommentTarget.novel(42),
      authRepository: FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_user),
      ),
    );
    addTearDown(controller.dispose);
    await controller.loadInitial();

    final outcome = await controller.submitComment(content: 'تعليق');

    expect(outcome.status, CommentSubmitStatus.failed);
    expect(outcome.errorMessage, 'انتهت الجلسة، سجل الدخول مرة أخرى للمتابعة.');
    expect(controller.value.submitErrorMessage, outcome.errorMessage);
  });

  test('authenticated submit inserts a reply under its root comment', () async {
    final target = CommentTarget.novel(42);
    final repository = FakeCommentsRepository(
      handler: (_, sort, _) => Future.value(
        _page(target: target, sort: sort, comments: [_comment(1)]),
      ),
      submitHandler: (_, content, parentId, isSpoiler) async {
        return _comment(
          2,
          parentId: parentId,
          rootId: 1,
          content: content,
          isSpoiler: isSpoiler,
        );
      },
    );
    final controller = CommentsController(
      repository: repository,
      target: target,
      authRepository: FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_user),
      ),
    );
    addTearDown(controller.dispose);
    await controller.loadInitial();

    final outcome = await controller.submitComment(
      content: ' رد جديد ',
      parentId: 1,
      isSpoiler: true,
    );

    expect(outcome.status, CommentSubmitStatus.saved);
    expect(repository.submitCalls.single.parentId, 1);
    expect(repository.submitCalls.single.content, 'رد جديد');
    expect(repository.submitCalls.single.isSpoiler, isTrue);
    final root = controller.value.comments.single;
    expect(root.replies, hasLength(1));
    expect(root.replies.single.content, 'رد جديد');
    expect(root.replies.single.isSpoiler, isTrue);
    expect(controller.value.isSubmitting, isFalse);
  });

  test('guest cannot vote on a comment', () async {
    final repository = FakeCommentsRepository.empty();
    final controller = CommentsController(
      repository: repository,
      target: CommentTarget.novel(42),
      authRepository: FakeAuthRepository(),
    );
    addTearDown(controller.dispose);

    final outcome = await controller.voteComment(
      commentId: 1,
      vote: CommentVote.like,
    );

    expect(outcome.status, CommentInteractionStatus.signInRequired);
    expect(repository.voteCalls, isEmpty);
    expect(controller.value.interactionErrorMessage, 'سجل الدخول للتفاعل.');
  });

  test('authenticated vote updates comment counts from the server', () async {
    final target = CommentTarget.novel(42);
    final repository = FakeCommentsRepository(
      handler: (_, sort, _) => Future.value(
        _page(target: target, sort: sort, comments: [_comment(1)]),
      ),
      voteHandler: (commentId, vote) async {
        return const CommentVoteResult(
          commentId: 1,
          vote: CommentVote.like,
          likeCount: 7,
          dislikeCount: 2,
          score: 5,
        );
      },
    );
    final controller = CommentsController(
      repository: repository,
      target: target,
      authRepository: FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_user),
      ),
    );
    addTearDown(controller.dispose);
    await controller.loadInitial();

    final outcome = await controller.voteComment(
      commentId: 1,
      vote: CommentVote.like,
    );

    expect(outcome.status, CommentInteractionStatus.saved);
    expect(repository.voteCalls.single.vote, CommentVote.like);
    final comment = controller.value.comments.single;
    expect(comment.likeCount, 7);
    expect(comment.dislikeCount, 2);
    expect(comment.score, 5);
    expect(comment.myVote, CommentVote.like);
  });

  test(
    'authenticated reaction updates target counts from the server',
    () async {
      final target = CommentTarget.chapter(9);
      final repository = FakeCommentsRepository(
        handler: (_, sort, _) =>
            Future.value(_page(target: target, sort: sort)),
        reactionHandler: (target, reaction) async {
          return CommentReactionResult(
            reaction: CommentReaction.love,
            counts: const {
              CommentReaction.like: 2,
              CommentReaction.laugh: 0,
              CommentReaction.love: 4,
              CommentReaction.wow: 1,
              CommentReaction.angry: 0,
              CommentReaction.sad: 0,
            },
          );
        },
      );
      final controller = CommentsController(
        repository: repository,
        target: target,
        authRepository: FakeAuthRepository(
          initialState: const AuthSessionState.authenticated(_user),
        ),
      );
      addTearDown(controller.dispose);
      await controller.loadInitial();

      final outcome = await controller.reactToTarget(CommentReaction.love);

      expect(outcome.status, CommentInteractionStatus.saved);
      expect(repository.reactionCalls.single.reaction, CommentReaction.love);
      expect(controller.value.myReaction, CommentReaction.love);
      expect(controller.value.reactions[CommentReaction.love], 4);
      expect(controller.value.reactions[CommentReaction.wow], 1);
    },
  );
}

const _user = AuthUser(
  id: 7,
  displayName: 'قارئ مسجل',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 0, display: ''),
  ),
);

PublicComment _comment(
  int id, {
  int parentId = 0,
  int rootId = 0,
  String? content,
  bool isSpoiler = false,
  List<PublicComment> replies = const [],
}) {
  return PublicComment(
    id: id,
    parentId: parentId,
    rootId: rootId,
    depth: 0,
    authorName: 'قارئ $id',
    authorRank: '',
    avatarUrl: '',
    replyToName: '',
    content: content ?? 'تعليق $id',
    isSpoiler: isSpoiler,
    likeCount: 0,
    dislikeCount: 0,
    repliesCount: replies.length,
    score: 0,
    isPinned: false,
    createdLabel: '',
    createdAt: null,
    replies: replies,
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
