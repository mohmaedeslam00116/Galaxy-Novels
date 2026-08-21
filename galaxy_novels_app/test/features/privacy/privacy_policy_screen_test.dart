import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/privacy/presentation/privacy_policy_screen.dart';

void main() {
  testWidgets('shows the approved Galaxy Novels privacy policy', (
    tester,
  ) async {
    await tester.pumpWidget(_surface(const PrivacyPolicyScreen()));

    expect(find.text('سياسة الخصوصية'), findsOneWidget);
    expect(find.text('سياسة الخصوصية لتطبيق مجرة الروايات'), findsOneWidget);
    expect(find.text('1. المعلومات التي نجمعها'), findsOneWidget);
    expect(find.text('3. الإعلانات وجمع البيانات'), findsOneWidget);
    expect(find.textContaining('مركز الروايات'), findsNothing);
    expect(find.textContaining('Markaz Riwayat'), findsNothing);
    expect(find.textContaining('support@markazriwayat.com'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('10. الامتثال للقوانين'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('10. الامتثال للقوانين'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dispatches the exact Google and contact URIs', (tester) async {
    const targets = <String, String>{
      'privacy-google-data-link':
          'https://policies.google.com/technologies/partner-sites?hl=ar',
      'privacy-google-ads-link': 'https://adssettings.google.com/',
      'privacy-contact-link': 'https://galaxynovels.com/contact/',
    };

    for (final target in targets.entries) {
      Uri? openedUri;
      await tester.pumpWidget(
        _surface(
          PrivacyPolicyScreen(
            uriLauncher: (uri) async {
              openedUri = uri;
              return true;
            },
          ),
        ),
      );
      final link = find.byKey(ValueKey(target.key));
      await _revealLink(tester, link);
      await tester.tap(link);
      await tester.pump();

      expect(openedUri, Uri.parse(target.value));
    }
  });

  testWidgets('shows safe feedback for rejected and throwing launchers', (
    tester,
  ) async {
    for (final throws in [false, true]) {
      await tester.pumpWidget(
        _surface(
          PrivacyPolicyScreen(
            uriLauncher: (_) async {
              if (throws) {
                throw Exception('launcher failed');
              }
              return false;
            },
          ),
        ),
      );
      final link = find.byKey(const ValueKey('privacy-google-data-link'));
      await _revealLink(tester, link);
      await tester.tap(link);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('تعذر فتح الرابط الآن.'), findsOneWidget);
    }
  });

  testWidgets('privacy link targets are at least 44px', (tester) async {
    for (final key in <String>[
      'privacy-google-data-link',
      'privacy-google-ads-link',
      'privacy-contact-link',
    ]) {
      await tester.pumpWidget(_surface(const PrivacyPolicyScreen()));
      final link = find.byKey(ValueKey(key));
      await _revealLink(tester, link);

      final size = tester.getSize(link);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('fits the required light and dark responsive matrix', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cases = <({Size size, TextScaler textScaler})>[
      for (final width in [320.0, 600.0, 840.0])
        (size: Size(width, 700), textScaler: TextScaler.noScaling),
      (size: const Size(320, 700), textScaler: const TextScaler.linear(2)),
      (size: const Size(840, 320), textScaler: TextScaler.noScaling),
    ];

    for (final theme in [AppTheme.dark(), AppTheme.light()]) {
      for (final testCase in cases) {
        tester.view.physicalSize = testCase.size;
        await tester.pumpWidget(
          _surface(
            const PrivacyPolicyScreen(),
            theme: theme,
            textScaler: testCase.textScaler,
          ),
        );
        await tester.pumpAndSettle();
        await tester.fling(find.byType(ListView), const Offset(0, -4000), 5000);
        await tester.pumpAndSettle();

        expect(find.text('10. الامتثال للقوانين'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}

Widget _surface(
  Widget child, {
  ThemeData? theme,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.dark(),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    ),
  );
}

Future<void> _revealLink(WidgetTester tester, Finder link) async {
  await tester.dragUntilVisible(
    link,
    find.byType(ListView),
    const Offset(0, -320),
  );
  await tester.pumpAndSettle();
}
