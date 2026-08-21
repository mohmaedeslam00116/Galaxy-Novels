import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/app/app_theme_controller.dart';
import 'package:galaxy_novels_app/features/catalog/application/library_customization_repository.dart';
import 'package:galaxy_novels_app/features/catalog/domain/library_customization.dart';
import 'package:galaxy_novels_app/features/catalog/presentation/library_customization_screen.dart';
import 'package:galaxy_novels_app/features/home/application/home_customization_repository.dart';
import 'package:galaxy_novels_app/features/home/domain/home_customization.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_customization_screen.dart';
import 'package:galaxy_novels_app/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('shows one preview and ten choices in dark and light rows', (
    tester,
  ) async {
    final controller = _MemoryThemeController();
    await tester.pumpWidget(_surface(controller));

    expect(
      find.byKey(const ValueKey('theme-choice-card-system')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('theme-choice-card-galaxyNoir')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-choice-card-starlightPaper')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-choice-card-neutralDark')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-choice-card-cosmicNight')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('theme-choice-card-lightNature')),
      findsOneWidget,
    );
    for (final key in const [
      'oceanAsh',
      'moonForest',
      'garnetVelvet',
      'copperDusk',
      'midnightTide',
    ]) {
      expect(find.byKey(ValueKey('theme-choice-card-$key')), findsOneWidget);
    }
    expect(
      find.byKey(const ValueKey('app-theme-large-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('app-theme-dark-choice-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('app-theme-light-choice-strip')),
      findsOneWidget,
    );
    expect(find.text('ثيمات داكنة'), findsOneWidget);
    expect(find.text('ثيمات فاتحة'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'theme-choice-card-',
            ),
      ),
      findsNWidgets(10),
    );
  });

  testWidgets('theme selection semantics update and targets stay at least 44', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = _MemoryThemeController();
    await tester.pumpWidget(_surface(controller));

    final noir = find.byKey(const ValueKey('theme-choice-card-galaxyNoir'));
    final paper = find.byKey(
      const ValueKey('theme-choice-card-starlightPaper'),
    );
    expect(
      tester.getSemantics(noir).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(
      tester.getSemantics(paper).flagsCollection.isSelected,
      Tristate.isFalse,
    );

    for (final key in const [
      'galaxyNoir',
      'starlightPaper',
      'neutralDark',
      'cosmicNight',
      'lightNature',
      'oceanAsh',
      'moonForest',
      'garnetVelvet',
      'copperDusk',
      'midnightTide',
    ]) {
      final size = tester.getSize(
        find.byKey(ValueKey('theme-choice-card-$key')),
      );
      expect(size.width, greaterThanOrEqualTo(44), reason: key);
      expect(size.height, greaterThanOrEqualTo(44), reason: key);
    }

    await tester.tap(
      find.byKey(const ValueKey('theme-choice-card-starlightPaper')),
    );
    await tester.pumpAndSettle();

    expect(controller.value, AppThemeChoice.starlightPaper);
    expect(find.text('تم التغيير'), findsNothing);
    expect(
      tester.getSemantics(noir).flagsCollection.isSelected,
      Tristate.isFalse,
    );
    expect(
      tester.getSemantics(paper).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('theme cards reflow without overflow at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_surface(_MemoryThemeController(), textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('نور الصفحات'), findsOneWidget);
    expect(find.text('سكون الليل'), findsOneWidget);
    expect(find.text('رماد المحيط'), findsOneWidget);
    expect(find.text('مدّ منتصف الليل'), findsOneWidget);
  });

  testWidgets('opens home customization from settings', (tester) async {
    await tester.pumpWidget(_surface(_MemoryThemeController()));

    final tile = find.text('تخصيص الرئيسية');
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.byType(HomeCustomizationScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-customization-preview')),
      findsOneWidget,
    );
  });

  testWidgets('opens library customization from settings', (tester) async {
    await tester.pumpWidget(_surface(_MemoryThemeController()));

    final tile = find.text('تخصيص المكتبة');
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.byType(LibraryCustomizationScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-customization-screen')),
      findsOneWidget,
    );
  });
}

class _MemoryThemeController extends ChangeNotifier
    implements AppThemeController {
  AppThemeChoice _value = AppThemeChoice.galaxyNoir;

  @override
  AppThemeChoice get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(AppThemeChoice choice) async {
    _value = choice;
    notifyListeners();
  }
}

Widget _surface(_MemoryThemeController controller, {double textScale = 1}) {
  return LibraryCustomizationRepositoryScope(
    repository: _MemoryLibraryCustomizationRepository(),
    child: HomeCustomizationRepositoryScope(
      repository: _MemoryHomeCustomizationRepository(),
      child: AppThemeControllerScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: const SettingsScreen(),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MemoryLibraryCustomizationRepository extends ChangeNotifier
    implements LibraryCustomizationRepository {
  LibraryCustomization _value = LibraryCustomization.defaults;

  @override
  LibraryCustomization get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(LibraryCustomization customization) async {
    _value = customization;
    notifyListeners();
  }
}

class _MemoryHomeCustomizationRepository extends ChangeNotifier
    implements HomeCustomizationRepository {
  HomeCustomization _value = HomeCustomization.defaults;

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
