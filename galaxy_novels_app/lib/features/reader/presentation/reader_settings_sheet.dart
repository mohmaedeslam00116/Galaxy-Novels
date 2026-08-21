import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/analytics/app_screen_names.dart';
import '../application/reader_advanced_terminology_repository.dart';
import '../application/reader_term_replacement_repository.dart';
import '../domain/reader_advanced_terminology.dart';
import '../domain/reader_term_replacement.dart';
import 'reader_advanced_terminology_screen.dart';
import 'reader_font_selector.dart';
import 'reader_preferences.dart';
import 'reader_reading_column.dart';
import 'reader_segmented_control.dart';
import 'reader_terms_settings_panel.dart';

Future<void> showReaderSettingsSheet({
  required BuildContext context,
  required ReaderPreferences preferences,
  required ValueChanged<ReaderPreferences> onChanged,
  List<ReaderTermReplacement> termReplacements = const [],
  ReaderTermReplacementRepository? termRepository,
  ReaderAdvancedTerminologyRepository? advancedTerminologyRepository,
  int novelId = 0,
  ValueChanged<ReaderTermReplacement>? onEditTerm,
  ValueChanged<ReaderTermReplacement>? onDeleteTerm,
}) {
  final mediaQuery = MediaQuery.of(context);
  final tabletLandscape = isReaderTabletLandscape(mediaQuery);
  final safeWidth = math.max(
    0.0,
    mediaQuery.size.width - mediaQuery.padding.horizontal - 48,
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: !tabletLandscape,
    constraints: tabletLandscape
        ? BoxConstraints(maxWidth: math.min(1080, safeWidth))
        : null,
    builder: (context) {
      return ReaderSettingsSheet(
        preferences: preferences,
        onChanged: onChanged,
        termReplacements: termReplacements,
        termRepository: termRepository,
        advancedTerminologyRepository: advancedTerminologyRepository,
        novelId: novelId,
        onEditTerm: onEditTerm,
        onDeleteTerm: onDeleteTerm,
      );
    },
  );
}

class ReaderSettingsSheet extends StatefulWidget {
  const ReaderSettingsSheet({
    required this.preferences,
    required this.onChanged,
    this.termReplacements = const [],
    this.termRepository,
    this.advancedTerminologyRepository,
    this.novelId = 0,
    this.onEditTerm,
    this.onDeleteTerm,
    super.key,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;
  final List<ReaderTermReplacement> termReplacements;
  final ReaderTermReplacementRepository? termRepository;
  final ReaderAdvancedTerminologyRepository? advancedTerminologyRepository;
  final int novelId;
  final ValueChanged<ReaderTermReplacement>? onEditTerm;
  final ValueChanged<ReaderTermReplacement>? onDeleteTerm;

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late ReaderPreferences _preferences;
  late final ScrollController _panelScrollController;
  _ReaderSettingsPanel _panel = _ReaderSettingsPanel.text;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences;
    _panelScrollController = ScrollController();
  }

  @override
  void dispose() {
    _panelScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final repository = widget.termRepository;
    if (repository != null) {
      return ValueListenableBuilder<List<ReaderTermReplacement>>(
        valueListenable: repository,
        builder: (context, replacements, child) {
          return _buildWithAdvanced(mediaQuery, replacements);
        },
      );
    }
    return _buildWithAdvanced(mediaQuery, widget.termReplacements);
  }

  Widget _buildWithAdvanced(
    MediaQueryData mediaQuery,
    List<ReaderTermReplacement> termReplacements,
  ) {
    final repository = widget.advancedTerminologyRepository;
    if (repository == null) {
      return _buildShell(
        mediaQuery,
        termReplacements,
        ReaderAdvancedTerminologyState.defaults,
      );
    }
    return ValueListenableBuilder<ReaderAdvancedTerminologyState>(
      valueListenable: repository,
      builder: (context, state, child) {
        return _buildShell(mediaQuery, termReplacements, state);
      },
    );
  }

  Widget _buildShell(
    MediaQueryData mediaQuery,
    List<ReaderTermReplacement> termReplacements,
    ReaderAdvancedTerminologyState advancedState,
  ) {
    final tabletLandscape = isReaderTabletLandscape(mediaQuery);
    final compactLandscape =
        mediaQuery.orientation == Orientation.landscape && !tabletLandscape;
    final availableHeight = math.max(
      0.0,
      mediaQuery.size.height - mediaQuery.viewInsets.bottom,
    );
    final shellHeight = switch ((tabletLandscape, compactLandscape)) {
      (true, _) => math.min(720.0, availableHeight * 0.94),
      (false, true) => availableHeight * 0.96,
      _ => availableHeight * 0.82,
    };
    final safeWidth = math.max(
      0.0,
      mediaQuery.size.width - mediaQuery.padding.horizontal - 48,
    );
    final shellWidth = tabletLandscape
        ? math.min(1080.0, safeWidth)
        : double.infinity;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: KeyedSubtree(
          key: const ValueKey('reader-settings-sheet'),
          child: SizedBox(
            key: const ValueKey('reader-settings-shell'),
            width: shellWidth,
            height: shellHeight,
            child: tabletLandscape
                ? _buildTabletLandscapeShell(termReplacements, advancedState)
                : _buildStandardShell(
                    termReplacements,
                    advancedState: advancedState,
                    compactLandscape: compactLandscape,
                    bottomInset: mediaQuery.viewInsets.bottom,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLandscapeShell(
    List<ReaderTermReplacement> termReplacements,
    ReaderAdvancedTerminologyState advancedState,
  ) {
    return Column(
      children: [
        _ReaderSettingsHeader(onClose: () => Navigator.maybePop(context)),
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 184,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: _ReaderSettingsSideTabs(
                          selected: _panel,
                          onChanged: _selectPanel,
                        ),
                      ),
                    ),
                    _ReaderSettingsResetBar(
                      enabled: _preferences != ReaderPreferences.defaults,
                      onReset: () => _update(ReaderPreferences.defaults),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Scrollbar(
                  controller: _panelScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    key: const ValueKey('reader-settings-panel-scroll'),
                    controller: _panelScrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: _buildPanel(
                      _preferences,
                      termReplacements,
                      advancedState,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStandardShell(
    List<ReaderTermReplacement> termReplacements, {
    ReaderAdvancedTerminologyState advancedState =
        ReaderAdvancedTerminologyState.defaults,
    required bool compactLandscape,
    required double bottomInset,
  }) {
    return Column(
      children: [
        _ReaderSettingsHeader(
          compact: compactLandscape,
          onClose: () => Navigator.maybePop(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ReaderSettingsSheetTabs(
            key: const ValueKey('reader-settings-tabs'),
            selected: _panel,
            onChanged: _selectPanel,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('reader-settings-panel-scroll'),
            controller: _panelScrollController,
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPanel(_preferences, termReplacements, advancedState),
                if (compactLandscape) ...[
                  const SizedBox(height: 12),
                  _ReaderSettingsResetBar(
                    enabled: _preferences != ReaderPreferences.defaults,
                    onReset: () => _update(ReaderPreferences.defaults),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!compactLandscape)
          _ReaderSettingsResetBar(
            enabled: _preferences != ReaderPreferences.defaults,
            onReset: () => _update(ReaderPreferences.defaults),
          ),
      ],
    );
  }

  void _selectPanel(_ReaderSettingsPanel panel) {
    if (_panel == panel) return;
    setState(() => _panel = panel);
    if (_panelScrollController.hasClients) {
      _panelScrollController.jumpTo(0);
    }
  }

  Widget _buildPanel(
    ReaderPreferences preferences,
    List<ReaderTermReplacement> termReplacements,
    ReaderAdvancedTerminologyState advancedState,
  ) {
    return switch (_panel) {
      _ReaderSettingsPanel.text => _TextSettingsPanel(
        preferences: preferences,
        onChanged: _update,
        layout: _ReaderSettingsLayout.sheet,
      ),
      _ReaderSettingsPanel.colors => _ColorSettingsPanel(
        preferences: preferences,
        onChanged: _update,
      ),
      _ReaderSettingsPanel.screen => _ScreenSettingsPanel(
        preferences: preferences,
        onChanged: _update,
        layout: _ReaderSettingsLayout.sheet,
      ),
      _ReaderSettingsPanel.terms => ReaderTermsSettingsPanel(
        replacements: termReplacements,
        novelId: widget.novelId,
        highlightEnabled: preferences.highlightReplacedTerms,
        onHighlightChanged: (enabled) {
          _update(preferences.copyWith(highlightReplacedTerms: enabled));
        },
        onEdit: widget.onEditTerm,
        onDelete: widget.onDeleteTerm,
        advancedState: advancedState,
        onOpenAdvanced:
            advancedState.accessUnlocked &&
                widget.advancedTerminologyRepository != null
            ? _openAdvancedTerminology
            : null,
      ),
    };
  }

  void _openAdvancedTerminology() {
    final repository = widget.advancedTerminologyRepository;
    if (repository == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.advancedTerminology),
        builder: (_) => ReaderAdvancedTerminologyScreen(repository: repository),
      ),
    );
  }

  void _update(ReaderPreferences preferences) {
    setState(() => _preferences = preferences);
    widget.onChanged(preferences);
  }
}

class _ReaderSettingsHeader extends StatelessWidget {
  const _ReaderSettingsHeader({required this.onClose, this.compact = false});

  final VoidCallback onClose;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('reader-settings-header'),
      padding: EdgeInsets.fromLTRB(16, compact ? 0 : 4, 8, compact ? 4 : 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'إعدادات القراءة',
              style:
                  (compact
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleLarge)
                      ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            key: const ValueKey('reader-settings-close'),
            tooltip: 'إغلاق إعدادات القراءة',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ReaderSettingsSheetTabs extends StatelessWidget {
  const _ReaderSettingsSheetTabs({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final _ReaderSettingsPanel selected;
  final ValueChanged<_ReaderSettingsPanel> onChanged;

  static const List<ReaderSegmentOption<_ReaderSettingsPanel>> _options = [
    (
      value: _ReaderSettingsPanel.text,
      label: 'النص',
      icon: Icons.format_size_rounded,
      key: ValueKey('reader-settings-tab-text'),
    ),
    (
      value: _ReaderSettingsPanel.colors,
      label: 'الألوان',
      icon: Icons.palette_outlined,
      key: ValueKey('reader-settings-tab-colors'),
    ),
    (
      value: _ReaderSettingsPanel.screen,
      label: 'الشاشة',
      icon: Icons.phone_android_rounded,
      key: ValueKey('reader-settings-tab-screen'),
    ),
    (
      value: _ReaderSettingsPanel.terms,
      label: 'المصطلحات',
      icon: Icons.find_replace_rounded,
      key: ValueKey('reader-settings-tab-terms'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ReaderSegmentedControl<_ReaderSettingsPanel>(
      options: _options,
      selected: selected,
      onChanged: onChanged,
    );
  }
}

class _ReaderSettingsSideTabs extends StatelessWidget {
  const _ReaderSettingsSideTabs({
    required this.selected,
    required this.onChanged,
  });

  final _ReaderSettingsPanel selected;
  final ValueChanged<_ReaderSettingsPanel> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('reader-settings-side-tabs'),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (
            var index = 0;
            index < _ReaderSettingsSheetTabs._options.length;
            index++
          ) ...[
            if (index > 0) const Divider(height: 1),
            _ReaderSettingsSideTab(
              option: _ReaderSettingsSheetTabs._options[index],
              selected:
                  selected == _ReaderSettingsSheetTabs._options[index].value,
              onTap: () =>
                  onChanged(_ReaderSettingsSheetTabs._options[index].value),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReaderSettingsSideTab extends StatelessWidget {
  const _ReaderSettingsSideTab({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ReaderSegmentOption<_ReaderSettingsPanel> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      excludeSemantics: true,
      child: InkWell(
        key: option.key,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: ColoredBox(
            color: selected
                ? colors.primary.withValues(alpha: 0.16)
                : Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    option.icon,
                    size: 20,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? colors.primary
                            : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderSettingsResetBar extends StatelessWidget {
  const _ReaderSettingsResetBar({required this.enabled, required this.onReset});

  final bool enabled;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('reader-settings-reset'),
            onPressed: enabled ? onReset : null,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('إعادة الافتراضي'),
          ),
        ),
      ),
    );
  }
}

class ReaderSettingsControls extends StatefulWidget {
  const ReaderSettingsControls({
    required this.preferences,
    required this.onChanged,
    this.showHeading = true,
    this.termReplacements = const [],
    this.advancedState = ReaderAdvancedTerminologyState.defaults,
    this.onOpenAdvanced,
    this.novelId = 0,
    this.onEditTerm,
    this.onDeleteTerm,
    super.key,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;
  final bool showHeading;
  final List<ReaderTermReplacement> termReplacements;
  final ReaderAdvancedTerminologyState advancedState;
  final VoidCallback? onOpenAdvanced;
  final int novelId;
  final ValueChanged<ReaderTermReplacement>? onEditTerm;
  final ValueChanged<ReaderTermReplacement>? onDeleteTerm;

  @override
  State<ReaderSettingsControls> createState() => _ReaderSettingsControlsState();
}

enum _ReaderSettingsPanel { text, colors, screen, terms }

enum _ReaderSettingsLayout { page, sheet }

class _ReaderSettingsControlsState extends State<ReaderSettingsControls> {
  _ReaderSettingsPanel _panel = _ReaderSettingsPanel.text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preferences = widget.preferences;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeading) ...[
          Text(
            'إعدادات القراءة',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
        ],
        _ReaderSettingsPanelSelector(
          selected: _panel,
          onChanged: (panel) => setState(() => _panel = panel),
        ),
        const SizedBox(height: 16),
        _buildPanel(preferences),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const ValueKey('reader-settings-reset'),
            onPressed: preferences == ReaderPreferences.defaults
                ? null
                : () => widget.onChanged(ReaderPreferences.defaults),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('إعادة الافتراضي'),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(ReaderPreferences preferences) {
    return switch (_panel) {
      _ReaderSettingsPanel.text => _TextSettingsPanel(
        preferences: preferences,
        onChanged: widget.onChanged,
        layout: _ReaderSettingsLayout.page,
      ),
      _ReaderSettingsPanel.colors => _ColorSettingsPanel(
        preferences: preferences,
        onChanged: widget.onChanged,
      ),
      _ReaderSettingsPanel.screen => _ScreenSettingsPanel(
        preferences: preferences,
        onChanged: widget.onChanged,
        layout: _ReaderSettingsLayout.page,
      ),
      _ReaderSettingsPanel.terms => ReaderTermsSettingsPanel(
        replacements: widget.termReplacements,
        novelId: widget.novelId,
        highlightEnabled: preferences.highlightReplacedTerms,
        onHighlightChanged: (enabled) {
          widget.onChanged(
            preferences.copyWith(highlightReplacedTerms: enabled),
          );
        },
        onEdit: widget.onEditTerm,
        onDelete: widget.onDeleteTerm,
        advancedState: widget.advancedState,
        onOpenAdvanced: widget.onOpenAdvanced,
      ),
    };
  }
}

class _ReaderSettingsPanelSelector extends StatelessWidget {
  const _ReaderSettingsPanelSelector({
    required this.selected,
    required this.onChanged,
  });

  final _ReaderSettingsPanel selected;
  final ValueChanged<_ReaderSettingsPanel> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (
        value: _ReaderSettingsPanel.text,
        label: 'النص',
        icon: Icons.format_size_rounded,
        key: ValueKey('reader-settings-tab-text'),
      ),
      (
        value: _ReaderSettingsPanel.colors,
        label: 'الألوان',
        icon: Icons.palette_outlined,
        key: ValueKey('reader-settings-tab-colors'),
      ),
      (
        value: _ReaderSettingsPanel.screen,
        label: 'الشاشة',
        icon: Icons.phone_android_rounded,
        key: ValueKey('reader-settings-tab-screen'),
      ),
      (
        value: _ReaderSettingsPanel.terms,
        label: 'المصطلحات',
        icon: Icons.find_replace_rounded,
        key: ValueKey('reader-settings-tab-terms'),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final optionWidth = _readerChoiceWidth(context, constraints, 4);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              SizedBox(
                width: optionWidth,
                child: _ReaderChoiceChip(
                  selected: selected == option.value,
                  label: option.label,
                  labelKey: option.key,
                  icon: option.icon,
                  onSelected: () => onChanged(option.value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TextSettingsPanel extends StatelessWidget {
  const _TextSettingsPanel({
    required this.preferences,
    required this.onChanged,
    required this.layout,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;
  final _ReaderSettingsLayout layout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fontSelector(context),
        const SizedBox(height: 16),
        if (layout == _ReaderSettingsLayout.sheet)
          _ReaderValueTable(preferences: preferences, onChanged: onChanged)
        else ...[
          _StepperRow(
            label: 'حجم الخط',
            value: '${(preferences.fontScale * 100).round()}%',
            decreaseKey: const ValueKey('reader-font-decrease'),
            increaseKey: const ValueKey('reader-font-increase'),
            onDecrease: () => onChanged(preferences.decreaseFont()),
            onIncrease: () => onChanged(preferences.increaseFont()),
          ),
          const SizedBox(height: 14),
          _StepperRow(
            label: 'تباعد الأسطر',
            value: preferences.lineHeight.toStringAsFixed(2),
            decreaseKey: const ValueKey('reader-line-decrease'),
            increaseKey: const ValueKey('reader-line-increase'),
            onDecrease: () => onChanged(preferences.decreaseLineHeight()),
            onIncrease: () => onChanged(preferences.increaseLineHeight()),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          'عرض النص',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _TextWidthSelector(
          selected: preferences.textWidth,
          layout: layout,
          onChanged: (textWidth) {
            onChanged(preferences.copyWith(textWidth: textWidth));
          },
        ),
      ],
    );
  }

  Widget _fontSelector(BuildContext context) {
    void onFontChanged(ReaderFontFamily fontFamily) {
      onChanged(preferences.copyWith(fontFamily: fontFamily));
    }

    if (layout == _ReaderSettingsLayout.sheet) {
      return ReaderFontSelector.compact(
        selected: preferences.fontFamily,
        readerScheme: preferences.colorSchemeFor(context),
        onChanged: onFontChanged,
      );
    }
    return ReaderFontSelector(
      selected: preferences.fontFamily,
      readerScheme: preferences.colorSchemeFor(context),
      onChanged: onFontChanged,
    );
  }
}

class _ColorSettingsPanel extends StatelessWidget {
  const _ColorSettingsPanel({
    required this.preferences,
    required this.onChanged,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ألوان القراءة',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _ReaderPaletteGrid(
          preferences: preferences,
          onChanged: (paletteMode) {
            onChanged(preferences.copyWith(paletteMode: paletteMode));
          },
        ),
      ],
    );
  }
}

class _ScreenSettingsPanel extends StatelessWidget {
  const _ScreenSettingsPanel({
    required this.preferences,
    required this.onChanged,
    required this.layout,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;
  final _ReaderSettingsLayout layout;

  @override
  Widget build(BuildContext context) {
    if (layout == _ReaderSettingsLayout.page) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadingFlowControls(
            preferences: preferences,
            onChanged: onChanged,
            layout: _ReaderSettingsLayout.page,
          ),
          const SizedBox(height: 8),
          _PinchZoomToggle(
            preferences: preferences,
            onChanged: onChanged,
            layout: _ReaderSettingsLayout.page,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const ValueKey('reader-immersive-toggle'),
            contentPadding: EdgeInsets.zero,
            value: preferences.immersiveMode,
            title: const Text('الوضع الغامر'),
            subtitle: const Text('إخفاء أشرطة النظام أثناء القراءة'),
            secondary: const Icon(Icons.fullscreen_rounded),
            onChanged: (enabled) {
              onChanged(preferences.copyWith(immersiveMode: enabled));
            },
          ),
          const SizedBox(height: 8),
          _BrightnessControls(
            preferences: preferences,
            onChanged: onChanged,
            layout: _ReaderSettingsLayout.page,
          ),
        ],
      );
    }
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('reader-screen-settings-surface'),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReadingFlowControls(
            preferences: preferences,
            onChanged: onChanged,
            layout: _ReaderSettingsLayout.sheet,
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          _PinchZoomToggle(
            preferences: preferences,
            onChanged: onChanged,
            layout: _ReaderSettingsLayout.sheet,
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          SwitchListTile(
            key: const ValueKey('reader-immersive-toggle'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            value: preferences.immersiveMode,
            title: const Text('الوضع الغامر'),
            subtitle: const Text('إخفاء أشرطة النظام أثناء القراءة'),
            secondary: const Icon(Icons.fullscreen_rounded),
            onChanged: (enabled) {
              onChanged(preferences.copyWith(immersiveMode: enabled));
            },
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: _BrightnessControls(
              preferences: preferences,
              onChanged: onChanged,
              layout: _ReaderSettingsLayout.sheet,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinchZoomToggle extends StatelessWidget {
  const _PinchZoomToggle({
    required this.preferences,
    required this.onChanged,
    required this.layout,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;
  final _ReaderSettingsLayout layout;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: const ValueKey('reader-pinch-zoom-toggle'),
      contentPadding: EdgeInsets.symmetric(
        horizontal: layout == _ReaderSettingsLayout.sheet ? 12 : 0,
      ),
      value: preferences.pinchZoomEnabled,
      title: const Text('التكبير بإصبعين'),
      subtitle: const Text('تكبير وتصغير النص بحركة إصبعين'),
      secondary: const Icon(Icons.zoom_in_map_rounded),
      onChanged: (enabled) {
        onChanged(preferences.copyWith(pinchZoomEnabled: enabled));
      },
    );
  }
}

class _ReadingFlowControls extends StatelessWidget {
  const _ReadingFlowControls({
    required this.preferences,
    required this.onChanged,
    required this.layout,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;
  final _ReaderSettingsLayout layout;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = layout == _ReaderSettingsLayout.sheet
        ? 12.0
        : 0.0;
    return Column(
      children: [
        SwitchListTile(
          key: const ValueKey('reader-continuous-reading-toggle'),
          contentPadding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          value: preferences.continuousReading,
          title: const Text('القراءة المتصلة'),
          subtitle: const Text('فتح الفصل التالي عند الوصول إلى نهاية الفصل'),
          secondary: const Icon(Icons.all_inclusive_rounded),
          onChanged: (enabled) {
            onChanged(preferences.copyWith(continuousReading: enabled));
          },
        ),
        if (layout == _ReaderSettingsLayout.sheet)
          const Divider(height: 1, indent: 12, endIndent: 12),
        SwitchListTile(
          key: const ValueKey('reader-auto-scroll-toggle'),
          contentPadding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          value: preferences.autoScrollEnabled,
          title: const Text('التمرير التلقائي'),
          subtitle: const Text('تحريك النص تلقائيًا والتوقف عند لمس الشاشة'),
          secondary: const Icon(Icons.slow_motion_video_rounded),
          onChanged: (enabled) {
            onChanged(preferences.copyWith(autoScrollEnabled: enabled));
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: preferences.autoScrollEnabled
              ? Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    4,
                    horizontalPadding,
                    10,
                  ),
                  child: _AutoScrollSpeedControl(
                    preferences: preferences,
                    onChanged: onChanged,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _AutoScrollSpeedControl extends StatelessWidget {
  const _AutoScrollSpeedControl({
    required this.preferences,
    required this.onChanged,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سرعة التمرير: ${_autoScrollSpeedLabel(preferences.autoScrollSpeed)}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            Expanded(
              child: Slider(
                key: const ValueKey('reader-auto-scroll-speed'),
                value: preferences.autoScrollSpeed,
                min: ReaderPreferences.minAutoScrollSpeed,
                max: ReaderPreferences.maxAutoScrollSpeed,
                divisions: 7,
                label: _autoScrollSpeedLabel(preferences.autoScrollSpeed),
                onChanged: (speed) {
                  onChanged(preferences.copyWith(autoScrollSpeed: speed));
                },
              ),
            ),
            const Icon(Icons.keyboard_double_arrow_down_rounded, size: 20),
          ],
        ),
      ],
    );
  }
}

String _autoScrollSpeedLabel(double speed) {
  if (speed < 32) return 'هادئة';
  if (speed < 56) return 'متوسطة';
  return 'سريعة';
}

class _BrightnessControls extends StatelessWidget {
  const _BrightnessControls({
    required this.preferences,
    required this.onChanged,
    required this.layout,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;
  final _ReaderSettingsLayout layout;

  static const List<ReaderSegmentOption<ReaderBrightnessMode>>
  _brightnessOptions = [
    (
      value: ReaderBrightnessMode.system,
      label: 'النظام',
      icon: Icons.brightness_auto_outlined,
      key: ValueKey('reader-brightness-system'),
    ),
    (
      value: ReaderBrightnessMode.manual,
      label: 'يدوي',
      icon: Icons.wb_sunny_outlined,
      key: ValueKey('reader-brightness-manual'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manual = preferences.brightnessMode == ReaderBrightnessMode.manual;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سطوع الشاشة',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _modeSelector(context),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.brightness_low_rounded, size: 20),
            Expanded(
              child: Slider(
                key: const ValueKey('reader-brightness-slider'),
                value: preferences.screenBrightness,
                min: 0.2,
                max: 1,
                divisions: 8,
                label: '${(preferences.screenBrightness * 100).round()}%',
                onChanged: manual
                    ? (value) {
                        onChanged(
                          preferences.copyWith(
                            brightnessMode: ReaderBrightnessMode.manual,
                            screenBrightness: value,
                          ),
                        );
                      }
                    : null,
              ),
            ),
            const Icon(Icons.brightness_high_rounded, size: 20),
          ],
        ),
      ],
    );
  }

  Widget _modeSelector(BuildContext context) {
    final manual = preferences.brightnessMode == ReaderBrightnessMode.manual;
    if (layout == _ReaderSettingsLayout.page) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final optionWidth = _readerChoiceWidth(context, constraints, 2);
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: optionWidth,
                child: _ReaderChoiceChip(
                  selected: !manual,
                  label: 'النظام',
                  labelKey: const ValueKey('reader-brightness-system'),
                  icon: Icons.brightness_auto_outlined,
                  onSelected: _useSystemBrightness,
                ),
              ),
              SizedBox(
                width: optionWidth,
                child: _ReaderChoiceChip(
                  selected: manual,
                  label: 'يدوي',
                  labelKey: const ValueKey('reader-brightness-manual'),
                  icon: Icons.wb_sunny_outlined,
                  onSelected: _useManualBrightness,
                ),
              ),
            ],
          );
        },
      );
    }

    return ReaderSegmentedControl<ReaderBrightnessMode>(
      key: const ValueKey('reader-brightness-mode-selector'),
      options: _brightnessOptions,
      selected: preferences.brightnessMode,
      onChanged: (brightnessMode) {
        onChanged(preferences.copyWith(brightnessMode: brightnessMode));
      },
    );
  }

  void _useSystemBrightness() {
    onChanged(
      preferences.copyWith(brightnessMode: ReaderBrightnessMode.system),
    );
  }

  void _useManualBrightness() {
    onChanged(
      preferences.copyWith(brightnessMode: ReaderBrightnessMode.manual),
    );
  }
}

class _ReaderPaletteGrid extends StatelessWidget {
  const _ReaderPaletteGrid({
    required this.preferences,
    required this.onChanged,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPaletteMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final scaled = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
        final columns = scaled ? 1 : (constraints.maxWidth >= 520 ? 3 : 2);
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          key: const ValueKey('reader-palette-grid'),
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final mode in ReaderPaletteMode.values)
              SizedBox(
                width: itemWidth,
                child: _ReaderPaletteCard(
                  mode: mode,
                  selected: preferences.paletteMode == mode,
                  onTap: () => onChanged(mode),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReaderPaletteCard extends StatelessWidget {
  const _ReaderPaletteCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ReaderPaletteMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = ReaderPreferences.defaults
        .copyWith(paletteMode: mode)
        .colorSchemeFor(context);
    final borderColor = selected
        ? scheme.primary
        : theme.colorScheme.outlineVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: _paletteLabel(mode),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          key: ValueKey('reader-palette-${mode.name}'),
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _PaletteSwatch(scheme: scheme),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _paletteLabel(mode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: selected ? scheme.primary : theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          width: 38,
          height: 28,
          child: Row(
            children: [
              Expanded(child: ColoredBox(color: scheme.surface)),
              Expanded(child: ColoredBox(color: scheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextWidthSelector extends StatelessWidget {
  const _TextWidthSelector({
    required this.selected,
    required this.onChanged,
    required this.layout,
  });

  final ReaderTextWidth selected;
  final ValueChanged<ReaderTextWidth> onChanged;
  final _ReaderSettingsLayout layout;

  static const List<ReaderSegmentOption<ReaderTextWidth>> _options = [
    (
      value: ReaderTextWidth.compact,
      label: 'مركز',
      icon: Icons.format_indent_increase_rounded,
      key: ValueKey('reader-width-compact'),
    ),
    (
      value: ReaderTextWidth.comfortable,
      label: 'مريح',
      icon: Icons.view_stream_outlined,
      key: ValueKey('reader-width-comfortable'),
    ),
    (
      value: ReaderTextWidth.wide,
      label: 'واسع',
      icon: Icons.format_indent_decrease_rounded,
      key: ValueKey('reader-width-wide'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (layout == _ReaderSettingsLayout.page) {
      return _pageSelector();
    }
    return ReaderSegmentedControl<ReaderTextWidth>(
      key: const ValueKey('reader-text-width-selector'),
      options: _options,
      selected: selected,
      onChanged: onChanged,
    );
  }

  Widget _pageSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final optionWidth = _readerChoiceWidth(context, constraints, 3);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in _options)
              SizedBox(
                width: optionWidth,
                child: _ReaderChoiceChip(
                  selected: selected == option.value,
                  label: option.label,
                  labelKey: option.key,
                  icon: option.icon,
                  onSelected: () => onChanged(option.value),
                ),
              ),
          ],
        );
      },
    );
  }
}

String _paletteLabel(ReaderPaletteMode mode) {
  return switch (mode) {
    ReaderPaletteMode.system => 'النظام',
    ReaderPaletteMode.light => 'نهاري',
    ReaderPaletteMode.dark => 'ليلي',
    ReaderPaletteMode.paper => 'ورق هادئ',
    ReaderPaletteMode.sepia => 'بني دافئ',
    ReaderPaletteMode.nightBlue => 'أزرق ليلي',
    ReaderPaletteMode.amoled => 'أسود AMOLED',
  };
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.decreaseKey,
    required this.increaseKey,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String value;
  final Key decreaseKey;
  final Key increaseKey;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton.outlined(
              key: decreaseKey,
              tooltip: 'تقليل $label',
              onPressed: onDecrease,
              icon: const Icon(Icons.remove),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
              child: Center(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            IconButton.filledTonal(
              key: increaseKey,
              tooltip: 'زيادة $label',
              onPressed: onIncrease,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReaderValueTable extends StatelessWidget {
  const _ReaderValueTable({required this.preferences, required this.onChanged});

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('reader-text-stepper-table'),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ReaderValueRow(
            label: 'حجم الخط',
            value: '${(preferences.fontScale * 100).round()}%',
            decreaseButton: IconButton.outlined(
              key: const ValueKey('reader-font-decrease'),
              tooltip: 'تقليل حجم الخط',
              onPressed: () => onChanged(preferences.decreaseFont()),
              icon: const Icon(Icons.remove),
            ),
            increaseButton: IconButton.filledTonal(
              key: const ValueKey('reader-font-increase'),
              tooltip: 'زيادة حجم الخط',
              onPressed: () => onChanged(preferences.increaseFont()),
              icon: const Icon(Icons.add),
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          _ReaderValueRow(
            label: 'تباعد الأسطر',
            value: preferences.lineHeight.toStringAsFixed(2),
            decreaseButton: IconButton.outlined(
              key: const ValueKey('reader-line-decrease'),
              tooltip: 'تقليل تباعد الأسطر',
              onPressed: () => onChanged(preferences.decreaseLineHeight()),
              icon: const Icon(Icons.remove),
            ),
            increaseButton: IconButton.filledTonal(
              key: const ValueKey('reader-line-increase'),
              tooltip: 'زيادة تباعد الأسطر',
              onPressed: () => onChanged(preferences.increaseLineHeight()),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderValueRow extends StatelessWidget {
  const _ReaderValueRow({
    required this.label,
    required this.value,
    required this.decreaseButton,
    required this.increaseButton,
  });

  final String label;
  final String value;
  final Widget decreaseButton;
  final Widget increaseButton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.5;
        final controls = _controls(context);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(label, style: _labelStyle(context)),
                    const SizedBox(height: 8),
                    controls,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: Text(label, style: _labelStyle(context))),
                    const SizedBox(width: 12),
                    controls,
                  ],
                ),
        );
      },
    );
  }

  Widget _controls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        decreaseButton,
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 58, minHeight: 44),
          child: Center(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        increaseButton,
      ],
    );
  }

  TextStyle? _labelStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800);
  }
}

class _ReaderChoiceChip extends StatelessWidget {
  const _ReaderChoiceChip({
    required this.selected,
    required this.label,
    required this.labelKey,
    required this.icon,
    required this.onSelected,
  });

  final bool selected;
  final String label;
  final Key labelKey;
  final IconData icon;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        avatar: Icon(icon),
        label: Text(label, key: labelKey),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

double _readerChoiceWidth(
  BuildContext context,
  BoxConstraints constraints,
  int columns,
) {
  final scaled = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
  if (scaled || constraints.maxWidth < 280) {
    return constraints.maxWidth;
  }
  return (constraints.maxWidth - 8 * (columns - 1)) / columns;
}
