import 'package:flutter/foundation.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_preferences_repository.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_preferences.dart';

class FakeReaderPreferencesRepository extends ChangeNotifier
    implements ReaderPreferencesRepository {
  FakeReaderPreferencesRepository({
    ReaderPreferences initialValue = ReaderPreferences.defaults,
  }) : _value = initialValue;

  ReaderPreferences _value;

  @override
  ReaderPreferences get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(ReaderPreferences preferences) async {
    if (_value == preferences) {
      return;
    }
    _value = preferences;
    notifyListeners();
  }
}
