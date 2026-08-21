import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/core/analytics/app_screen_names.dart';
import 'package:galaxy_novels_app/features/catalog/application/library_customization_repository.dart';
import 'package:galaxy_novels_app/features/catalog/domain/library_customization.dart';
import 'package:galaxy_novels_app/features/catalog/presentation/library_customization_screen.dart';

void main() {
  testWidgets('screen previews changes and applies the selected preset', (
    tester,
  ) async {
    final repository = _FakeRepository(LibraryCustomization.defaults);
    await _pumpScreen(tester, repository: repository);

    expect(find.text('معاينة المكتبة'), findsOneWidget);
    expect(find.text('بوستر هادئ'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('library-customization-scroll')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('سريع').first);
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('library-customization-apply')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('library-customization-apply')));
    await tester.pumpAndSettle();

    expect(
      repository.value,
      LibraryCustomization.forPreset(LibraryCustomizationPreset.quick),
    );
    expect(find.text('تم تطبيق تخصيص المكتبة'), findsOneWidget);
  });

  testWidgets('library Snackbar action works after editor route closes', (
    tester,
  ) async {
    final repository = _FakeRepository(LibraryCustomization.defaults);
    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(_routedScreen(repository, observer));
    await tester.tap(find.byKey(const ValueKey('open-library-customization')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('library-customization-scroll')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('سريع').first);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('library-customization-apply')));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرض المكتبة'));

    expect(tester.takeException(), isNull);
    expect(observer.pushedNames.last, AppScreenNames.library);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('back navigation protects an unapplied draft', (tester) async {
    final repository = _FakeRepository(LibraryCustomization.defaults);
    await _pumpScreen(tester, repository: repository);

    await tester.drag(
      find.byKey(const ValueKey('library-customization-scroll')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('بصري').first);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('لديك تغييرات غير مطبقة'), findsOneWidget);
    expect(find.text('تطبيق والخروج'), findsOneWidget);
    expect(find.text('تجاهل'), findsOneWidget);
    expect(find.text('متابعة التعديل'), findsOneWidget);
  });

  testWidgets('screen has no overflow at 320px and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpScreen(
      tester,
      repository: _FakeRepository(LibraryCustomization.defaults),
      textScaler: const TextScaler.linear(2),
    );

    await tester.scrollUntilVisible(
      find.text('سلوك المكتبة'),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeRepository repository,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: LibraryCustomizationScreen(repository: repository),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _routedScreen(_FakeRepository repository, NavigatorObserver observer) {
  return MaterialApp(
    locale: const Locale('ar'),
    theme: AppTheme.dark(),
    navigatorObservers: [observer],
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            key: const ValueKey('open-library-customization'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: LibraryCustomizationScreen(repository: repository),
                ),
              ),
            ),
            child: const Text('فتح التخصيص'),
          ),
        ),
      ),
    ),
  );
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<String?> pushedNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedNames.add(route.settings.name);
  }
}

class _FakeRepository extends ChangeNotifier
    implements LibraryCustomizationRepository {
  _FakeRepository(this._value);

  LibraryCustomization _value;

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
