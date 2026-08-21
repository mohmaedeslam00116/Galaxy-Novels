import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_dependencies.dart';
import '../application/home_customization_draft_controller.dart';
import '../domain/home_customization.dart';
import 'home_card_appearance.dart';
import 'home_customization_labels.dart';
import 'home_customization_preview.dart';
import 'home_poster_card.dart';
import 'home_section_card_preview.dart';

class HomeGeneralAppearanceScreen extends StatelessWidget {
  const HomeGeneralAppearanceScreen({required this.controller, super.key});

  final HomeCustomizationDraftController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final customization = controller.draft;
        return Scaffold(
          appBar: _EditorAppBar(title: 'المظهر العام', controller: controller),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeCustomizationPreview(customization: customization),
                        const SizedBox(height: 20),
                        _SettingsPanel(
                          title: 'شكل الرئيسية',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ChoiceWrap<HomeDensity>(
                                label: 'الكثافة',
                                values: HomeDensity.values,
                                selected: customization.density,
                                titleFor: homeDensityTitle,
                                onSelected: (value) => controller.replaceDraft(
                                  customization.copyWith(density: value),
                                ),
                              ),
                              _gap,
                              _ChoiceWrap<HomeHeaderStyle>(
                                label: 'عناوين الأقسام',
                                values: HomeHeaderStyle.values,
                                selected: customization.headerStyle,
                                titleFor: homeHeaderStyleTitle,
                                onSelected: (value) => controller.replaceDraft(
                                  customization.copyWith(headerStyle: value),
                                ),
                              ),
                              _gap,
                              _ChoiceWrap<HomeCoverCorner>(
                                label: 'زوايا الأغلفة',
                                values: HomeCoverCorner.values,
                                selected: customization.coverCorner,
                                titleFor: homeCoverCornerTitle,
                                keyFor: (value) =>
                                    ValueKey('home-cover-corner-${value.name}'),
                                onSelected: (value) => controller.replaceDraft(
                                  customization.copyWith(coverCorner: value),
                                ),
                              ),
                              _gap,
                              _ChoiceWrap<HomeCardSurface>(
                                label: 'سطح الكروت',
                                values: HomeCardSurface.values,
                                selected: customization.cardSurface,
                                titleFor: homeCardSurfaceTitle,
                                keyFor: (value) =>
                                    ValueKey('home-card-surface-${value.name}'),
                                onSelected: (value) => controller.replaceDraft(
                                  customization.copyWith(cardSurface: value),
                                ),
                              ),
                              _gap,
                              _ChoiceWrap<HomeCardTint>(
                                label: 'صبغة الثيم',
                                values: HomeCardTint.values,
                                selected: customization.cardTint,
                                titleFor: homeCardTintTitle,
                                keyFor: (value) =>
                                    ValueKey('home-card-tint-${value.name}'),
                                onSelected: (value) => controller.replaceDraft(
                                  customization.copyWith(cardTint: value),
                                ),
                              ),
                              _gap,
                              _ChoiceWrap<HomeProgressStyle>(
                                label: 'تقدم القراءة',
                                values: HomeProgressStyle.values,
                                selected: customization.progressStyle,
                                titleFor: homeProgressStyleTitle,
                                keyFor: (value) => ValueKey(
                                  'home-progress-style-${value.name}',
                                ),
                                onSelected: (value) => controller.replaceDraft(
                                  customization.copyWith(progressStyle: value),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomeSectionCustomizationScreen extends StatefulWidget {
  const HomeSectionCustomizationScreen({
    required this.controller,
    required this.section,
    super.key,
  });

  final HomeCustomizationDraftController controller;
  final HomeSectionId section;

  @override
  State<HomeSectionCustomizationScreen> createState() =>
      _HomeSectionCustomizationScreenState();
}

class _HomeSectionCustomizationScreenState
    extends State<HomeSectionCustomizationScreen> {
  bool _advancedExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final customization = widget.controller.draft;
        return Scaffold(
          appBar: _EditorAppBar(
            title: homeSectionTitle(widget.section),
            controller: widget.controller,
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  primary: false,
                  automaticallyImplyLeading: false,
                  pinned: true,
                  toolbarHeight: 68,
                  expandedHeight: _previewHeight(context, customization),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final expanded = constraints.maxHeight > 110;
                      if (!expanded) {
                        return _CollapsedPreview(section: widget.section);
                      }
                      return Padding(
                        key: const ValueKey(
                          'home-section-editor-preview-expanded',
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: HomeSectionCardPreview(
                          section: widget.section,
                          customization: customization,
                        ),
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SettingsPanel(
                              title: 'الخيارات الأساسية',
                              child: _BasicSectionOptions(
                                section: widget.section,
                                customization: customization,
                                onChanged: widget.controller.replaceDraft,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Card(
                              margin: EdgeInsets.zero,
                              child: ExpansionTile(
                                key: const ValueKey('home-advanced-toggle'),
                                initiallyExpanded: _advancedExpanded,
                                onExpansionChanged: (value) {
                                  setState(() => _advancedExpanded = value);
                                },
                                title: const Text('خيارات متقدمة'),
                                subtitle: const Text(
                                  'المعلومات الظاهرة، الإجراء السريع، والحاوية',
                                ),
                                childrenPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                children: [
                                  _AdvancedSectionOptions(
                                    section: widget.section,
                                    customization: customization,
                                    onChanged: widget.controller.replaceDraft,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              key: ValueKey(
                                'reset-home-section-${widget.section.name}',
                              ),
                              onPressed: () {
                                widget.controller.resetSection(widget.section);
                                HapticFeedback.selectionClick();
                              },
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: const Text('إعادة إعدادات القسم'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _previewHeight(BuildContext context, HomeCustomization customization) {
    final section = widget.section;
    final size = customization.cardSizeFor(section);
    final textGrowth = (MediaQuery.textScalerOf(context).scale(14) - 14)
        .clamp(0, 20)
        .toDouble();
    final contentHeight = switch (section) {
      HomeSectionId.continueReading => 220 * size.scale + textGrowth * 4,
      HomeSectionId.becauseYouRead =>
        customization.recommendedNovelsTemplate ==
                RecommendedNovelCardTemplate.horizontal
            ? 176 * size.scale + textGrowth * 3
            : homePosterExtent(size) + textGrowth * 3,
      HomeSectionId.updatedNovels =>
        customization.updatedNovelsTemplate ==
                UpdatedNovelCardTemplate.horizontal
            ? 176 * size.scale + textGrowth * 3
            : homePosterExtent(size) + textGrowth * 3,
      HomeSectionId.latestUpdates =>
        customization.latestUpdatesTemplate == LatestUpdateCardTemplate.poster
            ? homePosterExtent(size) + textGrowth * 3
            : 160 * size.scale + textGrowth * 6,
    };
    return (contentHeight + 44).clamp(252, 520);
  }
}

class _EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _EditorAppBar({required this.title, required this.controller});

  final String title;
  final HomeCustomizationDraftController controller;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          key: const ValueKey('home-customization-undo'),
          tooltip: 'تراجع عن آخر تغيير',
          onPressed: controller.canUndo ? controller.undo : null,
          icon: const Icon(Icons.undo_rounded),
        ),
        TextButton(
          key: const ValueKey('home-editor-done'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('تم'),
        ),
      ],
    );
  }
}

class _CollapsedPreview extends StatelessWidget {
  const _CollapsedPreview({required this.section});

  final HomeSectionId section;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.visibility_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'معاينة ${homeSectionTitle(section)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicSectionOptions extends StatelessWidget {
  const _BasicSectionOptions({
    required this.section,
    required this.customization,
    required this.onChanged,
  });

  final HomeSectionId section;
  final HomeCustomization customization;
  final ValueChanged<HomeCustomization> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _templateChoices(),
        _gap,
        _ChoiceWrap<HomeCardSize>(
          label: 'حجم البطاقة',
          values: HomeCardSize.values,
          selected: customization.cardSizeFor(section),
          titleFor: homeCardSizeTitle,
          keyFor: (value) =>
              ValueKey('home-card-size-${section.name}-${value.name}'),
          onSelected: _setCardSize,
        ),
        _gap,
        _ChoiceWrap<HomeCoverPresentation>(
          label: 'عرض الغلاف',
          values: HomeCoverPresentation.values,
          selected: customization.coverPresentationFor(section),
          titleFor: homeCoverPresentationTitle,
          keyFor: (value) => ValueKey('home-cover-presentation-${value.name}'),
          onSelected: _setCoverPresentation,
        ),
        if (section != HomeSectionId.continueReading) ...[
          _gap,
          _placementChoices(),
        ],
        _gap,
        _ChoiceWrap<HomeItemCount>(
          label: 'عدد العناصر',
          values: HomeItemCount.values,
          selected: customization.itemCounts[section] ?? HomeItemCount.medium,
          titleFor: homeItemCountTitle,
          onSelected: _setItemCount,
        ),
      ],
    );
  }

  Widget _templateChoices() => switch (section) {
    HomeSectionId.continueReading => _ChoiceWrap<ContinueReadingCardTemplate>(
      label: 'نموذج البطاقة',
      values: ContinueReadingCardTemplate.values,
      selected: customization.continueReadingTemplate,
      titleFor: homeContinueTemplateTitle,
      keyFor: (value) => ValueKey('home-continue-template-${value.name}'),
      onSelected: (value) =>
          onChanged(customization.copyWith(continueReadingTemplate: value)),
    ),
    HomeSectionId.becauseYouRead => _ChoiceWrap<RecommendedNovelCardTemplate>(
      label: 'نموذج البطاقة',
      values: RecommendedNovelCardTemplate.values,
      selected: customization.recommendedNovelsTemplate,
      titleFor: homeRecommendedTemplateTitle,
      keyFor: (value) => ValueKey('home-recommended-template-${value.name}'),
      onSelected: (value) =>
          onChanged(customization.copyWith(recommendedNovelsTemplate: value)),
    ),
    HomeSectionId.updatedNovels => _ChoiceWrap<UpdatedNovelCardTemplate>(
      label: 'نموذج البطاقة',
      values: UpdatedNovelCardTemplate.values,
      selected: customization.updatedNovelsTemplate,
      titleFor: homeUpdatedTemplateTitle,
      keyFor: (value) => ValueKey('home-updated-template-${value.name}'),
      onSelected: (value) =>
          onChanged(customization.copyWith(updatedNovelsTemplate: value)),
    ),
    HomeSectionId.latestUpdates => _ChoiceWrap<LatestUpdateCardTemplate>(
      label: 'نموذج البطاقة',
      values: LatestUpdateCardTemplate.values,
      selected: customization.latestUpdatesTemplate,
      titleFor: homeLatestTemplateTitle,
      keyFor: (value) => ValueKey('home-latest-template-${value.name}'),
      onSelected: (value) =>
          onChanged(customization.copyWith(latestUpdatesTemplate: value)),
    ),
  };

  Widget _placementChoices() => switch (section) {
    HomeSectionId.continueReading => const SizedBox.shrink(),
    HomeSectionId.becauseYouRead => _ChoiceWrap<RecommendedNovelsLayout>(
      label: 'ترتيب البطاقات',
      values: RecommendedNovelsLayout.values,
      selected: customization.recommendedNovelsLayout,
      titleFor: homeRecommendedLayoutTitle,
      onSelected: (value) =>
          onChanged(customization.copyWith(recommendedNovelsLayout: value)),
    ),
    HomeSectionId.updatedNovels => _ChoiceWrap<UpdatedNovelsLayout>(
      label: 'ترتيب البطاقات',
      values: UpdatedNovelsLayout.values,
      selected: customization.updatedNovelsLayout,
      titleFor: homeUpdatedLayoutTitle,
      onSelected: (value) =>
          onChanged(customization.copyWith(updatedNovelsLayout: value)),
    ),
    HomeSectionId.latestUpdates => _ChoiceWrap<LatestUpdatesLayout>(
      label: 'ترتيب البطاقات',
      values: LatestUpdatesLayout.values,
      selected: customization.latestUpdatesLayout,
      titleFor: homeLatestLayoutTitle,
      onSelected: (value) =>
          onChanged(customization.copyWith(latestUpdatesLayout: value)),
    ),
  };

  void _setCardSize(HomeCardSize value) {
    final values = Map<HomeSectionId, HomeCardSize>.of(customization.cardSizes)
      ..[section] = value;
    onChanged(customization.copyWith(cardSizes: values));
  }

  void _setCoverPresentation(HomeCoverPresentation value) {
    final values = Map<HomeSectionId, HomeCoverPresentation>.of(
      customization.coverPresentations,
    )..[section] = value;
    onChanged(customization.copyWith(coverPresentations: values));
  }

  void _setItemCount(HomeItemCount value) {
    final values = Map<HomeSectionId, HomeItemCount>.of(
      customization.itemCounts,
    )..[section] = value;
    onChanged(customization.copyWith(itemCounts: values));
  }
}

class _AdvancedSectionOptions extends StatelessWidget {
  const _AdvancedSectionOptions({
    required this.section,
    required this.customization,
    required this.onChanged,
  });

  final HomeSectionId section;
  final HomeCustomization customization;
  final ValueChanged<HomeCustomization> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'المعلومات الظاهرة',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        for (final field in _fieldsFor(section))
          SwitchListTile(
            key: ValueKey('home-field-${section.name}-${field.name}'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(homeFieldTitle(field)),
            value: customization.showsField(section, field),
            onChanged: (value) => _setField(field, value),
          ),
        if (section == HomeSectionId.continueReading)
          SwitchListTile(
            key: ValueKey('home-quick-action-${section.name}'),
            contentPadding: EdgeInsets.zero,
            title: const Text('زر متابعة القراءة'),
            subtitle: const Text('يظهر فقط عندما يؤدي إلى متابعة الفصل مباشرة'),
            value: customization.showsQuickAction(section),
            onChanged: _setQuickAction,
          ),
        const SizedBox(height: 10),
        _ChoiceWrap<HomeSectionContainer>(
          label: 'حاوية القسم',
          values: HomeSectionContainer.values,
          selected: customization.containerFor(section),
          titleFor: homeSectionContainerTitle,
          keyFor: (value) =>
              ValueKey('home-container-${section.name}-${value.name}'),
          onSelected: _setContainer,
        ),
        if (section == HomeSectionId.becauseYouRead) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            key: const ValueKey('restore-hidden-home-recommendations'),
            onPressed: () => _restoreHiddenRecommendations(context),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('إعادة الروايات المخفية'),
          ),
        ],
      ],
    );
  }

  void _setField(HomeCardField field, bool visible) {
    final fields = {
      for (final entry in customization.optionalFields.entries)
        entry.key: entry.value.toSet(),
    };
    final sectionFields = fields[section] ?? <HomeCardField>{};
    visible ? sectionFields.add(field) : sectionFields.remove(field);
    fields[section] = sectionFields;
    onChanged(customization.copyWith(optionalFields: fields));
  }

  void _setQuickAction(bool value) {
    final values = Map<HomeSectionId, bool>.of(customization.quickActions)
      ..[section] = value;
    onChanged(customization.copyWith(quickActions: values));
  }

  void _setContainer(HomeSectionContainer value) {
    final values = Map<HomeSectionId, HomeSectionContainer>.of(
      customization.sectionContainers,
    )..[section] = value;
    onChanged(customization.copyWith(sectionContainers: values));
  }

  Future<void> _restoreHiddenRecommendations(BuildContext context) async {
    final repository = AppDependencies.of(
      context,
    ).homeRecommendationExclusionRepository;
    if (repository == null) return;
    await repository.clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('أُعيدت الروايات المخفية إلى التوصيات')),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChoiceWrap<T> extends StatelessWidget {
  const _ChoiceWrap({
    required this.label,
    required this.values,
    required this.selected,
    required this.titleFor,
    required this.onSelected,
    this.keyFor,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) titleFor;
  final ValueChanged<T> onSelected;
  final Key Function(T value)? keyFor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                key: keyFor?.call(value),
                label: Text(titleFor(value)),
                selected: value == selected,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}

List<HomeCardField> _fieldsFor(HomeSectionId section) => switch (section) {
  HomeSectionId.continueReading => const [
    HomeCardField.chapter,
    HomeCardField.progress,
  ],
  HomeSectionId.becauseYouRead => const [
    HomeCardField.matchReason,
    HomeCardField.status,
    HomeCardField.chapterCount,
  ],
  HomeSectionId.updatedNovels => const [
    HomeCardField.status,
    HomeCardField.chapterCount,
    HomeCardField.firstGenre,
  ],
  HomeSectionId.latestUpdates => const [
    HomeCardField.status,
    HomeCardField.date,
    HomeCardField.secondChapter,
  ],
};

const _gap = SizedBox(height: 16);
