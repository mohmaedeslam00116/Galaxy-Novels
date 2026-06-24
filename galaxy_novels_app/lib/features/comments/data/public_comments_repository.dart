import '../../../core/network/private_api_client.dart';
import '../application/comments_repository.dart';
import '../domain/comment_target.dart';
import '../domain/comments_page.dart';

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
}
