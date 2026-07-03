import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/presentation/reader_banner_ad_slot.dart';

void main() {
  testWidgets('close button hides the reader banner for the current chapter', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _ReaderAdTestApp(
        contentKey: '/chapters/1',
        child: Text('إعلان تجريبي'),
      ),
    );

    expect(find.text('إعلان تجريبي'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reader-ad-close-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('reader-ad-close-button')));
    await tester.pumpAndSettle();

    expect(find.text('إعلان تجريبي'), findsNothing);
    expect(find.byKey(const ValueKey('reader-ad-close-button')), findsNothing);
  });

  testWidgets('hidden reader banner returns when the chapter changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _ReaderAdTestApp(
        contentKey: '/chapters/1',
        child: Text('إعلان تجريبي'),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('reader-ad-close-button')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      const _ReaderAdTestApp(
        contentKey: '/chapters/2',
        child: Text('إعلان تجريبي'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إعلان تجريبي'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reader-ad-close-button')),
      findsOneWidget,
    );
  });
}

class _ReaderAdTestApp extends StatelessWidget {
  const _ReaderAdTestApp({required this.contentKey, required this.child});

  final String contentKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: ReaderBannerAdSlot(
            contentKey: contentKey,
            height: 52,
            child: child,
          ),
        ),
      ),
    );
  }
}
