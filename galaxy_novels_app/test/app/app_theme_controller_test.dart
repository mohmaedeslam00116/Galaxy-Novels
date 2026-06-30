import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme_controller.dart';

void main() {
  test('loads a saved app theme choice', () async {
    final store = _MemoryThemeStore(raw: 'deepSpace');
    final controller = StoredAppThemeController(store: store);

    await controller.load();

    expect(controller.value, AppThemeChoice.deepSpace);
  });

  test('loads the old siteNoir storage value as Deep Space', () async {
    final store = _MemoryThemeStore(raw: 'siteNoir');
    final controller = StoredAppThemeController(store: store);

    await controller.load();

    expect(controller.value, AppThemeChoice.deepSpace);
  });

  test('keeps system theme when saved value is invalid', () async {
    final store = _MemoryThemeStore(raw: 'unknown-theme');
    final controller = StoredAppThemeController(store: store);

    await controller.load();

    expect(controller.value, AppThemeChoice.system);
  });

  test('updates and persists selected app theme choice', () async {
    final store = _MemoryThemeStore();
    final controller = StoredAppThemeController(store: store);

    await controller.update(AppThemeChoice.blueberryNebula);

    expect(controller.value, AppThemeChoice.blueberryNebula);
    expect(store.raw, 'blueberryNebula');
  });
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
