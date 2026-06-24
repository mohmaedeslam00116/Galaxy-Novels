import 'package:galaxy_novels_app/features/novel_engagement/application/novel_engagement_repository.dart';
import 'package:galaxy_novels_app/features/novel_engagement/domain/novel_user_state.dart';

class FakeNovelEngagementRepository implements NovelEngagementRepository {
  FakeNovelEngagementRepository({
    this.state,
    this.loadHandler,
    this.submitHandler,
  });

  final NovelUserState? state;
  final Future<NovelUserState> Function(int novelId)? loadHandler;
  final Future<int> Function(int novelId, int rating)? submitHandler;
  final List<int> loadedNovelIds = [];
  final List<(int, int)> submittedRatings = [];

  @override
  Future<NovelUserState> loadState(int novelId) async {
    loadedNovelIds.add(novelId);
    final handler = loadHandler;
    if (handler != null) {
      return handler(novelId);
    }
    return state ?? (throw StateError('No fake novel state configured.'));
  }

  @override
  Future<int> submitRating({required int novelId, required int rating}) async {
    submittedRatings.add((novelId, rating));
    final handler = submitHandler;
    return handler == null ? rating : handler(novelId, rating);
  }
}
