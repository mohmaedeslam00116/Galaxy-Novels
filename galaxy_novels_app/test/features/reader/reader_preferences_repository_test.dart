import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/data/shared_preferences_reader_preferences_store.dart';
import 'package:galaxy_novels_app/features/reader/data/stored_reader_preferences_repository.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reader preferences serialize and clamp unsafe stored values', () {
    final preferences = ReaderPreferences.fromJson({
      'font_scale': 4,
      'line_height': 0.5,
      'palette_mode': 'nightBlue',
      'font_family': 'amiri',
      'text_width': 'compact',
      'immersive_mode': true,
      'brightness_mode': 'manual',
      'screen_brightness': 4,
    });

    expect(preferences.fontScale, 1.35);
    expect(preferences.lineHeight, 1.75);
    expect(preferences.paletteMode, ReaderPaletteMode.nightBlue);
    expect(preferences.fontFamily, ReaderFontFamily.amiri);
    expect(preferences.textWidth, ReaderTextWidth.compact);
    expect(preferences.immersiveMode, isTrue);
    expect(preferences.brightnessMode, ReaderBrightnessMode.manual);
    expect(preferences.screenBrightness, 1);
    expect(ReaderPreferences.fromJson(preferences.toJson()), preferences);
  });

  test('stored repository restores the last reader preferences', () async {
    final store = _MemoryReaderPreferencesStore();
    final repository = StoredReaderPreferencesRepository(store: store);
    final updated = ReaderPreferences.defaults
        .increaseFont()
        .increaseLineHeight()
        .copyWith(
          paletteMode: ReaderPaletteMode.sepia,
          fontFamily: ReaderFontFamily.cairo,
          textWidth: ReaderTextWidth.wide,
          immersiveMode: true,
          brightnessMode: ReaderBrightnessMode.manual,
          screenBrightness: 0.42,
        );

    await repository.update(updated);

    final restored = StoredReaderPreferencesRepository(store: store);
    await restored.load();

    expect(restored.value, updated);
  });

  test('malformed stored preferences fall back to reader defaults', () async {
    final repository = StoredReaderPreferencesRepository(
      store: _MemoryReaderPreferencesStore(raw: '{broken-json'),
    );

    await repository.load();

    expect(repository.value, ReaderPreferences.defaults);
  });

  test('shared preferences store persists its payload', () async {
    final store = SharedPreferencesReaderPreferencesStore();
    final payload = jsonEncode(
      ReaderPreferences.defaults
          .copyWith(paletteMode: ReaderPaletteMode.dark)
          .toJson(),
    );

    await store.write(payload);

    expect(await store.read(), payload);
  });
}

class _MemoryReaderPreferencesStore implements ReaderPreferencesStore {
  _MemoryReaderPreferencesStore({this.raw});

  String? raw;

  @override
  Future<String?> read() async => raw;

  @override
  Future<void> write(String value) async {
    raw = value;
  }
}
