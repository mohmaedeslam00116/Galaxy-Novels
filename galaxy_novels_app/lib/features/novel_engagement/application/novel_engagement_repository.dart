import '../domain/novel_user_state.dart';

abstract class NovelEngagementRepository {
  Future<NovelUserState> loadState(int novelId);

  Future<int> submitRating({required int novelId, required int rating});
}

class NoopNovelEngagementRepository implements NovelEngagementRepository {
  const NoopNovelEngagementRepository();

  @override
  Future<NovelUserState> loadState(int novelId) async {
    throw UnsupportedError('Novel engagement is not configured.');
  }

  @override
  Future<int> submitRating({required int novelId, required int rating}) async {
    throw UnsupportedError('Novel engagement is not configured.');
  }
}
