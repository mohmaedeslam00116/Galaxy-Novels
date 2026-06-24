import '../models/rankings_data.dart';

abstract class RankingsRepository {
  Future<RankingsData> loadRankings();
}
