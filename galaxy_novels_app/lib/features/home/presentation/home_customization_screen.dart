import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/analytics/app_screen_names.dart';
import '../application/home_customization_draft_controller.dart';
import '../application/home_customization_repository.dart';
import '../domain/home_customization.dart';
import 'home_customization_editors.dart';
import 'home_customization_full_preview_screen.dart';
import 'home_customization_labels.dart';
import 'home_customization_preview.dart';
import 'home_section_card_preview.dart';

class HomeCustomizationScreen extends StatefulWidget {
  const HomeCustomizationScreen({required this.repository, super.key});

  final HomeCustomizationRepository repository;

  @override
  State<HomeCustomizationScreen> createState() =>
      _HomeCustomizationScreenState();
}

class _HomeCustomizationScreenState extends State<HomeCustomizationScreen> {
  late final HomeCustomizationDraftController _controller;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _resultSnackBar;

  @override
  void initState() {
    super.initState();
    _controller = HomeCustomizationDraftController(
      repository: widget.repository,
    );
  }

  @override
  void dispose() {
    _resultSnackBar?.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final customization = _controller.draft;
        return PopScope(
          canPop: !_controller.isDirty,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _handleExit();
            }
          },
          child: Scaffold(
            key: const ValueKey('home-customization-center'),
            appBar: AppBar(
              title: const Text('تخصيص الرئيسية'),
              actions: [
                IconButton(
                  key: const ValueKey('home-customization-undo'),
                  tooltip: 'تراجع عن آخر تغيير',
                  onPressed: _controller.canUndo ? _controller.undo : null,
                  icon: const Icon(Icons.undo_rounded),
                ),
              ],
            ),
            bottomNavigationBar: _CustomizationActions(
              isSaving: _controller.isSaving,
              canApply: _controller.isDirty,
              onApply: _apply,
              onReset: _confirmResetAll,
            ),
            body: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'صمّم الرئيسية بطريقتك',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ابدأ بنمط جاهز، ثم عدّل ما تحتاجه فقط.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _PreviewSummary(
                            customization: customization,
                            onOpen: _openFullPreview,
                          ),
                          const SizedBox(height: 22),
                          _PresetCarousel(
                            customization: customization,
                            onSelected: _controller.applyPreset,
                          ),
                          const SizedBox(height: 18),
                          _GeneralAppearanceSummary(
                            customization: customization,
                            onOpen: _openGeneralEditor,
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'الأقسام',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          _SectionsSummary(
                            customization: customization,
                            onOpen: _openSectionEditor,
                            onReorder: _reorder,
                            onMove: _moveSection,
                            onVisibilityChanged: _setVisibility,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openGeneralEditor() async {
    await Navigator.of(context).push<void>(
      _customizationRoute<void>(
        builder: (_) => HomeGeneralAppearanceScreen(controller: _controller),
      ),
    );
  }

  Future<void> _openSectionEditor(HomeSectionId section) async {
    await Navigator.of(context).push<void>(
      _customizationRoute<void>(
        builder: (_) => HomeSectionCustomizationScreen(
          controller: _controller,
          section: section,
        ),
      ),
    );
  }

  Future<void> _openFullPreview() async {
    final section = await Navigator.of(context).push<HomeSectionId>(
      _customizationRoute<HomeSectionId>(
        builder: (_) =>
            HomeCustomizationFullPreviewScreen(controller: _controller),
      ),
    );
    if (section != null && mounted) {
      await _openSectionEditor(section);
    }
  }

  PageRoute<T> _customizationRoute<T>({required WidgetBuilder builder}) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return PageRouteBuilder<T>(
      settings: const RouteSettings(name: AppScreenNames.homeCustomization),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    final order = _controller.draft.sectionOrder.toList();
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final moved = order.removeAt(oldIndex);
    order.insert(newIndex, moved);
    _controller.replaceDraft(_controller.draft.copyWith(sectionOrder: order));
    HapticFeedback.selectionClick();
  }

  void _moveSection(HomeSectionId section, int offset) {
    final order = _controller.draft.sectionOrder.toList();
    final from = order.indexOf(section);
    final to = from + offset;
    if (from < 0 || to < 0 || to >= order.length) {
      return;
    }
    order
      ..removeAt(from)
      ..insert(to, section);
    _controller.replaceDraft(_controller.draft.copyWith(sectionOrder: order));
    HapticFeedback.selectionClick();
  }

  void _setVisibility(HomeSectionId section, bool visible) {
    final hidden = _controller.draft.hiddenSections.toSet();
    visible ? hidden.remove(section) : hidden.add(section);
    _controller.replaceDraft(
      _controller.draft.copyWith(hiddenSections: hidden),
    );
  }

  Future<void> _apply() async {
    try {
      await _controller.apply();
    } on Exception {
      if (mounted) {
        _showSaveError();
      }
      return;
    }
    if (!mounted) {
      return;
    }
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    _resultSnackBar = messenger.showSnackBar(
      SnackBar(
        content: const Text('تم تطبيق تخصيص الرئيسية'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'معاينة النتيجة',
          onPressed: _openFullPreview,
        ),
      ),
    );
  }

  void _showSaveError() {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('تعذر حفظ تخصيص الرئيسية'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: 'إعادة المحاولة', onPressed: _apply),
        ),
      );
  }

  Future<void> _confirmResetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استعادة الإعدادات الافتراضية؟'),
        content: const Text('سيعود ترتيب الأقسام وشكلها إلى الوضع المتوازن.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _controller.replaceDraft(HomeCustomization.defaults);
    }
  }

  Future<void> _handleExit() async {
    final action = await showDialog<_ExitAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('لديك تعديلات غير مطبقة'),
        content: const Text('هل تريد تطبيق التغييرات قبل مغادرة الصفحة؟'),
        actions: [
          TextButton(
            key: const ValueKey('unsaved-continue'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('متابعة التعديل'),
          ),
          TextButton(
            key: const ValueKey('unsaved-discard'),
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ExitAction.discard),
            child: const Text('تجاهل'),
          ),
          FilledButton(
            key: const ValueKey('unsaved-apply-exit'),
            onPressed: () => Navigator.of(dialogContext).pop(_ExitAction.apply),
            child: const Text('تطبيق والخروج'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    switch (action) {
      case _ExitAction.discard:
        _controller.discard();
        Navigator.of(context).pop();
        return;
      case _ExitAction.apply:
        try {
          await _controller.apply();
        } on Exception {
          if (mounted) {
            _showSaveError();
          }
          return;
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      case null:
        return;
    }
  }
}

enum _ExitAction { apply, discard }

class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({required this.customization, required this.onOpen});

  final HomeCustomization customization;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeCustomizationPreview(customization: customization),
          const Divider(height: 1),
          TextButton.icon(
            key: const ValueKey('home-customization-full-preview'),
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_full_rounded),
            label: const Text('معاينة كاملة'),
          ),
        ],
      ),
    );
  }
}

class _PresetCarousel extends StatelessWidget {
  const _PresetCarousel({
    required this.customization,
    required this.onSelected,
  });

  final HomeCustomization customization;
  final ValueChanged<HomeCustomizationPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'أنماط جاهزة',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: _presetRailHeight(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: HomeCustomizationPreset.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final preset = HomeCustomizationPreset.values[index];
              final selected =
                  customization == customization.applyPreset(preset);
              return SizedBox(
                width: 190,
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    key: ValueKey('home-preset-${preset.name}'),
                    onTap: () => onSelected(preset),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_presetIcon(preset)),
                              const Spacer(),
                              if (selected)
                                const Icon(Icons.check_circle_rounded),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            homePresetTitle(preset),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            homePresetDescription(preset),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  double _presetRailHeight(BuildContext context) {
    final scaledBody = MediaQuery.textScalerOf(context).scale(14);
    return 136 + (scaledBody - 14).clamp(0, 16) * 5;
  }
}

class _GeneralAppearanceSummary extends StatelessWidget {
  const _GeneralAppearanceSummary({
    required this.customization,
    required this.onOpen,
  });

  final HomeCustomization customization;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('open-home-general-editor'),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 48,
                child: Icon(Icons.palette_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المظهر العام',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${homeDensityTitle(customization.density)} • '
                      '${homeCardSurfaceTitle(customization.cardSurface)} • '
                      '${homeProgressStyleTitle(customization.progressStyle)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionsSummary extends StatelessWidget {
  const _SectionsSummary({
    required this.customization,
    required this.onOpen,
    required this.onReorder,
    required this.onMove,
    required this.onVisibilityChanged,
  });

  final HomeCustomization customization;
  final ValueChanged<HomeSectionId> onOpen;
  final ReorderCallback onReorder;
  final void Function(HomeSectionId section, int offset) onMove;
  final void Function(HomeSectionId section, bool visible) onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final visibleCount = customization.sectionOrder
        .where(customization.isVisible)
        .length;
    return ReorderableListView.builder(
      key: const ValueKey('home-sections-reorderable-list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: customization.sectionOrder.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final section = customization.sectionOrder[index];
        final visible = customization.isVisible(section);
        final isLastVisible = visible && visibleCount == 1;
        return Padding(
          key: ValueKey('home-section-summary-${section.name}'),
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  key: ValueKey('open-home-section-editor-${section.name}'),
                  onTap: () => onOpen(section),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                homeSectionTitle(section),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (customization.newSections.contains(section))
                              const Badge(label: Text('جديد')),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_left_rounded),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: visible ? 1 : 0.45,
                          child: HomeSectionCardPreview(
                            section: section,
                            customization: customization,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${homeTemplateSummary(section, customization)} • '
                          '${homeCardSizeTitle(customization.cardSizeFor(section))} • '
                          '${homeItemCountTitle(customization.itemCounts[section] ?? HomeItemCount.medium)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
                  child: _SectionControls(
                    index: index,
                    section: section,
                    itemCount: customization.sectionOrder.length,
                    visible: visible,
                    isLastVisible: isLastVisible,
                    onMove: onMove,
                    onVisibilityChanged: onVisibilityChanged,
                  ),
                ),
                if (isLastVisible)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      0,
                      16,
                      12,
                    ),
                    child: Text(
                      'يجب إبقاء قسم واحد على الأقل ظاهرًا.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _SectionControls extends StatelessWidget {
  const _SectionControls({
    required this.index,
    required this.section,
    required this.itemCount,
    required this.visible,
    required this.isLastVisible,
    required this.onMove,
    required this.onVisibilityChanged,
  });

  final int index;
  final HomeSectionId section;
  final int itemCount;
  final bool visible;
  final bool isLastVisible;
  final void Function(HomeSectionId section, int offset) onMove;
  final void Function(HomeSectionId section, bool visible) onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final movement = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReorderableDragStartListener(
          index: index,
          child: const Tooltip(
            message: 'اسحب لإعادة الترتيب',
            child: SizedBox.square(
              dimension: 48,
              child: Icon(Icons.drag_indicator_rounded),
            ),
          ),
        ),
        IconButton(
          key: ValueKey('home-move-up-${section.name}'),
          tooltip: 'تحريك لأعلى',
          onPressed: index == 0 ? null : () => onMove(section, -1),
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
        ),
        IconButton(
          key: ValueKey('home-move-down-${section.name}'),
          tooltip: 'تحريك لأسفل',
          onPressed: index == itemCount - 1 ? null : () => onMove(section, 1),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
      ],
    );
    final visibility = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(visible ? 'ظاهر' : 'مخفي')),
        Switch(
          key: ValueKey('home-section-visibility-${section.name}'),
          value: visible,
          onChanged: isLastVisible
              ? null
              : (value) => onVisibilityChanged(section, value),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 380 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: movement,
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: visibility,
              ),
            ],
          );
        }
        return Row(children: [movement, const Spacer(), visibility]);
      },
    );
  }
}

class _CustomizationActions extends StatelessWidget {
  const _CustomizationActions({
    required this.isSaving,
    required this.canApply,
    required this.onApply,
    required this.onReset,
  });

  final bool isSaving;
  final bool canApply;
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stack =
                constraints.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            final apply = FilledButton.icon(
              key: const ValueKey('apply-home-customization'),
              onPressed: isSaving || !canApply ? null : onApply,
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('تطبيق'),
            );
            final reset = OutlinedButton(
              key: const ValueKey('reset-home-customization'),
              onPressed: isSaving ? null : onReset,
              child: const Text('استعادة الافتراضي'),
            );
            if (stack) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [apply, const SizedBox(height: 8), reset],
              );
            }
            return Row(
              children: [
                Expanded(child: apply),
                const SizedBox(width: 10),
                reset,
              ],
            );
          },
        ),
      ),
    );
  }
}

IconData _presetIcon(HomeCustomizationPreset preset) => switch (preset) {
  HomeCustomizationPreset.balanced => Icons.balance_rounded,
  HomeCustomizationPreset.quick => Icons.bolt_rounded,
  HomeCustomizationPreset.visual => Icons.auto_awesome_rounded,
};
