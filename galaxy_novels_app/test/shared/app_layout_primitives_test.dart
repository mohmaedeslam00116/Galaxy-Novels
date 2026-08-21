import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/shared/layout/app_breakpoints.dart';
import 'package:galaxy_novels_app/shared/widgets/app_scaffold.dart';
import 'package:galaxy_novels_app/shared/widgets/app_section_header.dart';
import 'package:galaxy_novels_app/shared/widgets/section_title.dart';

void main() {
  test('classifies approved breakpoints and screen padding', () {
    const classificationCases = [
      (width: 599.0, expected: AppWindowClass.compact),
      (width: 600.0, expected: AppWindowClass.medium),
      (width: 839.0, expected: AppWindowClass.medium),
      (width: 840.0, expected: AppWindowClass.expanded),
    ];
    for (final testCase in classificationCases) {
      expect(
        AppBreakpoints.classify(testCase.width),
        testCase.expected,
        reason: 'width ${testCase.width}',
      );
    }

    const paddingCases = [
      (width: 599.0, expected: 16.0),
      (width: 600.0, expected: 24.0),
    ];
    for (final testCase in paddingCases) {
      expect(
        AppBreakpoints.screenPadding(testCase.width),
        testCase.expected,
        reason: 'width ${testCase.width}',
      );
    }
  });

  testWidgets('app scaffold applies safe area and compact screen padding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 24, bottom: 16),
          ),
          child: const AppScaffold(
            body: SizedBox.expand(key: ValueKey('scaffold-body')),
          ),
        ),
      ),
    );

    final bodyRect = tester.getRect(
      find.byKey(const ValueKey('scaffold-body')),
    );
    expect(bodyRect.left, 16);
    expect(bodyRect.right, 374);
    expect(bodyRect.top, 24);
    expect(bodyRect.bottom, 828);
  });

  testWidgets('app scaffold centers expanded content within max width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: AppScaffold(
          body: SizedBox.expand(key: ValueKey('expanded-body')),
        ),
      ),
    );

    final bodyRect = tester.getRect(
      find.byKey(const ValueKey('expanded-body')),
    );
    expect(bodyRect.left, 124);
    expect(bodyRect.right, 1276);
  });

  testWidgets('app scaffold can disable horizontal screen padding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 24, bottom: 16),
          ),
          child: const AppScaffold(
            applyHorizontalPadding: false,
            body: SizedBox.expand(key: ValueKey('edge-to-edge-body')),
          ),
        ),
      ),
    );

    final bodyRect = tester.getRect(
      find.byKey(const ValueKey('edge-to-edge-body')),
    );
    expect(bodyRect.left, 0);
    expect(bodyRect.right, 390);
    expect(bodyRect.top, 24);
    expect(bodyRect.bottom, 828);
  });

  testWidgets('section header reflows at 200 percent text in a scroll view', (
    tester,
  ) async {
    var actionCount = 0;
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: AppSectionHeader(
                title: 'آخر التحديثات الطويلة للروايات',
                action: TextButton(
                  key: const ValueKey('section-action'),
                  onPressed: () => actionCount += 1,
                  child: const Text('عرض الكل'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('آخر التحديثات الطويلة للروايات'), findsOneWidget);
    expect(find.text('عرض الكل'), findsOneWidget);
    expect(
      tester.getSize(find.byType(AppSectionHeader)).height,
      greaterThanOrEqualTo(44),
    );

    final actionFinder = find.byKey(const ValueKey('section-action'));
    final actionSize = tester.getSize(actionFinder);
    expect(actionSize.width, greaterThanOrEqualTo(44));
    expect(actionSize.height, greaterThanOrEqualTo(44));

    final actionSemantics = tester.getSemantics(actionFinder);
    expect(actionSemantics.label, 'عرض الكل');
    final actionSemanticsData = actionSemantics.getSemanticsData();
    expect(actionSemanticsData.flagsCollection.isButton, isTrue);
    expect(actionSemanticsData.hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(actionFinder);
    expect(actionCount, 1);
    semantics.dispose();
  });

  testWidgets('legacy section title preserves title icon and action behavior', (
    tester,
  ) async {
    var actionCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SectionTitle(
            title: 'عن الرواية',
            leadingIcon: Icons.menu_book_rounded,
            action: TextButton(
              key: const ValueKey('legacy-section-action'),
              onPressed: () => actionCount += 1,
              child: const Text('المزيد'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('عن الرواية'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    expect(find.text('المزيد'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('legacy-section-action')));
    expect(actionCount, 1);
  });
}
