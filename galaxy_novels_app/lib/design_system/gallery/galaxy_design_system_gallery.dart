import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../components/galaxy_action.dart';
import '../components/galaxy_async_state.dart';
import '../components/galaxy_badge.dart';
import '../components/galaxy_command_bar.dart';
import '../components/galaxy_search_field.dart';
import '../components/galaxy_section_header.dart';
import '../components/galaxy_settings.dart';
import '../components/galaxy_tab_strip.dart';
import '../foundation/galaxy_component_variants.dart';
import '../novel/galaxy_chapter_row.dart';
import '../novel/galaxy_novel_card.dart';
import '../patterns/galaxy_novel_shelf.dart';
import '../patterns/galaxy_novel_details_header.dart';
import '../patterns/galaxy_progressive_info_table.dart';
import '../patterns/galaxy_section_band.dart';

class GalaxyDesignSystemGallery extends StatefulWidget {
  const GalaxyDesignSystemGallery({
    this.initialPreset = AppThemePreset.galaxyNoir,
    super.key,
  });

  final AppThemePreset initialPreset;

  @override
  State<GalaxyDesignSystemGallery> createState() =>
      _GalaxyDesignSystemGalleryState();
}

class _GalaxyDesignSystemGalleryState extends State<GalaxyDesignSystemGallery> {
  late AppThemePreset _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPreset;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _themeFor(_selected),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Galaxy Design System')),
          body: ListView(
            padding: const EdgeInsets.all(GalaxyMetrics.space16),
            children: [
              _ThemeStrip(
                selected: _selected,
                onSelected: (value) => setState(() => _selected = value),
              ),
              const SizedBox(height: GalaxyMetrics.space16),
              GalaxyCommandBar(
                label: 'أوامر المكتبة',
                actions: [
                  GalaxyCommand(
                    icon: Icons.tune_rounded,
                    label: 'الفلاتر',
                    onPressed: _ignoreTap,
                  ),
                  GalaxyCommand(
                    icon: Icons.swap_vert_rounded,
                    label: 'الترتيب',
                    onPressed: _ignoreTap,
                  ),
                ],
              ),
              const SizedBox(height: GalaxyMetrics.space24),
              const GalaxySectionHeader(
                title: 'روايات محدثة',
                subtitle: 'معاينة محلية للمكونات',
                actionLabel: 'عرض الكل',
              ),
              const SizedBox(height: GalaxyMetrics.space12),
              const SizedBox(height: 310, child: _NovelCards()),
              const SizedBox(height: GalaxyMetrics.space16),
              const GalaxyStatsRail(
                items: [
                  GalaxyStatItem(
                    icon: Icons.star_rounded,
                    value: '8.7',
                    label: 'التقييم',
                    tooltip: 'اضغط لإضافة أو تعديل تقييمك',
                    onTap: _ignoreTap,
                  ),
                  GalaxyStatItem(
                    icon: Icons.visibility_outlined,
                    value: '1.2م',
                    label: 'المشاهدات',
                  ),
                  GalaxyStatItem(
                    icon: Icons.menu_book_outlined,
                    value: '342',
                    label: 'الفصول',
                  ),
                ],
              ),
              const SizedBox(height: GalaxyMetrics.space16),
              const _States(key: ValueKey('galaxy-gallery-states')),
              const SizedBox(height: GalaxyMetrics.space24),
              const GalaxySettingsAccountSummary(
                summary: GalaxyAccountSummaryData(
                  title: 'قارئ المجرة',
                  subtitle: 'الحساب والعضوية',
                  badge: 'VIP 2',
                ),
                onTap: _ignoreTap,
              ),
              const SizedBox(height: GalaxyMetrics.space12),
              GalaxySettingsGroup(
                title: 'مكونات الإعدادات',
                children: [
                  GalaxySettingsTile(
                    icon: Icons.storage_outlined,
                    title: 'إدارة البيانات',
                    subtitle: 'المساحة والملفات المؤقتة',
                    onTap: _ignoreTap,
                  ),
                  GalaxySettingsSwitchTile(
                    icon: Icons.wifi_rounded,
                    title: 'التنزيل عبر Wi-Fi فقط',
                    value: true,
                    onChanged: _ignoreBool,
                  ),
                ],
              ),
              const SizedBox(height: GalaxyMetrics.space24),
              const GalaxyProgressiveInfoTable(
                primaryItems: [
                  GalaxyInfoItem(
                    icon: Icons.person_outline_rounded,
                    label: 'الكاتب',
                    value: 'كاتب الرواية',
                  ),
                  GalaxyInfoItem(
                    icon: Icons.translate_rounded,
                    label: 'المترجم',
                    value: 'فريق الترجمة',
                  ),
                ],
                secondaryItems: [
                  GalaxyInfoItem(
                    icon: Icons.public_rounded,
                    label: 'البلد',
                    value: 'الصين',
                  ),
                ],
              ),
              const SizedBox(height: GalaxyMetrics.space16),
              const _Actions(),
              const SizedBox(height: GalaxyMetrics.space24),
              const _Chapters(),
              const SizedBox(height: GalaxyMetrics.space24),
              const SizedBox(height: GalaxyMetrics.space24),
              const GalaxySectionBand(child: _DetailsPreview()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeStrip extends StatelessWidget {
  const _ThemeStrip({required this.selected, required this.onSelected});

  final AppThemePreset selected;
  final ValueChanged<AppThemePreset> onSelected;

  @override
  Widget build(BuildContext context) {
    const themes = [
      AppTheme.galaxyNoir,
      AppTheme.cosmicNight,
      AppTheme.neutralDark,
      AppTheme.starlightPaper,
      AppTheme.lightNature,
    ];
    return Wrap(
      spacing: GalaxyMetrics.space8,
      runSpacing: GalaxyMetrics.space8,
      children: [
        for (final tokens in themes)
          Semantics(
            label: 'معاينة ${tokens.preset.name}',
            selected: selected == tokens.preset,
            button: true,
            child: InkWell(
              onTap: () => onSelected(tokens.preset),
              borderRadius: BorderRadius.circular(GalaxyMetrics.radiusSmall),
              child: Container(
                width: 52,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(
                    GalaxyMetrics.radiusSmall,
                  ),
                  border: Border.all(
                    color: selected == tokens.preset
                        ? tokens.brand
                        : tokens.outline,
                    width: selected == tokens.preset ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: CircleAvatar(radius: 6, backgroundColor: tokens.brand),
              ),
            ),
          ),
      ],
    );
  }
}

class _NovelCards extends StatelessWidget {
  const _NovelCards();

  @override
  Widget build(BuildContext context) {
    return GalaxyNovelShelf(
      itemWidth: 124,
      padding: EdgeInsets.zero,
      children: const [
        GalaxyNovelCard(
          novel: GalaxyNovelCardData(
            title: 'حارس النجوم',
            badge: '126',
            metadata: 'مستمرة • خيال',
          ),
          style: GalaxyNovelCardStyle(
            variant: GalaxyNovelCardVariant.cinematicPoster,
          ),
        ),
        GalaxyNovelCard(
          novel: GalaxyNovelCardData(
            title: 'بوابة الشمال',
            badge: 'مكتملة',
            metadata: '88 فصلًا',
          ),
          style: GalaxyNovelCardStyle(
            variant: GalaxyNovelCardVariant.editorialPoster,
            coverPresentation: GalaxyCoverPresentation.tonalFrame,
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const SizedBox(height: GalaxyMetrics.space12),
        const GalaxySearchField(hintText: 'ابحث عن رواية', onChanged: _ignore),
        const SizedBox(height: GalaxyMetrics.space12),
        Wrap(
          spacing: GalaxyMetrics.space8,
          runSpacing: GalaxyMetrics.space8,
          children: [
            GalaxyButton(label: 'متابعة القراءة', onPressed: _ignoreTap),
            GalaxyButton(
              label: 'الثانوية',
              variant: GalaxyActionVariant.secondary,
              onPressed: _ignoreTap,
            ),
            GalaxyIconAction(
              icon: Icons.favorite_border_rounded,
              tooltip: 'المفضلة',
              onPressed: _ignoreTap,
            ),
            const GalaxyBadge(label: 'VIP', tone: GalaxyBadgeTone.warning),
          ],
        ),
      ],
    );
  }
}

class _Chapters extends StatelessWidget {
  const _Chapters();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        GalaxyChapterRow(
          chapter: GalaxyChapterRowData(
            title: 'الفصل 12',
            subtitle: 'تم التنزيل',
            leadingLabel: '12',
            state: GalaxyChapterState.downloaded,
          ),
          emphasized: true,
          showAction: false,
          showNavigationIndicator: true,
        ),
        SizedBox(height: GalaxyMetrics.space8),
        GalaxyChapterRow(
          chapter: GalaxyChapterRowData(
            title: 'الفصل 13',
            state: GalaxyChapterState.vipLocked,
          ),
        ),
      ],
    );
  }
}

class _States extends StatelessWidget {
  const _States({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        GalaxyAsyncState.empty(
          title: 'لا توجد روايات',
          message: 'ستظهر النتائج هنا.',
        ),
        SizedBox(height: GalaxyMetrics.space8),
        GalaxyAsyncState.error(
          title: 'تعذر التحميل',
          message: 'تحقق من الاتصال.',
        ),
      ],
    );
  }
}

class _DetailsPreview extends StatelessWidget {
  const _DetailsPreview();

  @override
  Widget build(BuildContext context) {
    return GalaxyNovelDetailsHeader(
      variant: GalaxyNovelDetailsHeaderVariant.centeredPoster,
      title: 'حارس المجرة',
      subtitle: 'Galaxy Keeper',
      cover: const ColoredBox(
        color: Colors.blueGrey,
        child: SizedBox(width: 148, height: 222),
      ),
      badges: const [GalaxyBadge(label: 'مستمرة')],
      content: const GalaxyStatsRail(
        items: [
          GalaxyStatItem(
            icon: Icons.star_rounded,
            value: '8.7',
            label: 'التقييم',
          ),
          GalaxyStatItem(
            icon: Icons.menu_book_outlined,
            value: '342',
            label: 'الفصول',
          ),
        ],
      ),
    );
  }
}

void _ignore(String _) {}

void _ignoreBool(bool _) {}

void _ignoreTap() {}

ThemeData _themeFor(AppThemePreset preset) => switch (preset) {
  AppThemePreset.galaxyNoir => AppTheme.dark(),
  AppThemePreset.cosmicNight => AppTheme.cosmicNightTheme(),
  AppThemePreset.neutralDark => AppTheme.neutralDarkTheme(),
  AppThemePreset.starlightPaper => AppTheme.light(),
  AppThemePreset.lightNature => AppTheme.lightNatureTheme(),
  AppThemePreset.oceanAsh => AppTheme.oceanAshTheme(),
  AppThemePreset.moonForest => AppTheme.moonForestTheme(),
  AppThemePreset.garnetVelvet => AppTheme.garnetVelvetTheme(),
  AppThemePreset.copperDusk => AppTheme.copperDuskTheme(),
  AppThemePreset.midnightTide => AppTheme.midnightTideTheme(),
};
