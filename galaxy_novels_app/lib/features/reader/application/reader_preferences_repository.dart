import 'package:flutter/foundation.dart';

import '../domain/reader_preferences.dart';

abstract class ReaderPreferencesRepository
    implements ValueListenable<ReaderPreferences> {
  Future<void> load();

  Future<void> update(ReaderPreferences preferences);
}
