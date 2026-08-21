import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/home/application/home_customization_draft_controller.dart';
import 'package:galaxy_novels_app/features/home/application/home_customization_repository.dart';
import 'package:galaxy_novels_app/features/home/domain/home_customization.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_customization_editors.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_customization_full_preview_screen.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_customization_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final readex = FontLoader('Readex Pro')
      ..addFont(rootBundle.load('assets/fonts/ReadexPro.ttf'));
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([readex.load(), materialIcons.load()]);
  });

  for (final theme in <(String, ThemeData)>[
    ('dark', AppTheme.dark()),
    ('light', AppTheme.light()),
  ]) {
    testWidgets('customization center ${theme.$1}', (tester) async {
      final repository = _GoldenRepository(
        HomeCustomization.forPreset(HomeCustomizationPreset.visual),
      );
      await _pumpGolden(
        tester,
        theme: theme.$2,
        child: HomeCustomizationScreen(repository: repository),
      );

      await expectLater(
        find.byKey(const ValueKey('home-v3-golden-root')),
        matchesGoldenFile('goldens/home_v3_center_${theme.$1}.png'),
      );
    });

    testWidgets('section editor ${theme.$1}', (tester) async {
      final controller = HomeCustomizationDraftController(
        repository: _GoldenRepository(
          HomeCustomization.forPreset(HomeCustomizationPreset.visual),
        ),
      );
      addTearDown(controller.dispose);
      await _pumpGolden(
        tester,
        theme: theme.$2,
        child: HomeSectionCustomizationScreen(
          controller: controller,
          section: HomeSectionId.updatedNovels,
        ),
      );

      await expectLater(
        find.byKey(const ValueKey('home-v3-golden-root')),
        matchesGoldenFile('goldens/home_v3_section_${theme.$1}.png'),
      );
    });

    testWidgets('full preview ${theme.$1}', (tester) async {
      final controller = HomeCustomizationDraftController(
        repository: _GoldenRepository(
          HomeCustomization.forPreset(HomeCustomizationPreset.visual),
        ),
      );
      addTearDown(controller.dispose);
      await _pumpGolden(
        tester,
        theme: theme.$2,
        child: HomeCustomizationFullPreviewScreen(controller: controller),
      );

      await expectLater(
        find.byKey(const ValueKey('home-v3-golden-root')),
        matchesGoldenFile('goldens/home_v3_preview_${theme.$1}.png'),
      );
    });
  }
}

Future<void> _pumpGolden(
  WidgetTester tester, {
  required ThemeData theme,
  required Widget child,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      theme: _withReadex(theme),
      home: RepaintBoundary(
        key: const ValueKey('home-v3-golden-root'),
        child: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

ThemeData _withReadex(ThemeData theme) {
  final textTheme = theme.textTheme.apply(fontFamily: 'Readex Pro');
  return theme.copyWith(
    textTheme: textTheme,
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Readex Pro'),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: textTheme.titleLarge,
      toolbarTextStyle: textTheme.bodyMedium,
    ),
    listTileTheme: theme.listTileTheme.copyWith(
      titleTextStyle: _readexStyle(theme.listTileTheme.titleTextStyle),
      subtitleTextStyle: _readexStyle(theme.listTileTheme.subtitleTextStyle),
      leadingAndTrailingTextStyle: _readexStyle(
        theme.listTileTheme.leadingAndTrailingTextStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _readexButtonStyle(theme.textButtonTheme.style, textTheme),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _readexButtonStyle(theme.filledButtonTheme.style, textTheme),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _readexButtonStyle(theme.outlinedButtonTheme.style, textTheme),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _readexButtonStyle(theme.elevatedButtonTheme.style, textTheme),
    ),
    chipTheme: theme.chipTheme.copyWith(
      labelStyle: _readexStyle(theme.chipTheme.labelStyle),
      secondaryLabelStyle: _readexStyle(theme.chipTheme.secondaryLabelStyle),
    ),
  );
}

TextStyle? _readexStyle(TextStyle? style) =>
    style?.copyWith(fontFamily: 'Readex Pro');

ButtonStyle? _readexButtonStyle(ButtonStyle? style, TextTheme textTheme) {
  if (style == null) return null;
  return style.copyWith(
    textStyle: WidgetStateProperty.resolveWith((states) {
      final resolved = style.textStyle?.resolve(states) ?? textTheme.labelLarge;
      return resolved?.copyWith(fontFamily: 'Readex Pro');
    }),
  );
}

class _GoldenRepository extends ChangeNotifier
    implements HomeCustomizationRepository {
  _GoldenRepository(this._value);

  HomeCustomization _value;

  @override
  HomeCustomization get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(HomeCustomization customization) async {
    _value = customization;
    notifyListeners();
  }
}
