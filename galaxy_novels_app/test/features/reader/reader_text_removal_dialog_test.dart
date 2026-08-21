import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_advanced_terminology.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_term_replacement.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_text_removal_dialog.dart';

void main() {
  testWidgets('saves selected text for the current novel by default', (
    tester,
  ) async {
    ReaderTextRemovalRule? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              saved = await showReaderTextRemovalDialog(
                context: context,
                source: 'عبارة محددة',
                novelId: 9,
              );
            },
            child: const Text('فتح'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-removal-save')));
    await tester.pumpAndSettle();

    expect(saved?.source, 'عبارة محددة');
    expect(saved?.scope, ReaderTermScope.currentNovel);
    expect(saved?.novelId, 9);
  });
}
