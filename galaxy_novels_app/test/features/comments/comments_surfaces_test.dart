import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/comments/application/comments_controller.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_interaction.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_target.dart';
import 'package:galaxy_novels_app/features/comments/domain/comments_page.dart';
import 'package:galaxy_novels_app/features/comments/domain/public_comment.dart';
import 'package:galaxy_novels_app/features/comments/presentation/chapter_comments_sheet.dart';
import 'package:galaxy_novels_app/features/comments/presentation/comments_sliver_section.dart';
import 'package:galaxy_novels_app/features/comments/presentation/widgets/comment_composer.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';

void main() {
  testWidgets('moves from loading to the empty state', (tester) async {
    final completion = Completer<CommentsPage>();
    final target = CommentTarget.novel(42);
    final controller = CommentsController(
      repository: FakeCommentsRepository(
        handler: (_, _, _) => completion.future,
      ),
      target: target,
    );
    addTearDown(controller.dispose);
    unawaited(controller.loadInitial());

    await tester.pumpWidget(_surface(controller));
    expect(find.text('تحميل التعليقات...'), findsOneWidget);

    completion.complete(
      CommentsPage.empty(target: target, sort: CommentsSort.newest),
    );
    await tester.pumpAndSettle();

    expect(find.text('لا توجد تعليقات بعد'), findsOneWidget);
  });

  testWidgets('changes sort and loads the next page explicitly', (
    tester,
  ) async {
    final target = CommentTarget.novel(42);
    final repository = FakeCommentsRepository(
      handler: (_, sort, page) async => _page(
        target: target,
        sort: sort,
        page: page,
        totalPages: 2,
        comments: [_comment(page, 'تعليق الصفحة $page')],
      ),
    );
    final controller = CommentsController(
      repository: repository,
      target: target,
    );
    addTearDown(controller.dispose);
    await controller.loadInitial();
    await tester.pumpWidget(_surface(controller));

    await tester.tap(find.byKey(const ValueKey('comments-sort-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الأعلى').last);
    await tester.pumpAndSettle();

    expect(repository.calls.last.sort, CommentsSort.top);
    expect(repository.calls.last.page, 1);
    expect(find.text('تعليق الصفحة 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('comments-load-more')));
    await tester.pumpAndSettle();

    expect(repository.calls.last.page, 2);
    expect(find.text('تعليق الصفحة 2'), findsOneWidget);
  });

  testWidgets('shows a local retry state when loading fails', (tester) async {
    final controller = CommentsController(
      repository: FakeCommentsRepository(
        handler: (_, _, _) => Future.error(Exception('offline')),
      ),
      target: CommentTarget.chapter(7),
    );
    addTearDown(controller.dispose);
    await controller.loadInitial();

    await tester.pumpWidget(_surface(controller));

    expect(find.text('تعذر تحميل التعليقات الآن.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('guest comment composer offers opening account screen', (
    tester,
  ) async {
    var openedAccount = false;
    final target = CommentTarget.novel(42);
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);
    final controller = CommentsController(
      repository: FakeCommentsRepository.empty(),
      target: target,
      authRepository: authRepository,
    );
    addTearDown(controller.dispose);
    await controller.loadInitial();

    await tester.pumpWidget(
      _surface(
        controller,
        authRepository: authRepository,
        onSignIn: () => openedAccount = true,
      ),
    );

    expect(find.text('سجل الدخول لكتابة تعليق.'), findsOneWidget);
    expect(find.text('فتح حسابي'), findsOneWidget);

    await tester.tap(find.text('فتح حسابي'));

    expect(openedAccount, isTrue);
  });

  testWidgets('authenticated reader writes a new root comment', (tester) async {
    final target = CommentTarget.novel(42);
    final repository = FakeCommentsRepository(
      handler: (_, sort, _) async =>
          _page(target: target, sort: sort, page: 1, totalPages: 1),
      submitHandler: (_, content, parentId, isSpoiler) async =>
          _comment(77, content, isSpoiler: isSpoiler),
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
    await tester.pumpWidget(_surface(controller));

    await tester.enterText(
      find.byKey(const ValueKey('comments-content-field')),
      'تعليق من التطبيق',
    );
    await tester.tap(find.byKey(const ValueKey('comments-spoiler-toggle')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('comments-submit-button')));
    await tester.pumpAndSettle();

    expect(repository.submitCalls.single.content, 'تعليق من التطبيق');
    expect(repository.submitCalls.single.isSpoiler, isTrue);
    expect(find.text('إظهار المحتوى المحروق'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('comment-spoiler-77')));
    await tester.pump();

    expect(find.text('تعليق من التطبيق'), findsOneWidget);
  });

  testWidgets(
    'does not complete composer callbacks after the composer is removed',
    (tester) async {
      final response = Completer<PublicComment>();
      final savedComment = _comment(78, 'تعليق مكتمل');
      addTearDown(() {
        if (!response.isCompleted) {
          response.complete(savedComment);
        }
      });
      final authRepository = FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_user),
      );
      addTearDown(authRepository.dispose);
      final repository = FakeCommentsRepository(
        handler: (target, sort, page) async =>
            CommentsPage.empty(target: target, sort: sort, page: page),
        submitHandler: (_, _, _, _) => response.future,
      );
      final controller = CommentsController(
        repository: repository,
        target: CommentTarget.novel(42),
        authRepository: authRepository,
      );
      addTearDown(controller.dispose);
      var submittedCallbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: CommentComposer(
              controller: controller,
              authRepository: authRepository,
              onSubmitted: () => submittedCallbackCalled = true,
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('comments-content-field')),
        'تعليق مؤجل',
      );
      await tester.tap(find.byKey(const ValueKey('comments-submit-button')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());

      response.complete(savedComment);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(submittedCallbackCalled, isFalse);
    },
  );

  testWidgets('authenticated reader votes and reacts from comments surface', (
    tester,
  ) async {
    final target = CommentTarget.novel(42);
    final repository = FakeCommentsRepository(
      handler: (_, sort, _) async => _page(
        target: target,
        sort: sort,
        page: 1,
        totalPages: 1,
        reactions: const {'like': 1, 'love': 2},
        comments: [_comment(7, 'تعليق قابل للتفاعل')],
      ),
      voteHandler: (commentId, vote) async => const CommentVoteResult(
        commentId: 7,
        vote: CommentVote.like,
        likeCount: 6,
        dislikeCount: 0,
        score: 6,
      ),
      reactionHandler: (target, reaction) async => CommentReactionResult(
        reaction: CommentReaction.love,
        counts: const {
          CommentReaction.like: 1,
          CommentReaction.laugh: 0,
          CommentReaction.love: 3,
          CommentReaction.wow: 0,
          CommentReaction.angry: 0,
          CommentReaction.sad: 0,
        },
      ),
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
    await tester.pumpWidget(_surface(controller));

    await tester.tap(find.byKey(const ValueKey('comment-vote-like-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('comment-reaction-love')));
    await tester.pumpAndSettle();

    expect(repository.voteCalls.single.vote, CommentVote.like);
    expect(repository.reactionCalls.single.reaction, CommentReaction.love);
    expect(controller.value.comments.single.likeCount, 6);
    expect(controller.value.reactions[CommentReaction.love], 3);
  });

  testWidgets('chapter sheet owns a draggable comments surface', (
    tester,
  ) async {
    final repository = FakeCommentsRepository.empty();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ChapterCommentsSheet(
                      repository: repository,
                      target: CommentTarget.chapter(7),
                    ),
                  ),
                  child: const Text('فتح'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('chapter-comments-sheet')),
      findsOneWidget,
    );
    expect(find.text('تعليقات الفصل'), findsOneWidget);
    expect(repository.calls, hasLength(1));
  });
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

Widget _surface(
  CommentsController controller, {
  FakeAuthRepository? authRepository,
  VoidCallback? onSignIn,
}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            CommentsSliverSection(
              controller: controller,
              authRepository: authRepository,
              onSignIn: onSignIn,
            ),
          ],
        ),
      ),
    ),
  );
}

PublicComment _comment(int id, String content, {bool isSpoiler = false}) {
  return PublicComment(
    id: id,
    parentId: 0,
    rootId: 0,
    depth: 0,
    authorName: 'قارئ $id',
    authorRank: '',
    avatarUrl: '',
    replyToName: '',
    content: content,
    isSpoiler: isSpoiler,
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
  required int page,
  required int totalPages,
  Map<String, int> reactions = const {},
  List<PublicComment> comments = const [],
}) {
  return CommentsPage(
    version: 2,
    target: target,
    sort: sort,
    page: page,
    perPage: 20,
    totalComments: totalPages,
    totalRoots: totalPages,
    totalPages: totalPages,
    generated: 1,
    reactions: reactions,
    comments: comments,
  );
}
