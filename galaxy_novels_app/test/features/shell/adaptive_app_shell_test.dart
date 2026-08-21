import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderSliverGrid;
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/galaxy_novels_app.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/core/analytics/app_screen_names.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/account/presentation/account_screen.dart';
import 'package:galaxy_novels_app/features/catalog/presentation/catalog_screen.dart';
import 'package:galaxy_novels_app/features/catalog/presentation/widgets/catalog_novel_tile.dart';
import 'package:galaxy_novels_app/features/history/presentation/history_screen.dart';
import 'package:galaxy_novels_app/features/downloads/presentation/downloads_screen.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_screen.dart';
import 'package:galaxy_novels_app/features/rankings/presentation/rankings_screen.dart';
import 'package:galaxy_novels_app/features/reader_journey/presentation/reader_journey_screen.dart';
import 'package:galaxy_novels_app/features/shell/presentation/adaptive_app_shell.dart';
import 'package:galaxy_novels_app/features/shell/presentation/app_shell.dart';
import 'package:galaxy_novels_app/features/shell/presentation/shell_destination.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_favorites_repository.dart';

void main() {
  final layoutCases = [
    (
      name: 'compact',
      size: const Size(390, 844),
      navigation: find.byType(NavigationBar),
      absent: [find.byType(NavigationRail), find.byType(NavigationDrawer)],
    ),
    (
      name: 'medium',
      size: const Size(700, 900),
      navigation: find.byType(NavigationRail),
      absent: [find.byType(NavigationBar), find.byType(NavigationDrawer)],
    ),
    (
      name: 'expanded',
      size: const Size(1000, 900),
      navigation: find.byType(NavigationRail),
      absent: [find.byType(NavigationBar), find.byType(NavigationDrawer)],
    ),
  ];

  for (final layoutCase in layoutCases) {
    testWidgets('${layoutCase.name} shell shows every final destination', (
      tester,
    ) async {
      await _pumpAt(tester, layoutCase.size, _counts());

      expect(layoutCase.navigation, findsOneWidget);
      for (final absentNavigation in layoutCase.absent) {
        expect(absentNavigation, findsNothing);
      }
      for (final label in _finalLabels) {
        expect(
          find.descendant(
            of: layoutCase.navigation,
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
    });
  }

  testWidgets('home owns its app bar instead of rendering shell chrome', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844), _counts());

    expect(find.byKey(const ValueKey('shell-app-bar')), findsNothing);
    expect(
      find.byKey(const ValueKey('shell-notifications-button')),
      findsNothing,
    );
  });

  testWidgets('non-home shell bar shows the selected destination title', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844), _counts());

    await tester.tap(_compactDestination(ShellDestination.library));
    await tester.pump();

    final appBar = find.byKey(const ValueKey('shell-app-bar'));
    expect(
      find.descendant(of: appBar, matching: find.text('المكتبة')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('shell-notifications-button')),
      findsNothing,
    );
  });

  testWidgets(
    'permanent primary navigation does not duplicate the drawer button',
    (tester) async {
      await _pumpAt(
        tester,
        const Size(1000, 900),
        _counts(),
        drawerBuilder: (_) => const SizedBox(),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(DrawerButton), findsNothing);
    },
  );

  testWidgets('AppShell navigates to every approved destination surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: const FakeHomeRepository(),
        catalogRepository: const FakeCatalogRepository(),
        novelRepository: const FakeNovelRepository(result: null),
        rankingsRepository: const FakeRankingsRepository(),
        searchRepository: const FakeSearchRepository(),
        readingHistoryRepository: _ShellReadingHistoryRepository(),
        authRepository: FakeAuthRepository(),
        favoritesRepository: FakeFavoritesRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byKey(const ValueKey('home-sliver-app-bar')), findsOneWidget);

    for (final (destination, surface) in [
      (ShellDestination.library, CatalogScreen),
      (ShellDestination.readerJourney, ReaderJourneyScreen),
      (ShellDestination.rankings, RankingsScreen),
      (ShellDestination.account, AccountScreen),
    ]) {
      await tester.tap(_compactDestination(destination));
      await tester.pumpAndSettle();

      expect(find.byType(surface), findsOneWidget);
      _expectSingleShellChrome();
    }
  });

  testWidgets(
    'reader journey embeds history and downloads in persistent tabs',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        GalaxyNovelsApp(
          homeRepository: const FakeHomeRepository(),
          catalogRepository: const FakeCatalogRepository(),
          novelRepository: const FakeNovelRepository(result: null),
          rankingsRepository: const FakeRankingsRepository(),
          searchRepository: const FakeSearchRepository(),
          readingHistoryRepository: _ShellReadingHistoryRepository(),
          authRepository: FakeAuthRepository(),
          favoritesRepository: FakeFavoritesRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(_compactDestination(ShellDestination.readerJourney));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.text('سجل القراءة'), findsOneWidget);

      await tester.tap(find.text('التنزيلات'));
      await tester.pumpAndSettle();
      expect(find.byType(DownloadsView), findsOneWidget);

      await tester.tap(_compactDestination(ShellDestination.home));
      await tester.pumpAndSettle();
      await tester.tap(_compactDestination(ShellDestination.readerJourney));
      await tester.pumpAndSettle();
      expect(find.byType(DownloadsView), findsOneWidget);

      await tester.tap(find.text('سجل القراءة'));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);
    },
  );

  for (final (windowWidth, expectedColumns) in const [
    (390.0, 2),
    (599.0, 4),
    (700.0, 3),
    (1000.0, 5),
  ]) {
    testWidgets(
      'real AppShell catalog uses $expectedColumns columns at ${windowWidth.toInt()}px',
      (tester) async {
        tester.view.physicalSize = Size(windowWidth, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          GalaxyNovelsApp(
            homeRepository: const FakeHomeRepository(),
            catalogRepository: FakeCatalogRepository(_catalogGridItems),
            novelRepository: const FakeNovelRepository(result: null),
            rankingsRepository: const FakeRankingsRepository(),
            searchRepository: const FakeSearchRepository(),
            readingHistoryRepository: _ShellReadingHistoryRepository(),
            authRepository: FakeAuthRepository(),
            favoritesRepository: FakeFavoritesRepository(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(_realShellDestination(ShellDestination.library));
        await tester.pumpAndSettle();

        final firstRowTiles = _firstCatalogRow(tester);
        expect(
          firstRowTiles,
          hasLength(expectedColumns),
          reason:
              'catalog=${tester.getSize(find.byType(CatalogScreen))}, '
              'gridCrossAxis=${tester.renderObject<RenderSliverGrid>(find.byKey(const ValueKey('catalog-sliver-grid'))).constraints.crossAxisExtent}, '
              'tileWidths=${firstRowTiles.map((tile) => tester.getSize(tile).width).toList()}',
        );
        for (final tile in firstRowTiles) {
          expect(tester.getSize(tile).width, inInclusiveRange(132, 176));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('creates only the selected destination builder', (tester) async {
    final counts = _counts();

    await _pumpAt(tester, const Size(390, 844), counts);

    expect(counts[ShellDestination.home], 1);
    for (final destination in ShellDestination.values.skip(1)) {
      expect(counts[destination], 0);
    }

    await tester.tap(_compactDestination(ShellDestination.readerJourney));
    await tester.pump();

    expect(counts[ShellDestination.home], 1);
    expect(counts[ShellDestination.readerJourney], 1);
    expect(counts[ShellDestination.library], 0);
    expect(counts[ShellDestination.rankings], 0);
    expect(counts[ShellDestination.account], 0);
  });

  testWidgets('visited destination is not recreated and preserves state', (
    tester,
  ) async {
    final counts = _counts();
    final builders = _builders(counts);
    builders[ShellDestination.readerJourney] = (context, selectDestination) {
      counts[ShellDestination.readerJourney] =
          counts[ShellDestination.readerJourney]! + 1;
      return const _StatefulTestScreen();
    };

    await _pumpAt(
      tester,
      const Size(390, 844),
      counts,
      screenBuilders: builders,
    );

    await tester.tap(_compactDestination(ShellDestination.readerJourney));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('increment-state')));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(_compactDestination(ShellDestination.home));
    await tester.pump();
    await tester.tap(_compactDestination(ShellDestination.readerJourney));
    await tester.pump();

    expect(counts[ShellDestination.readerJourney], 1);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('reports initial and changed shell screens without duplicates', (
    tester,
  ) async {
    final counts = _counts();
    final analytics = _RecordingAppAnalytics();

    await _pumpAt(tester, const Size(390, 844), counts, analytics: analytics);
    expect(analytics.screens, [AppScreenNames.home]);

    await tester.tap(_compactDestination(ShellDestination.library));
    await tester.pump();
    expect(analytics.screens, [AppScreenNames.home, AppScreenNames.library]);

    await tester.tap(_compactDestination(ShellDestination.library));
    await tester.pump();
    expect(analytics.screens, [AppScreenNames.home, AppScreenNames.library]);
  });

  testWidgets('selected destination preserves state across a breakpoint', (
    tester,
  ) async {
    final counts = _counts();
    final builders = _builders(counts);
    builders[ShellDestination.account] = (context, selectDestination) {
      counts[ShellDestination.account] = counts[ShellDestination.account]! + 1;
      return const _StatefulTestScreen();
    };

    await _pumpAt(
      tester,
      const Size(599, 900),
      counts,
      screenBuilders: builders,
    );
    await tester.tap(_compactDestination(ShellDestination.account));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('increment-state')));
    await tester.pump();

    tester.view.physicalSize = const Size(600, 900);
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(counts[ShellDestination.account], 1);
    expect(find.text('1'), findsOneWidget);
  });
}

const _finalLabels = ['الرئيسية', 'المكتبة', 'رحلة القارئ', 'الترتيب', 'حسابي'];

Map<ShellDestination, int> _counts() => {
  for (final destination in ShellDestination.values) destination: 0,
};

Map<ShellDestination, ShellScreenBuilder> _builders(
  Map<ShellDestination, int> counts,
) => {
  for (final destination in ShellDestination.values)
    destination: (context, selectDestination) {
      counts[destination] = counts[destination]! + 1;
      return Center(
        key: ValueKey('screen-${destination.name}'),
        child: Text(destination.label),
      );
    },
};

Future<void> _pumpAt(
  WidgetTester tester,
  Size size,
  Map<ShellDestination, int> counts, {
  Map<ShellDestination, ShellScreenBuilder>? screenBuilders,
  WidgetBuilder? drawerBuilder,
  AppAnalytics analytics = const NoopAppAnalytics(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: AdaptiveAppShell(
          screenBuilders: screenBuilders ?? _builders(counts),
          drawerBuilder: drawerBuilder,
          analytics: analytics,
        ),
      ),
    ),
  );
  await tester.pump();
}

class _RecordingAppAnalytics implements AppAnalytics {
  final List<String> screens = [];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> logScreenView(String screenName) async {
    screens.add(screenName);
  }
}

Finder _compactDestination(ShellDestination destination) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(destination.label),
  );
}

Finder _realShellDestination(ShellDestination destination) {
  return find.descendant(
    of: find.byWidgetPredicate(
      (widget) =>
          widget is NavigationBar ||
          widget is NavigationRail ||
          widget is NavigationDrawer,
    ),
    matching: find.text(destination.label),
  );
}

List<Finder> _firstCatalogRow(WidgetTester tester) {
  final tileFinders = find
      .byType(CatalogNovelTile)
      .evaluate()
      .map((element) => find.byWidget(element.widget))
      .toList(growable: false);
  final firstRowTop = tileFinders
      .map((tile) => tester.getTopLeft(tile).dy)
      .reduce((first, second) => first < second ? first : second);
  return tileFinders
      .where((tile) => (tester.getTopLeft(tile).dy - firstRowTop).abs() < 0.5)
      .toList(growable: false);
}

void _expectSingleShellChrome() {
  expect(find.byType(NavigationBar), findsOneWidget);
  expect(find.byType(Scaffold), findsOneWidget);
  expect(find.byType(AppBar), findsOneWidget);
}

class _ShellReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  @override
  Future<List<ReadingProgress>> load() async => const [];

  @override
  Future<void> record(ReadingProgress progress) async {}
}

final _catalogGridItems = List<CatalogNovel>.unmodifiable(
  List.generate(
    15,
    (index) => CatalogNovel(
      id: index + 1,
      title: 'رواية شبكة ${index + 1}',
      originalTitle: '',
      url: '/novel/grid-${index + 1}/',
      coverThumbnail: '',
      coverMedium: '',
      statusKey: 'ongoing',
      statusLabel: 'مستمرة',
      genres: const [],
      chaptersCount: 20,
      ratingAverage: 4,
      ratingCount: 1,
      views: 100,
      updatedAt: null,
      manifest: '',
    ),
  ),
);

class _StatefulTestScreen extends StatefulWidget {
  const _StatefulTestScreen();

  @override
  State<_StatefulTestScreen> createState() => _StatefulTestScreenState();
}

class _StatefulTestScreenState extends State<_StatefulTestScreen> {
  var _value = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        key: const ValueKey('increment-state'),
        onPressed: () => setState(() => _value += 1),
        child: Text('$_value'),
      ),
    );
  }
}
