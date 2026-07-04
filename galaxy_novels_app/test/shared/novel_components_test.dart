import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/shared/widgets/novel_cover.dart';
import 'package:galaxy_novels_app/shared/widgets/novel_poster_tile.dart';
import 'package:galaxy_novels_app/shared/widgets/status_badge.dart';

void main() {
  testWidgets('NovelCover reserves stable poster dimensions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: NovelCover.poster(title: 'رواية اختبار', imageUrl: ''),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(NovelCover));

    expect(size.width, NovelCover.posterWidth);
    expect(size.height, NovelCover.posterHeight);
  });

  testWidgets('NovelPosterTile keeps title constrained under the cover', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: NovelPosterTile(
              title: 'عنوان طويل جدا لا يجب أن يكسر أبعاد البطاقة',
              imageUrl: '',
              statusLabel: 'مستمرة',
            ),
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'عنوان طويل جدا لا يجب أن يكسر أبعاد البطاقة' &&
            widget.maxLines == 2,
      ),
    );

    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.byType(NovelPosterTile)).width, 112);
  });

  testWidgets('StatusBadge uses compact fixed visual language', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: StatusBadge(label: 'VIP')),
        ),
      ),
    );

    expect(find.text('VIP'), findsOneWidget);
    expect(
      tester.getSize(find.byType(StatusBadge)).height,
      greaterThanOrEqualTo(24),
    );
  });

  testWidgets('StatusBadge maps novel states to semantic colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Column(
              children: [
                StatusBadge(label: 'مستمرة'),
                StatusBadge(label: 'مكتملة'),
                StatusBadge(label: 'متوقفة'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(_badgeTextColor(tester, 'مستمرة'), const Color(0xFF22C55E));
    expect(_badgeTextColor(tester, 'مكتملة'), const Color(0xFFEF4444));
    expect(_badgeTextColor(tester, 'متوقفة'), const Color(0xFFA855F7));
  });
}

Color? _badgeTextColor(WidgetTester tester, String label) {
  return tester.widget<Text>(find.text(label)).style?.color;
}
