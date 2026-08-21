import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme_controller.dart';

void main() {
  test('maps every legacy dark value to Galaxy Noir', () {
    for (final raw in [
      'siteNoir',
      'deepSpace',
      'crimsonPagoda',
      'blueberryNebula',
    ]) {
      expect(AppThemeChoice.fromStorageValue(raw), AppThemeChoice.galaxyNoir);
    }
  });

  test('uses Galaxy Noir for null, unknown, and removed system values', () {
    for (final raw in [null, 'unknown-theme', 'system', '']) {
      expect(
        AppThemeChoice.fromStorageValue(raw),
        AppThemeChoice.galaxyNoir,
        reason: 'stored value: $raw',
      );
    }
  });

  test(
    'loads a legacy dark value through the controller as Galaxy Noir',
    () async {
      final controller = StoredAppThemeController(
        store: _MemoryThemeStore(raw: 'deepSpace'),
      );

      await controller.load();

      expect(controller.value, AppThemeChoice.galaxyNoir);
    },
  );

  test('maps the legacy light value to Starlight Paper', () {
    expect(
      AppThemeChoice.fromStorageValue('desertAstronaut'),
      AppThemeChoice.starlightPaper,
    );
  });

  test('keeps Galaxy Noir when reading the theme store throws', () async {
    final controller = StoredAppThemeController(store: _ThrowingThemeStore());

    expect(controller.value, AppThemeChoice.galaxyNoir);
    await expectLater(controller.load(), completes);
    expect(controller.value, AppThemeChoice.galaxyNoir);
  });

  test('persists an approved theme choice', () async {
    final store = _MemoryThemeStore();
    final controller = StoredAppThemeController(store: store);

    await controller.update(AppThemeChoice.cosmicNight);

    expect(controller.value, AppThemeChoice.cosmicNight);
    expect(store.raw, 'cosmicNight');
  });

  test('restores every new theme from its stored name', () {
    for (final choice in AppThemeChoice.values) {
      expect(AppThemeChoice.fromStorageValue(choice.name), choice);
    }
  });
}

class _ThrowingThemeStore implements AppThemeStore {
  @override
  Future<String?> read() => Future<String?>.error(StateError('read failed'));

  @override
  Future<void> write(String value) async {}
}

class _MemoryThemeStore implements AppThemeStore {
  _MemoryThemeStore({this.raw});

  String? raw;

  @override
  Future<String?> read() async => raw;

  @override
  Future<void> write(String value) async {
    raw = value;
  }
}
