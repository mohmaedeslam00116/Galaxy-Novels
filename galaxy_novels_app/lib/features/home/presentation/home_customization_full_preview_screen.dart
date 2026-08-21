import 'package:flutter/material.dart';

import '../../../data/models/chapter_summary.dart';
import '../../../data/models/catalog_data.dart';
import '../../../data/models/novel_summary.dart';
import '../../../data/models/reading_progress.dart' as reading_history;
import '../application/home_customization_draft_controller.dart';
import '../domain/home_customization.dart';
import '../domain/home_recommendations.dart';
import 'home_card_appearance.dart';
import 'home_continue_reading.dart';
import 'home_customization_labels.dart';
import 'home_updated_novels_strip.dart';
import 'home_recommendations_section.dart';
import 'home_section_header.dart';
import 'latest_updates_section.dart';

class HomeCustomizationFullPreviewScreen extends StatelessWidget {
  const HomeCustomizationFullPreviewScreen({
    required this.controller,
    super.key,
  });

  final HomeCustomizationDraftController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final customization = controller.draft;
        return Scaffold(
          appBar: AppBar(title: const Text('معاينة الرئيسية')),
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _PreviewBanner()),
              ..._contentSlivers(context, customization),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _contentSlivers(
    BuildContext context,
    HomeCustomization customization,
  ) {
    final visibleSections = customization.sectionOrder
        .where(customization.isVisible)
        .toList(growable: false);
    final contentSlivers = <Widget>[];
    for (var index = 0; index < visibleSections.length; index++) {
      final section = visibleSections[index];
      final slivers = _sectionSlivers(context, section, customization);
      if (customization.containerFor(section) == HomeSectionContainer.open) {
        contentSlivers.addAll(slivers);
      } else {
        contentSlivers.add(
          DecoratedSliver(
            decoration: homeSectionPanelDecoration(context, customization),
            sliver: SliverPadding(
              padding: const EdgeInsets.only(bottom: 12),
              sliver: SliverMainAxisGroup(slivers: slivers),
            ),
          ),
        );
      }
      if (index == 0) {
        contentSlivers.add(const SliverToBoxAdapter(child: _PreviewAdMarker()));
      }
    }
    return contentSlivers;
  }

  List<Widget> _sectionSlivers(
    BuildContext context,
    HomeSectionId section,
    HomeCustomization customization,
  ) {
    return switch (section) {
      HomeSectionId.continueReading => [
        SliverToBoxAdapter(
          child: _PreviewSectionHeader(
            section: section,
            customization: customization,
            onEdit: () => _returnSection(context, section),
          ),
        ),
        SliverToBoxAdapter(
          child: HomeContinueReadingStrip(
            entries: _sampleReadingEntries,
            onOpen: (_) => _returnSection(context, section),
            customization: customization,
          ),
        ),
      ],
      HomeSectionId.becauseYouRead => [
        SliverToBoxAdapter(
          child: _PreviewSectionHeader(
            section: section,
            customization: customization,
            onEdit: () => _returnSection(context, section),
          ),
        ),
        if (customization.recommendedNovelsLayout ==
            RecommendedNovelsLayout.horizontalStrip)
          SliverToBoxAdapter(
            child: HomeRecommendationsStrip(
              items: _sampleRecommendations,
              onOpen: (_) => _returnSection(context, section),
              onHide: (_) => _returnSection(context, section),
              customization: customization,
            ),
          )
        else
          HomeRecommendationsGrid(
            items: _sampleRecommendations,
            onOpen: (_) => _returnSection(context, section),
            onHide: (_) => _returnSection(context, section),
            customization: customization,
          ),
      ],
      HomeSectionId.updatedNovels => [
        SliverToBoxAdapter(
          child: _PreviewSectionHeader(
            section: section,
            customization: customization,
            onEdit: () => _returnSection(context, section),
          ),
        ),
        if (customization.updatedNovelsLayout ==
            UpdatedNovelsLayout.horizontalStrip)
          SliverToBoxAdapter(
            child: HomeUpdatedNovelsStrip(
              novels: _sampleNovels,
              onNovelTap: (_) => _returnSection(context, section),
              customization: customization,
            ),
          )
        else
          HomeUpdatedNovelsGrid(
            novels: _sampleNovels,
            onNovelTap: (_) => _returnSection(context, section),
            customization: customization,
          ),
      ],
      HomeSectionId.latestUpdates => [
        LatestUpdatesSection(
          chapters: _sampleChapters,
          novelsById: {for (final novel in _sampleNovels) novel.id: novel},
          onNovelTap: (_) => _returnSection(context, section),
          onHeaderAction: () => _returnSection(context, section),
          headerActionLabel: 'تعديل',
          customization: customization,
        ),
      ],
    };
  }

  void _returnSection(BuildContext context, HomeSectionId section) {
    Navigator.of(context).pop(section);
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_outlined, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'وضع المعاينة — اضغط على أي قسم لتعديله',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSectionHeader extends StatelessWidget {
  const _PreviewSectionHeader({
    required this.section,
    required this.customization,
    required this.onEdit,
  });

  final HomeSectionId section;
  final HomeCustomization customization;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return HomeSectionHeader(
      title: homeSectionTitle(section),
      icon: switch (section) {
        HomeSectionId.continueReading => Icons.menu_book_rounded,
        HomeSectionId.becauseYouRead => Icons.auto_awesome_outlined,
        HomeSectionId.updatedNovels => Icons.auto_stories_outlined,
        HomeSectionId.latestUpdates => Icons.schedule_rounded,
      },
      subtitle: section == HomeSectionId.becauseYouRead
          ? '«بوابة النجوم»'
          : null,
      actionKey: ValueKey('preview-edit-section-${section.name}'),
      actionLabel: 'تعديل',
      onAction: onEdit,
      customization: customization,
    );
  }
}

class _PreviewAdMarker extends StatelessWidget {
  const _PreviewAdMarker();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('home-preview-ad-placeholder'),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      constraints: const BoxConstraints(minHeight: 54),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        'موضع إعلان الرئيسية',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

final _sampleReadingEntries = [
  HomeContinueReadingEntry.fromLocal(
    reading_history.ReadingProgress(
      novelId: 1,
      novelTitle: 'بوابة النجوم',
      chapterId: 37,
      chapterTitle: 'المدينة البعيدة',
      contentApi: '/preview/chapter/37',
      updatedAt: DateTime.utc(2026, 8, 1),
      chapterPosition: 37,
      chaptersTotal: 120,
    ),
  ),
  HomeContinueReadingEntry.fromLocal(
    reading_history.ReadingProgress(
      novelId: 2,
      novelTitle: 'سيد الأسرار',
      chapterId: 18,
      chapterTitle: 'رسالة منتصف الليل',
      contentApi: '/preview/chapter/18',
      updatedAt: DateTime.utc(2026, 8, 2),
      chapterPosition: 18,
      chaptersTotal: 80,
    ),
  ),
];

const _sampleNovels = [
  NovelSummary(
    id: 1,
    title: 'بوابة النجوم',
    url: '/preview/novel/1',
    coverThumbnail: '',
    statusLabel: 'مستمرة',
    genres: ['خيال'],
    chaptersCount: 120,
    manifest: '/preview/manifest/1',
  ),
  NovelSummary(
    id: 2,
    title: 'سيد الأسرار',
    url: '/preview/novel/2',
    coverThumbnail: '',
    statusLabel: 'مكتملة',
    genres: ['غموض'],
    chaptersCount: 80,
    manifest: '/preview/manifest/2',
  ),
  NovelSummary(
    id: 3,
    title: 'وريث العرش الأخير',
    url: '/preview/novel/3',
    coverThumbnail: '',
    statusLabel: 'مستمرة',
    genres: ['مغامرة'],
    chaptersCount: 64,
    manifest: '/preview/manifest/3',
  ),
];

const _sampleRecommendations = [
  HomeRecommendation(
    novel: CatalogNovel(
      id: 11,
      title: 'عرش المجرات',
      originalTitle: '',
      url: '/preview/novel/11',
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
      manifest: '/preview/manifest/11',
    ),
    sharedGenres: ['خيال'],
  ),
  HomeRecommendation(
    novel: CatalogNovel(
      id: 12,
      title: 'رحلة ما وراء النجوم',
      originalTitle: '',
      url: '/preview/novel/12',
      coverThumbnail: '',
      coverMedium: '',
      statusKey: 'complete',
      statusLabel: 'مكتملة',
      genres: [CatalogGenre(id: 1, name: 'خيال', slug: 'fantasy')],
      chaptersCount: 156,
      ratingAverage: 0,
      ratingCount: 0,
      views: 900,
      updatedAt: null,
      manifest: '/preview/manifest/12',
    ),
    sharedGenres: ['خيال'],
  ),
];

const _sampleChapters = [
  ChapterSummary(
    id: 301,
    novelId: 1,
    novelTitle: 'بوابة النجوم',
    label: 'الفصل 120',
    title: 'ما وراء البوابة',
    dateLabel: 'اليوم',
    url: '/preview/chapter/301',
    contentApi: '/preview/content/301',
    manifest: '/preview/manifest/1',
  ),
  ChapterSummary(
    id: 302,
    novelId: 2,
    novelTitle: 'سيد الأسرار',
    label: 'الفصل 80',
    title: 'الإجابة الأخيرة',
    dateLabel: 'أمس',
    url: '/preview/chapter/302',
    contentApi: '/preview/content/302',
    manifest: '/preview/manifest/2',
  ),
];
