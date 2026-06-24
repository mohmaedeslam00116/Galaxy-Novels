import '../domain/comment_target.dart';
import '../domain/comments_page.dart';

abstract class CommentsRepository {
  Future<CommentsPage> loadPage({
    required CommentTarget target,
    required CommentsSort sort,
    required int page,
  });
}
