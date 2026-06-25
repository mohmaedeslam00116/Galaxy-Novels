import 'package:galaxy_novels_app/features/comments/application/comments_repository.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_target.dart';
import 'package:galaxy_novels_app/features/comments/domain/comments_page.dart';
import 'package:galaxy_novels_app/features/comments/domain/public_comment.dart';

typedef CommentsLoadHandler =
    Future<CommentsPage> Function(
      CommentTarget target,
      CommentsSort sort,
      int page,
    );

typedef CommentsSubmitHandler =
    Future<PublicComment> Function(
      CommentTarget target,
      String content,
      int parentId,
      bool isSpoiler,
    );

class FakeCommentsRepository implements CommentsRepository {
  FakeCommentsRepository({
    required this.handler,
    CommentsSubmitHandler? submitHandler,
  }) : submitHandler =
           submitHandler ??
           ((target, content, parentId, isSpoiler) {
             throw UnimplementedError('submitComment is not configured.');
           });

  FakeCommentsRepository.empty()
    : handler = ((target, sort, page) async {
        return CommentsPage.empty(target: target, sort: sort, page: page);
      }),
      submitHandler = ((target, content, parentId, isSpoiler) {
        throw UnimplementedError('submitComment is not configured.');
      });

  final CommentsLoadHandler handler;
  final CommentsSubmitHandler submitHandler;
  final calls = <({CommentTarget target, CommentsSort sort, int page})>[];
  final submitCalls =
      <
        ({CommentTarget target, String content, int parentId, bool isSpoiler})
      >[];

  @override
  Future<CommentsPage> loadPage({
    required CommentTarget target,
    required CommentsSort sort,
    required int page,
  }) {
    calls.add((target: target, sort: sort, page: page));
    return handler(target, sort, page);
  }

  @override
  Future<PublicComment> submitComment({
    required CommentTarget target,
    required String content,
    int parentId = 0,
    bool isSpoiler = false,
  }) {
    submitCalls.add((
      target: target,
      content: content,
      parentId: parentId,
      isSpoiler: isSpoiler,
    ));
    return submitHandler(target, content, parentId, isSpoiler);
  }
}
