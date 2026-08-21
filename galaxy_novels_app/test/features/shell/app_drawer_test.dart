import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/navigation/external_uri_launcher.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/design_system/gallery/galaxy_design_system_gallery.dart';
import 'package:galaxy_novels_app/features/about/application/app_version_info.dart';
import 'package:galaxy_novels_app/features/shell/presentation/app_drawer.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
  testWidgets('omits the legacy downloads destination', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_surface(uriLauncher: (_) async => true));
    await _openDrawer(tester);

    expect(
      find.byKey(const ValueKey('drawer-destination-downloads')),
      findsNothing,
    );
    expect(find.text('التنزيلات'), findsNothing);
  });

  testWidgets('shows approved reader destinations and developer gallery', (
    tester,
  ) async {
    await tester.pumpWidget(_surface(uriLauncher: (_) async => true));
    await _openDrawer(tester);

    expect(find.text('المكتبة والتفضيلات'), findsOneWidget);
    expect(find.text('المجتمع'), findsOneWidget);
    expect(find.text('للمطورين'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('drawer-section-library')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('drawer-section-community')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('drawer-section-developer')),
      findsOneWidget,
    );

    for (final destination in <String>[
      'favorites',
      'settings',
      'discord',
      'designSystem',
    ]) {
      expect(
        find.byKey(ValueKey('drawer-destination-$destination')),
        findsOneWidget,
      );
    }

    expect(
      find.byKey(const ValueKey('drawer-destination-account')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('drawer-destination-downloads')),
      findsNothing,
    );
    expect(find.text('حسابي'), findsNothing);
    expect(find.text('التنزيلات'), findsNothing);
    expect(find.text('قراءة عربية، تجربة كونية'), findsNothing);
  });

  testWidgets('opens the design system gallery from non-release drawer', (
    tester,
  ) async {
    await tester.pumpWidget(_surface(uriLauncher: (_) async => true));
    await _openDrawer(tester);

    final gallery = find.byKey(
      const ValueKey('drawer-destination-designSystem'),
    );
    await tester.scrollUntilVisible(
      gallery,
      100,
      scrollable: _drawerScrollable(),
    );
    await tester.tap(gallery);
    await tester.pumpAndSettle();

    expect(find.byType(GalaxyDesignSystemGallery), findsOneWidget);
  });

  testWidgets('keeps compact destinations accessible and at least 44px', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_surface(uriLauncher: (_) async => true));
    await _openDrawer(tester);

    for (final destination in <String>['favorites', 'settings', 'discord']) {
      final row = find.byKey(ValueKey('drawer-destination-$destination'));
      expect(tester.getSize(row).height, greaterThanOrEqualTo(44));
      expect(tester.getSemantics(row).label, isNotEmpty);
    }
    semantics.dispose();
  });

  testWidgets('does not clip destination labels at 200 percent text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_surface(uriLauncher: (_) async => true));
    await _openDrawer(tester);

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('مجتمع Discord'),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  testWidgets('shows injected package version in compact footer', (
    tester,
  ) async {
    await tester.pumpWidget(_surface(uriLauncher: (_) async => true));
    await _openDrawer(tester);

    expect(find.byKey(const ValueKey('drawer-app-version')), findsOneWidget);
    expect(find.text('الإصدار 9.8.7 (42)'), findsOneWidget);
  });

  testWidgets('shows safe version fallback when package metadata fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _surface(
        uriLauncher: (_) async => true,
        versionLoader: () async => throw Exception('metadata failed'),
      ),
    );
    await _openDrawer(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('الإصدار غير متاح'), findsOneWidget);
  });

  testWidgets('keeps only Discord in the community drawer group', (
    tester,
  ) async {
    await tester.pumpWidget(_surface(uriLauncher: (_) async => true));
    await _openDrawer(tester);

    final discord = find.byKey(const ValueKey('drawer-destination-discord'));

    expect(
      find.byKey(const ValueKey('drawer-destination-about')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('drawer-destination-privacy')),
      findsNothing,
    );
    expect(discord, findsOneWidget);
    expect(find.byKey(const ValueKey('discord-brand-mark')), findsOneWidget);
  });

  testWidgets('opens the approved Discord invite from the drawer', (
    tester,
  ) async {
    Uri? openedUri;
    await tester.pumpWidget(
      _surface(
        uriLauncher: (uri) async {
          openedUri = uri;
          return true;
        },
      ),
    );
    await _openDrawer(tester);

    final discord = find.byKey(const ValueKey('drawer-destination-discord'));
    await tester.drag(_drawerScrollable(), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(discord);
    await tester.pumpAndSettle();

    expect(openedUri, Uri.parse('https://discord.gg/fD7U7zbCgM'));
  });

  testWidgets('shows feedback when Discord cannot open', (tester) async {
    await tester.pumpWidget(_surface(uriLauncher: (_) async => false));
    await _openDrawer(tester);

    final discord = find.byKey(const ValueKey('drawer-destination-discord'));
    await tester.drag(_drawerScrollable(), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(discord);
    await tester.pumpAndSettle();

    expect(find.text('تعذر فتح رابط Discord الآن.'), findsOneWidget);
  });

  testWidgets('shows safe feedback when the Discord launcher throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      _surface(uriLauncher: (_) async => throw Exception('launcher failed')),
    );
    await _openDrawer(tester);

    final discord = find.byKey(const ValueKey('drawer-destination-discord'));
    await tester.drag(_drawerScrollable(), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(discord);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('تعذر فتح رابط Discord الآن.'), findsOneWidget);
  });
}

Widget _surface({
  required ExternalUriLauncher uriLauncher,
  AppVersionLoader versionLoader = _successfulVersionLoader,
}) {
  return AppDependencies(
    config: const AppConfig(),
    homeRepository: const FakeHomeRepository(),
    catalogRepository: const FakeCatalogRepository(),
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
      theme: AppTheme.dark(),
      home: Scaffold(
        drawer: AppDrawer(
          uriLauncher: uriLauncher,
          versionLoader: versionLoader,
        ),
        body: Builder(
          builder: (context) => IconButton(
            key: const ValueKey('open-drawer'),
            onPressed: Scaffold.of(context).openDrawer,
            icon: const Icon(Icons.menu),
          ),
        ),
      ),
    ),
  );
}

Future<AppVersionInfo> _successfulVersionLoader() async {
  return const AppVersionInfo(version: '9.8.7', buildNumber: '42');
}

Future<void> _openDrawer(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('open-drawer')));
  await tester.pumpAndSettle();
}

Finder _drawerScrollable() {
  return find.descendant(
    of: find.byType(Drawer),
    matching: find.byType(Scrollable),
  );
}

class _TestReaderRepository implements ReaderRepository {
  const _TestReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    return const ReaderChapterContent(
      id: 1,
      novelId: 1,
      label: 'الفصل 1',
      title: '',
      displayTitle: 'الفصل 1',
      position: 1,
      total: 1,
      contentHtml: '<p>اختبار</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
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
