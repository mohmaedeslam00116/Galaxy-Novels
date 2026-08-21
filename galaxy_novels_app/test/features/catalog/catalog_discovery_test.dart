import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/catalog/application/library_customization_repository.dart';
import 'package:galaxy_novels_app/features/catalog/domain/catalog_query.dart';
import 'package:galaxy_novels_app/features/catalog/domain/library_customization.dart';
import 'package:galaxy_novels_app/features/catalog/presentation/catalog_screen.dart';
import 'package:galaxy_novels_app/features/catalog/presentation/widgets/catalog_novel_tile.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
  testWidgets('catalog starts with compact controls and no rankings shortcut', (
    tester,
  ) async {
    await _pumpCatalog(tester);

    final search = find.byKey(const ValueKey('catalog-search-field'));
    final tools = find.byKey(const ValueKey('catalog-tools-row'));
    final summary = find.byKey(const ValueKey('catalog-results-summary'));
    final firstTile = find.byType(CatalogNovelTile).first;

    expect(find.byKey(const ValueKey('catalog-open-rankings')), findsNothing);
    expect(find.text('مكتبة الروايات'), findsNothing);
    expect(tester.getTopLeft(search).dy, lessThan(tester.getTopLeft(tools).dy));
    expect(
      tester.getTopLeft(tools).dy,
      lessThan(tester.getTopLeft(summary).dy),
    );
    expect(
      tester.getTopLeft(summary).dy,
      lessThan(tester.getTopLeft(firstTile).dy),
    );
  });

  testWidgets(
    'catalog keeps compact controls visible while initially loading',
    (tester) async {
      await _pumpCatalog(
        tester,
        catalogRepository: const _LoadingCatalogRepository(),
      );

      expect(
        find.byKey(const ValueKey('catalog-search-field')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('catalog-tools-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('catalog-sliver-grid')), findsNothing);
      expect(
        find.byKey(const ValueKey('catalog-results-summary')),
        findsNothing,
      );
    },
  );

  testWidgets('catalog keeps compact controls visible when initially empty', (
    tester,
  ) async {
    await _pumpCatalog(
      tester,
      catalogRepository: const FakeCatalogRepository([]),
    );

    expect(find.byKey(const ValueKey('catalog-search-field')), findsOneWidget);
    expect(find.text('لا توجد روايات في المكتبة الآن'), findsOneWidget);
    expect(find.text('0 رواية'), findsOneWidget);
  });

  testWidgets('catalog initial error keeps controls and retry recovers', (
    tester,
  ) async {
    final catalogRepository = _RetryingCatalogRepository();
    await _pumpCatalog(tester, catalogRepository: catalogRepository);

    expect(find.byKey(const ValueKey('catalog-search-field')), findsOneWidget);
    expect(find.text('0 رواية'), findsNothing);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(catalogRepository.callCount, 2);
    expect(find.byKey(const ValueKey('catalog-sliver-grid')), findsOneWidget);
  });

  testWidgets('catalog is RTL and keeps compact controls in one 48dp row', (
    tester,
  ) async {
    await _pumpCatalog(
      tester,
      size: const Size(320, 1200),
      textScaler: const TextScaler.linear(2),
    );

    final catalogContext = tester.element(find.byType(CatalogScreen));
    expect(Directionality.of(catalogContext), TextDirection.rtl);
    expect(find.byKey(const ValueKey('catalog-open-downloads')), findsNothing);
    final filter = find.byKey(const ValueKey('catalog-filter-button'));
    final sort = find.byKey(const ValueKey('catalog-sort-menu'));
    expect(
      tester.getTopLeft(sort).dy,
      closeTo(tester.getTopLeft(filter).dy, 0.1),
    );
    expect(tester.getSize(filter).height, 48);
    expect(tester.getSize(sort).height, 48);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected catalog filter keeps selected semantics in modal', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpCatalog(tester);

    await tester.tap(find.byKey(const ValueKey('catalog-filter-button')));
    await tester.pumpAndSettle();

    final dialogSemantics = tester.getSemantics(
      find.bySemanticsLabel('فلاتر المكتبة'),
    );
    expect(dialogSemantics.flagsCollection.scopesRoute, isTrue);
    expect(dialogSemantics.flagsCollection.namesRoute, isTrue);

    final ongoingChip = find.widgetWithText(FilterChip, 'مستمرة');
    await tester.tap(ongoingChip);
    await tester.pump();

    expect(
      tester.getSemantics(ongoingChip).flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );

    expect(find.bySemanticsLabel('فلاتر المكتبة'), findsOneWidget);
    semantics.dispose();
  });

  for (final (width, expectedColumns) in const [
    (320.0, 2),
    (390.0, 2),
    (600.0, 4),
    (840.0, 5),
    (1200.0, 5),
  ]) {
    testWidgets(
      'compact catalog uses $expectedColumns columns at ${width.toInt()}px',
      (tester) async {
        await _pumpCatalog(tester, size: Size(width, 1200));

        final grid = tester.widget<SliverGrid>(
          find.byKey(const ValueKey('catalog-sliver-grid')),
        );
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

        expect(delegate.crossAxisCount, expectedColumns);
        final tileWidth = tester
            .getSize(find.byType(CatalogNovelTile).first)
            .width;
        expect(tileWidth, inInclusiveRange(132, 176));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('catalog loading state uses a compact poster grid skeleton', (
    tester,
  ) async {
    await _pumpCatalog(
      tester,
      catalogRepository: const _LoadingCatalogRepository(),
    );

    expect(find.byKey(const ValueKey('catalog-grid-skeleton')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('catalog-skeleton-card-0')),
      findsOneWidget,
    );
    expect(find.byType(ListView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout toggle switches to list and persists the choice', (
    tester,
  ) async {
    final customizationRepository = _TestLibraryCustomizationRepository(
      LibraryCustomization.defaults,
    );
    await _pumpCatalog(
      tester,
      customizationRepository: customizationRepository,
    );

    await tester.tap(find.byKey(const ValueKey('catalog-layout-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('catalog-sliver-list')), findsOneWidget);
    expect(customizationRepository.value.layout, LibraryLayout.list);
  });

  testWidgets('explicit catalog query wins over the stored default sort', (
    tester,
  ) async {
    final customizationRepository = _TestLibraryCustomizationRepository(
      LibraryCustomization.defaults.copyWith(defaultSort: CatalogSort.rating),
    );
    await _pumpCatalog(
      tester,
      customizationRepository: customizationRepository,
      initialQuery: const CatalogQuery(sort: CatalogSort.views),
    );

    final sortMenu = tester.widget<PopupMenuButton<CatalogSort>>(
      find.byKey(const ValueKey('catalog-sort-menu')),
    );
    expect(sortMenu.initialValue, CatalogSort.views);
  });
}

Future<void> _pumpCatalog(
  WidgetTester tester, {
  Size size = const Size(390, 1200),
  TextScaler textScaler = TextScaler.noScaling,
  CatalogRepository catalogRepository = const FakeCatalogRepository(),
  LibraryCustomizationRepository? customizationRepository,
  CatalogQuery? initialQuery,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    _CatalogTestApp(
      size: size,
      textScaler: textScaler,
      catalogRepository: catalogRepository,
      customizationRepository: customizationRepository,
      initialQuery: initialQuery,
    ),
  );
  await tester.pumpAndSettle();
}

class _CatalogTestApp extends StatelessWidget {
  const _CatalogTestApp({
    required this.size,
    required this.textScaler,
    this.catalogRepository = const FakeCatalogRepository(),
    this.customizationRepository,
    this.initialQuery,
  });

  final Size size;
  final TextScaler textScaler;
  final CatalogRepository catalogRepository;
  final LibraryCustomizationRepository? customizationRepository;
  final CatalogQuery? initialQuery;

  @override
  Widget build(BuildContext context) {
    final app = AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: catalogRepository,
      novelRepository: const FakeNovelRepository(result: null),
      readerRepository: const _TestReaderRepository(),
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: const _TestReadingHistoryRepository(),
      readerPreferencesRepository: FakeReaderPreferencesRepository(),
      authRepository: FakeAuthRepository(),
      commentsRepository: FakeCommentsRepository.empty(),
      favoritesRepository: FakeFavoritesRepository(),
      novelEngagementRepository: FakeNovelEngagementRepository(),
      vipRepository: const FakeVipRepository(),
      child: MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData(size: size, textScaler: textScaler),
            child: Scaffold(body: CatalogScreen(initialQuery: initialQuery)),
          ),
        ),
      ),
    );
    final repository = customizationRepository;
    if (repository == null) return app;
    return LibraryCustomizationRepositoryScope(
      repository: repository,
      child: app,
    );
  }
}

class _TestLibraryCustomizationRepository extends ChangeNotifier
    implements LibraryCustomizationRepository {
  _TestLibraryCustomizationRepository(this._value);

  LibraryCustomization _value;

  @override
  LibraryCustomization get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(LibraryCustomization customization) async {
    _value = customization;
    notifyListeners();
  }
}

class _LoadingCatalogRepository implements CatalogRepository {
  const _LoadingCatalogRepository();

  @override
  Stream<CatalogLoadState> watchCatalog() {
    return Stream<CatalogLoadState>.multi((_) {});
  }
}

class _RetryingCatalogRepository implements CatalogRepository {
  int callCount = 0;

  @override
  Stream<CatalogLoadState> watchCatalog() async* {
    callCount += 1;
    if (callCount == 1) {
      throw const FormatException('initial catalog failure');
    }
    yield CatalogLoadState(
      items: const FakeCatalogRepository().items,
      loadedParts: 1,
      totalParts: 1,
      isLoadingMore: false,
    );
  }
}

class _TestReaderRepository implements ReaderRepository {
  const _TestReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) {
    throw UnimplementedError();
  }
}

class _TestReadingHistoryRepository implements ReadingHistoryRepository {
  const _TestReadingHistoryRepository();

  @override
  void addListener(VoidCallback listener) {}

  @override
  Future<List<ReadingProgress>> load() async => const [];

  @override
  Future<void> record(ReadingProgress progress) async {}

  @override
  void removeListener(VoidCallback listener) {}
}
