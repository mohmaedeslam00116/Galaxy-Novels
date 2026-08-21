import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/novel_engagement/application/novel_engagement_controller.dart';
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
}

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
