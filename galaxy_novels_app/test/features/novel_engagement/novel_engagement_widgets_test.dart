import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/novel_engagement/application/novel_engagement_controller.dart';
import 'package:galaxy_novels_app/features/novel_engagement/domain/novel_user_state.dart';
import 'package:galaxy_novels_app/features/novel_engagement/presentation/novel_personal_state_section.dart';
import 'package:galaxy_novels_app/features/novel_engagement/presentation/novel_rating_sheet.dart';

void main() {
  testWidgets('rating sheet blocks duplicate submits and shows the error', (
    tester,
  ) async {
    final completion = Completer<RatingSubmitOutcome>();
    var calls = 0;
    await tester.pumpWidget(
      _TestSurface(
        child: NovelRatingSheet(
          initialRating: 2,
          onSubmit: (rating) {
            calls++;
            return completion.future;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('personal-rating-4')));
    await tester.tap(find.text('حفظ التقييم'));
    await tester.pump();
    await tester.tap(find.text('حفظ التقييم'));
    expect(calls, 1);

    completion.complete(
      const RatingSubmitOutcome(
        RatingSubmitStatus.failed,
        errorMessage: 'محاولات كثيرة. حاول لاحقًا.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('محاولات كثيرة. حاول لاحقًا.'), findsOneWidget);
    expect(find.byType(NovelRatingSheet), findsOneWidget);
  });

  testWidgets('rating sheet exposes five accessible star controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestSurface(
        child: NovelRatingSheet(
          initialRating: 0,
          onSubmit: (_) async =>
              const RatingSubmitOutcome(RatingSubmitStatus.saved),
        ),
      ),
    );

    for (var rating = 1; rating <= 5; rating++) {
      expect(find.byKey(ValueKey('personal-rating-$rating')), findsOneWidget);
    }
    expect(find.byTooltip('خمس نجوم'), findsOneWidget);
  });

  testWidgets('personal state section fits a 320 pixel phone', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _TestSurface(
        child: NovelPersonalStateSection(
          state: const NovelEngagementState(
            status: NovelEngagementStatus.ready,
            novelId: 99,
            userId: 7,
            data: NovelUserState(
              novelId: 99,
              favorite: false,
              myRating: 4,
              lastRead: NovelLastRead(
                chapterId: 2,
                chapterUrl: '/chapter-2/',
                progress: 45,
                updatedAt: null,
              ),
              vip: NovelVipAccess(active: true, canReadPrivate: false),
            ),
          ),
          onRate: _noop,
          onSignIn: _noop,
          onRetry: _noop,
        ),
      ),
    );

    expect(find.text('تقييمك'), findsOneWidget);
    expect(find.text('عضوية VIP فعالة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}

class _TestSurface extends StatelessWidget {
  const _TestSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: SafeArea(child: child)),
      ),
    );
  }
}
