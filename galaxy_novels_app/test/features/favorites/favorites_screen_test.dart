import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/favorites/application/favorites_repository.dart';
import 'package:galaxy_novels_app/features/favorites/domain/favorite_item.dart';
import 'package:galaxy_novels_app/features/favorites/presentation/favorites_screen.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_comments_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';
import '../../helpers/fake_reader_preferences_repository.dart';
import '../../helpers/fake_vip_repository.dart';

void main() {
  testWidgets(
    'empty favorites opens the library once with an accessible action',
    (tester) async {
      var openLibraryCount = 0;
      await tester.pumpWidget(
        _FavoritesTestApp(
          repository: _ControlledFavoritesRepository(userId: 7),
          onOpenLibrary: () => openLibraryCount += 1,
        ),
      );
      await tester.pump();

      final action = find.ancestor(
        of: find.text('فتح المكتبة'),
        matching: find.byType(FilledButton),
      );
      expect(action, findsOneWidget);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
      expect(find.bySemanticsLabel('فتح المكتبة'), findsOneWidget);

      await tester.tap(action);

      expect(openLibraryCount, 1);
    },
  );

  testWidgets(
    'standalone empty favorites opens a titled library route and returns',
    (tester) async {
      await tester.pumpWidget(
        _FavoritesTestApp(
          repository: _ControlledFavoritesRepository(userId: 7),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('فتح المكتبة'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'المكتبة'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.text('لا توجد روايات مفضلة بعد'), findsOneWidget);
    },
  );

  testWidgets('successful removal offers undo and restores the same favorite', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _ControlledFavoritesRepository(
      userId: 7,
      items: [_favoriteItem],
    );
    await tester.pumpWidget(_FavoritesTestApp(repository: repository));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('remove-favorite-99')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.value.contains(99), isFalse);
    expect(find.text('تراجع'), findsOneWidget);

    await tester.tap(find.text('تراجع'));
    await tester.pump();

    expect(repository.value.contains(99), isTrue);
    expect(repository.toggledItems, [_favoriteItem, _favoriteItem]);
  });

  for (final nonRemovalResult in [
    FavoriteToggleResult.failed,
    FavoriteToggleResult.added,
    FavoriteToggleResult.signInRequired,
    FavoriteToggleResult.limitReached,
  ]) {
    testWidgets('$nonRemovalResult never offers removal undo', (tester) async {
      final repository = _ControlledFavoritesRepository(
        userId: 7,
        items: [_favoriteItem],
        nextResult: nonRemovalResult,
      );
      await tester.pumpWidget(_FavoritesTestApp(repository: repository));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('remove-favorite-99')));
      await tester.pump();

      expect(find.text('تراجع'), findsNothing);
    });
  }

  testWidgets('undo does not remove a favorite restored independently', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _ControlledFavoritesRepository(
      userId: 7,
      items: [_favoriteItem],
    );
    await tester.pumpWidget(_FavoritesTestApp(repository: repository));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('remove-favorite-99')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    repository.restoreIndependently(_favoriteItem);
    await tester.pump();

    await tester.tap(find.text('تراجع'));
    await tester.pump();

    expect(repository.value.contains(99), isTrue);
    expect(repository.toggleCalls, 1);
  });

  testWidgets('pending removal cannot expose undo after the account changes', (
    tester,
  ) async {
    final pendingRemoval = Completer<FavoriteToggleResult>();
    final repository = _ControlledFavoritesRepository(
      userId: 7,
      items: [_favoriteItem],
      pendingResult: pendingRemoval,
    );
    final authRepository = FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_userSeven),
    );
    await tester.pumpWidget(
      _FavoritesTestApp(repository: repository, authRepository: authRepository),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('remove-favorite-99')));
    await tester.pump();
    authRepository.value = const AuthSessionState.authenticated(_userEight);
    repository.changeAccount(8);
    await tester.pump();
    pendingRemoval.complete(FavoriteToggleResult.removed);
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('تراجع'), findsNothing);
  });

  testWidgets('favorite rows reflow at 320 pixels and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _FavoritesTestApp(
        repository: _ControlledFavoritesRepository(
          userId: 7,
          items: [_favoriteItem],
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final removeAction = find.byKey(const ValueKey('remove-favorite-99'));
    expect(tester.getSize(removeAction).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(removeAction).height, greaterThanOrEqualTo(44));
    expect(
      find.bySemanticsLabel(RegExp('إزالة رواية محفوظة من المفضلة')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('فتح تفاصيل رواية محفوظة')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _FavoritesTestApp(
        repository: _ControlledFavoritesRepository(userId: 7),
        onOpenLibrary: () {},
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final emptyAction = find.ancestor(
      of: find.text('فتح المكتبة'),
      matching: find.byType(FilledButton),
    );
    expect(tester.getSize(emptyAction).height, greaterThanOrEqualTo(44));
    expect(find.bySemanticsLabel('فتح المكتبة'), findsOneWidget);
  });
}

class _FavoritesTestApp extends StatelessWidget {
  const _FavoritesTestApp({
    required this.repository,
    this.authRepository,
    this.onOpenLibrary,
    this.textScaler = TextScaler.noScaling,
  });

  final FavoritesRepository repository;
  final FakeAuthRepository? authRepository;
  final VoidCallback? onOpenLibrary;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: const FakeNovelRepository(result: null),
      readerRepository: const _UnusedReaderRepository(),
      rankingsRepository: const FakeRankingsRepository(),
      searchRepository: const FakeSearchRepository(),
      readingHistoryRepository: _UnusedReadingHistoryRepository(),
      readerPreferencesRepository: FakeReaderPreferencesRepository(),
      authRepository:
          authRepository ??
          FakeAuthRepository(
            initialState: const AuthSessionState.authenticated(_userSeven),
          ),
      commentsRepository: FakeCommentsRepository.empty(),
      favoritesRepository: repository,
      novelEngagementRepository: FakeNovelEngagementRepository(),
      vipRepository: const FakeVipRepository(),
      child: MaterialApp(
        locale: const Locale('ar'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: FavoritesScreen(onOpenLibrary: onOpenLibrary),
        ),
      ),
    );
  }
}

class _ControlledFavoritesRepository extends ValueNotifier<FavoritesState>
    implements FavoritesRepository {
  _ControlledFavoritesRepository({
    required int userId,
    List<FavoriteItem> items = const [],
    this.nextResult = FavoriteToggleResult.removed,
    this.pendingResult,
  }) : super(
         FavoritesState(
           status: FavoritesLoadStatus.ready,
           userId: userId,
           items: items,
         ),
       );

  final FavoriteToggleResult nextResult;
  final Completer<FavoriteToggleResult>? pendingResult;
  final List<FavoriteItem> toggledItems = [];
  int toggleCalls = 0;

  @override
  Future<void> load() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> syncPending() async {}

  @override
  Future<FavoriteToggleResult> toggle(FavoriteItem favorite) async {
    toggleCalls += 1;
    toggledItems.add(favorite);
    final toggleResult = pendingResult != null && toggleCalls == 1
        ? await pendingResult!.future
        : toggleCalls == 1
        ? nextResult
        : value.contains(favorite.id)
        ? FavoriteToggleResult.removed
        : FavoriteToggleResult.added;
    if (toggleResult == FavoriteToggleResult.removed) {
      _replaceItems(
        value.items.where((candidate) => candidate.id != favorite.id),
      );
    } else if (toggleResult == FavoriteToggleResult.added) {
      _replaceItems([favorite, ...value.items]);
    }
    return toggleResult;
  }

  void restoreIndependently(FavoriteItem favorite) {
    if (!value.contains(favorite.id)) {
      _replaceItems([favorite, ...value.items]);
    }
  }

  void changeAccount(int userId) {
    value = FavoritesState(status: FavoritesLoadStatus.ready, userId: userId);
  }

  void _replaceItems(Iterable<FavoriteItem> favorites) {
    value = FavoritesState(
      status: FavoritesLoadStatus.ready,
      userId: value.userId,
      items: favorites.toList(),
    );
  }
}

class _UnusedReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  @override
  Future<List<ReadingProgress>> load() async => const [];

  @override
  Future<void> record(ReadingProgress progress) async {}
}

class _UnusedReaderRepository implements ReaderRepository {
  const _UnusedReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) {
    throw UnimplementedError();
  }
}

final _favoriteItem = FavoriteItem(
  id: 99,
  title: 'رواية محفوظة',
  url: '/novel/favorite/',
  cover: '',
  manifestPath: '/manifest/novel-99.json',
  addedAt: DateTime.utc(2026, 6, 23),
);

const _userSeven = AuthUser(
  id: 7,
  displayName: 'القارئ الأول',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 1, display: ''),
  ),
);

const _userEight = AuthUser(
  id: 8,
  displayName: 'القارئ الثاني',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 1, display: ''),
  ),
);
