import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/design_system/novel/galaxy_chapter_row.dart';
import 'package:galaxy_novels_app/design_system/patterns/galaxy_editorial_list.dart';
import 'package:galaxy_novels_app/design_system/patterns/galaxy_novel_shelf.dart';
import 'package:galaxy_novels_app/design_system/patterns/galaxy_novel_details_header.dart';
import 'package:galaxy_novels_app/design_system/patterns/galaxy_section_band.dart';

void main() {
  testWidgets('GalaxyChapterRow presents downloaded and VIP states', (
    tester,
  ) async {
    await _pump(
      tester,
      const Column(
        children: [
          GalaxyChapterRow(
            chapter: GalaxyChapterRowData(
              title: 'الفصل 12',
              state: GalaxyChapterState.downloaded,
            ),
          ),
          GalaxyChapterRow(
            chapter: GalaxyChapterRowData(
              title: 'الفصل 13',
              state: GalaxyChapterState.vipLocked,
            ),
          ),
        ],
      ),
    );

    expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_outlined), findsOneWidget);
  });

  testWidgets('GalaxyNovelShelf exposes the next card at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(
      tester,
      SizedBox(
        height: 190,
        child: GalaxyNovelShelf(
          itemWidth: 118,
          children: List.generate(
            4,
            (index) => ColoredBox(
              key: ValueKey('shelf-$index'),
              color: Colors.blueGrey,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('shelf-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('shelf-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GalaxyEditorialList uses one group surface and row separators', (
    tester,
  ) async {
    await _pump(
      tester,
      const GalaxyEditorialList(
        children: [Text('الأول'), Text('الثاني'), Text('الثالث')],
      ),
    );

    expect(find.byKey(const ValueKey('galaxy-editorial-list')), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('centered details header composes poster and stats rail', (
    tester,
  ) async {
    await _pump(
      tester,
      GalaxyNovelDetailsHeader(
        variant: GalaxyNovelDetailsHeaderVariant.centeredPoster,
        title: 'حارس المجرة',
        subtitle: 'Galaxy Keeper',
        cover: const SizedBox(
          key: ValueKey('centered-poster'),
          width: 176,
          height: 264,
        ),
        content: const GalaxyStatsRail(
          items: [
            GalaxyStatItem(
              icon: Icons.star_rounded,
              value: '8.7',
              label: 'التقييم',
            ),
            GalaxyStatItem(
              icon: Icons.visibility_rounded,
              value: '1.2M',
              label: 'المشاهدات',
            ),
            GalaxyStatItem(
              icon: Icons.menu_book_rounded,
              value: '342',
              label: 'الفصول',
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('centered-poster')), findsOneWidget);
    expect(find.byKey(const ValueKey('galaxy-stats-rail')), findsOneWidget);
    expect(find.text('التقييم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('centered details header becomes two columns when expanded', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(840, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(
      tester,
      const GalaxyNovelDetailsHeader(
        variant: GalaxyNovelDetailsHeaderVariant.centeredPoster,
        title: 'حارس المجرة',
        cover: SizedBox(width: 224, height: 336),
        content: Text('المعلومات'),
      ),
    );

    expect(
      find.byKey(const ValueKey('galaxy-details-expanded-header')),
      findsOneWidget,
    );
  });

  testWidgets('stats rail supports interactive and loading stat items', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      GalaxyStatsRail(
        items: [
          GalaxyStatItem(
            key: const ValueKey('interactive-stat'),
            icon: Icons.star_rounded,
            value: '4.8',
            label: 'التقييم',
            tooltip: 'اضغط لإضافة أو تعديل تقييمك',
            onTap: () => taps += 1,
          ),
          const GalaxyStatItem(
            key: ValueKey('loading-stat'),
            icon: Icons.visibility_rounded,
            value: '—',
            label: 'المشاهدات',
            loading: true,
          ),
        ],
      ),
    );

    expect(find.byTooltip('اضغط لإضافة أو تعديل تقييمك'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('interactive-stat')));
    expect(taps, 1);
  });

  testWidgets('collapsing details bar exposes title and read action', (
    tester,
  ) async {
    var reads = 0;
    await _pump(
      tester,
      GalaxyCollapsingDetailsBar(
        title: 'رواية طويلة جدًا',
        readLabel: 'متابعة',
        onRead: () => reads += 1,
      ),
    );

    expect(find.text('رواية طويلة جدًا'), findsOneWidget);
    await tester.tap(find.text('متابعة'));
    expect(reads, 1);
  });

  testWidgets('GalaxySectionBand is an unboxed thematic strip', (tester) async {
    await _pump(tester, const GalaxySectionBand(child: Text('قسم سينمائي')));

    expect(find.byKey(const ValueKey('galaxy-section-band')), findsOneWidget);
    expect(find.text('قسم سينمائي'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    ),
  );
}
