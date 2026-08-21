import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/analytics/app_screen_names.dart';
import '../../../data/models/catalog_data.dart';
import '../application/library_customization_draft_controller.dart';
import '../application/library_customization_repository.dart';
import '../domain/catalog_query.dart';
import '../domain/library_customization.dart';
import 'catalog_screen.dart';
import 'library_customization_metrics.dart';
import 'widgets/catalog_novel_tile.dart';

class LibraryCustomizationScreen extends StatefulWidget {
  const LibraryCustomizationScreen({required this.repository, super.key});

  final LibraryCustomizationRepository repository;

  @override
  State<LibraryCustomizationScreen> createState() =>
      _LibraryCustomizationScreenState();
}

class _LibraryCustomizationScreenState
    extends State<LibraryCustomizationScreen> {
  late final LibraryCustomizationDraftController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LibraryCustomizationDraftController(
      repository: widget.repository,
    );
  }

  @override
  void dispose() {
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
            if (!didPop) _handleExit();
          },
          child: Scaffold(
            key: const ValueKey('library-customization-screen'),
            appBar: AppBar(
              title: const Text('تخصيص المكتبة'),
              actions: [
                IconButton(
                  key: const ValueKey('library-customization-undo'),
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
              onReset: _confirmReset,
            ),
            body: SafeArea(
              bottom: false,
              child: ListView(
                key: const ValueKey('library-customization-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'رتّب تجربة تصفحك',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'اختر شكلًا جاهزًا أو اضبط البطاقات وسلوك المكتبة بالتفصيل.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _PreviewCard(
                            customization: customization,
                            onOpen: _openFullPreview,
                          ),
                          const SizedBox(height: 20),
                          _PresetSection(
                            customization: customization,
                            onSelected: _controller.applyPreset,
                          ),
                          const SizedBox(height: 16),
                          _CustomizationSection(
                            title: 'طريقة العرض',
                            icon: Icons.view_quilt_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ChoiceGroup<LibraryLayout>(
                                  value: customization.layout,
                                  values: LibraryLayout.values,
                                  label: _layoutLabel,
                                  onChanged: (value) => _replace(
                                    customization.copyWith(layout: value),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  customization.layout == LibraryLayout.grid
                                      ? 'قالب الشبكة'
                                      : 'قالب القائمة',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                if (customization.layout == LibraryLayout.grid)
                                  _ChoiceGroup<LibraryGridTemplate>(
                                    value: customization.gridTemplate,
                                    values: LibraryGridTemplate.values,
                                    label: _gridTemplateLabel,
                                    onChanged: (value) => _replace(
                                      customization.copyWith(
                                        gridTemplate: value,
                                      ),
                                    ),
                                  )
                                else
                                  _ChoiceGroup<LibraryListTemplate>(
                                    value: customization.listTemplate,
                                    values: LibraryListTemplate.values,
                                    label: _listTemplateLabel,
                                    onChanged: (value) => _replace(
                                      customization.copyWith(
                                        listTemplate: value,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CustomizationSection(
                            title: 'الحجم والكثافة',
                            icon: Icons.aspect_ratio_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SettingLabel(text: 'حجم البطاقة'),
                                const SizedBox(height: 8),
                                _ChoiceGroup<LibraryCardSize>(
                                  value: customization.cardSize,
                                  values: LibraryCardSize.values,
                                  label: _cardSizeLabel,
                                  onChanged: (value) => _replace(
                                    customization.copyWith(cardSize: value),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _SettingLabel(text: 'مسافات الشاشة'),
                                const SizedBox(height: 8),
                                _ChoiceGroup<LibraryDensity>(
                                  value: customization.density,
                                  values: LibraryDensity.values,
                                  label: _densityLabel,
                                  onChanged: (value) => _replace(
                                    customization.copyWith(density: value),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CustomizationSection(
                            title: 'معلومات البطاقة',
                            icon: Icons.notes_rounded,
                            child: Column(
                              children: [
                                for (final field in LibraryCardField.values)
                                  SwitchListTile.adaptive(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(_fieldLabel(field)),
                                    value: customization.shows(field),
                                    onChanged: (visible) =>
                                        _setField(field, visible),
                                  ),
                                const _RequiredFieldsNotice(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CustomizationSection(
                            title: 'مظهر البطاقات',
                            icon: Icons.palette_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SettingLabel(text: 'عرض الغلاف'),
                                const SizedBox(height: 8),
                                _ChoiceGroup<LibraryCoverPresentation>(
                                  value: customization.coverPresentation,
                                  values: LibraryCoverPresentation.values,
                                  label: _coverPresentationLabel,
                                  onChanged: (value) => _replace(
                                    customization.copyWith(
                                      coverPresentation: value,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const _SettingLabel(text: 'سطح البطاقة'),
                                const SizedBox(height: 8),
                                _ChoiceGroup<LibraryCardSurface>(
                                  value: customization.cardSurface,
                                  values: LibraryCardSurface.values,
                                  label: _surfaceLabel,
                                  onChanged: (value) => _replace(
                                    customization.copyWith(cardSurface: value),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const _SettingLabel(text: 'الزوايا'),
                                const SizedBox(height: 8),
                                _ChoiceGroup<LibraryCardCorner>(
                                  value: customization.cardCorner,
                                  values: LibraryCardCorner.values,
                                  label: _cornerLabel,
                                  onChanged: (value) => _replace(
                                    customization.copyWith(cardCorner: value),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CustomizationSection(
                            title: 'سلوك المكتبة',
                            icon: Icons.tune_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DropdownButtonFormField<CatalogSort>(
                                  key: ValueKey(
                                    'library-customization-default-sort-${customization.defaultSort.name}',
                                  ),
                                  initialValue: customization.defaultSort,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'الترتيب عند الفتح',
                                  ),
                                  items: [
                                    for (final sort in CatalogSort.values)
                                      DropdownMenuItem(
                                        value: sort,
                                        child: Text(sort.label),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _replace(
                                        customization.copyWith(
                                          defaultSort: value,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('تذكّر آخر عرض وترتيب'),
                                  subtitle: const Text(
                                    'لا يشمل نص البحث أو الفلاتر',
                                  ),
                                  value: customization.rememberViewAndSort,
                                  onChanged: (value) => _replace(
                                    customization.copyWith(
                                      rememberViewAndSort: value,
                                    ),
                                  ),
                                ),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('تثبيت البحث المصغّر'),
                                  subtitle: const Text(
                                    'يبقى البحث متاحًا أثناء التمرير',
                                  ),
                                  value: customization.pinCompactSearch,
                                  onChanged: (value) => _replace(
                                    customization.copyWith(
                                      pinCompactSearch: value,
                                    ),
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
          ),
        );
      },
    );
  }

  void _replace(LibraryCustomization customization) {
    _controller.replaceDraft(customization);
  }

  void _setField(LibraryCardField field, bool visible) {
    final fields = _controller.draft.visibleFields.toSet();
    visible ? fields.add(field) : fields.remove(field);
    _replace(_controller.draft.copyWith(visibleFields: fields));
  }

  Future<void> _openFullPreview() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: AppScreenNames.libraryCustomization,
        ),
        builder: (_) => LibraryCustomizationFullPreviewScreen(
          customization: _controller.draft,
        ),
      ),
    );
  }

  Future<void> _apply() async {
    try {
      await _controller.apply();
    } on Exception {
      if (mounted) _showSaveError();
      return;
    }
    if (!mounted) return;
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('تم تطبيق تخصيص المكتبة'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'عرض المكتبة',
            onPressed: () => _openActualLibrary(navigator),
          ),
        ),
      );
  }

  void _openActualLibrary(NavigatorState navigator) {
    if (!navigator.mounted) return;
    navigator.push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.library),
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('المكتبة')),
          body: const CatalogScreen(),
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة الشكل الافتراضي؟'),
        content: const Text('سيعود التخصيص إلى النمط المتوازن داخل المسودة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
    if (confirmed == true) _controller.reset();
  }

  Future<void> _handleExit() async {
    final action = await showDialog<_ExitAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لديك تغييرات غير مطبقة'),
        content: const Text('هل تريد تطبيق التغييرات قبل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _ExitAction.continueEdit),
            child: const Text('متابعة التعديل'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ExitAction.discard),
            child: const Text('تجاهل'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _ExitAction.applyAndExit),
            child: const Text('تطبيق والخروج'),
          ),
        ],
      ),
    );
    if (!mounted || action == null || action == _ExitAction.continueEdit) {
      return;
    }
    if (action == _ExitAction.discard) {
      _controller.discard();
      Navigator.of(context).pop();
      return;
    }
    try {
      await _controller.apply();
    } on Exception {
      if (mounted) _showSaveError();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _showSaveError() {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ تخصيص المكتبة. حاول مرة أخرى.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

enum _ExitAction { applyAndExit, discard, continueEdit }

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
    final useColumn = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final applyButton = FilledButton.icon(
      key: const ValueKey('library-customization-apply'),
      onPressed: canApply && !isSaving ? onApply : null,
      icon: isSaving
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check_rounded),
      label: const Text('تطبيق'),
    );
    final resetButton = OutlinedButton(
      key: const ValueKey('library-customization-reset'),
      onPressed: isSaving ? null : onReset,
      child: const Text('استعادة الافتراضي'),
    );
    return SafeArea(
      top: false,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: useColumn
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    applyButton,
                    const SizedBox(height: 8),
                    resetButton,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: applyButton),
                    const SizedBox(width: 10),
                    resetButton,
                  ],
                ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.customization, required this.onOpen});

  final LibraryCustomization customization;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (MediaQuery.textScalerOf(context).scale(1) >= 1.6)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'معاينة المكتبة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_full_rounded, size: 18),
                      label: const Text('معاينة كاملة'),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'معاينة المكتبة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_full_rounded, size: 18),
                    label: const Text('معاينة كاملة'),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: customization.layout == LibraryLayout.grid ? 250 : 220,
              child: LibraryCustomizationPreview(customization: customization),
            ),
          ],
        ),
      ),
    );
  }
}

class LibraryCustomizationPreview extends StatelessWidget {
  const LibraryCustomizationPreview({
    required this.customization,
    this.full = false,
    super.key,
  });

  final LibraryCustomization customization;
  final bool full;

  @override
  Widget build(BuildContext context) {
    if (customization.layout == LibraryLayout.list) {
      return ListView.separated(
        physics: full ? null : const NeverScrollableScrollPhysics(),
        itemCount: full ? _previewNovels.length : 2,
        separatorBuilder: (_, _) =>
            SizedBox(height: libraryCardSpacing(customization.density)),
        itemBuilder: (context, index) => CatalogNovelTile(
          novel: _previewNovels[index],
          customization: customization,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = libraryCardSpacing(customization.density);
        final columns = full
            ? _previewColumnCount(constraints.maxWidth, customization, spacing)
            : 2;
        final width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        return GridView.builder(
          physics: full ? null : const NeverScrollableScrollPhysics(),
          itemCount: full ? _previewNovels.length : 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: librarySectionSpacing(customization.density),
            mainAxisExtent: libraryGridTileExtent(
              width,
              customization,
              MediaQuery.textScalerOf(context).scale(1),
            ),
          ),
          itemBuilder: (context, index) => CatalogNovelTile(
            novel: _previewNovels[index],
            customization: customization,
          ),
        );
      },
    );
  }
}

class LibraryCustomizationFullPreviewScreen extends StatelessWidget {
  const LibraryCustomizationFullPreviewScreen({
    required this.customization,
    super.key,
  });

  final LibraryCustomization customization;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معاينة المكتبة')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(
                libraryOuterPadding(customization.density),
              ),
              child: const TextField(
                enabled: false,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'ابحث عن رواية...',
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: libraryOuterPadding(customization.density),
                ),
                child: LibraryCustomizationPreview(
                  customization: customization,
                  full: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetSection extends StatelessWidget {
  const _PresetSection({required this.customization, required this.onSelected});

  final LibraryCustomization customization;
  final ValueChanged<LibraryCustomizationPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'أنماط جاهزة',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final preset in LibraryCustomizationPreset.values) ...[
                _PresetCard(
                  preset: preset,
                  selected:
                      customization == LibraryCustomization.forPreset(preset),
                  onTap: () => onSelected(preset),
                ),
                if (preset != LibraryCustomizationPreset.values.last)
                  const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final LibraryCustomizationPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = LibraryCustomization.forPreset(preset);
    return SizedBox(
      width: 150,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  style.layout == LibraryLayout.grid
                      ? Icons.grid_view_rounded
                      : Icons.view_list_rounded,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  _presetLabel(preset),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_layoutLabel(style.layout)} • ${_cardSizeLabel(style.cardSize)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomizationSection extends StatelessWidget {
  const _CustomizationSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  final T value;
  final List<T> values;
  final String Function(T value) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in values)
          ChoiceChip(
            label: Text(label(option)),
            selected: option == value,
            onSelected: (_) => onChanged(option),
          ),
      ],
    );
  }
}

class _SettingLabel extends StatelessWidget {
  const _SettingLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _RequiredFieldsNotice extends StatelessWidget {
  const _RequiredFieldsNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('الغلاف وعنوان الرواية ظاهران دائمًا.')),
        ],
      ),
    );
  }
}

int _previewColumnCount(
  double width,
  LibraryCustomization customization,
  double spacing,
) {
  final fitted =
      ((width + spacing) /
              (libraryMinimumCardWidth(customization.cardSize) + spacing))
          .floor();
  return fitted.clamp(2, libraryMaximumColumns(customization.cardSize)).toInt();
}

String _presetLabel(LibraryCustomizationPreset preset) => switch (preset) {
  LibraryCustomizationPreset.balanced => 'متوازن',
  LibraryCustomizationPreset.quick => 'سريع',
  LibraryCustomizationPreset.visual => 'بصري',
};

String _layoutLabel(LibraryLayout value) => switch (value) {
  LibraryLayout.grid => 'شبكة',
  LibraryLayout.list => 'قائمة',
};

String _gridTemplateLabel(LibraryGridTemplate value) => switch (value) {
  LibraryGridTemplate.calmPoster => 'بوستر هادئ',
  LibraryGridTemplate.coverOnly => 'غلاف فقط',
};

String _listTemplateLabel(LibraryListTemplate value) => switch (value) {
  LibraryListTemplate.detailed => 'تفصيلي',
  LibraryListTemplate.compact => 'مختصر',
};

String _cardSizeLabel(LibraryCardSize value) => switch (value) {
  LibraryCardSize.small => 'صغير',
  LibraryCardSize.medium => 'متوسط',
  LibraryCardSize.large => 'كبير',
};

String _densityLabel(LibraryDensity value) => switch (value) {
  LibraryDensity.compact => 'مضغوط',
  LibraryDensity.balanced => 'متوازن',
  LibraryDensity.comfortable => 'مريح',
};

String _coverPresentationLabel(LibraryCoverPresentation value) =>
    switch (value) {
      LibraryCoverPresentation.fill => 'ملء',
      LibraryCoverPresentation.fit => 'الغلاف كاملًا',
      LibraryCoverPresentation.tonalFrame => 'إطار لوني',
    };

String _surfaceLabel(LibraryCardSurface value) => switch (value) {
  LibraryCardSurface.flat => 'مسطح',
  LibraryCardSurface.outlined => 'محدد',
  LibraryCardSurface.elevated => 'بارز',
};

String _cornerLabel(LibraryCardCorner value) => switch (value) {
  LibraryCardCorner.soft => 'ناعمة',
  LibraryCardCorner.medium => 'متوسطة',
  LibraryCardCorner.almostSquare => 'شبه مستقيمة',
};

String _fieldLabel(LibraryCardField field) => switch (field) {
  LibraryCardField.status => 'حالة الرواية',
  LibraryCardField.chapters => 'عدد الفصول',
  LibraryCardField.rating => 'التقييم',
  LibraryCardField.firstGenre => 'أول تصنيف',
};

const _previewNovels = [
  CatalogNovel(
    id: 9101,
    title: 'أسرار المجرة البعيدة',
    originalTitle: '',
    url: '',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: 'ongoing',
    statusLabel: 'مستمرة',
    genres: [CatalogGenre(id: 1, name: 'خيال', slug: 'fantasy')],
    chaptersCount: 128,
    ratingAverage: 4.7,
    ratingCount: 240,
    views: 42000,
    updatedAt: null,
    manifest: '',
  ),
  CatalogNovel(
    id: 9102,
    title: 'سيد القمر الأخير',
    originalTitle: '',
    url: '',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: 'completed',
    statusLabel: 'مكتملة',
    genres: [CatalogGenre(id: 2, name: 'أكشن', slug: 'action')],
    chaptersCount: 76,
    ratingAverage: 4.4,
    ratingCount: 180,
    views: 31000,
    updatedAt: null,
    manifest: '',
  ),
  CatalogNovel(
    id: 9103,
    title: 'بوابة العوالم',
    originalTitle: '',
    url: '',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: 'ongoing',
    statusLabel: 'مستمرة',
    genres: [CatalogGenre(id: 3, name: 'مغامرة', slug: 'adventure')],
    chaptersCount: 205,
    ratingAverage: 4.8,
    ratingCount: 510,
    views: 97000,
    updatedAt: null,
    manifest: '',
  ),
  CatalogNovel(
    id: 9104,
    title: 'مدينة بلا شمس',
    originalTitle: '',
    url: '',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: 'ongoing',
    statusLabel: 'مستمرة',
    genres: [CatalogGenre(id: 4, name: 'غموض', slug: 'mystery')],
    chaptersCount: 54,
    ratingAverage: 4.2,
    ratingCount: 90,
    views: 12000,
    updatedAt: null,
    manifest: '',
  ),
  CatalogNovel(
    id: 9105,
    title: 'وريث العرش المنسي',
    originalTitle: '',
    url: '',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: 'completed',
    statusLabel: 'مكتملة',
    genres: [CatalogGenre(id: 5, name: 'دراما', slug: 'drama')],
    chaptersCount: 112,
    ratingAverage: 4.6,
    ratingCount: 330,
    views: 63000,
    updatedAt: null,
    manifest: '',
  ),
  CatalogNovel(
    id: 9106,
    title: 'طريق الساحر',
    originalTitle: '',
    url: '',
    coverThumbnail: '',
    coverMedium: '',
    statusKey: 'ongoing',
    statusLabel: 'مستمرة',
    genres: [CatalogGenre(id: 6, name: 'سحر', slug: 'magic')],
    chaptersCount: 89,
    ratingAverage: 4.3,
    ratingCount: 150,
    views: 28000,
    updatedAt: null,
    manifest: '',
  ),
];
