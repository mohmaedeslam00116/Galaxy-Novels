import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/comments/domain/public_comment.dart';
import 'package:galaxy_novels_app/features/comments/presentation/widgets/comment_item.dart';

void main() {
  testWidgets('spoiler stays hidden until the reader reveals it', (
    tester,
  ) async {
    await tester.pumpWidget(_surface(CommentItem(comment: _spoilerComment())));

    expect(find.text('سر النهاية'), findsNothing);
    expect(find.text('إظهار المحتوى المحروق'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('comment-spoiler-7')));
    await tester.pump();

    expect(find.text('سر النهاية'), findsOneWidget);
  });

  testWidgets('renders replies and fits a 320 pixel screen', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _surface(
        SingleChildScrollView(child: CommentItem(comment: _commentWithReply())),
      ),
    );

    expect(find.text('رد طويل من قارئ آخر'), findsOneWidget);
    expect(find.text('مثبّت'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _surface(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: SafeArea(child: child)),
    ),
  );
}

PublicComment _spoilerComment() {
  return _comment(id: 7, content: 'سر النهاية', isSpoiler: true);
}

PublicComment _commentWithReply() {
  return _comment(
    id: 1,
    content: 'تعليق رئيسي',
    replies: [_comment(id: 2, content: 'رد طويل من قارئ آخر', parentId: 1)],
  );
}

PublicComment _comment({
  required int id,
  required String content,
  int parentId = 0,
  bool isSpoiler = false,
  List<PublicComment> replies = const [],
}) {
  return PublicComment(
    id: id,
    parentId: parentId,
    rootId: parentId == 0 ? 0 : 1,
    depth: parentId == 0 ? 0 : 1,
    authorName: 'اسم قارئ طويل للاختبار',
    authorRank: 'قارئ فضي',
    avatarUrl: '',
    replyToName: parentId == 0 ? '' : 'قارئ أول',
    content: content,
    isSpoiler: isSpoiler,
    likeCount: 4,
    dislikeCount: 1,
    repliesCount: replies.length,
    score: 3,
    isPinned: id == 1,
    createdLabel: 'منذ ساعة',
    createdAt: null,
    replies: replies,
  );
}
