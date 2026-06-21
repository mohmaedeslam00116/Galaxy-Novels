import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/widgets/novel_chapter_tile.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/widgets/novel_details_header.dart';

void main() {
  testWidgets('novel details header renders title and stats', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: ListView(children: [NovelDetailsHeader(details: _details)]),
          ),
        ),
      ),
    );

    expect(find.text('تفاصيل الاختبار'), findsOneWidget);
    expect(find.text('Test Details'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('فصل'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('مشاهدة'), findsOneWidget);
  });

  testWidgets('chapter tile calls onTap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: NovelChapterTile(
              chapter: _chapter,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('الفصل 1'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('chapter tile can show a download action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: NovelChapterTile(
              chapter: _chapter,
              onTap: () {},
              trailingAction: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
  });
}

const _details = NovelDetails(
  id: 99,
  title: 'تفاصيل الاختبار',
  originalTitle: 'Test Details',
  url: '/novel/details-test/',
  coverThumbnail: '',
  coverMedium: '',
  coverLarge: '',
  statusKey: 'ongoing',
  statusLabel: 'مستمرة',
  country: 'cn',
  author: 'كاتب الاختبار',
  translator: '',
  genres: [NovelGenre(id: 1, name: 'أكشن', slug: 'action')],
  chaptersCount: 2,
  firstChapterId: 1,
  firstChapterUrl: '/chapter-1/',
  ratingAverage: 4.2,
  ratingCount: 5,
  views: 120,
  updatedAt: null,
  summary: 'هذه نبذة تفاصيل الاختبار.',
  chaptersManifest: '/chapters.json',
  vipScheduleManifest: '',
  manifest: '/novel-test.json',
);

const _chapter = NovelChapter(
  id: 1,
  position: 1,
  number: '1',
  label: 'الفصل 1',
  title: 'البداية',
  url: '/chapter-1/',
  contentApi: '/wp-json/wor-reader-app/v1/chapters/1',
  dateLabel: 'اليوم',
  dateIso: null,
  views: 0,
  comments: 0,
  search: '',
);
