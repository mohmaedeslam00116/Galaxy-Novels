import 'package:flutter/widgets.dart';

import '../core/config/app_config.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/home_repository.dart';

class AppDependencies extends InheritedWidget {
  const AppDependencies({
    required this.config,
    required this.homeRepository,
    required this.catalogRepository,
    required super.child,
    super.key,
  });

  final AppConfig config;
  final HomeRepository homeRepository;
  final CatalogRepository catalogRepository;

  static AppDependencies of(BuildContext context) {
    final dependencies = context
        .dependOnInheritedWidgetOfExactType<AppDependencies>();

    assert(dependencies != null, 'AppDependencies was not found in context.');
    return dependencies!;
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) {
    return config != oldWidget.config ||
        homeRepository != oldWidget.homeRepository ||
        catalogRepository != oldWidget.catalogRepository;
  }
}
