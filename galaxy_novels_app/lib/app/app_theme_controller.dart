import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeChoice {
  starlightPaper,
  neutralDark,
  galaxyNoir,
  cosmicNight,
  lightNature,
  oceanAsh,
  moonForest,
  garnetVelvet,
  copperDusk,
  midnightTide;

  ThemeMode get themeMode => switch (this) {
    AppThemeChoice.starlightPaper ||
    AppThemeChoice.lightNature => ThemeMode.light,
    AppThemeChoice.neutralDark ||
    AppThemeChoice.galaxyNoir ||
    AppThemeChoice.cosmicNight ||
    AppThemeChoice.oceanAsh ||
    AppThemeChoice.moonForest ||
    AppThemeChoice.garnetVelvet ||
    AppThemeChoice.copperDusk ||
    AppThemeChoice.midnightTide => ThemeMode.dark,
  };

  static AppThemeChoice fromStorageValue(String? value) {
    return switch (value) {
      'galaxyNoir' ||
      'siteNoir' ||
      'deepSpace' ||
      'crimsonPagoda' ||
      'blueberryNebula' => AppThemeChoice.galaxyNoir,
      'starlightPaper' || 'desertAstronaut' => AppThemeChoice.starlightPaper,
      'neutralDark' => AppThemeChoice.neutralDark,
      'cosmicNight' => AppThemeChoice.cosmicNight,
      'lightNature' => AppThemeChoice.lightNature,
      'oceanAsh' => AppThemeChoice.oceanAsh,
      'moonForest' => AppThemeChoice.moonForest,
      'garnetVelvet' => AppThemeChoice.garnetVelvet,
      'copperDusk' => AppThemeChoice.copperDusk,
      'midnightTide' => AppThemeChoice.midnightTide,
      _ => AppThemeChoice.galaxyNoir,
    };
  }
}

abstract class AppThemeController implements ValueListenable<AppThemeChoice> {
  Future<void> load();

  Future<void> update(AppThemeChoice choice);
}

abstract class AppThemeStore {
  Future<String?> read();

  Future<void> write(String value);
}

class StoredAppThemeController extends ChangeNotifier
    implements AppThemeController {
  StoredAppThemeController({required AppThemeStore store}) : _store = store;

  final AppThemeStore _store;

  AppThemeChoice _value = AppThemeChoice.galaxyNoir;
  Future<void>? _loadOperation;
  Future<void> _pendingWrite = Future.value();
  bool _didLoad = false;
  int _revision = 0;

  @override
  AppThemeChoice get value => _value;

  @override
  Future<void> load() {
    if (_didLoad) {
      return Future.value();
    }
    return _loadOperation ??= _loadFromStore();
  }

  @override
  Future<void> update(AppThemeChoice choice) {
    if (_value != choice) {
      _value = choice;
      _revision++;
      notifyListeners();
    }

    _pendingWrite = _pendingWrite
        .catchError((Object _) {})
        .then((_) => _store.write(choice.name));
    return _pendingWrite;
  }

  Future<void> _loadFromStore() async {
    final revisionBeforeLoad = _revision;
    try {
      final raw = await _store.read();
      if (revisionBeforeLoad != _revision) {
        return;
      }

      final choice = AppThemeChoice.fromStorageValue(raw);
      if (_value != choice) {
        _value = choice;
        notifyListeners();
      }
    } catch (_) {
      // Theme persistence failures should never block app startup.
    } finally {
      _didLoad = true;
    }
  }
}

class SharedPreferencesAppThemeStore implements AppThemeStore {
  SharedPreferencesAppThemeStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const key = 'app_theme_choice.v1';

  SharedPreferencesAsync? _preferences;
  String? _fallbackValue;

  @override
  Future<String?> read() async {
    final preferences = _safePreferences();
    if (preferences == null) {
      return _fallbackValue;
    }

    try {
      return await preferences.getString(key) ?? _fallbackValue;
    } on MissingPluginException {
      return _fallbackValue;
    } on PlatformException {
      return _fallbackValue;
    }
  }

  @override
  Future<void> write(String value) async {
    _fallbackValue = value;
    final preferences = _safePreferences();
    if (preferences == null) {
      return;
    }

    try {
      await preferences.setString(key, value);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  SharedPreferencesAsync? _safePreferences() {
    try {
      return _preferences ??= SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }
}

class AppThemeControllerScope extends InheritedNotifier<AppThemeController> {
  const AppThemeControllerScope({
    required AppThemeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppThemeControllerScope>();
    assert(scope != null, 'AppThemeControllerScope was not found in context.');
    if (scope == null) {
      throw StateError('AppThemeControllerScope was not found in context.');
    }
    final controller = scope.notifier;
    if (controller == null) {
      throw StateError(
        'AppThemeController was not found in AppThemeControllerScope.',
      );
    }
    return controller;
  }
}
