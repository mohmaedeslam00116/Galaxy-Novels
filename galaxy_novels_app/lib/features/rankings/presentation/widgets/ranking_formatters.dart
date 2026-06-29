import '../../../../data/models/catalog_data.dart';

String rankingSubtitle(CatalogNovel novel) {
  final genres = novel.genres.take(2).map((genre) => genre.name).join('، ');
  if (genres.isNotEmpty) {
    return genres;
  }
  return novel.statusLabel;
}

String rankingCoverUrl(CatalogNovel novel) {
  if (novel.coverMedium.isNotEmpty) {
    return novel.coverMedium;
  }
  return novel.coverThumbnail;
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
