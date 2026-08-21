import 'dart:async';
import 'dart:ui' as ui;

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
  testWidgets('reply focuses and reveals composer from a scrolled list', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_user),
    );
    final target = CommentTarget.novel(42);
    final comments = List.generate(
      5,
      (index) => _comment(index + 1, 'تعليق طويل للاختبار رقم ${index + 1}'),
    );
    final controller = CommentsController(
      repository: FakeCommentsRepository(
        handler: (_, sort, page) async => CommentsPage(
          version: 2,
          target: target,
          sort: sort,
          page: page,
          perPage: 20,
          totalComments: comments.length,
          totalRoots: comments.length,
          totalPages: 1,
          generated: 1,
          reactions: const {},
          comments: comments,
        ),
      ),
      target: target,
      authRepository: authRepository,
    );
    addTearDown(authRepository.dispose);
    addTearDown(controller.dispose);
    await controller.loadInitial();
    await tester.pumpWidget(
      _novelSurface(controller, authRepository: authRepository),
    );

    final reply = find.byKey(const ValueKey('comment-reply-1'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(reply.hitTestable(), findsOneWidget);
    await tester.tap(reply);
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('comments-content-field'));
    final editable = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isTrue);
    expect(field.hitTestable(), findsOneWidget);
    expect(find.text('رد على قارئ 1'), findsOneWidget);
  });

  testWidgets('reply target is announced as a live region', (tester) async {
    final semantics = tester.ensureSemantics();
    final target = CommentTarget.novel(42);
    final repository = FakeCommentsRepository(
      handler: (_, sort, page) async => _page(
        target: target,
        sort: sort,
        page: page,
        comments: [_comment(1, 'تعليق للرد')],
      ),
    );
    final harness = _authenticatedController(repository, target);
    await harness.controller.loadInitial();
    await tester.pumpWidget(
      _novelSurface(harness.controller, authRepository: harness.authRepository),
    );

    try {
      await tester.tap(find.byKey(const ValueKey('comment-reply-1')));
      await tester.pumpAndSettle();

      _expectLiveRegion(
        tester,
        const ValueKey('comments-reply-announcement'),
        'رد على قارئ 1',
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('guest account CTA works on novel and chapter surfaces', (
    tester,
  ) async {
    final guestAuth = FakeAuthRepository();
    final novelTarget = CommentTarget.novel(42);
    final novelController = CommentsController(
      repository: FakeCommentsRepository.empty(),
      target: novelTarget,
      authRepository: guestAuth,
    );
    addTearDown(guestAuth.dispose);
    addTearDown(novelController.dispose);
    await novelController.loadInitial();
    var novelAccountOpened = false;

    await tester.pumpWidget(
      _novelSurface(
        novelController,
        authRepository: guestAuth,
        onSignIn: () => novelAccountOpened = true,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('comments-open-account')));
    expect(novelAccountOpened, isTrue);

    final chapterAuth = FakeAuthRepository();
    addTearDown(chapterAuth.dispose);
    var chapterAccountOpened = false;
    await tester.pumpWidget(
      _chapterSurface(
        repository: FakeCommentsRepository.empty(),
        authRepository: chapterAuth,
        onSignIn: () => chapterAccountOpened = true,
      ),
    );
    await tester.pumpAndSettle();

    final chapterCta = find.byKey(const ValueKey('comments-open-account'));
    expect(chapterCta, findsOneWidget);
    await tester.tap(chapterCta);
    expect(chapterAccountOpened, isTrue);
  });

  testWidgets('comment controls meet target sizes and expose selection', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final authRepository = FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_user),
      );
      final target = CommentTarget.novel(42);
      final repository = FakeCommentsRepository(
        handler: (_, sort, page) async => _page(
          target: target,
          sort: sort,
          page: page,
          comments: [
            _comment(
              1,
              'تعليق قابل للتفاعل',
              likeCount: 4,
              dislikeCount: 1,
              myVote: CommentVote.like,
            ),
          ],
          reactions: const {'love': 2},
        ),
        reactionHandler: (_, reaction) async => CommentReactionResult(
          reaction: reaction,
          counts: const {
            CommentReaction.like: 0,
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
        authRepository: authRepository,
      );
      addTearDown(authRepository.dispose);
      addTearDown(controller.dispose);
      await controller.loadInitial();
      await tester.pumpWidget(
        _novelSurface(controller, authRepository: authRepository),
      );

      for (final key in const [
        'comment-vote-like-1',
        'comment-vote-dislike-1',
        'comment-reply-1',
        'comment-reaction-like',
        'comments-sort-menu',
      ]) {
        _expectMinimumTarget(tester, ValueKey(key));
      }

      final selectedVote = tester.getSemantics(
        find.byKey(const ValueKey('comment-vote-like-1')),
      );
      expect(selectedVote.flagsCollection.isSelected, ui.Tristate.isTrue);

      await tester.tap(find.byKey(const ValueKey('comment-reaction-love')));
      await tester.pumpAndSettle();
      final selectedReaction = tester.getSemantics(
        find.byKey(const ValueKey('comment-reaction-love')),
      );
      expect(selectedReaction.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(selectedReaction.label, contains('أحببته'));

      final sort = tester.getSemantics(
        find.byKey(const ValueKey('comments-sort-menu')),
      );
      expect(sort.flagsCollection.isSelected, ui.Tristate.none);
      expect(sort.label, contains('ترتيب التعليقات'));
      expect(sort.label, contains('الأحدث'));

      await tester.tap(find.byKey(const ValueKey('comments-sort-menu')));
      await tester.pumpAndSettle();
      final currentSort = tester.getSemantics(
        find.byKey(const ValueKey('comments-sort-option-newest')),
      );
      final otherSort = tester.getSemantics(
        find.byKey(const ValueKey('comments-sort-option-top')),
      );
      expect(currentSort.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(otherSort.flagsCollection.isSelected, ui.Tristate.isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('composer does not dispose a supplied focus node', (
    tester,
  ) async {
    final focusNode = FocusNode();
    final authRepository = FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_user),
    );
    final controller = CommentsController(
      repository: FakeCommentsRepository.empty(),
      target: CommentTarget.novel(42),
      authRepository: authRepository,
    );
    addTearDown(focusNode.dispose);
    addTearDown(authRepository.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _composerSurface(
        controller: controller,
        authRepository: authRepository,
        focusNode: focusNode,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('comments-content-field')));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    void listener() {}
    expect(() => focusNode.addListener(listener), returnsNormally);
    focusNode.removeListener(listener);
    expect(focusNode.requestFocus, returnsNormally);
  });

  testWidgets('composer focus-node swaps preserve every supplied node', (
    tester,
  ) async {
    final firstFocusNode = FocusNode();
    final secondFocusNode = FocusNode();
    final authRepository = FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_user),
    );
    final controller = CommentsController(
      repository: FakeCommentsRepository.empty(),
      target: CommentTarget.novel(42),
      authRepository: authRepository,
    );
    FocusNode? suppliedFocusNode = firstFocusNode;
    late StateSetter updateComposer;
    addTearDown(firstFocusNode.dispose);
    addTearDown(secondFocusNode.dispose);
    addTearDown(authRepository.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateComposer = setState;
              return CommentComposer(
                controller: controller,
                authRepository: authRepository,
                focusNode: suppliedFocusNode,
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('comments-content-field')));
    await tester.pump();
    expect(firstFocusNode.hasFocus, isTrue);

    updateComposer(() => suppliedFocusNode = null);
    await tester.pump();
    void firstListener() {}
    expect(() => firstFocusNode.addListener(firstListener), returnsNormally);
    firstFocusNode.removeListener(firstListener);

    updateComposer(() => suppliedFocusNode = secondFocusNode);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('comments-content-field')));
    await tester.pump();
    expect(secondFocusNode.hasFocus, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    void secondListener() {}
    expect(() => secondFocusNode.addListener(secondListener), returnsNormally);
    secondFocusNode.removeListener(secondListener);
    expect(firstFocusNode.requestFocus, returnsNormally);
    expect(secondFocusNode.requestFocus, returnsNormally);
  });

  testWidgets('chapter sheet exposes named route semantics', (tester) async {
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);
    await tester.pumpWidget(
      _chapterSurface(
        repository: FakeCommentsRepository.empty(),
        authRepository: authRepository,
        onSignIn: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.scopesRoute == true &&
            widget.properties.namesRoute == true &&
            widget.properties.label == 'تعليقات الفصل',
      ),
      findsOneWidget,
    );
  });

  testWidgets('submit sending and saved announcements are live regions', (
    tester,
  ) async {
    final submit = Completer<PublicComment>();
    addTearDown(() {
      if (!submit.isCompleted) {
        submit.complete(_comment(90, 'تعليق مكتمل'));
      }
    });
    final target = CommentTarget.novel(42);
    final repository = FakeCommentsRepository(
      handler: (_, sort, page) async =>
          _page(target: target, sort: sort, page: page),
      submitHandler: (_, _, _, _) => submit.future,
    );
    final harness = _authenticatedController(repository, target);
    await harness.controller.loadInitial();
    await tester.pumpWidget(
      _novelSurface(harness.controller, authRepository: harness.authRepository),
    );
    await tester.enterText(
      find.byKey(const ValueKey('comments-content-field')),
      'تعليق جديد',
    );
    await tester.tap(find.byKey(const ValueKey('comments-submit-button')));
    await tester.pump();

    _expectLiveRegion(
      tester,
      const ValueKey('comments-submit-announcement'),
      'جارٍ إرسال التعليق',
    );

    submit.complete(_comment(91, 'تعليق جديد'));
    await tester.pumpAndSettle();

    _expectLiveRegion(
      tester,
      const ValueKey('comments-submit-announcement'),
      'تم نشر تعليقك',
    );
  });

  testWidgets('submit failure is announced as a live safe error', (
    tester,
  ) async {
    final target = CommentTarget.novel(42);
    final repository = FakeCommentsRepository(
      handler: (_, sort, page) async =>
          _page(target: target, sort: sort, page: page),
      submitHandler: (_, _, _, _) async => throw const FormatException(),
    );
    final harness = _authenticatedController(repository, target);
    await harness.controller.loadInitial();
    await tester.pumpWidget(
      _novelSurface(harness.controller, authRepository: harness.authRepository),
    );
    await tester.enterText(
      find.byKey(const ValueKey('comments-content-field')),
      'تعليق سيفشل',
    );
    await tester.tap(find.byKey(const ValueKey('comments-submit-button')));
    await tester.pumpAndSettle();

    _expectLiveRegion(
      tester,
      const ValueKey('comments-submit-announcement'),
      'أرسل الموقع تعليقًا غير صالح. حاول مجددًا.',
    );
  });

  testWidgets('interaction failure is announced as a live safe error', (
    tester,
  ) async {
    final target = CommentTarget.novel(42);
    final repository = FakeCommentsRepository(
      handler: (_, sort, page) async => _page(
        target: target,
        sort: sort,
        page: page,
        comments: [_comment(1, 'تعليق')],
      ),
      reactionHandler: (_, _) async => throw ArgumentError(),
    );
    final harness = _authenticatedController(repository, target);
    await harness.controller.loadInitial();
    await tester.pumpWidget(
      _novelSurface(harness.controller, authRepository: harness.authRepository),
    );
    await tester.tap(find.byKey(const ValueKey('comment-reaction-like')));
    await tester.pumpAndSettle();

    _expectLiveRegion(
      tester,
      const ValueKey('comments-interaction-error'),
      'تعذر تنفيذ التفاعل الآن.',
    );
  });

  testWidgets(
    'novel composer stays focused and revealed after keyboard metrics at 320 and 200%',
    (tester) async {
      _configureSmallView(tester);
      final target = CommentTarget.novel(42);
      final repository = FakeCommentsRepository(
        handler: (_, sort, page) async => _page(
          target: target,
          sort: sort,
          page: page,
          comments: List.generate(
            4,
            (index) => _comment(index + 1, 'تعليق ${index + 1}'),
          ),
        ),
      );
      final harness = _authenticatedController(repository, target);
      await harness.controller.loadInitial();
      await tester.pumpWidget(
        _novelSurface(
          harness.controller,
          authRepository: harness.authRepository,
          textScaler: const TextScaler.linear(2),
        ),
      );

      expect(tester.takeException(), isNull);
      for (final key in const [
        'comment-vote-like-1',
        'comment-vote-dislike-1',
        'comment-reply-1',
        'comment-reaction-like',
        'comments-sort-menu',
      ]) {
        _expectMinimumTarget(tester, ValueKey(key));
      }

      final reply = find.byKey(const ValueKey('comment-reply-1'));
      await _jumpCustomScrollView(
        tester,
        find.byKey(const ValueKey('novel-comments-scroll')),
        200,
      );
      expect(reply.hitTestable(), findsOneWidget);
      await tester.tap(reply);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      _expectFocusedAndRevealed(tester);

      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      _expectFocusedAndRevealed(tester, keyboardInset: 240);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'chapter composer stays focused and revealed after keyboard metrics at 320 and 200%',
    (tester) async {
      _configureSmallView(tester);
      final target = CommentTarget.chapter(7);
      final repository = FakeCommentsRepository(
        handler: (_, sort, page) async => _page(
          target: target,
          sort: sort,
          page: page,
          comments: List.generate(
            4,
            (index) => _comment(index + 1, 'تعليق فصل ${index + 1}'),
          ),
        ),
      );
      final authRepository = FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_user),
      );
      addTearDown(authRepository.dispose);
      await tester.pumpWidget(
        _chapterSurface(
          repository: repository,
          authRepository: authRepository,
          onSignIn: () {},
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final sheet = find.byKey(const ValueKey('chapter-comments-sheet'));
      final reply = find.byKey(const ValueKey('comment-reply-1'));
      final chapterScrollView = find
          .descendant(of: sheet, matching: find.byType(CustomScrollView))
          .first;
      await _jumpCustomScrollView(tester, chapterScrollView, 360);
      expect(reply.hitTestable(), findsOneWidget);
      await tester.tap(reply);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      _expectFocusedAndRevealed(tester);

      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      _expectFocusedAndRevealed(tester, keyboardInset: 240);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _novelSurface(
  CommentsController controller, {
  required FakeAuthRepository authRepository,
  VoidCallback? onSignIn,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          key: const ValueKey('novel-comments-scroll'),
          cacheExtent: 3000,
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

Widget _chapterSurface({
  required FakeCommentsRepository repository,
  required FakeAuthRepository authRepository,
  required VoidCallback onSignIn,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final sheet = ChapterCommentsSheet(
    repository: repository,
    target: CommentTarget.chapter(7),
    authRepository: authRepository,
    onSignIn: onSignIn,
  );
  return MaterialApp(
    theme: AppTheme.dark(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: sheet),
    ),
  );
}

Widget _composerSurface({
  required CommentsController controller,
  required FakeAuthRepository authRepository,
  required FocusNode focusNode,
}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(
      body: CommentComposer(
        controller: controller,
        authRepository: authRepository,
        focusNode: focusNode,
      ),
    ),
  );
}

void _expectMinimumTarget(WidgetTester tester, Key key) {
  final size = tester.getSize(find.byKey(key));
  expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
  expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
}

Future<void> _jumpCustomScrollView(
  WidgetTester tester,
  Finder customScrollView,
  double offset,
) async {
  final scrollable = find
      .descendant(of: customScrollView, matching: find.byType(Scrollable))
      .first;
  expect(
    tester.widget<Scrollable>(scrollable).axisDirection,
    AxisDirection.down,
  );
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(offset.clamp(0, position.maxScrollExtent).toDouble());
  await tester.pump();
}

({CommentsController controller, FakeAuthRepository authRepository})
_authenticatedController(
  FakeCommentsRepository repository,
  CommentTarget target,
) {
  final authRepository = FakeAuthRepository(
    initialState: const AuthSessionState.authenticated(_user),
  );
  final controller = CommentsController(
    repository: repository,
    target: target,
    authRepository: authRepository,
  );
  addTearDown(authRepository.dispose);
  addTearDown(controller.dispose);
  return (controller: controller, authRepository: authRepository);
}

void _expectLiveRegion(WidgetTester tester, Key key, String label) {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget);
  final node = tester.getSemantics(finder);
  expect(node.flagsCollection.isLiveRegion, isTrue);
  expect(node.label, contains(label));
}

void _configureSmallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void _expectFocusedAndRevealed(
  WidgetTester tester, {
  double keyboardInset = 0,
}) {
  final field = find.byKey(const ValueKey('comments-content-field'));
  expect(field, findsOneWidget);
  final editable = tester.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );
  expect(editable.focusNode.hasFocus, isTrue);
  expect(field.hitTestable(), findsOneWidget);
  final rect = tester.getRect(field);
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(720 - keyboardInset));
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
  int id,
  String content, {
  int likeCount = 0,
  int dislikeCount = 0,
  CommentVote? myVote,
}) {
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
    isSpoiler: false,
    likeCount: likeCount,
    dislikeCount: dislikeCount,
    repliesCount: 0,
    score: 0,
    myVote: myVote,
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
  List<PublicComment> comments = const [],
  Map<String, int> reactions = const {},
}) {
  return CommentsPage(
    version: 2,
    target: target,
    sort: sort,
    page: page,
    perPage: 20,
    totalComments: comments.length,
    totalRoots: comments.length,
    totalPages: 1,
    generated: 1,
    reactions: reactions,
    comments: comments,
  );
}
