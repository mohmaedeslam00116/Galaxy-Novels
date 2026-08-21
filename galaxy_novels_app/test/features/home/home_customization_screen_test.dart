import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/home/application/home_customization_repository.dart';
import 'package:galaxy_novels_app/features/home/domain/home_customization.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_customization_editors.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_customization_full_preview_screen.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_customization_screen.dart';

void main() {
  testWidgets('center keeps changes as a draft until apply', (tester) async {
    final repository = _MemoryHomeCustomizationRepository();
    await tester.pumpWidget(_surface(repository));

    await _tapVisible(tester, 'home-preset-quick');

    expect(repository.value, HomeCustomization.defaults);
    expect(repository.updateCount, 0);
    expect(_button(tester, 'apply-home-customization').onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('apply-home-customization')));
    await tester.pumpAndSettle();

    expect(repository.updateCount, 1);
    expect(repository.value.density, HomeDensity.compact);
    expect(find.text('تم تطبيق تخصيص الرئيسية'), findsOneWidget);
    expect(find.text('معاينة النتيجة'), findsOneWidget);
  });

  testWidgets('preview Snackbar is removed when the editor route closes', (
    tester,
  ) async {
    final repository = _MemoryHomeCustomizationRepository();
    await tester.pumpWidget(_routedSurface(repository));
    await tester.tap(find.byKey(const ValueKey('open-home-customization')));
    await tester.pumpAndSettle();
    await _tapVisible(tester, 'home-preset-quick');
    await tester.tap(find.byKey(const ValueKey('apply-home-customization')));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('home-launcher')), findsOneWidget);
    expect(find.text('معاينة النتيجة'), findsNothing);
  });

  testWidgets('center exposes summaries instead of all editor controls', (
    tester,
  ) async {
    await tester.pumpWidget(_surface(_MemoryHomeCustomizationRepository()));

    expect(
      find.byKey(const ValueKey('home-customization-center')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-customization-full-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('open-home-general-editor')),
      findsOneWidget,
    );
    for (final section in HomeSectionId.values) {
      expect(
        find.byKey(ValueKey('open-home-section-editor-${section.name}')),
        findsOneWidget,
      );
    }
    expect(find.text('زوايا الأغلفة'), findsNothing);
  });

  testWidgets('last visible section switch is disabled with an explanation', (
    tester,
  ) async {
    await tester.pumpWidget(_surface(_MemoryHomeCustomizationRepository()));

    await _setSectionVisibility(tester, HomeSectionId.continueReading);
    await _setSectionVisibility(tester, HomeSectionId.becauseYouRead);
    await _setSectionVisibility(tester, HomeSectionId.updatedNovels);

    final lastSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('home-section-visibility-latestUpdates')),
    );
    expect(lastSwitch.value, isTrue);
    expect(lastSwitch.onChanged, isNull);
    expect(find.text('يجب إبقاء قسم واحد على الأقل ظاهرًا.'), findsOneWidget);
  });

  testWidgets('move buttons reorder sections and remain a draft', (
    tester,
  ) async {
    final repository = _MemoryHomeCustomizationRepository();
    await tester.pumpWidget(_surface(repository));

    await _tapVisible(tester, 'home-move-down-continueReading');

    expect(
      repository.value.sectionOrder,
      HomeCustomization.defaultSectionOrder,
    );
    await tester.tap(find.byKey(const ValueKey('apply-home-customization')));
    await tester.pumpAndSettle();
    expect(repository.value.sectionOrder[1], HomeSectionId.continueReading);
  });

  testWidgets('general appearance editor updates the shared draft', (
    tester,
  ) async {
    final repository = _MemoryHomeCustomizationRepository();
    await tester.pumpWidget(_surface(repository));

    await _tapVisible(tester, 'open-home-general-editor');
    expect(find.byType(HomeGeneralAppearanceScreen), findsOneWidget);

    await _tapVisible(tester, 'home-card-tint-strong');
    await tester.tap(find.byKey(const ValueKey('home-editor-done')));
    await tester.pumpAndSettle();

    expect(repository.value.cardTint, HomeCardTint.neutral);
    await tester.tap(find.byKey(const ValueKey('apply-home-customization')));
    await tester.pumpAndSettle();
    expect(repository.value.cardTint, HomeCardTint.strong);
  });

  testWidgets('section editor groups advanced options and resets its style', (
    tester,
  ) async {
    final repository = _MemoryHomeCustomizationRepository(
      HomeCustomization.forPreset(HomeCustomizationPreset.visual),
    );
    await tester.pumpWidget(_surface(repository));

    await _tapVisible(tester, 'open-home-section-editor-continueReading');
    expect(find.byType(HomeSectionCustomizationScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-section-editor-preview-expanded')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-quick-action-continueReading')),
      findsNothing,
    );

    await _tapVisible(tester, 'home-cover-presentation-fit');
    await _tapVisible(tester, 'home-advanced-toggle');
    expect(
      find.byKey(const ValueKey('home-quick-action-continueReading')),
      findsOneWidget,
    );

    await _tapVisible(tester, 'reset-home-section-continueReading');
    await tester.tap(find.byKey(const ValueKey('home-editor-done')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('apply-home-customization')));
    await tester.pumpAndSettle();

    expect(
      repository.value.continueReadingTemplate,
      ContinueReadingCardTemplate.detailed,
    );
    expect(
      repository.value.coverPresentationFor(HomeSectionId.continueReading),
      HomeCoverPresentation.fill,
    );
    expect(repository.value.cardSurface, HomeCardSurface.elevated);
  });

  testWidgets('undo restores the state before the latest change', (
    tester,
  ) async {
    final repository = _MemoryHomeCustomizationRepository();
    await tester.pumpWidget(_surface(repository));

    await _tapVisible(tester, 'home-preset-visual');
    await tester.tap(find.byKey(const ValueKey('home-customization-undo')));
    await tester.pump();

    expect(_button(tester, 'apply-home-customization').onPressed, isNull);
  });

  testWidgets('back with a dirty draft offers the three approved actions', (
    tester,
  ) async {
    await tester.pumpWidget(_surface(_MemoryHomeCustomizationRepository()));
    await _tapVisible(tester, 'home-preset-quick');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('لديك تعديلات غير مطبقة'), findsOneWidget);
    expect(find.byKey(const ValueKey('unsaved-apply-exit')), findsOneWidget);
    expect(find.byKey(const ValueKey('unsaved-discard')), findsOneWidget);
    expect(find.byKey(const ValueKey('unsaved-continue')), findsOneWidget);
  });

  testWidgets('full preview shows the ad marker and opens section editor', (
    tester,
  ) async {
    await tester.pumpWidget(_surface(_MemoryHomeCustomizationRepository()));

    await _tapVisible(tester, 'home-customization-full-preview');
    expect(find.byType(HomeCustomizationFullPreviewScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-preview-ad-placeholder')),
      findsOneWidget,
    );

    await _tapVisible(tester, 'preview-edit-section-becauseYouRead');
    expect(find.byType(HomeSectionCustomizationScreen), findsOneWidget);
  });

  testWidgets('center and editor fit a narrow phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _surface(
        _MemoryHomeCustomizationRepository(),
        textScaler: const TextScaler.linear(2),
      ),
    );
    expect(tester.takeException(), isNull);

    await _tapVisible(tester, 'open-home-section-editor-continueReading');
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed apply keeps draft and offers retry', (tester) async {
    final repository = _MemoryHomeCustomizationRepository()..failWrites = true;
    await tester.pumpWidget(_surface(repository));
    await _tapVisible(tester, 'home-preset-quick');

    await tester.tap(find.byKey(const ValueKey('apply-home-customization')));
    await tester.pumpAndSettle();

    expect(find.text('تعذر حفظ تخصيص الرئيسية'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(_button(tester, 'apply-home-customization').onPressed, isNotNull);
  });

  testWidgets(
    'editor navigation disables motion when accessibility requests it',
    (tester) async {
      await tester.pumpWidget(
        _surface(_MemoryHomeCustomizationRepository(), disableAnimations: true),
      );

      final target = find.byKey(const ValueKey('open-home-general-editor'));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pump();

      expect(find.byType(HomeGeneralAppearanceScreen), findsOneWidget);
      final route = ModalRoute.of(
        tester.element(find.byType(HomeGeneralAppearanceScreen)),
      );
      expect(route?.transitionDuration, Duration.zero);
    },
  );
}

ButtonStyleButton _button(WidgetTester tester, String key) {
  return tester.widget<ButtonStyleButton>(find.byKey(ValueKey(key)));
}

Future<void> _setSectionVisibility(
  WidgetTester tester,
  HomeSectionId section,
) async {
  final target = find.byKey(
    ValueKey('home-section-visibility-${section.name}'),
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Widget _surface(
  _MemoryHomeCustomizationRepository repository, {
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    locale: const Locale('ar'),
    home: MediaQuery(
      data: MediaQueryData(
        textScaler: textScaler,
        disableAnimations: disableAnimations,
      ),
      child: HomeCustomizationScreen(repository: repository),
    ),
  );
}

Widget _routedSurface(_MemoryHomeCustomizationRepository repository) {
  return MaterialApp(
    locale: const Locale('ar'),
    home: Builder(
      builder: (context) => Scaffold(
        key: const ValueKey('home-launcher'),
        body: Center(
          child: FilledButton(
            key: const ValueKey('open-home-customization'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => HomeCustomizationScreen(repository: repository),
              ),
            ),
            child: const Text('فتح التخصيص'),
          ),
        ),
      ),
    ),
  );
}

class _MemoryHomeCustomizationRepository extends ChangeNotifier
    implements HomeCustomizationRepository {
  _MemoryHomeCustomizationRepository([HomeCustomization? initial])
    : _value = initial ?? HomeCustomization.defaults;

  HomeCustomization _value;
  int updateCount = 0;
  bool failWrites = false;

  @override
  HomeCustomization get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(HomeCustomization customization) async {
    updateCount++;
    if (failWrites) {
      throw Exception('failed');
    }
    _value = customization;
    notifyListeners();
  }
}
