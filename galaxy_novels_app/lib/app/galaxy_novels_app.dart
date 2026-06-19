import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/config/app_config.dart';
import '../core/network/public_cache_client.dart';
import '../data/repositories/bootstrap_repository.dart';
import '../data/repositories/home_repository.dart';
import '../data/repositories/public_home_repository.dart';
import '../features/shell/presentation/app_shell.dart';
import 'app_dependencies.dart';
import 'app_theme.dart';

class GalaxyNovelsApp extends StatelessWidget {
  const GalaxyNovelsApp({AppConfig? config, this.homeRepository, super.key})
    : config = config ?? const AppConfig();

  final AppConfig config;
  final HomeRepository? homeRepository;

  @override
  Widget build(BuildContext context) {
    final cacheClient = PublicCacheClient(config: config);
    final effectiveHomeRepository =
        homeRepository ??
        PublicHomeRepository(
          bootstrapRepository: BootstrapRepository(cacheClient),
          cacheClient: cacheClient,
        );

    return MaterialApp(
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
      home: AppDependencies(
        config: config,
        homeRepository: effectiveHomeRepository,
        child: const Directionality(
          textDirection: TextDirection.rtl,
          child: AppShell(),
        ),
      ),
    );
  }
}
