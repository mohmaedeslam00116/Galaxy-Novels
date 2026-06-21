import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/downloaded_chapter.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/data/repositories/downloads_repository.dart';
import 'package:galaxy_novels_app/features/downloads/presentation/download_chapters_sheet.dart';

void main() {
  testWidgets('selects the latest ten chapters for batch download', (
    tester,
  ) async {
    List<NovelChapter> selected = const [];
    await tester.pumpWidget(
      _TestApp(
        child: DownloadChaptersSheet(
          details: _details,
          chapters: _chapters(12),
          downloadsState: DownloadsState(),
          onStart: (chapters) => selected = chapters,
        ),
      ),
    );

    expect(find.text('0 محدد'), findsOneWidget);
    await tester.tap(find.text('آخر 10 فصول'));
    await tester.pump();

    expect(find.text('10 محدد'), findsOneWidget);
    await tester.tap(find.text('تحميل 10 فصل'));
    await tester.pumpAndSettle();

    expect(selected, hasLength(10));
  });

  testWidgets('disables starting when selection exceeds remaining limit', (
    tester,
  ) async {
    final state = DownloadsState(
      chapters: List.generate(99, (index) => _downloadedChapter(index + 1000)),
    );
    await tester.pumpWidget(
      _TestApp(
        child: DownloadChaptersSheet(
          details: _details,
          chapters: _chapters(3),
          downloadsState: state,
          onStart: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('download-chapter-1')));
    await tester.tap(find.byKey(const ValueKey('download-chapter-2')));
    await tester.pump();

    expect(find.textContaining('المتبقي لديك 1 فصل'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'تحميل 2 فصل'),
    );
    expect(button.onPressed, isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );
  }
}

List<NovelChapter> _chapters(int count) {
  return List.generate(
    count,
    (index) => NovelChapter(
      id: index + 1,
      position: index + 1,
      number: '${index + 1}',
      label: 'الفصل ${index + 1}',
      title: 'عنوان ${index + 1}',
      url: '/chapter-${index + 1}/',
      contentApi: '/chapters/${index + 1}',
      dateLabel: '',
      dateIso: null,
      views: 0,
      comments: 0,
      search: '',
    ),
  );
}

DownloadedChapter _downloadedChapter(int id) {
  return DownloadedChapter(
    novelId: 99,
    novelTitle: 'رواية الاختبار',
    novelCover: '',
    chapterId: id,
    chapterTitle: 'عنوان $id',
    chapterLabel: 'الفصل $id',
    chapterPosition: id,
    chaptersTotal: 100,
    contentApi: '/downloaded/$id',
    contentHtml: '<p>الفصل</p>',
    plainTextPreview: 'الفصل',
    downloadedAt: DateTime.utc(2026, 6, 20),
    lastOpenedAt: null,
  );
}

const _details = NovelDetails(
  id: 99,
  title: 'رواية الاختبار',
  originalTitle: '',
  url: '/novel/test/',
  coverThumbnail: '',
  coverMedium: '',
  coverLarge: '',
  statusKey: 'ongoing',
  statusLabel: 'مستمرة',
  country: '',
  author: '',
  translator: '',
  genres: [],
  chaptersCount: 12,
  firstChapterId: 1,
  firstChapterUrl: '/chapter-1/',
  ratingAverage: 0,
  ratingCount: 0,
  views: 0,
  updatedAt: null,
  summary: '',
  chaptersManifest: '/chapters.json',
  vipScheduleManifest: '',
  manifest: '/novel.json',
);
