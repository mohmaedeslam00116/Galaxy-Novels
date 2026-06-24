import 'package:galaxy_novels_app/features/comments/application/comments_repository.dart';
import 'package:galaxy_novels_app/features/comments/domain/comment_target.dart';
import 'package:galaxy_novels_app/features/comments/domain/comments_page.dart';

typedef CommentsLoadHandler =
    Future<CommentsPage> Function(
      CommentTarget target,
      CommentsSort sort,
      int page,
    );

class FakeCommentsRepository implements CommentsRepository {
  FakeCommentsRepository({required this.handler});

  FakeCommentsRepository.empty()
    : handler = ((target, sort, page) async {
        return CommentsPage.empty(target: target, sort: sort, page: page);
      });

  final CommentsLoadHandler handler;
  final calls = <({CommentTarget target, CommentsSort sort, int page})>[];

  @override
  Future<CommentsPage> loadPage({
    required CommentTarget target,
    required CommentsSort sort,
    required int page,
  }) {
    calls.add((target: target, sort: sort, page: page));
    return handler(target, sort, page);
  }
}
