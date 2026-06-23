import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/galaxy_novels_app.dart';
import 'package:galaxy_novels_app/data/models/catalog_data.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_downloads_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/novel_repository.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/favorites/domain/favorite_item.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_favorites_repository.dart';

void main() {
  testWidgets('opens account favorites from the drawer and removes an item', (
    tester,
  ) async {
    final favoritesRepository = FakeFavoritesRepository(
      userId: 7,
      items: [_favoriteItem],
    );
    await tester.pumpWidget(_testApp(favoritesRepository: favoritesRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المفضلة'));
    await tester.pumpAndSettle();

    expect(find.text('رواية محفوظة'), findsOneWidget);
    expect(find.text('عرض التفاصيل'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('remove-favorite-99')));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد روايات مفضلة بعد'), findsOneWidget);
    expect(favoritesRepository.value.contains(99), isFalse);
  });

  testWidgets('toggles the loaded novel from the fixed details action bar', (
    tester,
  ) async {
    final favoritesRepository = FakeFavoritesRepository(userId: 7);
    await tester.pumpWidget(_testApp(favoritesRepository: favoritesRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('رواية المفضلة'));
    await tester.pumpAndSettle();

    final toggle = find.byKey(const ValueKey('novel-favorite-toggle'));
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(favoritesRepository.value.contains(99), isTrue);
    expect(
      find.descendant(
        of: toggle,
        matching: find.byIcon(Icons.bookmark_rounded),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(favoritesRepository.value.contains(99), isFalse);
  });
}

Widget _testApp({required FakeFavoritesRepository favoritesRepository}) {
  return GalaxyNovelsApp(
    homeRepository: const FakeHomeRepository(),
    catalogRepository: const FakeCatalogRepository([_catalogNovel]),
    novelRepository: const FakeNovelRepository(result: _novelResult),
    downloadsRepository: FakeDownloadsRepository(),
    authRepository: FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_user),
    ),
    favoritesRepository: favoritesRepository,
  );
}

const _catalogNovel = CatalogNovel(
  id: 99,
  title: 'رواية المفضلة',
  originalTitle: '',
  url: '/novel/favorite/',
  coverThumbnail: '',
  coverMedium: '',
  statusKey: 'ongoing',
  statusLabel: 'مستمرة',
  genres: [],
  chaptersCount: 0,
  ratingAverage: 0,
  ratingCount: 0,
  views: 0,
  updatedAt: null,
  manifest: '/manifest/novel-99.json',
);

const _novelResult = NovelDetailsLoadResult(
  details: NovelDetails(
    id: 99,
    title: 'رواية المفضلة',
    originalTitle: '',
    url: '/novel/favorite/',
    coverThumbnail: '',
    coverMedium: '',
    coverLarge: '',
    statusKey: 'ongoing',
    statusLabel: 'مستمرة',
    country: '',
    author: '',
    translator: '',
    genres: [],
    chaptersCount: 0,
    firstChapterId: 0,
    firstChapterUrl: '',
    ratingAverage: 0,
    ratingCount: 0,
    views: 0,
    updatedAt: null,
    summary: '',
    chaptersManifest: '',
    vipScheduleManifest: '',
    manifest: '/manifest/novel-99.json',
  ),
  chapters: [],
);

final _favoriteItem = FavoriteItem(
  id: 99,
  title: 'رواية محفوظة',
  url: '/novel/favorite/',
  cover: '',
  manifestPath: '/manifest/novel-99.json',
  addedAt: DateTime.utc(2026, 6, 23),
);

const _user = AuthUser(
  id: 7,
  displayName: 'قارئ المفضلة',
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
