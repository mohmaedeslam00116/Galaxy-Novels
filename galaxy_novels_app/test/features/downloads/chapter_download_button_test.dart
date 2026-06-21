import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/downloads/presentation/chapter_download_button.dart';

void main() {
  testWidgets('shows downloaded state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChapterDownloadButton(
            isDownloaded: true,
            isEnabled: true,
            onPressed: () async {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
    expect(find.byTooltip('محمل'), findsOneWidget);
  });

  testWidgets('runs chapter download action', (tester) async {
    var downloaded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChapterDownloadButton(
            isDownloaded: false,
            isEnabled: true,
            onPressed: () async => downloaded = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('تحميل الفصل'));
    await tester.pumpAndSettle();

    expect(downloaded, isTrue);
  });
}
