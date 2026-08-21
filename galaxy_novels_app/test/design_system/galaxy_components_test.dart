import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_action.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_async_state.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_badge.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_command_bar.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_section_header.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_settings.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_skeleton.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_surface.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_tab_strip.dart';
import 'package:galaxy_novels_app/design_system/novel/galaxy_chapter_row.dart';
import 'package:galaxy_novels_app/design_system/novel/galaxy_novel_card.dart';
import 'package:galaxy_novels_app/design_system/novel/galaxy_novel_cover.dart';

void main() {
  testWidgets('GalaxyButton grows instead of clipping at 200 percent text', (
    tester,
  ) async {
    await _pump(
      tester,
      SizedBox(
        width: 132,
        child: GalaxyButton(
          label: 'تابع القراءة',
          icon: Icons.menu_book_rounded,
          onPressed: () {},
        ),
      ),
      textScale: 2,
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('تابع القراءة'),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.getSize(find.byType(FilledButton)).height, greaterThan(48));
  });

  testWidgets('GalaxyTabStrip switches between two 48dp tabs', (tester) async {
    await _pump(
      tester,
      DefaultTabController(
        length: 2,
        child: Builder(
          builder: (context) => GalaxyTabStrip(
            controller: DefaultTabController.of(context),
            tabs: const [
              GalaxyTabSpec(label: 'سجل القراءة'),
              GalaxyTabSpec(label: 'التنزيلات'),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.text('سجل القراءة')).height, greaterThan(0));
    await tester.tap(find.text('التنزيلات'));
    await tester.pumpAndSettle();
    final controller = DefaultTabController.of(
      tester.element(find.byType(GalaxyTabStrip)),
    );
    expect(controller.index, 1);
  });

  testWidgets('GalaxyAsyncState empty action invokes once', (tester) async {
    var actions = 0;
    await _pump(
      tester,
      GalaxyAsyncState.empty(
        title: 'لا توجد تنزيلات',
        message: 'ابدأ من المكتبة.',
        actionLabel: 'فتح المكتبة',
        onAction: () => actions += 1,
      ),
    );

    await tester.tap(find.text('فتح المكتبة'));
    expect(actions, 1);
  });

  testWidgets('GalaxyChapterRow can emphasize the current chapter', (
    tester,
  ) async {
    await _pump(
      tester,
      const GalaxyChapterRow(
        emphasized: true,
        chapter: GalaxyChapterRowData(title: 'الفصل 12'),
      ),
    );

    expect(
      tester.widget<GalaxySurface>(find.byType(GalaxySurface)).variant,
      GalaxySurfaceVariant.tonal,
    );
  });

  testWidgets('GalaxyChapterRow announces its selected state', (tester) async {
    await _pump(
      tester,
      GalaxyChapterRow(
        selectionMode: true,
        selected: true,
        chapter: const GalaxyChapterRowData(title: 'الفصل 12'),
        onSelectionChanged: (_) {},
      ),
    );

    final semantics = tester.getSemantics(find.byType(GalaxyChapterRow));
    expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);
  });

  testWidgets(
    'interactive GalaxySurface exposes one tap target of at least 48dp',
    (tester) async {
      var taps = 0;
      await _pump(
        tester,
        GalaxySurface(
          key: const ValueKey('surface'),
          variant: GalaxySurfaceVariant.raised,
          onTap: () => taps += 1,
          semanticLabel: 'فتح العنصر',
          child: const SizedBox(width: 32, height: 24),
        ),
      );

      expect(tester.getSize(find.byKey(const ValueKey('surface'))).height, 48);
      await tester.tap(find.bySemanticsLabel('فتح العنصر'));
      expect(taps, 1);
    },
  );

  testWidgets('GalaxySurface forwards long press without requiring a tap', (
    tester,
  ) async {
    var longPresses = 0;
    await _pump(
      tester,
      GalaxySurface(
        key: const ValueKey('long-press-surface'),
        semanticLabel: 'تحديد الفصل',
        onLongPress: () => longPresses += 1,
        child: const Text('الفصل 10'),
      ),
    );

    await tester.longPress(find.byKey(const ValueKey('long-press-surface')));
    expect(longPresses, 1);
  });

  testWidgets('interactive GalaxySurface uses the quiet 0.99 press scale', (
    tester,
  ) async {
    await _pump(
      tester,
      GalaxySurface(
        onTap: () {},
        semanticLabel: 'فتح الرواية',
        child: const SizedBox(width: 120, height: 80),
      ),
    );

    final center = tester.getCenter(find.bySemanticsLabel('فتح الرواية'));
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 60));

    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.99,
    );
    await gesture.up();
  });

  testWidgets('GalaxyBadge derives semantic tones from design tokens', (
    tester,
  ) async {
    await _pump(
      tester,
      const Wrap(
        children: [
          GalaxyBadge(label: 'مستمرة', tone: GalaxyBadgeTone.success),
          GalaxyBadge(label: 'VIP', tone: GalaxyBadgeTone.warning),
        ],
      ),
    );

    expect(find.text('مستمرة'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GalaxySectionHeader keeps its action accessible at large text', (
    tester,
  ) async {
    var actions = 0;
    await _pump(
      tester,
      GalaxySectionHeader(
        title: 'روايات محدثة جدًا بعنوان طويل',
        subtitle: 'وصل محتوى جديد للقارئ',
        actionLabel: 'عرض الكل',
        onAction: () => actions += 1,
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('عرض الكل'));
    expect(actions, 1);
  });

  testWidgets(
    'GalaxyAsyncState renders loading empty error and disabled states',
    (tester) async {
      await _pump(
        tester,
        const Column(
          children: [
            GalaxyAsyncState.loading(label: 'تحميل الروايات'),
            GalaxyAsyncState.empty(
              title: 'لا توجد روايات',
              message: 'ستظهر النتائج هنا.',
            ),
            GalaxyAsyncState.error(
              title: 'تعذر التحميل',
              message: 'تحقق من الاتصال.',
            ),
            GalaxyAsyncState.disabled(
              title: 'غير متاح',
              message: 'سيعود لاحقًا.',
            ),
          ],
        ),
      );

      expect(find.byType(GalaxyAsyncState), findsNWidgets(4));
      expect(find.text('تعذر التحميل'), findsOneWidget);
      expect(find.text('غير متاح'), findsOneWidget);
    },
  );

  testWidgets('GalaxySkeleton is stable and does not run a shimmer loop', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 120,
        child: GalaxySkeleton(variant: GalaxySkeletonVariant.poster),
      ),
    );

    expect(find.bySemanticsLabel('جارٍ تحميل المحتوى'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GalaxySkeleton),
        matching: find.byType(AnimatedBuilder),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'GalaxyNovelCover keeps a stable 2:3 frame and fallback semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        const SizedBox(
          width: 120,
          child: GalaxyNovelCover(
            artwork: GalaxyNovelArtwork(title: 'حارس النجوم'),
            presentation: GalaxyCoverPresentation.tonalFrame,
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(GalaxyNovelCover)),
        const Size(120, 180),
      );
      final coverSemantics = tester
          .getSemantics(find.bySemanticsLabel(RegExp('غلاف رواية حارس النجوم')))
          .getSemanticsData();
      expect(coverSemantics.flagsCollection.isImage, isTrue);
      semantics.dispose();
    },
  );

  testWidgets('GalaxyNovelCard opens once and constrains poster copy', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      SizedBox(
        width: 136,
        child: GalaxyNovelCard(
          novel: const GalaxyNovelCardData(
            title: 'عنوان رواية طويل جدًا داخل بطاقة سينمائية',
            badge: '126',
            metadata: 'مستمرة • خيال',
          ),
          style: const GalaxyNovelCardStyle.poster(),
          onTap: () => taps += 1,
        ),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(GalaxyNovelCard));
    expect(taps, 1);
    final title = tester.widget<Text>(find.textContaining('عنوان رواية طويل'));
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
  });

  testWidgets(
    'GalaxyNovelCard accepts feature slots without duplicating taps',
    (tester) async {
      var cardTaps = 0;
      var actionTaps = 0;
      await _pump(
        tester,
        SizedBox(
          width: 136,
          child: GalaxyNovelCard(
            novel: const GalaxyNovelCardData(title: 'رواية بفتحات مخصصة'),
            style: const GalaxyNovelCardStyle.poster(),
            slots: GalaxyNovelCardSlots(
              cover: const ColoredBox(
                key: ValueKey('custom-cover'),
                color: Colors.blueGrey,
              ),
              captionAction: IconButton(
                key: const ValueKey('caption-action'),
                onPressed: () => actionTaps += 1,
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ),
            onTap: () => cardTaps += 1,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('custom-cover')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('caption-action')));
      expect(actionTaps, 1);
      expect(cardTaps, 0);
    },
  );

  testWidgets(
    'cinematic poster keeps copy on the cover while editorial poster captions it below',
    (tester) async {
      await _pump(
        tester,
        const Row(
          children: [
            SizedBox(
              width: 128,
              child: GalaxyNovelCard(
                key: ValueKey('cinematic-card'),
                novel: GalaxyNovelCardData(
                  title: 'مدينة الرماد',
                  badge: '128',
                  metadata: 'مستمرة • خيال',
                ),
                style: GalaxyNovelCardStyle(
                  variant: GalaxyNovelCardVariant.cinematicPoster,
                ),
              ),
            ),
            SizedBox(width: 12),
            SizedBox(
              width: 128,
              child: GalaxyNovelCard(
                key: ValueKey('editorial-card'),
                novel: GalaxyNovelCardData(
                  title: 'قمر الشتاء',
                  badge: 'مكتملة',
                  metadata: '92 فصلًا',
                ),
                style: GalaxyNovelCardStyle(
                  variant: GalaxyNovelCardVariant.editorialPoster,
                ),
              ),
            ),
          ],
        ),
      );

      final cinematicTitle = find.descendant(
        of: find.byKey(const ValueKey('galaxy-cinematic-cover')),
        matching: find.text('مدينة الرماد'),
      );
      final editorialTitle = find.descendant(
        of: find.byKey(const ValueKey('galaxy-editorial-caption')),
        matching: find.text('قمر الشتاء'),
      );
      expect(cinematicTitle, findsOneWidget);
      expect(editorialTitle, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('GalaxyCommandBar keeps compact actions accessible', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      GalaxyCommandBar(
        label: 'أدوات المكتبة',
        actions: [
          GalaxyCommand(
            icon: Icons.tune_rounded,
            label: 'الفلاتر',
            onPressed: () => taps += 1,
          ),
          GalaxyCommand(
            icon: Icons.swap_vert_rounded,
            label: 'الترتيب',
            onPressed: () => taps += 1,
          ),
        ],
      ),
    );

    expect(find.bySemanticsLabel('أدوات المكتبة'), findsOneWidget);
    expect(tester.getSize(find.byTooltip('الفلاتر')).height, 48);
    await tester.tap(find.byTooltip('الفلاتر'));
    expect(taps, 1);
  });

  testWidgets('GalaxySettingsGroup composes accessible rows and switches', (
    tester,
  ) async {
    var tileTaps = 0;
    bool? switchValue;
    await _pump(
      tester,
      GalaxySettingsGroup(
        title: 'البيانات والتنزيلات',
        children: [
          GalaxySettingsTile(
            key: const ValueKey('settings-data-row'),
            icon: Icons.storage_outlined,
            title: 'إدارة البيانات',
            subtitle: 'المساحة والملفات المؤقتة',
            onTap: () => tileTaps += 1,
          ),
          GalaxySettingsSwitchTile(
            key: const ValueKey('settings-wifi-row'),
            icon: Icons.wifi_rounded,
            title: 'التنزيل عبر Wi-Fi فقط',
            subtitle: 'يمنع استخدام بيانات الهاتف',
            value: true,
            onChanged: (enabled) => switchValue = enabled,
          ),
        ],
      ),
    );

    expect(find.text('البيانات والتنزيلات'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('settings-data-row'))).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.byKey(const ValueKey('settings-data-row')));
    await tester.tap(find.byType(Switch));
    expect(tileTaps, 1);
    expect(switchValue, isFalse);
  });

  testWidgets('GalaxySettingsAccountSummary remains readable at large text', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      GalaxySettingsAccountSummary(
        summary: const GalaxyAccountSummaryData(
          title: 'قارئ المجرة',
          subtitle: 'حسابك ومزامنة القراءة',
          badge: 'VIP 2',
        ),
        onTap: () => taps += 1,
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('قارئ المجرة'));
    expect(taps, 1);
  });

  testWidgets('GalaxyCompactThemePreview exposes the selected palette', (
    tester,
  ) async {
    await _pump(
      tester,
      const GalaxyCompactThemePreview(
        preview: GalaxyThemePreviewData(
          title: 'أطياف السديم',
          canvas: Color(0xFF0E1520),
          surface: Color(0xFF141E2B),
          surfaceRaised: Color(0xFF1B2838),
          brand: Color(0xFF8EA9D1),
          onBrand: Colors.black,
        ),
      ),
      textScale: 2,
    );

    expect(find.text('أطياف السديم'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('galaxy-theme-compact-preview')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('GalaxyCommandBar reveals short labels from medium widths', (
    tester,
  ) async {
    await _pump(
      tester,
      GalaxyCommandBar(
        actions: [
          GalaxyCommand(
            icon: Icons.tune_rounded,
            label: 'الفلاتر',
            onPressed: () {},
          ),
        ],
      ),
      size: const Size(600, 800),
    );

    expect(find.text('الفلاتر'), findsOneWidget);
    expect(tester.getSize(find.byTooltip('الفلاتر')).height, 48);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
  Size size = const Size(320, 800),
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}
