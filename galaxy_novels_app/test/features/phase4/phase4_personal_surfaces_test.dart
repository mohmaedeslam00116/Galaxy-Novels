import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/app/app_theme_controller.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/about/application/app_version_info.dart';
import 'package:galaxy_novels_app/features/about/presentation/about_screen.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/account/presentation/account_screen.dart';
import 'package:galaxy_novels_app/features/favorites/domain/favorite_item.dart';
import 'package:galaxy_novels_app/features/favorites/presentation/favorites_screen.dart';
import 'package:galaxy_novels_app/features/history/presentation/history_screen.dart';
import 'package:galaxy_novels_app/features/privacy/presentation/privacy_policy_screen.dart';
import 'package:galaxy_novels_app/features/settings/presentation/settings_screen.dart';
import 'package:galaxy_novels_app/features/shell/presentation/app_drawer.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final cairo = FontLoader('Cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo.ttf'));
    await cairo.load();
  });

  final variants = <_MatrixVariant>[
    for (final theme in AppThemeChoice.values) ...[
      _MatrixVariant('${theme.name}-320', theme, const Size(320, 700)),
      _MatrixVariant('${theme.name}-600', theme, const Size(600, 800)),
      _MatrixVariant('${theme.name}-840', theme, const Size(840, 900)),
      _MatrixVariant(
        '${theme.name}-320-200pct',
        theme,
        const Size(320, 700),
        textScale: 2,
      ),
      _MatrixVariant('${theme.name}-landscape', theme, const Size(840, 420)),
    ],
  ];

  for (final variant in variants) {
    testWidgets('personal surfaces remain healthy in ${variant.name}', (
      tester,
    ) async {
      await _configureView(tester, variant);

      await _pumpSurface(
        tester,
        variant: variant,
        authState: const AuthSessionState.guest(),
        child: const AccountScreen(),
      );
      expect(find.text('تتصفح كزائر'), findsOneWidget);
      expect(find.byKey(const ValueKey('login-submit')), findsNothing);
      _expectSurfaceContract(tester);

      await _pumpSurface(
        tester,
        variant: variant,
        authState: const AuthSessionState.authenticated(_accountUser),
        child: const AccountScreen(),
      );
      expect(find.text('قارئ المصفوفة'), findsOneWidget);
      expect(find.byKey(const ValueKey('login-submit')), findsNothing);
      _expectSurfaceContract(tester);

      await _pumpSurface(
        tester,
        variant: variant,
        authState: const AuthSessionState.authenticated(_accountUser),
        child: const FavoritesScreen(),
      );
      expect(find.text('لا توجد روايات مفضلة بعد'), findsOneWidget);
      _expectSurfaceContract(tester);

      await _pumpSurface(
        tester,
        variant: variant,
        authState: const AuthSessionState.authenticated(_accountUser),
        favorites: [_favorite],
        child: const FavoritesScreen(),
      );
      expect(find.text('مدينة النجوم البعيدة'), findsOneWidget);
      _expectSurfaceContract(tester);

      await _pumpSurface(
        tester,
        variant: variant,
        history: const [],
        child: Scaffold(
          appBar: AppBar(title: const Text('السجل')),
          body: const HistoryScreen(onOpenLibrary: _noop),
        ),
      );
      expect(find.text('لا يوجد سجل قراءة بعد'), findsOneWidget);
      _expectSurfaceContract(tester);

      await _pumpSurface(
        tester,
        variant: variant,
        history: [_progress],
        child: Scaffold(
          appBar: AppBar(title: const Text('السجل')),
          body: const HistoryScreen(onOpenLibrary: _noop),
        ),
      );
      expect(find.text('رحلة إلى سديم أندروميدا'), findsOneWidget);
      _expectSurfaceContract(tester);

      await _pumpSurface(
        tester,
        variant: variant,
        child: const SettingsScreen(),
      );
      expect(
        find.byKey(const ValueKey('app-theme-dark-choice-strip')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('app-theme-light-choice-strip')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('theme-choice-card-starlightPaper')),
        findsOneWidget,
      );
      _expectSurfaceContract(tester);

      await _pumpSurface(tester, variant: variant, child: const _DrawerHost());
      await tester.tap(find.byKey(const ValueKey('phase4-open-drawer')));
      await tester.pumpAndSettle();
      expect(find.byType(AppDrawer), findsOneWidget);
      expect(
        find.byKey(const ValueKey('drawer-destination-downloads')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('drawer-destination-account')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('drawer-section-library')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('drawer-section-community')),
        findsOneWidget,
      );
      _expectSurfaceContract(tester);

      await _pumpSurface(
        tester,
        variant: variant,
        child: AboutScreen(versionLoader: _fixedVersion),
      );
      expect(find.text('الإصدار 4.0.0 (40)'), findsOneWidget);
      _expectSurfaceContract(tester);

      await _pumpSurface(
        tester,
        variant: variant,
        child: const PrivacyPolicyScreen(uriLauncher: _successfulLauncher),
      );
      expect(find.text('سياسة الخصوصية لتطبيق مجرة الروايات'), findsOneWidget);
      _expectSurfaceContract(tester);
    });
  }
}

Future<void> _configureView(WidgetTester tester, _MatrixVariant variant) async {
  tester.view.physicalSize = variant.size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = variant.textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required _MatrixVariant variant,
  required Widget child,
  AuthSessionState authState = const AuthSessionState.guest(),
  List<FavoriteItem> favorites = const [],
  List<ReadingProgress> history = const [],
}) async {
  final authRepository = FakeAuthRepository(initialState: authState);
  final favoritesRepository = FakeFavoritesRepository(
    userId: authState.user?.id,
    items: favorites,
  );
  final historyRepository = _StaticHistoryRepository(history);
  final preferencesRepository = FakeReaderPreferencesRepository();
  final themeController = _FixedThemeController(variant.theme);
  addTearDown(authRepository.dispose);
  addTearDown(favoritesRepository.dispose);
  addTearDown(preferencesRepository.dispose);
  addTearDown(themeController.dispose);

  final theme = switch (variant.theme) {
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
  final cairoTheme = _withCairo(theme);
  await tester.pumpWidget(
    AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: const FakeNovelRepository(result: null),
      readerRepository: const _StaticReaderRepository(),
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: historyRepository,
      readerPreferencesRepository: preferencesRepository,
      authRepository: authRepository,
      commentsRepository: FakeCommentsRepository.empty(),
      favoritesRepository: favoritesRepository,
      novelEngagementRepository: FakeNovelEngagementRepository(),
      vipRepository: const FakeVipRepository(),
      child: AppThemeControllerScope(
        controller: themeController,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          theme: cairoTheme,
          builder: (context, builtChild) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(variant.textScale),
              disableAnimations: true,
              accessibleNavigation: true,
            ),
            child: builtChild!,
          ),
          home: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectSurfaceContract(WidgetTester tester) {
  expect(find.textContaining('Exception', findRichText: true), findsNothing);
  expect(find.textContaining('StateError', findRichText: true), findsNothing);
  expect(find.textContaining('A RenderFlex overflowed'), findsNothing);
  expect(find.byKey(const ValueKey('login-submit')), findsNothing);
  expect(tester.takeException(), isNull);

  final interactive = find
      .byWidgetPredicate(
        (widget) =>
            widget is ButtonStyleButton ||
            widget is IconButton ||
            widget is InkWell ||
            (widget is ListTile && widget.onTap != null),
      )
      .hitTestable();
  for (final element in interactive.evaluate()) {
    final renderObject = element.renderObject;
    if (renderObject is! RenderBox || !renderObject.hasSize) continue;
    expect(
      renderObject.size.width,
      greaterThanOrEqualTo(44),
      reason: '${element.widget.runtimeType} has a narrow target',
    );
    expect(
      renderObject.size.height,
      greaterThanOrEqualTo(44),
      reason: '${element.widget.runtimeType} has a short target',
    );

    if (element.widget is! ButtonStyleButton) continue;

    void inspectLabel(Element descendant) {
      final paragraph = descendant.renderObject;
      if (descendant.widget is Text && paragraph is RenderParagraph) {
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: 'interactive label was clipped: ${descendant.widget}',
        );
      }
      descendant.visitChildren(inspectLabel);
    }

    element.visitChildren(inspectLabel);
  }

  for (final label in _interactiveLabels) {
    for (final element in find.text(label).hitTestable().evaluate()) {
      final paragraph = element.renderObject;
      if (paragraph is RenderParagraph) {
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: 'interactive label was clipped: $label',
        );
      }
    }
  }
}

ThemeData _withCairo(ThemeData theme) {
  final textTheme = theme.textTheme.apply(fontFamily: 'Cairo');
  return theme.copyWith(
    textTheme: textTheme,
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Cairo'),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: textTheme.titleLarge,
      toolbarTextStyle: textTheme.bodyMedium,
    ),
  );
}

const _interactiveLabels = <String>[
  'تسجيل الدخول',
  'إنشاء حساب',
  'فتح المكتبة',
  'عرض التفاصيل',
  'المفضلة',
  'السجل',
  'الإعدادات',
  'أطياف السديم',
  'نور الصفحات',
  'حسابي',
  'حول التطبيق',
  'سياسة الخصوصية',
  'مجتمع Discord',
  'تراخيص البرمجيات المفتوحة',
  'كيفية استخدام Google للمعلومات من المواقع أو التطبيقات',
  'إدارة تفضيلات إعلانات Google',
  'التواصل مع مجرة الروايات',
];

class _DrawerHost extends StatelessWidget {
  const _DrawerHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(uriLauncher: _successfulLauncher),
      body: Builder(
        builder: (context) => IconButton(
          key: const ValueKey('phase4-open-drawer'),
          onPressed: Scaffold.of(context).openDrawer,
          tooltip: 'فتح القائمة',
          icon: const Icon(Icons.menu_rounded),
        ),
      ),
    );
  }
}

class _MatrixVariant {
  const _MatrixVariant(this.name, this.theme, this.size, {this.textScale = 1});

  final String name;
  final AppThemeChoice theme;
  final Size size;
  final double textScale;
}

class _FixedThemeController extends ChangeNotifier
    implements AppThemeController {
  _FixedThemeController(this._value);

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

class _StaticHistoryRepository implements ReadingHistoryRepository {
  const _StaticHistoryRepository(this.items);

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

class _StaticReaderRepository implements ReaderRepository {
  const _StaticReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    return const ReaderChapterContent(
      id: 7,
      novelId: 11,
      label: 'الفصل السابع',
      title: 'بوابة النجوم',
      displayTitle: 'الفصل السابع: بوابة النجوم',
      position: 7,
      total: 20,
      contentHtml: '<p>نص ثابت للمصفوفة.</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }
}

Future<AppVersionInfo> _fixedVersion() async {
  return const AppVersionInfo(version: '4.0.0', buildNumber: '40');
}

Future<bool> _successfulLauncher(Uri uri) async => true;

void _noop() {}

const _accountUser = AuthUser(
  id: 4,
  displayName: 'قارئ المصفوفة',
  avatar: null,
  vip: AuthVip(
    active: true,
    tier: 'astral',
    label: 'عضوية نجمية',
    expiresAt: null,
  ),
  xp: AuthXp(
    total: 12400,
    today: 180,
    secondsTotal: 36000,
    chaptersTotal: 73,
    rank: AuthRank(level: 12, display: 'مستكشف المجرات'),
  ),
);

final _favorite = FavoriteItem(
  id: 11,
  title: 'مدينة النجوم البعيدة',
  url: '/novels/star-city',
  cover: '',
  manifestPath: '/manifest/novel-11.json',
  addedAt: DateTime.utc(2026, 7, 11, 12),
);

final _progress = ReadingProgress(
  novelId: 11,
  novelTitle: 'رحلة إلى سديم أندروميدا',
  chapterId: 7,
  chapterTitle: 'الفصل السابع: بوابة النجوم',
  contentApi: '/api/chapters/7',
  chapterPosition: 7,
  chaptersTotal: 20,
  updatedAt: DateTime.utc(2026, 7, 11, 12),
);
