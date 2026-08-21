import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/design_system/patterns/galaxy_adaptive_novel_collection.dart';

void main() {
  testWidgets('renders nothing when the collection is empty', (tester) async {
    await _pump(tester, itemCount: 0);

    expect(find.byKey(const ValueKey('galaxy-adaptive-single')), findsNothing);
    expect(find.byKey(const ValueKey('galaxy-adaptive-pair')), findsNothing);
    expect(find.byKey(const ValueKey('galaxy-adaptive-shelf')), findsNothing);
  });

  testWidgets('uses the full-width editorial treatment for one item', (
    tester,
  ) async {
    await _pump(tester, itemCount: 1);

    expect(
      find.byKey(const ValueKey('galaxy-adaptive-single')),
      findsOneWidget,
    );
    expect(find.text('تحريري'), findsOneWidget);
    expect(find.text('بطاقة 0'), findsNothing);
  });

  testWidgets('fills the available width with a balanced pair', (tester) async {
    await _pump(tester, itemCount: 2);

    expect(find.byKey(const ValueKey('galaxy-adaptive-pair')), findsOneWidget);
    expect(find.text('بطاقة 0'), findsOneWidget);
    expect(find.text('بطاقة 1'), findsOneWidget);
  });

  testWidgets('keeps three or more items in a horizontal shelf', (
    tester,
  ) async {
    await _pump(tester, itemCount: 3);

    expect(find.byKey(const ValueKey('galaxy-adaptive-shelf')), findsOneWidget);
    expect(find.text('بطاقة 0'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, {required int itemCount}) async {
  tester.view.physicalSize = const Size(390, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: GalaxyAdaptiveNovelCollection(
            itemCount: itemCount,
            itemWidth: 136,
            itemExtent: 220,
            singleItemExtent: 176,
            itemBuilder: (context, index) => ColoredBox(
              color: Colors.blueGrey,
              child: Center(child: Text('بطاقة $index')),
            ),
            singleItemBuilder: (context) => const ColoredBox(
              color: Colors.indigo,
              child: Center(child: Text('تحريري')),
            ),
          ),
        ),
      ),
    ),
  );
}
