import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/features/novel_details/domain/readable_chapter.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/chapter_download_state.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/widgets/readable_chapter_tile.dart';

void main() {
  testWidgets('chapter tile exposes a compact download action', (tester) async {
    var downloads = 0;
    await tester.pumpWidget(
      _TestTile(
        downloadState: ChapterDownloadState.available,
        onDownload: () => downloads++,
      ),
    );

    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    expect(find.byTooltip('تنزيل الفصل'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chapter-download-public:71')));
    expect(downloads, 1);
  });

  testWidgets('pending chapter replaces download action with progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestTile(downloadState: ChapterDownloadState.pending),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('الفصل قيد التنزيل'), findsOneWidget);
    expect(find.byIcon(Icons.download_rounded), findsNothing);
  });

  testWidgets('downloaded chapter shows a disabled completion action', (
    tester,
  ) async {
    var downloads = 0;
    await tester.pumpWidget(
      _TestTile(
        downloadState: ChapterDownloadState.downloaded,
        onDownload: () => downloads++,
      ),
    );

    expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
    expect(find.byTooltip('تم تنزيل الفصل'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('chapter-download-public:71')),
      warnIfMissed: false,
    );
    expect(downloads, 0);
  });

  testWidgets('failed chapter exposes a separate retry action', (tester) async {
    var downloads = 0;
    var retries = 0;
    await tester.pumpWidget(
      _TestTile(
        downloadState: const ChapterDownloadState(
          ChapterDownloadStatus.failed,
          retryJobId: 'job-71',
        ),
        onDownload: () => downloads++,
        onRetryDownload: () => retries++,
      ),
    );

    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.byTooltip('إعادة محاولة تنزيل الفصل'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chapter-download-public:71')));
    expect(retries, 1);
    expect(downloads, 0);
  });
}

class _TestTile extends StatelessWidget {
  const _TestTile({
    required this.downloadState,
    this.onDownload,
    this.onRetryDownload,
  });

  final ChapterDownloadState downloadState;
  final VoidCallback? onDownload;
  final VoidCallback? onRetryDownload;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ReadableChapterTile(
          chapter: _chapter,
          onTap: _noOp,
          downloadState: downloadState,
          onDownload: onDownload,
          onRetryDownload: onRetryDownload,
        ),
      ),
    );
  }
}

void _noOp() {}

final _chapter = ReadableChapter.public(
  const NovelChapter(
    id: 71,
    position: 71,
    number: '71',
    label: 'الفصل 71',
    title: '',
    url: '',
    contentApi: '/chapters/71',
    dateLabel: '',
    dateIso: null,
    views: 0,
    comments: 0,
    search: '',
  ),
);
