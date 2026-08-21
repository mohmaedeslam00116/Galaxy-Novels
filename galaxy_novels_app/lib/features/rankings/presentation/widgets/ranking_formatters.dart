import '../../../../data/models/catalog_data.dart';

String rankingCoverUrl(CatalogNovel novel) {
  return novel.bestCover;
}

String rankingPeriodLabel(String period) {
  switch (period.toLowerCase()) {
    case 'day':
    case 'today':
      return 'اليوم';
    case 'week':
      return 'هذا الأسبوع';
    case 'month':
      return 'هذا الشهر';
    case 'year':
      return 'هذا العام';
    case 'all':
    case 'all_time':
      return 'كل الوقت';
    case '':
      return 'أحدث إحصاء';
    default:
      return period;
  }
}

String compactRankingNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

String? rankingRatingLabel(CatalogNovel novel) {
  if (novel.ratingAverage <= 0) return null;
  return novel.ratingAverage.toStringAsFixed(1);
}

String rankingSemanticLabel(CatalogNovel novel, int rank) {
  final rating = rankingRatingLabel(novel);
  final ratingText = rating == null ? '' : '، التقييم $rating من 5';
  return '${novel.title}، الترتيب $rank، '
      '${compactRankingNumber(novel.views)} مشاهدة$ratingText';
}
