import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/chapter_summary.dart';
import 'package:galaxy_novels_app/data/models/home_data.dart';
import 'package:galaxy_novels_app/data/models/novel_summary.dart';
import 'package:galaxy_novels_app/design_system/novel/galaxy_novel_card.dart';
import 'package:galaxy_novels_app/features/home/domain/home_customization.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_continue_reading.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_customization_preview.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_novel_open_request.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_section_card_preview.dart';
import 'package:galaxy_novels_app/features/home/presentation/home_updated_novels_strip.dart';
import 'package:galaxy_novels_app/features/home/presentation/latest_updates_section.dart';
import 'package:galaxy_novels_app/shared/widgets/novel_cover.dart';

void main() {
  testWidgets('compact and card previews reflect cover presentation', (
    tester,
  ) async {
    final customization = HomeCustomization.defaults.copyWith(
      coverPresentations: {
        for (final section in HomeSectionId.values)
          section: HomeCoverPresentation.tonalFrame,
      },
    );

    await _pump(
      tester,
      ListView(
        children: [
          HomeCustomizationPreview(customization: customization),
          HomeSectionCardPreview(
            section: HomeSectionId.updatedNovels,
            customization: customization,
          ),
        ],
      ),
    );

    expect(
      find.byKey(const ValueKey('home-mini-cover-updatedNovels-tonalFrame')),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('home-section-card-preview-updatedNovels'),
        ),
        matching: find.byKey(
          const ValueKey('home-cover-updatedNovels-tonalFrame'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('detailed continue reading stacks three real novel cards', (
    tester,
  ) async {
    await _pump(
      tester,
      HomeContinueReadingStrip(
        entries: [_readingEntry, _readingEntry2, _readingEntry3],
        onOpen: (_) {},
        customization: HomeCustomization.defaults.copyWith(
          continueReadingTemplate: ContinueReadingCardTemplate.detailed,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('continue-reading-deck-front-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('continue-reading-deck-layer-1-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('continue-reading-deck-layer-2-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('continue-reading-stack-back-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('continue-reading-page-view')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('continue-reading-deck-counter')),
      findsOneWidget,
    );
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('detailed deck swipes both ways and loops circularly', (
    tester,
  ) async {
    await _pump(
      tester,
      HomeContinueReadingStrip(
        entries: [_readingEntry, _readingEntry2, _readingEntry3],
        onOpen: (_) {},
        customization: HomeCustomization.defaults.copyWith(
          continueReadingTemplate: ContinueReadingCardTemplate.detailed,
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('continue-reading-deck-draggable')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('continue-reading-deck-front-1')),
      findsOneWidget,
    );
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('continue-reading-deck-draggable')),
      const Offset(360, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('continue-reading-deck-front-0')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('continue-reading-deck-draggable')),
      const Offset(360, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('continue-reading-deck-front-2')),
      findsOneWidget,
    );
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('cancelled deck swipe restores the next novels behind it', (
    tester,
  ) async {
    await _pump(
      tester,
      HomeContinueReadingStrip(
        entries: [_readingEntry, _readingEntry2, _readingEntry3],
        onOpen: (_) {},
        customization: HomeCustomization.defaults.copyWith(
          continueReadingTemplate: ContinueReadingCardTemplate.detailed,
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('continue-reading-deck-draggable')),
      const Offset(40, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('continue-reading-deck-front-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('continue-reading-deck-layer-1-1')),
      findsOneWidget,
    );
  });

  testWidgets('continue reading hides deck controls for one entry', (
    tester,
  ) async {
    await _pump(
      tester,
      HomeContinueReadingStrip(
        entries: [_readingEntry],
        onOpen: (_) {},
        customization: HomeCustomization.defaults.copyWith(
          continueReadingTemplate: ContinueReadingCardTemplate.detailed,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('continue-reading-deck-counter')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('continue-reading-deck-draggable')),
      findsNothing,
    );
  });

  testWidgets('two-entry deck does not duplicate a third layer', (
    tester,
  ) async {
    await _pump(
      tester,
      HomeContinueReadingStrip(
        entries: [_readingEntry, _readingEntry2],
        onOpen: (_) {},
        customization: HomeCustomization.defaults.copyWith(
          continueReadingTemplate: ContinueReadingCardTemplate.detailed,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('continue-reading-deck-front-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('continue-reading-deck-layer-1-1')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'continue-reading-deck-layer-2-',
            ),
      ),
      findsNothing,
    );
  });

  testWidgets('medium poster rail shows about two and a half covers', (
    tester,
  ) async {
    await _pump(
      tester,
      HomeUpdatedNovelsStrip(
        novels: const [_novel, _novel2, _novel3],
        onNovelTap: (_) {},
        customization: HomeCustomization.defaults.copyWith(
          updatedNovelsTemplate: UpdatedNovelCardTemplate.poster,
        ),
      ),
    );

    final firstPoster = find.byKey(const ValueKey('updated-card-poster-1'));
    expect(tester.getSize(firstPoster).width, closeTo(136, 0.1));
  });

  testWidgets('one updated novel becomes a full-width editorial card', (
    tester,
  ) async {
    await _pump(
      tester,
      HomeUpdatedNovelsStrip(
        novels: const [_novel],
        onNovelTap: (_) {},
        customization: HomeCustomization.defaults,
      ),
    );

    expect(
      find.byKey(const ValueKey('galaxy-adaptive-single')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('updated-card-horizontal-1')),
      findsOneWidget,
    );
  });

  testWidgets('two updated novels fill the available width', (tester) async {
    await _pump(
      tester,
      HomeUpdatedNovelsStrip(
        novels: const [_novel, _novel2],
        onNovelTap: (_) {},
        customization: HomeCustomization.defaults,
      ),
    );

    expect(find.byKey(const ValueKey('galaxy-adaptive-pair')), findsOneWidget);
  });

  testWidgets('three updated novels remain a cinematic shelf', (tester) async {
    await _pump(
      tester,
      HomeUpdatedNovelsStrip(
        novels: const [_novel, _novel2, _novel3],
        onNovelTap: (_) {},
        customization: HomeCustomization.defaults,
      ),
    );

    expect(find.byKey(const ValueKey('galaxy-adaptive-shelf')), findsOneWidget);
  });

  testWidgets('one grid result also uses the editorial treatment', (
    tester,
  ) async {
    await _pumpSliver(
      tester,
      HomeUpdatedNovelsGrid(
        novels: const [_novel],
        onNovelTap: (_) {},
        customization: HomeCustomization.defaults,
      ),
    );

    expect(
      find.byKey(const ValueKey('galaxy-adaptive-single')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('updated-novels-grid')), findsNothing);
  });

  testWidgets(
    'updated poster uses one shared cover-first shell and chapter tab',
    (tester) async {
      await _pump(
        tester,
        HomeUpdatedNovelsStrip(
          novels: const [_novel, _novel2, _novel3],
          onNovelTap: (_) {},
          customization: HomeCustomization.defaults.copyWith(
            updatedNovelsTemplate: UpdatedNovelCardTemplate.poster,
          ),
        ),
      );

      final poster = find.byKey(const ValueKey('updated-card-poster-1'));
      expect(
        find.descendant(
          of: poster,
          matching: find.byKey(
            const ValueKey('home-poster-shell-updatedNovels'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: poster,
          matching: find.byKey(
            const ValueKey('home-poster-chapter-count-tab-updatedNovels'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: poster, matching: find.byType(GalaxyNovelCard)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: poster,
          matching: find.byKey(const ValueKey('galaxy-cinematic-cover')),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('latest poster uses the shared cover-first shell', (
    tester,
  ) async {
    await _pumpSliver(
      tester,
      LatestUpdatesSection(
        chapters: const [_chapter],
        novelsById: const {1: _novel},
        onNovelTap: (_) {},
        customization: HomeCustomization.defaults.copyWith(
          latestUpdatesLayout: LatestUpdatesLayout.grid,
          latestUpdatesTemplate: LatestUpdateCardTemplate.poster,
        ),
      ),
    );

    final poster = find.byKey(const ValueKey('latest-card-poster-7'));
    expect(
      find.descendant(
        of: poster,
        matching: find.byKey(const ValueKey('home-poster-shell-latestUpdates')),
      ),
      findsOneWidget,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'poster caption stays inside the cover in ${brightness.name} theme',
      (tester) async {
        await _pumpWithTheme(
          tester,
          brightness: brightness,
          child: HomeUpdatedNovelsStrip(
            novels: const [_novel, _novel2, _novel3],
            onNovelTap: (_) {},
            customization: HomeCustomization.defaults.copyWith(
              updatedNovelsTemplate: UpdatedNovelCardTemplate.poster,
            ),
          ),
        );

        final poster = find.byKey(const ValueKey('updated-card-poster-1'));
        final cover = find.descendant(
          of: poster,
          matching: find.byType(NovelCover),
        );
        final title = find.descendant(
          of: poster,
          matching: find.text(_novel.title),
        );
        expect(
          tester.getTopLeft(title).dy,
          greaterThan(tester.getTopLeft(cover).dy),
        );
        expect(
          tester.getBottomLeft(title).dy,
          lessThanOrEqualTo(tester.getBottomLeft(cover).dy),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final presentation in HomeCoverPresentation.values) {
    testWidgets(
      'all home sections render ${presentation.name} cover presentation',
      (tester) async {
        final presentations = {
          for (final section in HomeSectionId.values) section: presentation,
        };
        final customization = HomeCustomization.defaults.copyWith(
          coverPresentations: presentations,
        );

        await _pump(
          tester,
          ListView(
            children: [
              HomeContinueReadingStrip(
                entries: [_readingEntry],
                onOpen: (_) {},
                customization: customization,
              ),
              HomeUpdatedNovelsStrip(
                novels: const [_novel],
                onNovelTap: (_) {},
                customization: customization,
              ),
              HomeSectionCardPreview(
                section: HomeSectionId.becauseYouRead,
                customization: customization,
              ),
              SizedBox(
                height: 500,
                child: CustomScrollView(
                  slivers: [
                    LatestUpdatesSection(
                      chapters: const [_chapter],
                      novelsById: const {1: _novel},
                      onNovelTap: (_) {},
                      customization: customization,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        for (final section in HomeSectionId.values) {
          expect(
            find.byKey(
              ValueKey('home-cover-${section.name}-${presentation.name}'),
            ),
            findsWidgets,
          );
        }
        final covers = tester.widgetList<NovelCover>(find.byType(NovelCover));
        final expectedFit = presentation == HomeCoverPresentation.fill
            ? BoxFit.cover
            : BoxFit.contain;
        expect(covers, isNotEmpty);
        expect(covers.every((cover) => cover.fit == expectedFit), isTrue);
        expect(
          covers.every(
            (cover) => presentation == HomeCoverPresentation.fill
                ? cover.backgroundColor == null
                : cover.backgroundColor != null,
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in HomeCardSize.values) {
    for (final template in ContinueReadingCardTemplate.values) {
      testWidgets('continue reading renders ${template.name} at ${size.name}', (
        tester,
      ) async {
        final customization = _withSize(
          HomeCustomization.defaults.copyWith(
            continueReadingTemplate: template,
          ),
          HomeSectionId.continueReading,
          size,
        );
        await _pump(
          tester,
          HomeContinueReadingStrip(
            entries: [_readingEntry],
            onOpen: (_) {},
            customization: customization,
          ),
        );

        expect(
          find.byKey(ValueKey('continue-reading-template-${template.name}-0')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final template in UpdatedNovelCardTemplate.values) {
      testWidgets('updated novels renders ${template.name} at ${size.name}', (
        tester,
      ) async {
        final customization = _withSize(
          HomeCustomization.defaults.copyWith(updatedNovelsTemplate: template),
          HomeSectionId.updatedNovels,
          size,
        );
        await _pump(
          tester,
          HomeUpdatedNovelsStrip(
            novels: const [_novel, _novel2, _novel3],
            onNovelTap: (_) {},
            customization: customization,
          ),
        );

        expect(
          find.byKey(ValueKey('updated-card-${template.name}-1')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final template in LatestUpdateCardTemplate.values) {
      testWidgets('latest updates renders ${template.name} at ${size.name}', (
        tester,
      ) async {
        final customization = _withSize(
          HomeCustomization.defaults.copyWith(latestUpdatesTemplate: template),
          HomeSectionId.latestUpdates,
          size,
        ).copyWith(latestUpdatesLayout: LatestUpdatesLayout.detailedList);
        await _pumpSliver(
          tester,
          LatestUpdatesSection(
            chapters: const [_chapter],
            novelsById: const {1: _novel},
            onNovelTap: (_) {},
            customization: customization,
          ),
        );

        expect(
          find.byKey(ValueKey('latest-card-${template.name}-7')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('all visual templates fit 320 pixels at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final customization = HomeCustomization.forPreset(
      HomeCustomizationPreset.visual,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: ListView(
              children: [
                HomeContinueReadingStrip(
                  entries: [_readingEntry],
                  onOpen: (_) {},
                  customization: customization,
                ),
                HomeUpdatedNovelsStrip(
                  novels: const [_novel],
                  onNovelTap: (_) {},
                  customization: customization,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('default continue card fits 320 pixels at 200 percent text', (
    tester,
  ) async {
    await _pumpLargeText(
      tester,
      HomeContinueReadingStrip(
        entries: [_readingEntry],
        onOpen: (_) {},
        customization: HomeCustomization.defaults,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('default updated card fits 320 pixels at 200 percent text', (
    tester,
  ) async {
    await _pumpLargeText(
      tester,
      HomeUpdatedNovelsStrip(
        novels: const [_novel],
        onNovelTap: (_) {},
        customization: HomeCustomization.defaults,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('latest poster fits 320 pixels at 200 percent text', (
    tester,
  ) async {
    await _pumpSliverLargeText(
      tester,
      LatestUpdatesSection(
        chapters: const [_chapter],
        novelsById: const {1: _novel},
        onNovelTap: (_) {},
        customization: HomeCustomization.defaults.copyWith(
          latestUpdatesLayout: LatestUpdatesLayout.grid,
          latestUpdatesTemplate: LatestUpdateCardTemplate.poster,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('updated card navigates once without a duplicate quick action', (
    tester,
  ) async {
    var opens = 0;
    await _pump(
      tester,
      HomeUpdatedNovelsStrip(
        novels: const [_novel],
        onNovelTap: (_) => opens++,
        customization: HomeCustomization.defaults,
      ),
    );

    expect(find.byKey(const ValueKey('updated-action-1')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('updated-card-horizontal-1')));
    await tester.pump();

    expect(opens, 1);
  });

  testWidgets('premium cover forwards one unique hero transition request', (
    tester,
  ) async {
    HomeNovelOpenRequest? request;
    await _pump(
      tester,
      HomeUpdatedNovelsStrip(
        novels: const [_novel],
        onNovelTap: (_) => fail('legacy callback should not be used'),
        onNovelOpen: (value) => request = value,
        customization: HomeCustomization.defaults,
      ),
    );

    expect(find.byType(Hero), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('updated-card-horizontal-1')));
    await tester.pump();

    expect(request?.manifestPath, _novel.manifest);
    expect(request?.heroTag, 'home-cover:updatedNovels:1');
    expect(request?.title, _novel.title);
  });

  testWidgets('premium cover disables Hero when reduced motion is enabled', (
    tester,
  ) async {
    await _pump(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: HomeUpdatedNovelsStrip(
          novels: const [_novel],
          onNovelTap: (_) {},
          onNovelOpen: (_) {},
          customization: HomeCustomization.defaults,
        ),
      ),
    );

    expect(find.byType(Hero), findsNothing);
  });

  testWidgets('latest row navigates once without a duplicate quick action', (
    tester,
  ) async {
    var opens = 0;
    await _pumpSliver(
      tester,
      LatestUpdatesSection(
        chapters: const [_chapter],
        novelsById: const {1: _novel},
        onNovelTap: (_) => opens++,
        customization: HomeCustomization.defaults,
      ),
    );

    expect(find.byKey(const ValueKey('latest-action-7')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('latest-update-7')));
    await tester.pump();

    expect(opens, 1);
  });

  for (final (width, columns) in const [(390.0, 1), (840.0, 2)]) {
    testWidgets('horizontal updated grid uses $columns columns at $width', (
      tester,
    ) async {
      final customization = HomeCustomization.defaults.copyWith(
        updatedNovelsLayout: UpdatedNovelsLayout.grid,
        updatedNovelsTemplate: UpdatedNovelCardTemplate.horizontal,
      );
      await _pumpSliverAt(
        tester,
        width: width,
        sliver: HomeUpdatedNovelsGrid(
          novels: const [_novel, _novel2, _novel3, _novel4],
          onNovelTap: (_) {},
          customization: customization,
        ),
      );

      final cards = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('updated-card-horizontal-');
      });
      final xPositions = cards
          .evaluate()
          .map((element) => tester.getTopLeft(find.byWidget(element.widget)).dx)
          .map((value) => value.round())
          .toSet();
      expect(xPositions, hasLength(columns));
      expect(tester.takeException(), isNull);
    });
  }
}

HomeCustomization _withSize(
  HomeCustomization customization,
  HomeSectionId section,
  HomeCardSize size,
) {
  final sizes = Map<HomeSectionId, HomeCardSize>.of(customization.cardSizes);
  sizes[section] = size;
  return customization.copyWith(cardSizes: sizes);
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSliver(WidgetTester tester, Widget sliver) async {
  await _pump(tester, CustomScrollView(slivers: [sliver]));
}

Future<void> _pumpWithTheme(
  WidgetTester tester, {
  required Brightness brightness,
  required Widget child,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSliverAt(
  WidgetTester tester, {
  required double width,
  required Widget sliver,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      home: Scaffold(body: CustomScrollView(slivers: [sliver])),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpLargeText(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSliverLargeText(WidgetTester tester, Widget sliver) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(body: CustomScrollView(slivers: [sliver])),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _readingEntry = HomeContinueReadingEntry.fromHome(
  const ReadingProgress(
    novelTitle: 'رواية تجريبية',
    chapterLabel: 'الفصل 12',
    progress: 62,
  ),
);

final _readingEntry2 = HomeContinueReadingEntry.fromHome(
  const ReadingProgress(
    novelTitle: 'رواية ثانية',
    chapterLabel: 'الفصل 24',
    progress: 35,
  ),
);

final _readingEntry3 = HomeContinueReadingEntry.fromHome(
  const ReadingProgress(
    novelTitle: 'رواية ثالثة',
    chapterLabel: 'الفصل 36',
    progress: 18,
  ),
);

const _novel = NovelSummary(
  id: 1,
  title: 'رواية تجريبية',
  url: '/novel/1',
  coverThumbnail: '',
  statusLabel: 'مستمرة',
  genres: ['خيال'],
  chaptersCount: 42,
  manifest: '/manifest/1.json',
);

const _novel2 = NovelSummary(
  id: 2,
  title: 'رواية ثانية',
  url: '/novel/2',
  coverThumbnail: '',
  statusLabel: 'مكتملة',
  genres: ['دراما'],
  chaptersCount: 30,
  manifest: '/manifest/2.json',
);

const _novel3 = NovelSummary(
  id: 3,
  title: 'رواية ثالثة',
  url: '/novel/3',
  coverThumbnail: '',
  statusLabel: 'مستمرة',
  genres: ['أكشن'],
  chaptersCount: 20,
  manifest: '/manifest/3.json',
);

const _novel4 = NovelSummary(
  id: 4,
  title: 'رواية رابعة',
  url: '/novel/4',
  coverThumbnail: '',
  statusLabel: 'مستمرة',
  genres: ['غموض'],
  chaptersCount: 10,
  manifest: '/manifest/4.json',
);

const _chapter = ChapterSummary(
  id: 7,
  novelId: 1,
  novelTitle: 'رواية تجريبية',
  label: 'الفصل 7',
  title: '',
  dateLabel: 'اليوم',
  url: '/chapter/7',
  manifest: '/manifest/1.json',
  chapters: [
    ChapterSummaryItem(
      id: 7,
      label: 'الفصل 7',
      title: '',
      dateLabel: 'اليوم',
      url: '/chapter/7',
    ),
    ChapterSummaryItem(
      id: 6,
      label: 'الفصل 6',
      title: '',
      dateLabel: 'أمس',
      url: '/chapter/6',
    ),
  ],
);
