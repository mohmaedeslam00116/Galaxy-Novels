import 'package:flutter/material.dart';

import 'reader_preferences.dart';

Future<void> showReaderSettingsSheet({
  required BuildContext context,
  required ReaderPreferences preferences,
  required ValueChanged<ReaderPreferences> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return ReaderSettingsSheet(
        preferences: preferences,
        onChanged: onChanged,
      );
    },
  );
}

class ReaderSettingsSheet extends StatefulWidget {
  const ReaderSettingsSheet({
    required this.preferences,
    required this.onChanged,
    super.key,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late ReaderPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.84,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ReaderSettingsControls(
            key: const ValueKey('reader-settings-sheet'),
            preferences: _preferences,
            onChanged: _update,
          ),
        ),
      ),
    );
  }

  void _update(ReaderPreferences preferences) {
    setState(() => _preferences = preferences);
    widget.onChanged(preferences);
  }
}

class ReaderSettingsControls extends StatelessWidget {
  const ReaderSettingsControls({
    required this.preferences,
    required this.onChanged,
    this.showHeading = true,
    super.key,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;
  final bool showHeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading) ...[
          Text(
            'إعدادات القراءة',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
        ],
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
        const SizedBox(height: 18),
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
        const SizedBox(height: 18),
        Text(
          'عرض النص',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _TextWidthSelector(
          selected: preferences.textWidth,
          onChanged: (textWidth) {
            onChanged(preferences.copyWith(textWidth: textWidth));
          },
        ),
        const SizedBox(height: 18),
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
        _BrightnessControls(preferences: preferences, onChanged: onChanged),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const ValueKey('reader-settings-reset'),
            onPressed: preferences == ReaderPreferences.defaults
                ? null
                : () => onChanged(ReaderPreferences.defaults),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('إعادة الافتراضي'),
          ),
        ),
      ],
    );
  }
}

class _BrightnessControls extends StatelessWidget {
  const _BrightnessControls({
    required this.preferences,
    required this.onChanged,
  });

  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onChanged;

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
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ReaderBrightnessMode>(
            segments: const [
              ButtonSegment(
                value: ReaderBrightnessMode.system,
                label: Text(
                  'النظام',
                  key: ValueKey('reader-brightness-system'),
                ),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ReaderBrightnessMode.manual,
                label: Text('يدوي', key: ValueKey('reader-brightness-manual')),
                icon: Icon(Icons.wb_sunny_outlined),
              ),
            ],
            selected: {preferences.brightnessMode},
            onSelectionChanged: (selection) {
              onChanged(preferences.copyWith(brightnessMode: selection.single));
            },
          ),
        ),
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
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
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
  const _TextWidthSelector({required this.selected, required this.onChanged});

  final ReaderTextWidth selected;
  final ValueChanged<ReaderTextWidth> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ReaderTextWidth>(
      segments: const [
        ButtonSegment(
          value: ReaderTextWidth.compact,
          label: Text('مركز', key: ValueKey('reader-width-compact')),
          icon: Icon(Icons.format_indent_increase_rounded),
        ),
        ButtonSegment(
          value: ReaderTextWidth.comfortable,
          label: Text('مريح', key: ValueKey('reader-width-comfortable')),
          icon: Icon(Icons.view_stream_outlined),
        ),
        ButtonSegment(
          value: ReaderTextWidth.wide,
          label: Text('واسع', key: ValueKey('reader-width-wide')),
          icon: Icon(Icons.format_indent_decrease_rounded),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.single),
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

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton.outlined(
          key: decreaseKey,
          tooltip: 'تقليل $label',
          onPressed: onDecrease,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 64,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
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
    );
  }
}
