import 'package:flutter/material.dart';

import 'reader_preferences.dart';

Future<void> showReaderSettingsSheet({
  required BuildContext context,
  required ReaderPreferences preferences,
  required ValueChanged<ReaderPreferences> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ReaderSettingsControls(
          key: const ValueKey('reader-settings-sheet'),
          preferences: _preferences,
          onChanged: _update,
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
          'وضع القراءة',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ReaderPaletteMode>(
            segments: const [
              ButtonSegment(
                value: ReaderPaletteMode.system,
                label: Text('النظام', key: ValueKey('reader-palette-system')),
              ),
              ButtonSegment(
                value: ReaderPaletteMode.light,
                label: Text('فاتح', key: ValueKey('reader-palette-light')),
              ),
              ButtonSegment(
                value: ReaderPaletteMode.dark,
                label: Text('داكن', key: ValueKey('reader-palette-dark')),
              ),
            ],
            selected: {preferences.paletteMode},
            onSelectionChanged: (selection) {
              onChanged(preferences.copyWith(paletteMode: selection.single));
            },
          ),
        ),
      ],
    );
  }
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
