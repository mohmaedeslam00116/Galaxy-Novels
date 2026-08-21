import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_term_replacement.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_term_replacement_dialog.dart';

void main() {
  testWidgets('creates a novel-specific replacement by default', (
    tester,
  ) async {
    ReaderTermReplacement? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                saved = await showReaderTermReplacementDialog(
                  context: context,
                  source: 'البطل',
                  novelId: 17,
                );
              },
              child: const Text('فتح'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-term-source')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('reader-term-replacement-input')),
      'المغامر',
    );
    await tester.tap(find.byKey(const ValueKey('reader-term-save')));
    await tester.pumpAndSettle();

    expect(saved?.source, 'البطل');
    expect(saved?.replacement, 'المغامر');
    expect(saved?.scope, ReaderTermScope.currentNovel);
    expect(saved?.novelId, 17);
  });

  testWidgets('can apply a replacement to every novel', (tester) async {
    ReaderTermReplacement? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                saved = await showReaderTermReplacementDialog(
                  context: context,
                  source: 'الطاقة',
                  novelId: 17,
                );
              },
              child: const Text('فتح'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reader-term-replacement-input')),
      'القوة',
    );
    await tester.tap(find.byKey(const ValueKey('reader-term-scope-all')));
    await tester.tap(find.byKey(const ValueKey('reader-term-save')));
    await tester.pumpAndSettle();

    expect(saved?.scope, ReaderTermScope.allNovels);
    expect(saved?.novelId, 0);
  });
}
