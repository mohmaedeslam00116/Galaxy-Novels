import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/widgets/novel_chapter_tile.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/widgets/novel_details_header.dart';
import 'package:galaxy_novels_app/features/novel_engagement/application/novel_engagement_controller.dart';
import 'package:galaxy_novels_app/features/novel_engagement/domain/novel_user_state.dart';

void main() {
  testWidgets('details keep core metadata visible and reveal secondary data', (
    tester,
  ) async {
    await _pumpHeader(
      tester,
      engagementState: const NovelEngagementState(
        status: NovelEngagementStatus.ready,
        novelId: 99,
        userId: 7,
        userState: _userState,
      ),
    );

    expect(find.byKey(const ValueKey('novel-details-hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('galaxy-stats-rail')), findsOneWidget);
    expect(find.text('المشاهدات'), findsOneWidget);
    final table = find.byKey(const ValueKey('novel-details-metadata-table'));
    expect(table, findsOneWidget);
    expect(
      find.byKey(const ValueKey('novel-details-metadata-grid')),
      findsNothing,
    );
    for (final key in const [
      'novel-metadata-author',
      'novel-metadata-translator',
    ]) {
      expect(
        find.descendant(of: table, matching: find.byKey(ValueKey(key))),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: table,
        matching: find.byKey(const ValueKey('novel-metadata-chapters')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: table,
        matching: find.byKey(const ValueKey('novel-details-rating-action')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('galaxy-stats-rail')),
        matching: find.byKey(const ValueKey('novel-details-rating-action')),
      ),
      findsOneWidget,
    );
    expect(find.text('تفاصيل الاختبار'), findsOneWidget);
    expect(find.text('Test Details'), findsNothing);
    expect(find.text('الكاتب'), findsOneWidget);
    expect(find.text('كاتب الاختبار'), findsOneWidget);
    expect(find.text('المترجم'), findsOneWidget);
    expect(find.text('غير متوفر'), findsOneWidget);
    expect(find.text('عدد الفصول'), findsNothing);
    expect(find.text('تقييمك: 4 من 5'), findsOneWidget);
    expect(find.text('★ 4.2'), findsOneWidget);
    expect(find.byTooltip('اضغط لإضافة أو تعديل تقييمك'), findsOneWidget);
    expect(find.textContaining('2024'), findsNothing);

    await tester.ensureVisible(find.text('عرض كل البيانات'));
    await tester.pump();
    await tester.tap(find.text('عرض كل البيانات'));
    await tester.pumpAndSettle();
    expect(find.text('Test Details'), findsOneWidget);
    expect(find.text('الصين'), findsOneWidget);
  });

  testWidgets('rating stats cell routes ready, guest, and failure actions', (
    tester,
  ) async {
    var action = '';

    Future<void> pump(NovelEngagementState state) => _pumpHeader(
      tester,
      engagementState: state,
      onRate: () => action = 'rate',
      onSignIn: () => action = 'sign-in',
      onRetry: () => action = 'retry',
    );

    await pump(
      const NovelEngagementState(
        status: NovelEngagementStatus.ready,
        novelId: 99,
        userId: 7,
        userState: _userState,
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('novel-details-rating-action')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('novel-details-rating-action')));
    expect(action, 'rate');

    action = '';
    await pump(
      const NovelEngagementState(
        status: NovelEngagementStatus.guest,
        novelId: 99,
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('novel-details-rating-action')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('novel-details-rating-action')));
    expect(action, 'sign-in');

    action = '';
    await pump(
      const NovelEngagementState(
        status: NovelEngagementStatus.failure,
        novelId: 99,
        errorMessage: 'تعذر تحميل حالتك مع الرواية.',
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('novel-details-rating-action')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('novel-details-rating-action')));
    expect(action, 'retry');
  });

  testWidgets('rating stats cell disables interaction while loading', (
    tester,
  ) async {
    await _pumpHeader(
      tester,
      engagementState: const NovelEngagementState(
        status: NovelEngagementStatus.loading,
        novelId: 99,
      ),
    );

    final rail = find.byKey(const ValueKey('galaxy-stats-rail'));
    expect(
      find.descendant(
        of: rail,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
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
}

Future<void> _pumpHeader(
  WidgetTester tester, {
  required NovelEngagementState engagementState,
  VoidCallback? onRate,
  VoidCallback? onSignIn,
  VoidCallback? onRetry,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: ListView(
            children: [
              NovelDetailsHeader(
                details: _details,
                chaptersCount: 2,
                engagementState: engagementState,
                onRate: onRate ?? () {},
                onSignIn: onSignIn ?? () {},
                onRetryEngagement: onRetry ?? () {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
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

const _userState = NovelUserState(
  novelId: 99,
  favorite: false,
  myRating: 4,
  lastRead: NovelLastRead(
    chapterId: 0,
    chapterUrl: '',
    progress: 0,
    updatedAt: null,
  ),
  vip: NovelVipAccess(active: true, canReadPrivate: true),
);
