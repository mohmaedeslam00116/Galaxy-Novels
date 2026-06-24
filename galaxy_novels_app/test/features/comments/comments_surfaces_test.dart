import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/comments/application/comments_controller.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_target.dart';
import 'package:galaxy_novels_app/features/comments/domain/comments_page.dart';
import 'package:galaxy_novels_app/features/comments/domain/public_comment.dart';
import 'package:galaxy_novels_app/features/comments/presentation/chapter_comments_sheet.dart';
import 'package:galaxy_novels_app/features/comments/presentation/comments_sliver_section.dart';

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

Widget _surface(CommentsController controller) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [CommentsSliverSection(controller: controller)],
        ),
      ),
    ),
  );
}

PublicComment _comment(int id, String content) {
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
  required List<PublicComment> comments,
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
    reactions: const {},
    comments: comments,
  );
}
