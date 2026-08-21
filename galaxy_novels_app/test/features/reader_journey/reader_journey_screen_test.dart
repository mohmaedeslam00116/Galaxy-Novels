import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader_journey/presentation/reader_journey_screen.dart';

void main() {
  testWidgets(
    'history is the default journey tab and downloads opens in place',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReaderJourneyScreen(
              history: Center(child: Text('محتوى السجل')),
              downloads: Center(child: Text('محتوى التنزيلات')),
            ),
          ),
        ),
      );

      expect(find.text('محتوى السجل'), findsOneWidget);
      expect(find.text('محتوى التنزيلات'), findsNothing);

      await tester.tap(find.text('التنزيلات'));
      await tester.pumpAndSettle();

      expect(find.text('محتوى السجل'), findsNothing);
      expect(find.text('محتوى التنزيلات'), findsOneWidget);
    },
  );

  testWidgets('journey tabs support swiping and keep child state alive', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReaderJourneyScreen(
            history: _CounterPage(label: 'السجل'),
            downloads: _CounterPage(label: 'التنزيلات'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('زيادة السجل'));
    await tester.pump();
    expect(find.text('السجل: 1'), findsOneWidget);

    await tester.drag(find.byType(TabBarView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('التنزيلات: 0'), findsOneWidget);

    await tester.tap(find.text('سجل القراءة'));
    await tester.pumpAndSettle();
    expect(find.text('السجل: 1'), findsOneWidget);
  });

  testWidgets('journey tabs fit 320 pixels at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReaderJourneyScreen(
            history: SizedBox.expand(),
            downloads: SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('سجل القراءة'), findsOneWidget);
    expect(find.text('التنزيلات'), findsOneWidget);
  });
}

class _CounterPage extends StatefulWidget {
  const _CounterPage({required this.label});

  final String label;

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('${widget.label}: $_count'),
        FilledButton(
          onPressed: () => setState(() => _count += 1),
          child: Text('زيادة ${widget.label}'),
        ),
      ],
    );
  }
}
