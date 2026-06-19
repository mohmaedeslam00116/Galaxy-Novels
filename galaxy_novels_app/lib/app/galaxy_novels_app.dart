import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/config/app_config.dart';
import '../core/network/public_cache_client.dart';
import '../data/repositories/bootstrap_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/home_repository.dart';
import '../data/repositories/novel_repository.dart';
import '../data/repositories/public_catalog_repository.dart';
import '../data/repositories/public_home_repository.dart';
import '../data/repositories/public_novel_repository.dart';
import '../features/shell/presentation/app_shell.dart';
import 'app_dependencies.dart';
import 'app_theme.dart';

class GalaxyNovelsApp extends StatelessWidget {
  const GalaxyNovelsApp({
    AppConfig? config,
    this.homeRepository,
    this.catalogRepository,
    this.novelRepository,
    super.key,
  }) : config = config ?? const AppConfig();

  final AppConfig config;
  final HomeRepository? homeRepository;
  final CatalogRepository? catalogRepository;
  final NovelRepository? novelRepository;

  @override
  Widget build(BuildContext context) {
    final cacheClient = PublicCacheClient(config: config);
    final bootstrapRepository = BootstrapRepository(cacheClient);
    final effectiveHomeRepository =
        homeRepository ??
        PublicHomeRepository(
          bootstrapRepository: bootstrapRepository,
          cacheClient: cacheClient,
        );
    final effectiveCatalogRepository =
        catalogRepository ??
        PublicCatalogRepository(
          bootstrapRepository: bootstrapRepository,
          cacheClient: cacheClient,
        );
    final effectiveNovelRepository =
        novelRepository ?? PublicNovelRepository(cacheClient: cacheClient);

    return AppDependencies(
      config: config,
      homeRepository: effectiveHomeRepository,
      catalogRepository: effectiveCatalogRepository,
      novelRepository: effectiveNovelRepository,
      child: MaterialApp(
        title: 'مجرة الروايات',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: AppShell(),
        ),
      ),
    );
  }
}
