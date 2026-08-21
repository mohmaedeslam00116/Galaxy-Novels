import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/reading_history_repository.dart';
import '../application/home_recommendation_exclusion_repository.dart';

class SharedPreferencesHomeRecommendationExclusionStore
    implements HomeRecommendationExclusionStore {
  SharedPreferencesHomeRecommendationExclusionStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences;

  static const keyPrefix = 'home_recommendation_exclusions.v1.';

  SharedPreferencesAsync? _preferences;
  final Map<String, String> _fallbackValues = {};

  @override
  Future<String?> read(ReadingHistoryScope scope) {
    final key = '$keyPrefix${scope.storageSuffix}';
    final preferences = _safePreferences();
    return preferences == null
        ? Future.value(_fallbackValues[key])
        : preferences.getString(key);
  }

  @override
  Future<void> write(ReadingHistoryScope scope, String value) {
    final key = '$keyPrefix${scope.storageSuffix}';
    final preferences = _safePreferences();
    if (preferences == null) {
      _fallbackValues[key] = value;
      return Future.value();
    }
    return preferences.setString(key, value);
  }

  SharedPreferencesAsync? _safePreferences() {
    try {
      return _preferences ??= SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }
}
