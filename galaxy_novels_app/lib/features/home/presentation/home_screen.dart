import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/analytics/app_screen_names.dart';
import '../../../data/models/chapter_summary.dart';
import '../../../data/models/home_data.dart';
import '../../../data/models/novel_summary.dart';
import '../../../data/models/reading_progress.dart' as local_progress;
import '../../../data/models/search_index_data.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../data/repositories/reading_history_repository.dart';
import '../../../data/repositories/search_repository.dart';
import '../../../design_system/patterns/galaxy_section_band.dart';
import '../../../shared/widgets/app_async_state.dart';
import '../../ads/presentation/standard_ad_gate.dart';
import '../../app_update/presentation/home_update_banner.dart';
import '../../catalog/domain/catalog_query.dart';
import '../../catalog/presentation/catalog_screen.dart';
import '../../novel_details/presentation/novel_details_navigation.dart';
import '../../novel_details/presentation/novel_details_transition.dart';
import '../../reader/presentation/reader_screen.dart';
import '../application/home_customization_repository.dart';
import '../application/home_recommendation_exclusion_repository.dart';
import '../domain/home_customization.dart';
import '../domain/home_recommendations.dart';
import 'home_loading_skeleton.dart';
import 'home_novel_open_request.dart';
import 'home_sliver_app_bar.dart';
import 'home_section_header.dart';
import 'home_continue_reading.dart';
import 'home_updated_novels_strip.dart';
import 'home_recommendations_section.dart';
import 'latest_updates_section.dart';

typedef _HomeSectionContent = ({
  List<HomeContinueReadingEntry> continueReading,
  List<ChapterSummary> latestChapters,
  Map<int, NovelSummary> novelsById,
  HomeRecommendationResult? recommendations,
  List<NovelSummary> updatedNovels,
});

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeRepository? _repository;
  ReadingHistoryRepository? _historyRepository;
  SearchRepository? _searchRepository;
  HomeRecommendationExclusionRepository? _exclusionRepository;
  Future<HomeData>? _homeFuture;
  Future<List<local_progress.ReadingProgress>>? _historyFuture;
  Future<SearchIndex>? _searchIndexFuture;
  Future<Set<int>>? _excludedNovelIdsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dependencies = AppDependencies.of(context);
    _bindHomeRepository(dependencies.homeRepository);
    _bindHistoryRepository(dependencies.readingHistoryRepository);
    _bindSearchRepository(dependencies.searchRepository);
    _bindExclusionRepository(
      dependencies.homeRecommendationExclusionRepository,
    );
  }

  @override
  void dispose() {
    _historyRepository?.removeListener(_refreshHistory);
    _exclusionRepository?.removeListener(_refreshExclusions);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customizationRepository = HomeCustomizationRepositoryScope.maybeOf(
      context,
    );
    if (customizationRepository == null) {
      return _homeFutureBuilder(HomeCustomization.defaults);
    }
    return ValueListenableBuilder<HomeCustomization>(
      valueListenable: customizationRepository,
      builder: (context, customization, child) {
        return _homeFutureBuilder(customization);
      },
    );
  }

  Widget _homeFutureBuilder(HomeCustomization customization) {
    return FutureBuilder<HomeData>(
      future: _homeFuture,
      builder: (context, snapshot) {
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        return AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _homeSnapshot(snapshot, customization),
        );
      },
    );
  }

  Widget _homeSnapshot(
    AsyncSnapshot<HomeData> snapshot,
    HomeCustomization customization,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return _homeScroll(
        key: const ValueKey('home-loading-scroll'),
        slivers: const [SliverToBoxAdapter(child: HomeLoadingSkeleton())],
      );
    }
    if (snapshot.hasError || !snapshot.hasData) {
      return _homeScroll(
        key: const ValueKey('home-error-scroll'),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: SafeArea(
              top: false,
              child: AppAsyncState.error(
                title: 'تعذر تحميل الرئيسية الآن',
                message: 'تحقق من اتصالك ثم أعد المحاولة.',
                onRetry: _retryHome,
              ),
            ),
          ),
        ],
      );
    }
    return KeyedSubtree(
      key: const ValueKey('home-ready-content'),
      child: _homeWithHistory(snapshot.data!, customization),
    );
  }

  Widget _homeScroll({required Key key, required List<Widget> slivers}) {
    return KeyedSubtree(
      key: key,
      child: CustomScrollView(
        key: const PageStorageKey<String>('home-scroll-position'),
        slivers: [
          const HomeSliverAppBar(),
          if (AppDependencies.of(context).appUpdateController
              case final controller?)
            HomeUpdateBannerSliver(controller: controller),
          ...slivers,
          const SliverToBoxAdapter(
            child: SafeArea(top: false, child: SizedBox(height: 28)),
          ),
        ],
      ),
    );
  }

  Widget _homeWithHistory(HomeData home, HomeCustomization customization) {
    return FutureBuilder<List<local_progress.ReadingProgress>>(
      future: _historyFuture,
      builder: (context, historySnapshot) {
        final history = historySnapshot.data ?? const [];
        if (home.isEmpty && history.isEmpty) {
          return _homeScroll(
            key: const ValueKey('home-empty-scroll'),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: SafeArea(
                  top: false,
                  child: AppAsyncState.empty(
                    title: 'لا توجد بيانات للعرض',
                    message: 'أعد المحاولة للحصول على أحدث الروايات.',
                    actionLabel: 'إعادة المحاولة',
                    onAction: _retryHome,
                  ),
                ),
              ),
            ],
          );
        }
        return _homeWithRecommendations(home, history, customization);
      },
    );
  }

  Widget _homeWithRecommendations(
    HomeData home,
    List<local_progress.ReadingProgress> history,
    HomeCustomization customization,
  ) {
    if (history.isEmpty ||
        !customization.isVisible(HomeSectionId.becauseYouRead)) {
      return _buildHome(home, history, customization, null);
    }
    final searchIndexFuture = _searchIndexFuture ??= _searchRepository
        ?.loadSearchIndex();
    if (searchIndexFuture == null) {
      return _buildHome(home, history, customization, null);
    }
    return FutureBuilder<SearchIndex>(
      future: searchIndexFuture,
      builder: (context, searchSnapshot) {
        final index = searchSnapshot.data;
        if (index == null) {
          return _buildHome(home, history, customization, null);
        }
        final exclusionsFuture = _excludedNovelIdsFuture;
        if (exclusionsFuture == null) {
          return _buildHome(home, history, customization, null);
        }
        return FutureBuilder<Set<int>>(
          future: exclusionsFuture,
          builder: (context, exclusionsSnapshot) {
            if (!exclusionsSnapshot.hasData) {
              return _buildHome(home, history, customization, null);
            }
            final recommendations = buildHomeRecommendations(
              history: history,
              index: index,
              excludedNovelIds: exclusionsSnapshot.data!,
              limit:
                  customization.itemLimitFor(HomeSectionId.becauseYouRead) ??
                  12,
            );
            return _buildHome(home, history, customization, recommendations);
          },
        );
      },
    );
  }

  Widget _buildHome(
    HomeData home,
    List<local_progress.ReadingProgress> history,
    HomeCustomization customization,
    HomeRecommendationResult? recommendations,
  ) {
    final content = _sectionContent(
      home,
      history,
      customization,
      recommendations,
    );
    final availableSections = _availableSections(content, customization);
    if (availableSections.isEmpty) {
      return _homeScroll(
        key: const ValueKey('home-no-sections-scroll'),
        slivers: const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: SafeArea(
              top: false,
              child: AppAsyncState.empty(
                title: 'لا توجد أقسام متاحة الآن',
                message: 'يمكنك تغيير الأقسام الظاهرة من تخصيص الرئيسية.',
              ),
            ),
          ),
        ],
      );
    }

    final slivers = _contentSlivers(availableSections, content, customization);
    return _homeScroll(
      key: const ValueKey('home-scroll-view'),
      slivers: slivers,
    );
  }

  _HomeSectionContent _sectionContent(
    HomeData home,
    List<local_progress.ReadingProgress> history,
    HomeCustomization customization,
    HomeRecommendationResult? recommendations,
  ) {
    final novelsById = {for (final novel in home.recentNovels) novel.id: novel};
    final continueReading = _limitedItems(
      _continueReadingEntries(home, history),
      HomeSectionId.continueReading,
      customization,
    );
    final updatedNovels = _limitedItems(
      home.recentNovels,
      HomeSectionId.updatedNovels,
      customization,
    );
    final latestChapters = _limitedItems(
      home.latestChapters,
      HomeSectionId.latestUpdates,
      customization,
    );
    return (
      continueReading: continueReading,
      latestChapters: latestChapters,
      novelsById: novelsById,
      recommendations: recommendations,
      updatedNovels: updatedNovels,
    );
  }

  List<HomeSectionId> _availableSections(
    _HomeSectionContent content,
    HomeCustomization customization,
  ) {
    return customization.sectionOrder
        .where((section) {
          if (!customization.isVisible(section)) {
            return false;
          }
          return switch (section) {
            HomeSectionId.continueReading => content.continueReading.isNotEmpty,
            HomeSectionId.becauseYouRead =>
              content.recommendations?.items.isNotEmpty ?? false,
            HomeSectionId.updatedNovels => content.updatedNovels.isNotEmpty,
            HomeSectionId.latestUpdates => content.latestChapters.isNotEmpty,
          };
        })
        .toList(growable: false);
  }

  List<Widget> _contentSlivers(
    List<HomeSectionId> sections,
    _HomeSectionContent content,
    HomeCustomization customization,
  ) {
    final slivers = <Widget>[];
    for (var index = 0; index < sections.length; index++) {
      slivers.addAll(
        _sliversForSection(sections[index], content, customization),
      );
      if (index == 0) {
        slivers.add(_homeAdSliver());
      }
    }

    return slivers;
  }

  List<Widget> _sliversForSection(
    HomeSectionId section,
    _HomeSectionContent content,
    HomeCustomization customization,
  ) {
    final sectionSlivers = switch (section) {
      HomeSectionId.continueReading => _continueReadingSlivers(
        content.continueReading,
        customization,
      ),
      HomeSectionId.becauseYouRead => _recommendationSlivers(
        content.recommendations!,
        customization,
      ),
      HomeSectionId.updatedNovels => _updatedNovelSlivers(
        content.updatedNovels,
        customization,
      ),
      HomeSectionId.latestUpdates => _latestSlivers(
        content.latestChapters,
        content.novelsById,
        customization,
      ),
    };
    if (customization.containerFor(section) == HomeSectionContainer.open) {
      return sectionSlivers;
    }
    return [
      DecoratedSliver(
        key: ValueKey('home-section-panel-${section.name}'),
        decoration: galaxySectionBandDecoration(context),
        sliver: SliverPadding(
          padding: const EdgeInsets.only(bottom: 12),
          sliver: SliverMainAxisGroup(slivers: sectionSlivers),
        ),
      ),
    ];
  }

  List<Widget> _continueReadingSlivers(
    List<HomeContinueReadingEntry> entries,
    HomeCustomization customization,
  ) {
    return [
      SliverToBoxAdapter(
        child: _sectionHeader(
          key: ValueKey('home-continue-reading-header'),
          title: 'أكمل القراءة',
          subtitle: 'عد إلى آخر فصل وصلت إليه',
          icon: Icons.menu_book_rounded,
          customization: customization,
        ),
      ),
      SliverToBoxAdapter(
        child: HomeContinueReadingStrip(
          entries: entries,
          onOpen: _openContinueReading,
          customization: customization,
        ),
      ),
    ];
  }

  List<Widget> _updatedNovelSlivers(
    List<NovelSummary> novels,
    HomeCustomization customization,
  ) {
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: _sectionHeader(
          key: ValueKey('home-recent-header'),
          title: 'روايات محدثة',
          subtitle: 'اكتشف الروايات التي وصلها محتوى جديد',
          icon: Icons.auto_stories_outlined,
          customization: customization,
        ),
      ),
    ];
    if (customization.updatedNovelsLayout ==
        UpdatedNovelsLayout.horizontalStrip) {
      slivers.add(
        SliverToBoxAdapter(
          child: HomeUpdatedNovelsStrip(
            novels: novels,
            onNovelTap: _openNovelDetails,
            onNovelOpen: _openHomeNovel,
            customization: customization,
          ),
        ),
      );
    } else {
      slivers.add(
        HomeUpdatedNovelsGrid(
          novels: novels,
          onNovelTap: _openNovelDetails,
          onNovelOpen: _openHomeNovel,
          customization: customization,
        ),
      );
    }
    return slivers;
  }

  List<Widget> _recommendationSlivers(
    HomeRecommendationResult recommendationSet,
    HomeCustomization customization,
  ) {
    final header = SliverToBoxAdapter(
      child: _sectionHeader(
        key: const ValueKey('home-recommendations-header'),
        title: 'لأنك قرأت',
        subtitle: '«${recommendationSet.anchorNovel.title}»',
        icon: Icons.auto_awesome_outlined,
        customization: customization,
        actionKey: const ValueKey('home-recommendations-more'),
        actionLabel: 'عرض المزيد',
        onAction: () =>
            _openRecommendationCatalog(recommendationSet.strongestGenre),
      ),
    );
    if (customization.recommendedNovelsLayout ==
        RecommendedNovelsLayout.horizontalStrip) {
      return [
        header,
        SliverToBoxAdapter(
          child: HomeRecommendationsStrip(
            items: recommendationSet.items,
            customization: customization,
            onOpen: _openRecommendation,
            onNovelOpen: _openHomeNovel,
            onHide: _hideRecommendation,
          ),
        ),
      ];
    }
    return [
      header,
      HomeRecommendationsGrid(
        items: recommendationSet.items,
        customization: customization,
        onOpen: _openRecommendation,
        onNovelOpen: _openHomeNovel,
        onHide: _hideRecommendation,
      ),
    ];
  }

  List<Widget> _latestSlivers(
    List<ChapterSummary> chapters,
    Map<int, NovelSummary> novelsById,
    HomeCustomization customization,
  ) {
    return [
      LatestUpdatesSection(
        key: const ValueKey('latest-updates-section'),
        chapters: chapters,
        novelsById: novelsById,
        onNovelTap: _openNovelDetails,
        onNovelOpen: _openHomeNovel,
        customization: customization,
      ),
    ];
  }

  HomeSectionHeader _sectionHeader({
    required Key key,
    required String title,
    required HomeCustomization customization,
    IconData? icon,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    Key? actionKey,
  }) {
    return HomeSectionHeader(
      key: key,
      title: title,
      icon: icon,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
      actionKey: actionKey,
      customization: customization,
    );
  }

  List<T> _limitedItems<T>(
    List<T> items,
    HomeSectionId section,
    HomeCustomization customization,
  ) {
    final limit = customization.itemLimitFor(section);
    if (limit == null || items.length <= limit) {
      return items;
    }
    return items.take(limit).toList(growable: false);
  }

  Widget _homeAdSliver() {
    final dependencies = AppDependencies.of(context);
    return SliverToBoxAdapter(
      child: StandardAdGate(
        key: const ValueKey('home-standard-ad-gate'),
        authRepository: dependencies.authRepository,
        builder: (context) {
          final ad = dependencies.homeAdRepository.buildHomeNativeAd(context);
          if (ad == null) {
            return const SizedBox.shrink();
          }
          return KeyedSubtree(
            key: const ValueKey('home-native-ad-slot'),
            child: ad,
          );
        },
      ),
    );
  }

  List<HomeContinueReadingEntry> _continueReadingEntries(
    HomeData home,
    List<local_progress.ReadingProgress> history,
  ) {
    if (history.isNotEmpty) {
      return history
          .map(HomeContinueReadingEntry.fromLocal)
          .toList(growable: false);
    }
    final remoteProgress = home.continueReading;
    return remoteProgress == null
        ? const []
        : [HomeContinueReadingEntry.fromHome(remoteProgress)];
  }

  void _bindHomeRepository(HomeRepository repository) {
    if (_repository == repository) {
      return;
    }
    _repository = repository;
    _homeFuture = repository.loadHome();
  }

  void _bindHistoryRepository(ReadingHistoryRepository repository) {
    if (_historyRepository == repository) {
      return;
    }
    _historyRepository?.removeListener(_refreshHistory);
    _historyRepository = repository;
    repository.addListener(_refreshHistory);
    _historyFuture = repository.load();
  }

  void _bindSearchRepository(SearchRepository repository) {
    if (_searchRepository == repository) return;
    _searchRepository = repository;
    _searchIndexFuture = null;
  }

  void _bindExclusionRepository(
    HomeRecommendationExclusionRepository? repository,
  ) {
    if (_exclusionRepository == repository) return;
    _exclusionRepository?.removeListener(_refreshExclusions);
    _exclusionRepository = repository;
    repository?.addListener(_refreshExclusions);
    _excludedNovelIdsFuture = repository?.load() ?? Future.value(const {});
  }

  void _retryHome() {
    setState(() {
      _homeFuture = _repository!.loadHome();
      _historyFuture = _historyRepository!.load();
      _searchIndexFuture = _searchRepository?.loadSearchIndex();
      _excludedNovelIdsFuture = _exclusionRepository?.load();
    });
  }

  void _refreshHistory() {
    final repository = _historyRepository;
    if (repository == null || !mounted) {
      return;
    }
    setState(() {
      _historyFuture = repository.load();
    });
  }

  void _refreshExclusions() {
    final repository = _exclusionRepository;
    if (!mounted || repository == null) return;
    setState(() {
      _excludedNovelIdsFuture = repository.load();
    });
  }

  void _openContinueReading(HomeContinueReadingEntry progress) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.reader),
        builder: (context) => ReaderScreen(
          contentApi: progress.contentApi,
          chapterTitle: progress.chapterTitle,
          novelTitle: progress.novelTitle,
          coverUrl: progress.coverUrl,
        ),
      ),
    );
  }

  void _openNovelDetails(String manifestPath) {
    if (manifestPath.isEmpty) {
      return;
    }
    unawaited(NovelDetailsNavigation.open(context, manifestPath: manifestPath));
  }

  void _openHomeNovel(HomeNovelOpenRequest request) {
    if (request.manifestPath.isEmpty) {
      return;
    }
    final transition = MediaQuery.disableAnimationsOf(context)
        ? null
        : NovelDetailsTransitionData(
            heroTag: request.heroTag,
            title: request.title,
            coverUrl: request.coverUrl,
          );
    unawaited(
      NovelDetailsNavigation.open(
        context,
        manifestPath: request.manifestPath,
        transition: transition,
      ),
    );
  }

  void _openRecommendation(HomeRecommendation recommendation) {
    _openNovelDetails(recommendation.novel.manifest);
  }

  Future<void> _hideRecommendation(HomeRecommendation recommendation) async {
    final repository = _exclusionRepository;
    if (repository == null) return;
    await repository.hide(recommendation.novel.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('لن نقترح «${recommendation.novel.title}»'),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () => repository.restore(recommendation.novel.id),
          ),
        ),
      );
  }

  void _openRecommendationCatalog(String genre) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.library),
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('روايات $genre')),
          body: CatalogScreen(initialQuery: CatalogQuery(genreName: genre)),
        ),
      ),
    );
  }
}
