import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/analytics/app_analytics.dart';
import '../../account/presentation/account_screen.dart';
import '../../catalog/presentation/catalog_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../downloads/presentation/downloads_screen.dart';
import '../../rankings/presentation/rankings_screen.dart';
import '../../reader_journey/presentation/reader_journey_screen.dart';
import 'adaptive_app_shell.dart';
import 'app_drawer.dart';
import 'shell_destination.dart';

class AppShell extends StatelessWidget {
  const AppShell({this.analytics = const NoopAppAnalytics(), super.key});

  final AppAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return AdaptiveAppShell(
      analytics: analytics,
      drawerBuilder: (context) => const AppDrawer(),
      screenBuilders: {
        ShellDestination.home: (context, select) => const HomeScreen(),
        ShellDestination.library: (context, select) => const CatalogScreen(),
        ShellDestination.readerJourney: (context, select) {
          final dependencies = AppDependencies.of(context);
          return ReaderJourneyScreen(
            history: HistoryScreen(
              onOpenLibrary: () => select(ShellDestination.library),
            ),
            downloads: DownloadsView(
              repository: dependencies.downloadRepository,
              rewardedAds: dependencies.rewardedDownloadAdRepository,
              readingHistoryRepository: dependencies.readingHistoryRepository,
              onOpenLibrary: () => select(ShellDestination.library),
              downloadAnalytics: dependencies.downloadAnalytics,
            ),
          );
        },
        ShellDestination.rankings: (context, select) => const RankingsScreen(),
        ShellDestination.account: (context, select) =>
            const AccountScreen(embedded: true),
      },
    );
  }
}
