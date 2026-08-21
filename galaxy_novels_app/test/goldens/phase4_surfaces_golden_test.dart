import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/app/app_theme_controller.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/core/network/app_cache_maintenance.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/rankings_data.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/data/repositories/rankings_repository.dart';
import 'package:galaxy_novels_app/features/about/application/app_version_info.dart';
import 'package:galaxy_novels_app/features/about/presentation/about_screen.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/account/presentation/account_screen.dart';
import 'package:galaxy_novels_app/features/catalog/presentation/catalog_screen.dart';
import 'package:galaxy_novels_app/features/favorites/domain/favorite_item.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_repository.dart';
import 'package:galaxy_novels_app/features/favorites/presentation/favorites_screen.dart';
import 'package:galaxy_novels_app/features/history/presentation/history_screen.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/novel_details_screen.dart';
import 'package:galaxy_novels_app/features/novel_engagement/domain/novel_user_state.dart';
import 'package:galaxy_novels_app/features/privacy/presentation/privacy_policy_screen.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_preferences.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_screen.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_settings_sheet.dart';
import 'package:galaxy_novels_app/features/rankings/presentation/rankings_screen.dart';
import 'package:galaxy_novels_app/features/settings/presentation/settings_screen.dart';
import 'package:galaxy_novels_app/features/settings/presentation/data_management_screen.dart';
import 'package:galaxy_novels_app/features/shell/presentation/app_drawer.dart';
import 'package:galaxy_novels_app/features/shell/presentation/app_shell.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_comments_repository.dart';
import '../helpers/fake_favorites_repository.dart';
import '../helpers/fake_novel_engagement_repository.dart';
import '../helpers/fake_reader_preferences_repository.dart';
import '../helpers/fake_vip_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final readex = FontLoader('Readex Pro')
      ..addFont(rootBundle.load('assets/fonts/ReadexPro.ttf'));
    final readerFonts = <FontLoader>[
      FontLoader('Amiri')
        ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf')),
      FontLoader('Tajawal')
        ..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf')),
      FontLoader('Readex Pro')
        ..addFont(rootBundle.load('assets/fonts/ReadexPro.ttf')),
      FontLoader(
        'IBM Plex Sans Arabic',
      )..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf')),
      FontLoader('Almarai')
        ..addFont(rootBundle.load('assets/fonts/Almarai-Regular.ttf')),
      FontLoader('Aref Ruqaa')
        ..addFont(rootBundle.load('assets/fonts/ArefRuqaa-Regular.ttf')),
      FontLoader('El Messiri')
        ..addFont(rootBundle.load('assets/fonts/ElMessiri.ttf')),
      FontLoader('Changa')..addFont(rootBundle.load('assets/fonts/Changa.ttf')),
    ];
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    final fontAwesomeBrands =
        FontLoader('packages/font_awesome_flutter/FontAwesomeBrands')..addFont(
          rootBundle.load(
            'packages/font_awesome_flutter/lib/fonts/'
            'Font-Awesome-7-Brands-Regular-400.otf',
          ),
        );
    await Future.wait([
      readex.load(),
      for (final font in readerFonts) font.load(),
      materialIcons.load(),
      fontAwesomeBrands.load(),
    ]);
  });

  for (final theme in AppThemeChoice.values) {
    for (final width in const [320, 600, 840]) {
      for (final group in _GoldenGroup.values) {
        final name = 'phase4_${group.name}_${theme.name}_$width.png';
        testWidgets('${group.name} ${theme.name} at $width', (tester) async {
          await _pumpGolden(
            tester,
            theme: theme,
            width: width.toDouble(),
            group: group,
          );

          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('phase4-golden-root')),
            matchesGoldenFile('goldens/$name'),
          );
        });
      }
    }
  }
}

Future<void> _pumpGolden(
  WidgetTester tester, {
  required AppThemeChoice theme,
  required double width,
  required _GoldenGroup group,
}) async {
  final height = switch (group) {
    _GoldenGroup.support when width < 600 => 1180.0,
    _GoldenGroup.settingsHub || _GoldenGroup.dataManagement => 1180.0,
    _GoldenGroup.novelDetails => 1180.0,
    _GoldenGroup.signedInAccount => 1000.0,
    _GoldenGroup.readerSettingsSheet => 720.0,
    _GoldenGroup.homeShell => 1180.0,
    _ => 820.0,
  };
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  final isPersonal = group == _GoldenGroup.personalLibrary;
  final isAuthenticated =
      isPersonal ||
      group == _GoldenGroup.novelDetails ||
      group == _GoldenGroup.signedInAccount;
  final authRepository = FakeAuthRepository(
    initialState: isAuthenticated
        ? const AuthSessionState.authenticated(_goldenUser)
        : const AuthSessionState.guest(),
  );
  final favoritesRepository = FakeFavoritesRepository(
    userId: isAuthenticated ? _goldenUser.id : null,
    items: isAuthenticated ? [_goldenFavorite] : const [],
  );
  final historyRepository = _GoldenHistoryRepository(
    isPersonal ? [_goldenProgress] : const [],
  );
  final preferencesRepository = FakeReaderPreferencesRepository();
  final themeController = _GoldenThemeController(theme);
  addTearDown(authRepository.dispose);
  addTearDown(favoritesRepository.dispose);
  addTearDown(preferencesRepository.dispose);
  addTearDown(themeController.dispose);

  final baseTheme = switch (theme) {
    AppThemeChoice.starlightPaper => AppTheme.light(),
    AppThemeChoice.neutralDark => AppTheme.neutralDarkTheme(),
    AppThemeChoice.galaxyNoir => AppTheme.dark(),
    AppThemeChoice.cosmicNight => AppTheme.cosmicNightTheme(),
    AppThemeChoice.lightNature => AppTheme.lightNatureTheme(),
    AppThemeChoice.oceanAsh => AppTheme.oceanAshTheme(),
    AppThemeChoice.moonForest => AppTheme.moonForestTheme(),
    AppThemeChoice.garnetVelvet => AppTheme.garnetVelvetTheme(),
    AppThemeChoice.copperDusk => AppTheme.copperDuskTheme(),
    AppThemeChoice.midnightTide => AppTheme.midnightTideTheme(),
  };
  final goldenTheme = _withReadex(baseTheme);

  await tester.pumpWidget(
    AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: FakeNovelRepository(
        result: group == _GoldenGroup.novelDetails
            ? _goldenNovelLoadResult
            : null,
      ),
      readerRepository: const _GoldenReaderRepository(),
      rankingsRepository: group == _GoldenGroup.rankings
          ? const _GoldenRankingsRepository()
          : const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: historyRepository,
      readerPreferencesRepository: preferencesRepository,
      authRepository: authRepository,
      commentsRepository: FakeCommentsRepository.empty(),
      favoritesRepository: favoritesRepository,
      novelEngagementRepository: FakeNovelEngagementRepository(
        state: group == _GoldenGroup.novelDetails
            ? _goldenNovelUserState
            : null,
      ),
      vipRepository: const FakeVipRepository(),
      child: AppThemeControllerScope(
        controller: themeController,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          theme: goldenTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
              disableAnimations: true,
              accessibleNavigation: true,
            ),
            child: child!,
          ),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: RepaintBoundary(
              key: const ValueKey('phase4-golden-root'),
              child: _GoldenShowcase(group: group, width: width),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (group == _GoldenGroup.reader) {
    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();
  }
  final imageContext = tester.element(
    find.byKey(const ValueKey('phase4-golden-root')),
  );
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/branding/galaxy_novels_play_icon_512.png'),
      imageContext,
    ),
  );
  await tester.pumpAndSettle();
}

ThemeData _withReadex(ThemeData theme) {
  final textTheme = theme.textTheme.apply(fontFamily: 'Readex Pro');
  return theme.copyWith(
    textTheme: textTheme,
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Readex Pro'),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: textTheme.titleLarge,
      toolbarTextStyle: textTheme.bodyMedium,
    ),
    listTileTheme: theme.listTileTheme.copyWith(
      titleTextStyle: _readexTextStyle(theme.listTileTheme.titleTextStyle),
      subtitleTextStyle: _readexTextStyle(
        theme.listTileTheme.subtitleTextStyle,
      ),
      leadingAndTrailingTextStyle: _readexTextStyle(
        theme.listTileTheme.leadingAndTrailingTextStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _readexButtonStyle(theme.textButtonTheme.style, textTheme),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _readexButtonStyle(theme.filledButtonTheme.style, textTheme),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _readexButtonStyle(theme.outlinedButtonTheme.style, textTheme),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _readexButtonStyle(theme.elevatedButtonTheme.style, textTheme),
    ),
    chipTheme: theme.chipTheme.copyWith(
      labelStyle: _readexTextStyle(theme.chipTheme.labelStyle),
      secondaryLabelStyle: _readexTextStyle(
        theme.chipTheme.secondaryLabelStyle,
      ),
    ),
  );
}

TextStyle? _readexTextStyle(TextStyle? style) {
  return style?.copyWith(fontFamily: 'Readex Pro');
}

ButtonStyle? _readexButtonStyle(ButtonStyle? style, TextTheme textTheme) {
  if (style == null) return null;
  return style.copyWith(
    textStyle: WidgetStateProperty.resolveWith((states) {
      final resolved = style.textStyle?.resolve(states) ?? textTheme.labelLarge;
      return resolved?.copyWith(fontFamily: 'Readex Pro');
    }),
  );
}

class _GoldenShowcase extends StatelessWidget {
  const _GoldenShowcase({required this.group, required this.width});

  final _GoldenGroup group;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: switch (group) {
        _GoldenGroup.personalLibrary => _adaptivePair(
          width,
          const FavoritesScreen(),
          Scaffold(
            appBar: AppBar(title: const Text('السجل')),
            body: const HistoryScreen(onOpenLibrary: _noop),
          ),
        ),
        _GoldenGroup.accountSettings => _adaptivePair(
          width,
          const AccountScreen(),
          const SettingsScreen(),
        ),
        _GoldenGroup.settingsHub => const SettingsScreen(),
        _GoldenGroup.dataManagement => const DataManagementScreen(
          cacheMaintenance: NoopAppCacheMaintenance(),
          downloadRepository: NoopDownloadRepository(),
        ),
        _GoldenGroup.signedInAccount => const Scaffold(body: AccountScreen()),
        _GoldenGroup.support => _supportShowcase(width),
        _GoldenGroup.novelDetails => const NovelDetailsScreen(
          manifestPath: '/golden-novel.json',
        ),
        _GoldenGroup.reader => const ReaderScreen(
          contentApi: '/golden-chapter.json',
        ),
        _GoldenGroup.readerSettingsSheet => Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ReaderSettingsSheet(
              preferences: ReaderPreferences.defaults,
              onChanged: _ignoreReaderPreferences,
            ),
          ),
        ),
        _GoldenGroup.catalog => Scaffold(
          appBar: AppBar(title: const Text('المكتبة')),
          body: const CatalogScreen(),
        ),
        _GoldenGroup.homeShell => const AppShell(),
        _GoldenGroup.rankings => const Scaffold(body: RankingsScreen()),
      },
    );
  }
}

Widget _adaptivePair(double width, Widget first, Widget second) {
  if (width >= 720) {
    return Row(
      children: [
        Expanded(child: ClipRect(child: first)),
        const VerticalDivider(width: 1),
        Expanded(child: ClipRect(child: second)),
      ],
    );
  }
  return Column(
    children: [
      Expanded(child: ClipRect(child: first)),
      const Divider(height: 1),
      Expanded(child: ClipRect(child: second)),
    ],
  );
}

Widget _supportShowcase(double width) {
  const drawer = AppDrawer(
    uriLauncher: _goldenLauncher,
    versionLoader: _goldenVersion,
  );
  final about = SizedBox(
    height: 320,
    child: ClipRect(child: AboutScreen(versionLoader: _goldenVersion)),
  );
  const privacy = ClipRect(
    child: PrivacyPolicyScreen(uriLauncher: _goldenLauncher),
  );

  if (width >= 720) {
    return Row(
      children: [
        const Expanded(child: drawer),
        const VerticalDivider(width: 1),
        Expanded(
          child: Align(alignment: Alignment.topCenter, child: about),
        ),
        const VerticalDivider(width: 1),
        const Expanded(child: privacy),
      ],
    );
  }
  if (width >= 600) {
    return Row(
      children: [
        const SizedBox(width: 300, child: drawer),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              about,
              const Divider(height: 1),
              const Expanded(child: privacy),
            ],
          ),
        ),
      ],
    );
  }
  return Column(
    children: [
      const Expanded(child: drawer),
      const Divider(height: 1),
      about,
      const Divider(height: 1),
      const Expanded(child: privacy),
    ],
  );
}

enum _GoldenGroup {
  personalLibrary,
  accountSettings,
  settingsHub,
  dataManagement,
  signedInAccount,
  support,
  novelDetails,
  reader,
  readerSettingsSheet,
  catalog,
  homeShell,
  rankings,
}

void _ignoreReaderPreferences(ReaderPreferences preferences) {}

class _GoldenThemeController extends ChangeNotifier
    implements AppThemeController {
  _GoldenThemeController(this._value);

  AppThemeChoice _value;

  @override
  AppThemeChoice get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(AppThemeChoice choice) async {
    if (_value == choice) return;
    _value = choice;
    notifyListeners();
  }
}

class _GoldenHistoryRepository implements ReadingHistoryRepository {
  const _GoldenHistoryRepository(this.items);

  final List<ReadingProgress> items;

  @override
  void addListener(VoidCallback listener) {}

  @override
  Future<List<ReadingProgress>> load() async => List.unmodifiable(items);

  @override
  void removeListener(VoidCallback listener) {}

  @override
  Future<void> record(ReadingProgress progress) async {}
}

class _GoldenRankingsRepository implements RankingsRepository {
  const _GoldenRankingsRepository();

  @override
  Future<RankingsData> loadRankings() async => const RankingsData(
    period: 'month',
    items: [
      CatalogNovel(
        id: 1,
        title: 'سيدة العوالم',
        originalTitle: '',
        url: '/lady-of-worlds/',
        coverThumbnail: '',
        coverMedium: '',
        statusKey: 'ongoing',
        statusLabel: 'مستمرة',
        genres: [],
        chaptersCount: 180,
        ratingAverage: 4.9,
        ratingCount: 120,
        views: 24800,
        updatedAt: null,
        manifest: '/lady-of-worlds.json',
      ),
      CatalogNovel(
        id: 2,
        title: 'حارس النجوم',
        originalTitle: '',
        url: '/star-guardian/',
        coverThumbnail: '',
        coverMedium: '',
        statusKey: 'completed',
        statusLabel: 'مكتملة',
        genres: [],
        chaptersCount: 132,
        ratingAverage: 4.7,
        ratingCount: 98,
        views: 19300,
        updatedAt: null,
        manifest: '/star-guardian.json',
      ),
      CatalogNovel(
        id: 3,
        title: 'بوابة السديم',
        originalTitle: '',
        url: '/nebula-gate/',
        coverThumbnail: '',
        coverMedium: '',
        statusKey: 'ongoing',
        statusLabel: 'مستمرة',
        genres: [],
        chaptersCount: 95,
        ratingAverage: 0,
        ratingCount: 0,
        views: 15700,
        updatedAt: null,
        manifest: '/nebula-gate.json',
      ),
      CatalogNovel(
        id: 4,
        title: 'رحلة إلى أندروميدا',
        originalTitle: '',
        url: '/andromeda-journey/',
        coverThumbnail: '',
        coverMedium: '',
        statusKey: 'ongoing',
        statusLabel: 'مستمرة',
        genres: [],
        chaptersCount: 72,
        ratingAverage: 4.4,
        ratingCount: 61,
        views: 9800,
        updatedAt: null,
        manifest: '/andromeda-journey.json',
      ),
    ],
  );
}

class _GoldenReaderRepository implements ReaderRepository {
  const _GoldenReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    return const ReaderChapterContent(
      id: 12,
      novelId: 25,
      label: 'الفصل 12',
      title: 'نداء السديم',
      displayTitle: 'الفصل 12: نداء السديم',
      position: 12,
      total: 60,
      contentHtml: '<p>نص ذهبي ثابت.</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '/golden-chapter-11.json',
        nextApi: '/golden-chapter-13.json',
        previousId: 11,
        nextId: 13,
      ),
    );
  }
}

Future<AppVersionInfo> _goldenVersion() async {
  return const AppVersionInfo(version: '4.0.0', buildNumber: '40');
}

Future<bool> _goldenLauncher(Uri uri) async => true;

void _noop() {}

const _goldenUser = AuthUser(
  id: 25,
  displayName: 'قارئ السديم',
  avatar: null,
  vip: AuthVip(
    active: true,
    tier: 'nebula',
    label: 'عضوية نجمية',
    expiresAt: null,
  ),
  xp: AuthXp(
    total: 8600,
    today: 120,
    secondsTotal: 28800,
    chaptersTotal: 48,
    rank: AuthRank(level: 9, display: 'رحّالة المجرة'),
  ),
);

final _goldenFavorite = FavoriteItem(
  id: 25,
  title: 'أغنية القمر الأزرق',
  url: '/novels/blue-moon',
  cover: '',
  manifestPath: '/manifest/novel-25.json',
  addedAt: DateTime.utc(2026, 7, 11, 10),
);

final _goldenProgress = ReadingProgress(
  novelId: 25,
  novelTitle: 'أغنية القمر الأزرق',
  chapterId: 12,
  chapterTitle: 'الفصل 12: نداء السديم',
  contentApi: '/api/chapters/12',
  chapterPosition: 12,
  chaptersTotal: 60,
  updatedAt: _goldenDate,
);

final _goldenDate = DateTime.utc(2026, 7, 11, 10);

const _goldenNovelLoadResult = NovelDetailsLoadResult(
  details: NovelDetails(
    id: 25,
    title: 'القس المجنون',
    originalTitle: 'REVEREND INSANITY',
    url: '/novels/reverend-insanity',
    coverThumbnail: '',
    coverMedium: '',
    coverLarge: '',
    statusKey: 'ongoing',
    statusLabel: 'مستمرة',
    country: 'cn',
    author: 'Gu Zhen Ren',
    translator: 'أحمد علي',
    genres: [
      NovelGenre(id: 1, name: 'أكشن', slug: 'action'),
      NovelGenre(id: 2, name: 'خيال', slug: 'fantasy'),
      NovelGenre(id: 3, name: 'غموض', slug: 'mystery'),
      NovelGenre(id: 4, name: 'فنون قتال', slug: 'martial-arts'),
    ],
    chaptersCount: 67,
    firstChapterId: 1,
    firstChapterUrl: '/chapters/1',
    ratingAverage: 4.8,
    ratingCount: 132,
    views: 24000,
    updatedAt: null,
    summary:
        'في قلب عالم قاسٍ تحكمه الأسرار والقوى الخارقة، يعود فانغ يوان إلى الماضي حاملًا خبرة قرون طويلة، ويبدأ رحلته من جديد متحديًا المصير والقواعد التي تحكم الجميع.',
    chaptersManifest: '/golden-chapters.json',
    vipScheduleManifest: '',
    manifest: '/golden-novel.json',
  ),
  chapters: [
    NovelChapter(
      id: 1,
      position: 1,
      number: '1',
      label: 'الفصل 1',
      title: 'مقدمة (حكمة نينغ تشو المبكرة)',
      url: '/chapters/1',
      contentApi: '/api/chapters/1',
      dateLabel: '2026-07-11',
      dateIso: null,
      views: 120,
      comments: 2,
      search: 'الفصل 1 مقدمة',
    ),
    NovelChapter(
      id: 2,
      position: 2,
      number: '2',
      label: 'الفصل 2',
      title: 'سيد الدمى الغامض',
      url: '/chapters/2',
      contentApi: '/api/chapters/2',
      dateLabel: '2026-07-11',
      dateIso: null,
      views: 110,
      comments: 1,
      search: 'الفصل 2 سيد الدمى الغامض',
    ),
    NovelChapter(
      id: 3,
      position: 3,
      number: '3',
      label: 'الفصل 3',
      title: 'منطقة عائلة نينغ تشو',
      url: '/chapters/3',
      contentApi: '/api/chapters/3',
      dateLabel: '2026-07-11',
      dateIso: null,
      views: 100,
      comments: 1,
      search: 'الفصل 3 منطقة العائلة',
    ),
  ],
);

const _goldenNovelUserState = NovelUserState(
  novelId: 25,
  favorite: true,
  myRating: 4,
  lastRead: NovelLastRead(
    chapterId: 2,
    chapterUrl: '/chapters/2',
    progress: 42,
    updatedAt: null,
  ),
  vip: NovelVipAccess(active: true, canReadPrivate: false),
);
