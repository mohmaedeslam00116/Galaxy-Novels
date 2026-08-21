import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/galaxy_novels_app.dart';
import 'package:galaxy_novels_app/data/models/home_data.dart';
import 'package:galaxy_novels_app/data/models/novel_summary.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart'
    as local_progress;
import 'package:galaxy_novels_app/data/models/search_index_data.dart';
import 'package:galaxy_novels_app/data/repositories/home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/data/repositories/search_repository.dart';
import 'package:galaxy_novels_app/features/ads/application/home_ad_repository.dart';
import 'package:galaxy_novels_app/features/home/application/home_recommendation_exclusion_repository.dart';
import 'package:galaxy_novels_app/features/home/application/home_customization_repository.dart';
import 'package:galaxy_novels_app/features/home/domain/home_customization.dart';
import 'package:galaxy_novels_app/features/home/domain/home_recommendations.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_recommendations_section.dart';

void main() {
  testWidgets(
    'recommendations render from latest reading and support hide undo',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final exclusions = _MemoryExclusionRepository();

      await tester.pumpWidget(
        GalaxyNovelsApp(
          homeRepository: const _HomeRepository(),
          searchRepository: const _SearchRepository(),
          readingHistoryRepository: _HistoryRepository(),
          homeRecommendationExclusionRepository: exclusions,
          homeCustomizationRepository: _CustomizationRepository(),
          homeAdRepository: const NoopHomeAdRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('لأنك قرأت'), findsOneWidget);
      expect(find.text('«الرواية المرجعية»'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('recommendation-card-2')),
        findsOneWidget,
      );
      expect(find.textContaining('مشترك في: خيال وأكشن'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('recommendation-menu-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('لا تقترح هذه الرواية'));
      await tester.pumpAndSettle();

      expect(exclusions.ids, contains(2));
      expect(find.byKey(const ValueKey('recommendation-card-2')), findsNothing);
      expect(
        find.byKey(const ValueKey('recommendation-card-3')),
        findsOneWidget,
      );

      await tester.tap(find.text('تراجع'));
      await tester.pumpAndSettle();
      expect(exclusions.ids, isNot(contains(2)));
      expect(
        find.byKey(const ValueKey('recommendation-card-2')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('one recommendation uses the full-width editorial treatment', (
    tester,
  ) async {
    final recommendations = buildHomeRecommendations(
      history: await _HistoryRepository().load(),
      index: await const _SearchRepository().loadSearchIndex(),
      excludedNovelIds: const {},
      limit: 1,
    )!.items;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeRecommendationsStrip(
            items: recommendations,
            customization: HomeCustomization.defaults,
            onOpen: (_) {},
            onHide: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('galaxy-adaptive-single')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('recommendation-card-2')), findsOneWidget);
  });

  testWidgets(
    'recommendation templates and sizes fit a narrow large-text view',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final recommendations = buildHomeRecommendations(
        history: await _HistoryRepository().load(),
        index: await const _SearchRepository().loadSearchIndex(),
        excludedNovelIds: const {},
        limit: 12,
      )!.items;

      for (final template in RecommendedNovelCardTemplate.values) {
        for (final size in HomeCardSize.values) {
          final customization = HomeCustomization.defaults.copyWith(
            recommendedNovelsTemplate: template,
            cardSizes: {
              ...HomeCustomization.defaults.cardSizes,
              HomeSectionId.becauseYouRead: size,
            },
          );
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 900),
                  textScaler: TextScaler.linear(2),
                ),
                child: Scaffold(
                  body: HomeRecommendationsStrip(
                    items: recommendations,
                    customization: customization,
                    onOpen: (_) {},
                    onHide: (_) {},
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(
            find.byKey(const ValueKey('recommendation-card-2')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}

class _HomeRepository implements HomeRepository {
  const _HomeRepository();

  @override
  Future<HomeData> loadHome() async => const HomeData(
    continueReading: null,
    latestChapters: [],
    recentNovels: [
      NovelSummary(
        id: 9,
        title: 'رواية محدثة',
        url: '/novel/9',
        coverThumbnail: '',
        statusLabel: 'مستمرة',
        genres: ['خيال'],
        chaptersCount: 10,
        manifest: '/manifest/9.json',
      ),
    ],
  );
}

class _SearchRepository implements SearchRepository {
  const _SearchRepository();

  @override
  Future<SearchIndex> loadSearchIndex() async => const SearchIndex(
    items: [
      SearchIndexItem(
        id: 1,
        title: 'الرواية المرجعية',
        originalTitle: '',
        url: '/novel/1',
        cover: '',
        genres: ['خيال', 'أكشن'],
        chaptersCount: 100,
        statusLabel: 'مستمرة',
        views: 100,
        normalizedSearch: '',
        manifest: '/manifest/1.json',
      ),
      SearchIndexItem(
        id: 2,
        title: 'المرشح الأقوى',
        originalTitle: '',
        url: '/novel/2',
        cover: '',
        genres: ['خيال', 'أكشن'],
        chaptersCount: 80,
        statusLabel: 'مستمرة',
        views: 90,
        normalizedSearch: '',
        manifest: '/manifest/2.json',
      ),
      SearchIndexItem(
        id: 3,
        title: 'المرشح التالي',
        originalTitle: '',
        url: '/novel/3',
        cover: '',
        genres: ['خيال'],
        chaptersCount: 60,
        statusLabel: 'مكتملة',
        views: 70,
        normalizedSearch: '',
        manifest: '/manifest/3.json',
      ),
    ],
  );
}

class _HistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  @override
  Future<List<local_progress.ReadingProgress>> load() async => [
    local_progress.ReadingProgress(
      novelId: 1,
      novelTitle: 'الرواية المرجعية',
      chapterId: 4,
      chapterTitle: 'الفصل 4',
      contentApi: '/chapter/4',
      updatedAt: DateTime.utc(2026, 8, 6),
    ),
  ];

  @override
  Future<void> record(local_progress.ReadingProgress progress) async {}
}

class _MemoryExclusionRepository extends ChangeNotifier
    implements HomeRecommendationExclusionRepository {
  final Set<int> ids = {};

  @override
  Future<Set<int>> load() async => Set.unmodifiable(ids);

  @override
  Future<void> hide(int novelId) async {
    ids.add(novelId);
    notifyListeners();
  }

  @override
  Future<void> restore(int novelId) async {
    ids.remove(novelId);
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    ids.clear();
    notifyListeners();
  }
}

class _CustomizationRepository extends ValueNotifier<HomeCustomization>
    implements HomeCustomizationRepository {
  _CustomizationRepository() : super(HomeCustomization.defaults);

  @override
  Future<void> load() async {}

  @override
  Future<void> update(HomeCustomization customization) async {
    value = customization;
  }
}
