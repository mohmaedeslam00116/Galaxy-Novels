import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../domain/home_customization.dart';

abstract class HomeCustomizationRepository
    implements ValueListenable<HomeCustomization> {
  Future<void> load();

  Future<void> update(HomeCustomization customization);
}

class HomeCustomizationRepositoryScope
    extends InheritedNotifier<HomeCustomizationRepository> {
  const HomeCustomizationRepositoryScope({
    required HomeCustomizationRepository repository,
    required super.child,
    super.key,
  }) : super(notifier: repository);

  static HomeCustomizationRepository of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'HomeCustomizationRepositoryScope was not found.');
    if (scope == null) {
      throw StateError('HomeCustomizationRepository was not found.');
    }
    return scope;
  }

  static HomeCustomizationRepository? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<HomeCustomizationRepositoryScope>()
        ?.notifier;
  }
}
