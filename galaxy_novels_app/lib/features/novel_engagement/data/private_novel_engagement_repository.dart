import '../../../core/network/private_api_client.dart';
import '../application/novel_engagement_repository.dart';
import '../domain/novel_user_state.dart';

class PrivateNovelEngagementRepository implements NovelEngagementRepository {
  const PrivateNovelEngagementRepository({required PrivateApiClient client})
    : _client = client;

  final PrivateApiClient _client;

  @override
  Future<NovelUserState> loadState(int novelId) async {
    if (novelId <= 0) {
      throw RangeError.value(novelId, 'novelId');
    }
    final response = await _client.getAuthenticatedWithNonceRefresh(
      'me/novels/$novelId',
    );
    return NovelUserState.fromResponse(response, expectedNovelId: novelId);
  }

  @override
  Future<int> submitRating({required int novelId, required int rating}) async {
    if (novelId <= 0) {
      throw RangeError.value(novelId, 'novelId');
    }
    if (rating < 1 || rating > 5) {
      throw RangeError.range(rating, 1, 5, 'rating');
    }

    final response = await _client.postAuthenticatedWithNonceRefresh(
      'ratings/novel/$novelId',
      body: {'rating': rating},
    );
    final savedRating = int.tryParse(response['rating']?.toString() ?? '') ?? 0;
    if (savedRating < 1 || savedRating > 5) {
      throw const FormatException('Invalid saved rating payload.');
    }
    return savedRating;
  }
}
