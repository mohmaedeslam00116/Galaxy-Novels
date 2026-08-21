import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/app/app_theme_controller.dart';
import 'package:galaxy_novels_app/app/galaxy_novels_app.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/data/models/chapter_summary.dart';
import 'package:galaxy_novels_app/data/models/home_data.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/models/novel_summary.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart'
    as local_progress;
import 'package:galaxy_novels_app/data/models/rankings_data.dart';
import 'package:galaxy_novels_app/data/models/search_index_data.dart';
import 'package:galaxy_novels_app/data/repositories/catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/data/repositories/rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/search_repository.dart';
import 'package:galaxy_novels_app/features/about/presentation/about_screen.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/ads/application/home_ad_repository.dart';
import 'package:galaxy_novels_app/features/downloads/presentation/downloads_screen.dart';
import 'package:galaxy_novels_app/features/history/presentation/history_screen.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/novel_details_screen.dart';
import 'package:galaxy_novels_app/features/novel_engagement/application/novel_engagement_repository.dart';
import 'package:galaxy_novels_app/features/novel_engagement/domain/novel_user_state.dart';
import 'package:galaxy_novels_app/features/shell/presentation/app_shell.dart';
import 'package:galaxy_novels_app/features/reader_journey/presentation/reader_journey_screen.dart';
import 'package:galaxy_novels_app/shared/widgets/novel_cover.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/fake_comments_repository.dart';
import 'helpers/fake_novel_engagement_repository.dart';
import 'helpers/fake_reader_preferences_repository.dart';
import 'helpers/fake_vip_repository.dart';

void main() {
  testWidgets('shows Galaxy Novels Arabic shell', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        searchRepository: const _TestSearchRepository.empty(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('المكتبة'), findsOneWidget);
    expect(find.text('رحلة القارئ'), findsOneWidget);
    expect(find.text('الترتيب'), findsOneWidget);
    expect(find.text('حسابي'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('التنزيلات'),
      ),
      findsNothing,
    );
  });

  testWidgets('guest opens lazy reader journey and account inside the shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        searchRepository: const _TestSearchRepository.empty(),
        authRepository: FakeAuthRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_shellDestination('رحلة القارئ'));
    await tester.pumpAndSettle();

    expect(find.byType(ReaderJourneyScreen), findsOneWidget);
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('سجل القراءة'), findsOneWidget);

    await tester.tap(find.text('التنزيلات'));
    await tester.pumpAndSettle();
    expect(find.byType(DownloadsView), findsOneWidget);

    await tester.tap(find.text('سجل القراءة'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    await tester.tap(_shellDestination('حسابي'));
    await tester.pumpAndSettle();

    expect(find.text('تتصفح كزائر'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-submit')), findsNothing);
    expect(find.byKey(const ValueKey('auth-show-login')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    await tester.tap(_shellDestination('رحلة القارئ'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('startup shows only splash then opens the home shell', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);
    await tester.pumpWidget(
      GalaxyNovelsApp(
        splashDuration: const Duration(milliseconds: 1200),
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        searchRepository: const _TestSearchRepository.empty(),
        authRepository: authRepository,
      ),
    );

    expect(find.byKey(const ValueKey('galaxy-splash-screen')), findsOneWidget);
    expect(find.text('مجرة الروايات'), findsOneWidget);
    expect(find.text('الرئيسية'), findsNothing);
    expect(find.byKey(const ValueKey('login-submit')), findsNothing);
    expect(find.byKey(const ValueKey('auth-show-register')), findsNothing);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 241));
    await tester.pump();

    expect(find.byKey(const ValueKey('galaxy-splash-screen')), findsNothing);
    expect(find.text('الرئيسية'), findsWidgets);
  });

  testWidgets('injects the configured novel engagement repository', (
    tester,
  ) async {
    final engagementRepository = FakeNovelEngagementRepository();
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        novelEngagementRepository: engagementRepository,
      ),
    );
    await tester.pumpAndSettle();

    final shellContext = tester.element(find.byType(AppShell));
    expect(
      AppDependencies.of(shellContext).novelEngagementRepository,
      same(engagementRepository),
    );
  });

  testWidgets('injects the configured comments repository', (tester) async {
    final commentsRepository = FakeCommentsRepository.empty();
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        commentsRepository: commentsRepository,
      ),
    );
    await tester.pumpAndSettle();

    final shellContext = tester.element(find.byType(AppShell));
    expect(
      AppDependencies.of(shellContext).commentsRepository,
      same(commentsRepository),
    );
  });

  testWidgets('injects the configured VIP repository', (tester) async {
    const vipRepository = FakeVipRepository();
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        vipRepository: vipRepository,
      ),
    );
    await tester.pumpAndSettle();

    final shellContext = tester.element(find.byType(AppShell));
    expect(AppDependencies.of(shellContext).vipRepository, same(vipRepository));
  });

  testWidgets('defers ad initialization until after startup paint', (
    tester,
  ) async {
    final homeAds = _CountingHomeAdRepository();

    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        homeAdRepository: homeAds,
      ),
    );

    expect(homeAds.initializeCalls, 0);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1199));

    expect(homeAds.initializeCalls, 0);

    await tester.pump(const Duration(milliseconds: 1));

    expect(homeAds.initializeCalls, 1);
  });

  testWidgets('cancels deferred ad initialization timer when app is disposed', (
    tester,
  ) async {
    final homeAds = _CountingHomeAdRepository();

    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        homeAdRepository: homeAds,
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(homeAds.initializeCalls, 0);
  });

  testWidgets('restores the saved account session when the app starts', (
    tester,
  ) async {
    final authRepository = _StartupRestoringAuthRepository(
      restoredState: const AuthSessionState.authenticated(_testVipAuthUser),
    );
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        authRepository: authRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(authRepository.restoreCalls, 1);
    expect(authRepository.value.status, AuthSessionStatus.authenticated);
    expect(authRepository.value.user?.vip.active, isTrue);
  });

  testWidgets('opens account screen and submits login credentials', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository(
      initialState: const AuthSessionState.idle(),
    );
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        authRepository: authRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_shellDestination('حسابي'));
    await tester.pumpAndSettle();
    await _showOptionalLogin(tester);

    expect(find.text('تسجيل الدخول'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('login-username')),
      'reader@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'secret-value',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('login-submit')),
      120,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(authRepository.lastLogin?.username, 'reader@example.com');
    expect(authRepository.lastLogin?.password, 'secret-value');
    expect(authRepository.lastLogin?.rememberSession, isTrue);
  });

  testWidgets('account screen submits registration credentials', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository(
      initialState: const AuthSessionState.idle(),
    );
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        authRepository: authRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_shellDestination('حسابي'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('auth-show-register')),
      120,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-show-register')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('register-username')),
      'reader123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'reader@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-display-name')),
      'Reader',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password')),
      'secret123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm-password')),
      'secret123',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('register-submit')),
      120,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('register-submit')));
    await tester.pump();

    expect(authRepository.lastRegister?.username, 'reader123');
    expect(authRepository.lastRegister?.email, 'reader@example.com');
    expect(authRepository.lastRegister?.displayName, 'Reader');
    expect(authRepository.lastRegister?.password, 'secret123');
  });

  testWidgets('keeps the account signed in after closing and reopening', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository(
      authenticatedUser: _testAuthUser,
      expireOnRefresh: true,
    );
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        authRepository: authRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_shellDestination('حسابي'));
    await tester.pumpAndSettle();
    await _showOptionalLogin(tester);

    await tester.enterText(
      find.byKey(const ValueKey('login-username')),
      'reader@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'secret-value',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('login-submit')),
      120,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('قارئ الاختبار'), findsOneWidget);

    await tester.tap(_shellDestination('الرئيسية'));
    await tester.pumpAndSettle();
    await tester.tap(_shellDestination('حسابي'));
    await tester.pumpAndSettle();

    expect(find.text('قارئ الاختبار'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-submit')), findsNothing);
    expect(authRepository.refreshProfileCalls, 0);
  });

  testWidgets('signed in account can log out', (tester) async {
    final authRepository = FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_testAuthUser),
    );
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        authRepository: authRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_shellDestination('حسابي'));
    await tester.pumpAndSettle();

    expect(find.text('قارئ الاختبار'), findsOneWidget);
    await tester.ensureVisible(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();

    expect(find.text('تتصفح كزائر'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-submit')), findsNothing);
    expect(find.byKey(const ValueKey('auth-show-login')), findsOneWidget);
  });

  testWidgets('signed in account shows cached XP statistics without refresh', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final authRepository = FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_testAuthUser),
    );
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        authRepository: authRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_shellDestination('حسابي'));
    await tester.pumpAndSettle();

    expect(authRepository.refreshProfileCalls, 0);
    expect(find.text('نقاط XP'), findsOneWidget);
    expect(find.text('XP اليوم'), findsOneWidget);
    expect(find.text('الفصول المقروءة'), findsOneWidget);
    expect(find.text('مستكشف'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer keeps the light destinations and settings opens about', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-drawer-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('drawer-destination-account')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('drawer-destination-favorites')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('drawer-destination-settings')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('drawer-destination-downloads')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('drawer-destination-about')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('drawer-destination-privacy')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('drawer-destination-discord')),
      findsOneWidget,
    );
    expect(find.text('مجتمع Discord'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Drawer), matching: find.text('المفضلة')),
      findsOneWidget,
    );
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('إعدادات القراءة'), findsNothing);
    expect(find.text('الاشتراك و VIP'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('drawer-destination-settings')));
    await tester.pumpAndSettle();
    final about = find.byKey(const ValueKey('settings-about'));
    await tester.ensureVisible(about);
    await tester.pumpAndSettle();
    await tester.tap(about);
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
    final version = tester.widget<Text>(
      find.byKey(const ValueKey('about-app-version')),
    );
    expect(version.data, startsWith('الإصدار '));
    expect(find.text('تراخيص البرمجيات المفتوحة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings screen keeps reader settings shared after reopening', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final preferencesRepository = FakeReaderPreferencesRepository();
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        readerPreferencesRepository: preferencesRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-drawer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsWidgets);
    expect(find.text('إعدادات القراءة'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-hub-screen')), findsOneWidget);
    expect(find.text('الخط والتمرير والمصطلحات وألوان الفصل'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('إعدادات القراءة'),
      120,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعدادات القراءة'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-settings-preview')),
      findsOneWidget,
    );
    expect(find.text('100%'), findsOneWidget);

    final fontIncrease = find.byKey(const ValueKey('reader-font-increase'));
    await tester.ensureVisible(fontIncrease);
    await tester.pumpAndSettle();
    expect(fontIncrease.hitTestable(), findsOneWidget);
    await tester.tap(fontIncrease);
    await tester.pumpAndSettle();

    expect(preferencesRepository.value.fontScale, 1.1);
    expect(find.text('110%'), findsOneWidget);

    Navigator.of(
      tester.element(find.byKey(const ValueKey('reader-settings-preview'))),
    ).pop();
    await tester.pumpAndSettle();

    Navigator.of(
      tester.element(find.byKey(const ValueKey('settings-hub-screen'))),
    ).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-drawer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('إعدادات القراءة'),
      120,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعدادات القراءة'));
    await tester.pumpAndSettle();

    expect(find.text('110%'), findsOneWidget);
  });

  testWidgets('settings applies the saved app themes immediately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final appThemeController = _TestAppThemeController();
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        appThemeController: appThemeController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-drawer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('theme-choice-card-system')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('theme-choice-card-galaxyNoir')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-choice-card-starlightPaper')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-choice-card-neutralDark')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-choice-card-cosmicNight')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-choice-card-lightNature')),
      findsOneWidget,
    );
    expect(find.text('الفضاء السحيق / Deep Space'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('theme-choice-card-starlightPaper')),
    );
    await tester.pumpAndSettle();

    expect(appThemeController.value, AppThemeChoice.starlightPaper);
    expect(
      Theme.of(
        tester.element(
          find.byKey(const ValueKey('theme-choice-card-starlightPaper')),
        ),
      ).extension<AppThemeTokens>()!.preset,
      AppThemePreset.starlightPaper,
    );

    final galaxyNoirChoice = find.byKey(
      const ValueKey('theme-choice-card-galaxyNoir'),
    );
    await tester.ensureVisible(galaxyNoirChoice);
    await tester.pumpAndSettle();
    await tester.tap(galaxyNoirChoice);
    await tester.pumpAndSettle();

    expect(appThemeController.value, AppThemeChoice.galaxyNoir);
  });

  testWidgets('settings theme cards fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-drawer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('theme-choice-card-system')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('theme-choice-card-galaxyNoir')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-choice-card-starlightPaper')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home screen renders repository-provided sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );

    expect(find.bySemanticsLabel('جار تحميل الرئيسية...'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('اختبار المجرة'), findsOneWidget);
    expect(find.text('رواية الاختبار'), findsWidgets);
    expect(find.text('مختارة من المجرة'), findsNothing);
    expect(find.byKey(const ValueKey('updated-novels-strip')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('updated-novel-spotlight-1')),
      findsNothing,
    );

    await _scrollHomeDown(tester);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('latest-update-5')),
        matching: find.text('الفصل 5'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('home fits a narrow phone without recent novel overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeDataWithMultipleRecent()),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await _scrollHomeDown(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('latest updates header keeps the count hidden', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeDataWithLatestCount(50)),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await _scrollHomeDown(tester);

    final countChip = find.byKey(const ValueKey('latest-updates-count-chip'));
    expect(countChip, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home cover images request cache-sized decodes', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeDataWithCoverImages()),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final images = tester.widgetList<Image>(find.byType(Image));

    expect(images.any((image) => image.image is ResizeImage), isTrue);
  });

  testWidgets('home prefers local history and continues in native reader', (
    tester,
  ) async {
    final historyRepository = _TestReadingHistoryRepository();
    String? requestedContentApi;
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        readerRepository: _TestReaderRepository(
          onLoad: (value) => requestedContentApi = value,
        ),
        readingHistoryRepository: historyRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('اختبار المجرة'), findsOneWidget);

    await historyRepository.record(
      local_progress.ReadingProgress(
        novelId: 99,
        novelTitle: 'رواية السجل المحلي',
        chapterId: 2,
        chapterTitle: 'الفصل 2',
        contentApi: '/wp-json/wor-reader-app/v1/chapters/2',
        chapterPosition: 2,
        chaptersTotal: 100,
        updatedAt: DateTime.utc(2026, 6, 22),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('رواية السجل المحلي'), findsOneWidget);
    expect(find.text('الفصل 2 من 100'), findsOneWidget);
    expect(find.text('اختبار المجرة'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('continue-reading-tile')));
    await tester.pumpAndSettle();

    expect(requestedContentApi, '/wp-json/wor-reader-app/v1/chapters/2');
    expect(find.text('قارئ تجريبي'), findsOneWidget);
  });

  testWidgets('home opens the selected entry from the reading history strip', (
    tester,
  ) async {
    String? requestedContentApi;
    final historyRepository = _TestReadingHistoryRepository(
      items: [
        local_progress.ReadingProgress(
          novelId: 99,
          novelTitle: 'رواية السجل الأولى',
          chapterId: 7,
          chapterTitle: 'الفصل 7',
          contentApi: '/chapters/7',
          chapterPosition: 7,
          chaptersTotal: 40,
          updatedAt: DateTime.utc(2026, 7, 19, 12),
        ),
        local_progress.ReadingProgress(
          novelId: 100,
          novelTitle: 'رواية السجل الثانية',
          chapterId: 3,
          chapterTitle: 'الفصل 3',
          contentApi: '/chapters/3',
          chapterPosition: 3,
          chaptersTotal: 20,
          updatedAt: DateTime.utc(2026, 7, 19, 11),
        ),
      ],
    );
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        readerRepository: _TestReaderRepository(
          onLoad: (contentApi) => requestedContentApi = contentApi,
        ),
        readingHistoryRepository: historyRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('continue-reading-deck-draggable')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-reading-tile')));
    await tester.pumpAndSettle();

    expect(requestedContentApi, '/chapters/3');
    expect(find.text('قارئ تجريبي'), findsOneWidget);
  });

  testWidgets('home continue reading row keeps the saved novel cover', (
    tester,
  ) async {
    final historyRepository = _TestReadingHistoryRepository();
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        readingHistoryRepository: historyRepository,
      ),
    );
    await tester.pumpAndSettle();

    await historyRepository.record(
      local_progress.ReadingProgress(
        novelId: 99,
        novelTitle: 'رواية بغلاف',
        chapterId: 2,
        chapterTitle: 'الفصل 2',
        contentApi: '/wp-json/wor-reader-app/v1/chapters/2',
        coverUrl: '/wp-content/uploads/covers/local-cover.jpg',
        chapterPosition: 2,
        chaptersTotal: 100,
        updatedAt: DateTime.utc(2026, 6, 22),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('continue-reading-card-0'));
    final cover = tester.widget<NovelCover>(
      find.descendant(of: card, matching: find.byType(NovelCover)),
    );
    expect(cover.title, 'رواية بغلاف');
    expect(cover.imageUrl, '/wp-content/uploads/covers/local-cover.jpg');
  });

  testWidgets('latest update opens the novel details screen', (tester) async {
    String? requestedContentApi;
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        readerRepository: _TestReaderRepository(
          onLoad: (value) => requestedContentApi = value,
        ),
        readingHistoryRepository: _TestReadingHistoryRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final latestUpdate = find.byKey(const ValueKey('latest-update-5'));
    await _scrollHomeDown(tester);
    await tester.ensureVisible(latestUpdate);
    await tester.pumpAndSettle();
    await tester.tap(latestUpdate);
    await tester.pumpAndSettle();

    expect(requestedContentApi, isNull);
    expect(find.byType(NovelDetailsScreen), findsOneWidget);
    expect(find.text('تفاصيل الاختبار'), findsWidgets);
  });

  testWidgets('latest update opens details when home pack omits its manifest', (
    tester,
  ) async {
    String? requestedManifestPath;
    const homeData = HomeData(
      continueReading: null,
      latestChapters: [
        ChapterSummary(
          id: 82,
          novelId: 130585,
          novelTitle: 'تحديث بلا manifest',
          label: 'الفصل 82',
          title: '',
          dateLabel: 'الآن',
          url: '/chapter-82/',
        ),
      ],
      recentNovels: [],
    );

    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: const _TestHomeRepository(homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: _TestNovelRepository(
          onLoad: (value) => requestedManifestPath = value,
        ),
        readingHistoryRepository: _TestReadingHistoryRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('latest-update-82')));
    await tester.pumpAndSettle();

    expect(
      requestedManifestPath,
      '/wp-content/uploads/wor-reader-cache/app/manifest/novel-130585.json',
    );
    expect(find.byType(NovelDetailsScreen), findsOneWidget);
  });

  testWidgets(
    'latest updates use the configured list without an inline toggle',
    (tester) async {
      await tester.pumpWidget(
        GalaxyNovelsApp(
          homeRepository: _TestHomeRepository(_homeData),
          catalogRepository: const _TestCatalogRepository(),
          novelRepository: const _TestNovelRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollHomeDown(tester);

      expect(find.text('آخر تحديثات الروايات'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('latest-updates-count-chip')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('latest-update-5')),
          matching: find.text('الفصل 5'),
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('عرض كشبكة'), findsNothing);
      expect(find.byTooltip('عرض كقائمة'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('latest-update-5')));
      await tester.pumpAndSettle();

      expect(find.byType(NovelDetailsScreen), findsOneWidget);
    },
  );

  testWidgets('latest update card keeps the novel title bounded', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollHomeDown(tester);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'نجوم الاختبار' &&
            widget.maxLines == 2 &&
            widget.overflow == TextOverflow.ellipsis,
      ),
      findsOneWidget,
    );
  });

  testWidgets('recent novels are shown before latest updates', (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final recentTop = tester.getTopLeft(find.text('روايات محدثة')).dy;
    final latestTop = tester.getTopLeft(find.text('آخر تحديثات الروايات')).dy;

    expect(recentTop, lessThan(latestTop));
  });

  testWidgets('catalog tab renders repository-provided novels', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();

    expect(find.text('مكتبة الاختبار'), findsOneWidget);
    expect(find.text('ابحث عن رواية...'), findsOneWidget);
    expect(find.text('2 رواية'), findsOneWidget);
  });

  testWidgets('catalog exposes active filters as compact chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('كل التصنيفات'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(FilterChip),
        matching: find.text('مكتملة'),
      ),
    );
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('catalog-active-filter-status')),
      findsOneWidget,
    );
    expect(find.text('الحالة: مكتملة'), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-clear-query')), findsOneWidget);
  });

  testWidgets('catalog uses a lazy sliver grid on narrow phones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('catalog-sliver-grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog search filters results locally', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'غير موجود');
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);

    await tester.tap(find.text('مسح البحث والفلاتر'));
    await tester.pumpAndSettle();

    expect(find.text('مكتبة الاختبار'), findsOneWidget);
  });

  testWidgets('catalog search can use the public search index', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        searchRepository: const _TestSearchRepository.withExternalResult(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'خارجي');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('بحث خارجي'), findsOneWidget);
    expect(find.text('مكتبة الاختبار'), findsNothing);
  });

  testWidgets('catalog filters are applied from the bottom sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('كل التصنيفات'));
    await tester.pumpAndSettle();

    expect(find.text('الحالة'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(FilterChip),
        matching: find.text('مكتملة'),
      ),
    );
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    expect(find.text('مكتملة الاختبار'), findsOneWidget);
    expect(find.text('مكتبة الاختبار'), findsNothing);
  });

  testWidgets('catalog keeps data visible when a later pack fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _BackgroundErrorCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();

    expect(find.text('مكتبة الاختبار'), findsOneWidget);
    expect(find.text('تعذر تحميل بقية المكتبة'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('loads personal state for the opened novel', (tester) async {
    final engagementRepository = FakeNovelEngagementRepository(
      state: _personalState(novelId: 99),
    );

    await _pumpOpenedDetails(
      tester,
      authRepository: FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_testAuthUser),
      ),
      engagementRepository: engagementRepository,
    );
    await _revealPersonalState(
      tester,
      find.byKey(const ValueKey('novel-details-rating-action')),
    );

    expect(engagementRepository.loadedNovelIds, [99]);
    expect(find.text('تقييمك: 4 من 5'), findsOneWidget);
  });

  testWidgets('matching last read chapter becomes the native continue action', (
    tester,
  ) async {
    String? openedApi;
    final engagementRepository = FakeNovelEngagementRepository(
      state: _personalState(
        novelId: 99,
        lastRead: const NovelLastRead(
          chapterId: 2,
          chapterUrl: '/chapter-2/',
          progress: 45,
          updatedAt: null,
        ),
      ),
    );

    await _pumpOpenedDetails(
      tester,
      authRepository: FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_testAuthUser),
      ),
      engagementRepository: engagementRepository,
      readerRepository: _TestReaderRepository(onLoad: (api) => openedApi = api),
    );

    await _revealPersonalState(tester, find.text('متابعة الفصل 2'));
    expect(find.text('متابعة الفصل 2'), findsOneWidget);
    await tester.tap(find.text('متابعة الفصل 2'));
    await tester.pumpAndSettle();

    expect(openedApi, '/wp-json/wor-reader-app/v1/chapters/2');
  });

  testWidgets('authenticated reader edits the personal rating', (tester) async {
    final engagementRepository = FakeNovelEngagementRepository(
      state: _personalState(novelId: 99),
      submitHandler: (_, _) async => 5,
    );

    await _pumpOpenedDetails(
      tester,
      authRepository: FakeAuthRepository(
        initialState: const AuthSessionState.authenticated(_testAuthUser),
      ),
      engagementRepository: engagementRepository,
    );
    await _revealPersonalState(
      tester,
      find.byKey(const ValueKey('novel-details-rating-action')),
    );

    await tester.tap(find.byKey(const ValueKey('novel-details-rating-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('personal-rating-5')));
    await tester.tap(find.text('حفظ التقييم'));
    await tester.pumpAndSettle();

    expect(engagementRepository.submittedRatings, [(99, 5)]);
    expect(find.text('تم حفظ تقييمك'), findsOneWidget);
  });

  testWidgets('guest rating action opens the account screen', (tester) async {
    await _pumpOpenedDetails(
      tester,
      authRepository: FakeAuthRepository(),
      engagementRepository: FakeNovelEngagementRepository(),
    );
    await _revealPersonalState(
      tester,
      find.byKey(const ValueKey('novel-details-rating-action')),
    );

    await tester.tap(find.byKey(const ValueKey('novel-details-rating-action')));
    await tester.pumpAndSettle();

    expect(find.text('حسابي'), findsOneWidget);
    expect(find.text('تتصفح كزائر'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-submit')), findsNothing);
    expect(find.byKey(const ValueKey('auth-show-login')), findsOneWidget);
  });

  testWidgets('opens novel details from the catalog', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        readerRepository: const _TestReaderRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مكتبة الاختبار'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('novel-details-hero')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('هذه نبذة تفاصيل الاختبار.'),
      420,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('هذه نبذة تفاصيل الاختبار.'), findsOneWidget);
    expect(find.text('ابدأ القراءة'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('الفصل 1'),
      320,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('الفصل 1'), findsOneWidget);

    await tester.tap(find.text('ابدأ القراءة'));
    await tester.pumpAndSettle();

    expect(find.text('الفصل 1'), findsWidgets);
    expect(find.text('قارئ تجريبي'), findsOneWidget);
    expect(find.text('القارئ سيكون في المرحلة التالية'), findsNothing);
  });

  testWidgets('opens novel details from the home screen', (tester) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final homeNovelTitle = find.text('رواية الاختبار').first;
    await tester.ensureVisible(homeNovelTitle);
    await tester.pumpAndSettle();
    await tester.tap(homeNovelTitle);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('novel-details-hero')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('هذه نبذة تفاصيل الاختبار.'),
      420,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('هذه نبذة تفاصيل الاختبار.'), findsOneWidget);
  });

  testWidgets(
    'novel details hides read button when no chapters are available',
    (tester) async {
      await tester.pumpWidget(
        GalaxyNovelsApp(
          homeRepository: _TestHomeRepository(_homeData),
          catalogRepository: const _TestCatalogRepository(),
          novelRepository: const _EmptyNovelRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('المكتبة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('مكتبة الاختبار'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('لا توجد فصول متاحة للعرض الآن'),
        420,
        scrollable: _verticalScrollable(),
      );
      await tester.pumpAndSettle();

      expect(find.text('لا توجد فصول متاحة للعرض الآن'), findsOneWidget);
      expect(find.text('ابدأ القراءة'), findsNothing);
    },
  );

  testWidgets('rankings destination renders repository-provided novels', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        rankingsRepository: const _TestRankingsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_shellDestination('الترتيب'));
    await tester.pumpAndSettle();

    expect(find.text('ترتيب الاختبار'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('15.0K مشاهدة'), findsOneWidget);
    expect(find.textContaining('150 فصل'), findsNothing);
    expect(find.text('حارس النجوم'), findsNothing);
  });

  testWidgets('rankings destination highlights the top three novels', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        rankingsRepository: const _TestRankingsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_shellDestination('الترتيب'));
    await tester.pumpAndSettle();

    expect(find.text('ترتيب الروايات'), findsOneWidget);
    expect(find.text('الأعلى مشاهدة داخل المجرة'), findsOneWidget);
    expect(find.text('هذا الشهر'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('rankings-podium-horizontal')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ranking-top-pick-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('ranking-top-pick-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('ranking-top-pick-3')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ranking-list-row-4')),
      320,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ranking-list-row-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('rankings-table')), findsOneWidget);
  });

  testWidgets('rankings destination fits a narrow phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GalaxyNovelsApp(
        homeRepository: _TestHomeRepository(_homeData),
        catalogRepository: const _TestCatalogRepository(),
        novelRepository: const _TestNovelRepository(),
        rankingsRepository: const _TestRankingsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_shellDestination('الترتيب'));
    await tester.pumpAndSettle();
    await tester.drag(_verticalScrollable(), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Finder _shellDestination(String label) {
  return find.descendant(
    of: find.byWidgetPredicate(
      (widget) =>
          widget is NavigationBar ||
          widget is NavigationRail ||
          widget is NavigationDrawer,
    ),
    matching: find.text(label),
  );
}

Future<void> _pumpOpenedDetails(
  WidgetTester tester, {
  required FakeAuthRepository authRepository,
  required NovelEngagementRepository engagementRepository,
  ReaderRepository readerRepository = const _TestReaderRepository(),
}) async {
  await tester.pumpWidget(
    GalaxyNovelsApp(
      homeRepository: _TestHomeRepository(_homeData),
      catalogRepository: const _TestCatalogRepository(),
      novelRepository: const _TestNovelRepository(includeSecondChapter: true),
      readerRepository: readerRepository,
      authRepository: authRepository,
      novelEngagementRepository: engagementRepository,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('المكتبة'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('مكتبة الاختبار'));
  await tester.pumpAndSettle();
}

Future<void> _revealPersonalState(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    160,
    scrollable: _verticalScrollable(),
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

NovelUserState _personalState({
  required int novelId,
  int rating = 4,
  NovelLastRead lastRead = const NovelLastRead(
    chapterId: 0,
    chapterUrl: '',
    progress: 0,
    updatedAt: null,
  ),
}) {
  return NovelUserState(
    novelId: novelId,
    favorite: false,
    myRating: rating,
    lastRead: lastRead,
    vip: const NovelVipAccess(active: false, canReadPrivate: false),
  );
}

Future<void> _scrollHomeDown(WidgetTester tester) async {
  final mainList = find
      .descendant(
        of: find.byKey(const ValueKey('home-scroll-view')),
        matching: find.byType(Scrollable),
      )
      .first;

  await tester.drag(mainList, const Offset(0, -640));
  await tester.pumpAndSettle();
}

Finder _verticalScrollable() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
}

Future<void> _showOptionalLogin(WidgetTester tester) async {
  final action = find.byKey(const ValueKey('auth-show-login'));
  await tester.ensureVisible(action);
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pumpAndSettle();
}

const _homeData = HomeData(
  continueReading: ReadingProgress(
    novelTitle: 'اختبار المجرة',
    chapterLabel: 'الفصل 5',
    progress: 42,
  ),
  latestChapters: [
    ChapterSummary(
      id: 5,
      novelId: 1,
      novelTitle: 'نجوم الاختبار',
      label: 'الفصل 5',
      title: '',
      dateLabel: 'الآن',
      url: '/chapter-5/',
      chapters: [
        ChapterSummaryItem(
          id: 5,
          label: 'الفصل 5',
          title: 'عنوان الاختبار',
          dateLabel: 'الآن',
          url: '/chapter-5/',
        ),
      ],
    ),
  ],
  recentNovels: [
    NovelSummary(
      id: 1,
      title: 'رواية الاختبار',
      url: '/novel/test/',
      coverThumbnail: '',
      statusLabel: 'مستمرة',
      genres: ['خيال'],
      chaptersCount: 12,
      manifest: '/novel-home-test.json',
    ),
  ],
);

HomeData _homeDataWithMultipleRecent() {
  return HomeData(
    continueReading: _homeData.continueReading,
    latestChapters: _homeData.latestChapters,
    recentNovels: [
      ..._homeData.recentNovels,
      const NovelSummary(
        id: 2,
        title: 'عنوان طويل لرواية ثانية لا يجب أن يسبب overflow',
        url: '/novel/second/',
        coverThumbnail: '',
        statusLabel: 'مستمرة',
        genres: ['أكشن'],
        chaptersCount: 100,
        manifest: '/novel-second.json',
      ),
    ],
  );
}

HomeData _homeDataWithLatestCount(int count) {
  return HomeData(
    continueReading: _homeData.continueReading,
    recentNovels: _homeData.recentNovels,
    latestChapters: List.generate(count, (index) {
      final chapterNumber = index + 1;
      return ChapterSummary(
        id: chapterNumber,
        novelId: 1,
        novelTitle: 'نجوم الاختبار',
        label: 'الفصل $chapterNumber',
        title: '',
        dateLabel: 'الآن',
        url: '/chapter-$chapterNumber/',
        chapters: [
          ChapterSummaryItem(
            id: chapterNumber,
            label: 'الفصل $chapterNumber',
            title: 'عنوان الاختبار',
            dateLabel: 'الآن',
            url: '/chapter-$chapterNumber/',
          ),
        ],
      );
    }),
  );
}

HomeData _homeDataWithCoverImages() {
  return HomeData(
    continueReading: _homeData.continueReading,
    latestChapters: const [],
    recentNovels: [
      const NovelSummary(
        id: 1,
        title: 'رواية الاختبار',
        url: '/novel/test/',
        coverThumbnail: '/wp-content/uploads/test-cover.jpg',
        statusLabel: 'مستمرة',
        genres: ['خيال'],
        chaptersCount: 12,
        manifest: '/novel-home-test.json',
      ),
      const NovelSummary(
        id: 2,
        title: 'رواية ثانية',
        url: '/novel/second/',
        coverThumbnail: '/wp-content/uploads/test-cover-2.jpg',
        statusLabel: 'مستمرة',
        genres: ['أكشن'],
        chaptersCount: 100,
        manifest: '/novel-second.json',
      ),
    ],
  );
}

const _testAuthUser = AuthUser(
  id: 7,
  displayName: 'قارئ الاختبار',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 120,
    today: 10,
    secondsTotal: 600,
    chaptersTotal: 8,
    rank: AuthRank(level: 2, display: 'مستكشف'),
  ),
);

const _testVipAuthUser = AuthUser(
  id: 8,
  displayName: 'قارئ VIP',
  avatar: null,
  vip: AuthVip(active: true, tier: 'max', label: 'VIP Max', expiresAt: null),
  xp: AuthXp(
    total: 120,
    today: 10,
    secondsTotal: 600,
    chaptersTotal: 8,
    rank: AuthRank(level: 2, display: 'مستكشف'),
  ),
);

class _StartupRestoringAuthRepository extends FakeAuthRepository {
  _StartupRestoringAuthRepository({required this.restoredState})
    : super(initialState: const AuthSessionState.idle());

  final AuthSessionState restoredState;
  int restoreCalls = 0;

  @override
  Future<void> restoreSession() async {
    restoreCalls += 1;
    value = restoredState;
  }
}

class _TestHomeRepository implements HomeRepository {
  const _TestHomeRepository(this.data);

  final HomeData data;

  @override
  Future<HomeData> loadHome() async => data;
}

class _TestCatalogRepository implements CatalogRepository {
  const _TestCatalogRepository();

  @override
  Stream<CatalogLoadState> watchCatalog() async* {
    yield const CatalogLoadState(
      items: [
        CatalogNovel(
          id: 99,
          title: 'مكتبة الاختبار',
          originalTitle: '',
          url: '/novel/catalog-test/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'ongoing',
          statusLabel: 'مستمرة',
          genres: [CatalogGenre(id: 1, name: 'أكشن', slug: 'action')],
          chaptersCount: 10,
          ratingAverage: 4.2,
          ratingCount: 5,
          views: 100,
          updatedAt: null,
          manifest: '/novel-catalog-test.json',
        ),
        CatalogNovel(
          id: 100,
          title: 'مكتملة الاختبار',
          originalTitle: '',
          url: '/novel/completed-test/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'completed',
          statusLabel: 'مكتملة',
          genres: [CatalogGenre(id: 2, name: 'دراما', slug: 'drama')],
          chaptersCount: 20,
          ratingAverage: 4.6,
          ratingCount: 8,
          views: 200,
          updatedAt: null,
          manifest: '',
        ),
      ],
      loadedParts: 1,
      totalParts: 1,
      isLoadingMore: false,
    );
  }
}

class _TestRankingsRepository implements RankingsRepository {
  const _TestRankingsRepository();

  @override
  Future<RankingsData> loadRankings() async {
    return const RankingsData(
      period: 'month',
      items: [
        CatalogNovel(
          id: 77,
          title: 'ترتيب الاختبار',
          originalTitle: '',
          url: '/novel/ranking-test/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'ongoing',
          statusLabel: 'مستمرة',
          genres: [CatalogGenre(id: 1, name: 'أكشن', slug: 'action')],
          chaptersCount: 150,
          ratingAverage: 4.8,
          ratingCount: 22,
          views: 15000,
          updatedAt: null,
          manifest: '/manifest/novel-77.json',
        ),
        CatalogNovel(
          id: 78,
          title: 'سيدة العوالم',
          originalTitle: '',
          url: '/novel/world-lady/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'ongoing',
          statusLabel: 'مستمرة',
          genres: [CatalogGenre(id: 2, name: 'فانتازيا', slug: 'fantasy')],
          chaptersCount: 98,
          ratingAverage: 4.6,
          ratingCount: 18,
          views: 12000,
          updatedAt: null,
          manifest: '/manifest/novel-78.json',
        ),
        CatalogNovel(
          id: 79,
          title: 'بوابة الاختبار',
          originalTitle: '',
          url: '/novel/test-gate/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'completed',
          statusLabel: 'مكتملة',
          genres: [CatalogGenre(id: 3, name: 'دراما', slug: 'drama')],
          chaptersCount: 64,
          ratingAverage: 4.3,
          ratingCount: 12,
          views: 9300,
          updatedAt: null,
          manifest: '/manifest/novel-79.json',
        ),
        CatalogNovel(
          id: 80,
          title: 'المرتبة الرابعة',
          originalTitle: '',
          url: '/novel/fourth-rank/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'ongoing',
          statusLabel: 'مستمرة',
          genres: [CatalogGenre(id: 4, name: 'أكشن', slug: 'action')],
          chaptersCount: 42,
          ratingAverage: 4.1,
          ratingCount: 9,
          views: 8700,
          updatedAt: null,
          manifest: '/manifest/novel-80.json',
        ),
      ],
    );
  }
}

class _TestSearchRepository implements SearchRepository {
  const _TestSearchRepository(this.index);

  const _TestSearchRepository.empty() : index = const SearchIndex(items: []);

  const _TestSearchRepository.withExternalResult()
    : index = const SearchIndex(
        items: [
          SearchIndexItem(
            id: 700,
            title: 'بحث خارجي',
            originalTitle: '',
            url: '/novel/external-search/',
            cover: '',
            genres: ['خيال'],
            chaptersCount: 77,
            statusLabel: 'مستمرة',
            views: 900,
            normalizedSearch: 'بحث خارجي',
            manifest:
                '/wp-content/uploads/wor-reader-cache/app/manifest/novel-700.json',
          ),
        ],
      );

  final SearchIndex index;

  @override
  Future<SearchIndex> loadSearchIndex() async => index;
}

class _BackgroundErrorCatalogRepository implements CatalogRepository {
  const _BackgroundErrorCatalogRepository();

  @override
  Stream<CatalogLoadState> watchCatalog() async* {
    yield const CatalogLoadState(
      items: [
        CatalogNovel(
          id: 99,
          title: 'مكتبة الاختبار',
          originalTitle: '',
          url: '/novel/catalog-test/',
          coverThumbnail: '',
          coverMedium: '',
          statusKey: 'ongoing',
          statusLabel: 'مستمرة',
          genres: [CatalogGenre(id: 1, name: 'أكشن', slug: 'action')],
          chaptersCount: 10,
          ratingAverage: 4.2,
          ratingCount: 5,
          views: 100,
          updatedAt: null,
          manifest: '',
        ),
      ],
      loadedParts: 1,
      totalParts: 2,
      isLoadingMore: false,
      backgroundError: 'Second pack failed.',
    );
  }
}

class _EmptyNovelRepository implements NovelRepository {
  const _EmptyNovelRepository();

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    return const NovelDetailsLoadResult(
      details: NovelDetails(
        id: 101,
        title: 'تفاصيل بلا فصول',
        originalTitle: '',
        url: '/novel/no-chapters/',
        coverThumbnail: '',
        coverMedium: '',
        coverLarge: '',
        statusKey: 'ongoing',
        statusLabel: 'مستمرة',
        country: '',
        author: '',
        translator: '',
        genres: [],
        chaptersCount: 10,
        firstChapterId: 0,
        firstChapterUrl: '',
        ratingAverage: 0,
        ratingCount: 0,
        views: 0,
        updatedAt: null,
        summary: 'لا توجد فصول بعد.',
        chaptersManifest: '',
        vipScheduleManifest: '',
        manifest: '/novel-empty.json',
      ),
      chapters: [],
    );
  }
}

class _TestNovelRepository implements NovelRepository {
  const _TestNovelRepository({this.includeSecondChapter = false, this.onLoad});

  final bool includeSecondChapter;
  final ValueChanged<String>? onLoad;

  @override
  Future<NovelDetailsLoadResult> loadNovel(String manifestPath) async {
    onLoad?.call(manifestPath);
    return NovelDetailsLoadResult(
      details: const NovelDetails(
        id: 99,
        title: 'تفاصيل الاختبار',
        originalTitle: 'Test Details',
        url: '/novel/details-test/',
        coverThumbnail: '',
        coverMedium: '',
        coverLarge: '',
        statusKey: 'ongoing',
        statusLabel: 'مستمرة',
        country: 'cn',
        author: 'كاتب الاختبار',
        translator: '',
        genres: [NovelGenre(id: 1, name: 'أكشن', slug: 'action')],
        chaptersCount: 2,
        firstChapterId: 1,
        firstChapterUrl: '/chapter-1/',
        ratingAverage: 4.2,
        ratingCount: 5,
        views: 120,
        updatedAt: null,
        summary: 'هذه نبذة تفاصيل الاختبار.',
        chaptersManifest: '/chapters.json',
        vipScheduleManifest: '',
        manifest: '/novel-test.json',
      ),
      chapters: [
        const NovelChapter(
          id: 1,
          position: 1,
          number: '1',
          label: 'الفصل 1',
          title: 'البداية',
          url: '/chapter-1/',
          contentApi: '/wp-json/wor-reader-app/v1/chapters/1',
          dateLabel: 'اليوم',
          dateIso: null,
          views: 0,
          comments: 0,
          search: '',
        ),
        if (includeSecondChapter)
          const NovelChapter(
            id: 2,
            position: 2,
            number: '2',
            label: 'الفصل 2',
            title: 'المتابعة',
            url: '/chapter-2/',
            contentApi: '/wp-json/wor-reader-app/v1/chapters/2',
            dateLabel: 'اليوم',
            dateIso: null,
            views: 0,
            comments: 0,
            search: '',
          ),
      ],
    );
  }
}

class _TestReaderRepository implements ReaderRepository {
  const _TestReaderRepository({this.onLoad});

  final ValueChanged<String>? onLoad;

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    onLoad?.call(contentApi);
    return const ReaderChapterContent(
      id: 1,
      novelId: 99,
      label: 'الفصل 1',
      title: '',
      displayTitle: 'الفصل 1',
      position: 1,
      total: 2,
      contentHtml: '<p>قارئ تجريبي</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '',
        previousId: 0,
        nextId: 0,
      ),
    );
  }
}

class _TestReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  _TestReadingHistoryRepository({
    List<local_progress.ReadingProgress> items = const [],
  }) : _items = [...items];

  List<local_progress.ReadingProgress> _items;

  @override
  Future<List<local_progress.ReadingProgress>> load() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<void> record(local_progress.ReadingProgress progress) async {
    _items = [
      progress,
      for (final item in _items)
        if (item.novelId != progress.novelId) item,
    ];
    notifyListeners();
  }
}

class _CountingHomeAdRepository implements HomeAdRepository {
  int initializeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
  }

  @override
  Widget? buildHomeNativeAd(BuildContext context) => null;
}

class _TestAppThemeController extends ChangeNotifier
    implements AppThemeController {
  _TestAppThemeController();

  AppThemeChoice _value = AppThemeChoice.galaxyNoir;

  @override
  AppThemeChoice get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(AppThemeChoice choice) async {
    if (_value == choice) {
      return;
    }
    _value = choice;
    notifyListeners();
  }
}
