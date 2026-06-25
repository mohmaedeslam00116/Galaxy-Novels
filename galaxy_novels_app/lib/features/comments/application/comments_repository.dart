import '../domain/comment_interaction.dart';
import '../domain/comment_target.dart';
import '../domain/comments_page.dart';
import '../domain/public_comment.dart';

abstract class CommentsRepository {
  Future<CommentsPage> loadPage({
    required CommentTarget target,
    required CommentsSort sort,
    required int page,
  });

  Future<PublicComment> submitComment({
    required CommentTarget target,
    required String content,
    int parentId = 0,
    bool isSpoiler = false,
  });

  Future<CommentVoteResult> voteComment({
    required int commentId,
    CommentVote? vote,
  });

  Future<CommentReactionResult> reactToTarget({
    required CommentTarget target,
    CommentReaction? reaction,
  });
}
