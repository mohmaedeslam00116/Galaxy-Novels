import '../../../core/network/private_api_client.dart';
import '../application/comments_repository.dart';
import '../domain/comment_interaction.dart';
import '../domain/comment_target.dart';
import '../domain/comments_page.dart';
import '../domain/public_comment.dart';

class PublicCommentsRepository implements CommentsRepository {
  const PublicCommentsRepository({required PrivateApiClient client})
    : _client = client;

  final PrivateApiClient _client;

  @override
  Future<CommentsPage> loadPage({
    required CommentTarget target,
    required CommentsSort sort,
    required int page,
  }) async {
    if (page <= 0) {
      throw RangeError.value(page, 'page', 'Page must be positive.');
    }

    final response = await _client.getPublic(
      'comments/${target.pathSegment}?page=$page&sort=${sort.apiValue}',
    );
    return CommentsPage.fromJson(
      response,
      expectedTarget: target,
      expectedSort: sort,
      expectedPage: page,
    );
  }

  @override
  Future<PublicComment> submitComment({
    required CommentTarget target,
    required String content,
    int parentId = 0,
    bool isSpoiler = false,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(content, 'content', 'Comment cannot be empty.');
    }
    if (parentId < 0) {
      throw RangeError.value(
        parentId,
        'parentId',
        'Parent id cannot be negative.',
      );
    }

    final response = await _client.postAuthenticated(
      'comments/${target.pathSegment}',
      body: {
        'content': trimmed,
        'parent_id': parentId,
        'is_spoiler': isSpoiler,
      },
    );
    return PublicComment.fromJson(_commentPayload(response));
  }

  @override
  Future<CommentVoteResult> voteComment({
    required int commentId,
    CommentVote? vote,
  }) async {
    if (commentId <= 0) {
      throw RangeError.value(
        commentId,
        'commentId',
        'Comment id must be positive.',
      );
    }

    final response = await _client.postAuthenticated(
      'comments/$commentId/vote',
      body: {'vote': vote?.apiValue ?? ''},
    );
    return CommentVoteResult.fromJson(response);
  }

  @override
  Future<CommentReactionResult> reactToTarget({
    required CommentTarget target,
    CommentReaction? reaction,
  }) async {
    final response = await _client.postAuthenticated(
      'comments/${target.pathSegment}/reaction',
      body: {'reaction': reaction?.apiValue ?? ''},
    );
    return CommentReactionResult.fromJson(response);
  }

  Map<String, dynamic> _commentPayload(Map<String, dynamic> response) {
    final wrapped = response['comment'];
    if (wrapped is Map) {
      return wrapped.map((key, value) => MapEntry(key.toString(), value));
    }
    final data = response['data'];
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return response;
  }
}
