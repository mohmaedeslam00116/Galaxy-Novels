import 'package:flutter/material.dart';

import '../../../data/models/chapter_summary.dart';
import '../../../data/models/catalog_data.dart';
import '../../../data/models/novel_summary.dart';
import '../../../data/models/reading_progress.dart' as reading_history;
import '../domain/home_customization.dart';
import '../domain/home_recommendations.dart';
import 'home_continue_reading.dart';
import 'home_density_metrics.dart';
import 'home_updated_novels_strip.dart';
import 'home_recommendations_section.dart';
import 'latest_updates_section.dart';

class HomeSectionCardPreview extends StatelessWidget {
  const HomeSectionCardPreview({
    required this.section,
    required this.customization,
    super.key,
  });

  final HomeSectionId section;
  final HomeCustomization customization;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'معاينة بطاقة ${_sectionTitle(section)}',
      child: Container(
        key: ValueKey('home-section-card-preview-${section.name}'),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.24),
          ),
        ),
        child: IgnorePointer(child: _sectionPreview()),
      ),
    );
  }

  Widget _sectionPreview() {
    return switch (section) {
      HomeSectionId.continueReading => HomeContinueReadingStrip(
        entries: [_sampleReading],
        onOpen: (_) {},
        customization: customization,
      ),
      HomeSectionId.becauseYouRead => HomeRecommendationsStrip(
        items: const [_sampleRecommendation],
        onOpen: (_) {},
        onHide: (_) {},
        customization: customization,
      ),
      HomeSectionId.updatedNovels => HomeUpdatedNovelsStrip(
        novels: const [_sampleNovel],
        onNovelTap: (_) {},
        customization: customization,
      ),
      HomeSectionId.latestUpdates => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: customization.density.horizontalPadding,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: HomeLatestUpdateCardPreview(
            chapter: _sampleChapter,
            novel: _sampleNovel,
            customization: customization,
          ),
        ),
      ),
    };
  }
}

String _sectionTitle(HomeSectionId section) => switch (section) {
  HomeSectionId.continueReading => 'أكمل القراءة',
  HomeSectionId.becauseYouRead => 'لأنك قرأت…',
  HomeSectionId.updatedNovels => 'روايات محدثة',
  HomeSectionId.latestUpdates => 'آخر التحديثات',
};

final _sampleReading = HomeContinueReadingEntry.fromLocal(
  reading_history.ReadingProgress(
    novelId: 901,
    novelTitle: 'بوابة النجوم',
    chapterId: 902,
    chapterTitle: 'الفصل 37',
    contentApi: '/preview/chapter/902',
    updatedAt: DateTime.utc(2026, 8, 1),
    chapterPosition: 37,
    chaptersTotal: 120,
  ),
);

const _sampleNovel = NovelSummary(
  id: 901,
  title: 'بوابة النجوم',
  url: '/preview/novel/901',
  coverThumbnail: '',
  statusLabel: 'مستمرة',
  genres: ['خيال'],
  chaptersCount: 120,
  manifest: '/preview/manifest/901',
);

const _sampleRecommendation = HomeRecommendation(
  novel: CatalogNovel(
    id: 903,
    title: 'عرش المجرات',
    originalTitle: '',
    url: '/preview/novel/903',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: 'ongoing',
    statusLabel: 'مستمرة',
    genres: [CatalogGenre(id: 1, name: 'خيال', slug: 'fantasy')],
    chaptersCount: 84,
    ratingAverage: 0,
    ratingCount: 0,
    views: 1200,
    updatedAt: null,
    manifest: '/preview/manifest/903',
  ),
  sharedGenres: ['خيال'],
);

const _sampleChapter = ChapterSummary(
  id: 902,
  novelId: 901,
  novelTitle: 'بوابة النجوم',
  label: 'الفصل 120',
  title: 'ما وراء البوابة',
  dateLabel: 'اليوم',
  url: '/preview/chapter/902',
  manifest: '/preview/manifest/901',
  chapters: [
    ChapterSummaryItem(
      id: 902,
      label: 'الفصل 120',
      title: 'ما وراء البوابة',
      dateLabel: 'اليوم',
      url: '/preview/chapter/902',
    ),
    ChapterSummaryItem(
      id: 901,
      label: 'الفصل 119',
      title: 'الطريق الأخير',
      dateLabel: 'أمس',
      url: '/preview/chapter/901',
    ),
  ],
);
