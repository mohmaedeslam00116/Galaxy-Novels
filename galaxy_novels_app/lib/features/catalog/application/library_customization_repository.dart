import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../domain/library_customization.dart';

abstract class LibraryCustomizationRepository
    implements ValueListenable<LibraryCustomization> {
  Future<void> load();

  Future<void> update(LibraryCustomization customization);
}

class LibraryCustomizationRepositoryScope
    extends InheritedNotifier<LibraryCustomizationRepository> {
  const LibraryCustomizationRepositoryScope({
    required LibraryCustomizationRepository repository,
    required super.child,
    super.key,
  }) : super(notifier: repository);

  static LibraryCustomizationRepository of(BuildContext context) {
    final repository = maybeOf(context);
    if (repository == null) {
      throw StateError('LibraryCustomizationRepository was not found.');
    }
    return repository;
  }

  static LibraryCustomizationRepository? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<
          LibraryCustomizationRepositoryScope
        >()
        ?.notifier;
  }
}
