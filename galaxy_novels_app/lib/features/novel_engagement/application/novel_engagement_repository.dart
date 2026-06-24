import '../domain/novel_user_state.dart';

abstract class NovelEngagementRepository {
  Future<NovelUserState> loadState(int novelId);

  Future<int> submitRating({required int novelId, required int rating});
}
