import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_pinch_font_scale_controller.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_preferences.dart';

void main() {
  late ReaderPinchFontScaleController controller;

  setUp(() {
    controller = ReaderPinchFontScaleController(
      minFontScale: ReaderPreferences.minFontScale,
      maxFontScale: ReaderPreferences.maxFontScale,
    );
  });

  test('one pointer never starts or changes the font scale', () {
    expect(
      controller.addPointer(
        pointer: 1,
        position: Offset.zero,
        baseFontScale: 1,
      ),
      isFalse,
    );

    expect(
      controller.updatePointer(pointer: 1, position: const Offset(40, 0)),
      isNull,
    );
    expect(controller.removePointer(1, commit: true), isNull);
  });

  test('two pointers scale from their initial distance and commit once', () {
    controller.addPointer(pointer: 1, position: Offset.zero, baseFontScale: 1);
    expect(
      controller.addPointer(
        pointer: 2,
        position: const Offset(100, 0),
        baseFontScale: 1,
      ),
      isTrue,
    );

    expect(
      controller.updatePointer(pointer: 2, position: const Offset(200, 0)),
      2,
    );
    expect(
      controller.addPointer(
        pointer: 3,
        position: const Offset(300, 0),
        baseFontScale: 1,
      ),
      isFalse,
    );

    expect(controller.removePointer(2, commit: true), 2);
    expect(controller.removePointer(1, commit: true), isNull);
  });

  test('pinch scale is clamped to reader font bounds', () {
    controller.addPointer(pointer: 1, position: Offset.zero, baseFontScale: 1);
    controller.addPointer(
      pointer: 2,
      position: const Offset(100, 0),
      baseFontScale: 1,
    );

    expect(
      controller.updatePointer(pointer: 2, position: const Offset(10, 0)),
      ReaderPreferences.minFontScale,
    );
    expect(controller.removePointer(2, commit: true), 0.85);
  });

  test('cancel resets an active pinch without committing its value', () {
    controller.addPointer(pointer: 1, position: Offset.zero, baseFontScale: 1);
    controller.addPointer(
      pointer: 2,
      position: const Offset(100, 0),
      baseFontScale: 1,
    );
    controller.updatePointer(pointer: 2, position: const Offset(150, 0));

    expect(controller.removePointer(2, commit: false), isNull);
    expect(controller.isActive, isFalse);
    expect(controller.removePointer(1, commit: true), isNull);
  });
}
