import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/galaxy_novels_app.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/core/analytics/app_screen_names.dart';
import 'package:galaxy_novels_app/data/models/reading_progress.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_rankings_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_search_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/shell/presentation/app_shell.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_favorites_repository.dart';

void main() {
  testWidgets('app wires shell and named page routes to app analytics', (
    tester,
  ) async {
    final analytics = _RecordingAppAnalytics();
    await tester.pumpWidget(
      GalaxyNovelsApp(
        appAnalytics: analytics,
        homeRepository: const FakeHomeRepository(),
        catalogRepository: const FakeCatalogRepository(),
        novelRepository: const FakeNovelRepository(result: null),
        rankingsRepository: const FakeRankingsRepository(),
        searchRepository: const FakeSearchRepository(),
        readingHistoryRepository: _EmptyReadingHistoryRepository(),
        authRepository: FakeAuthRepository(),
        favoritesRepository: FakeFavoritesRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(analytics.screens, contains(AppScreenNames.home));

    final shellContext = tester.element(find.byType(AppShell));
    Navigator.of(shellContext).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.settings),
        builder: (_) => const Scaffold(body: Text('settings-test')),
      ),
    );
    await tester.pumpAndSettle();

    expect(analytics.screens.last, AppScreenNames.settings);
  });
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

class _EmptyReadingHistoryRepository extends ChangeNotifier
    implements ReadingHistoryRepository {
  @override
  Future<List<ReadingProgress>> load() async => const [];

  @override
  Future<void> record(ReadingProgress progress) async {}
}
