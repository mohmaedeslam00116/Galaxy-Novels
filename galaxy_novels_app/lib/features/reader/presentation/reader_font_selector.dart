import 'package:flutter/material.dart';

import '../domain/reader_preferences.dart';
import 'reader_font_options.dart';

class ReaderFontSelector extends StatelessWidget {
  const ReaderFontSelector({
    required this.selected,
    required this.readerScheme,
    required this.onChanged,
    super.key,
  }) : _layout = _ReaderFontSelectorLayout.page;

  const ReaderFontSelector.compact({
    required this.selected,
    required this.readerScheme,
    required this.onChanged,
    super.key,
  }) : _layout = _ReaderFontSelectorLayout.sheet;

  final ReaderFontFamily selected;
  final ColorScheme readerScheme;
  final ValueChanged<ReaderFontFamily> onChanged;
  final _ReaderFontSelectorLayout _layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewStyle = readerFontTextStyle(
      (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
        color: readerScheme.onSurface,
        height: 1.8,
        fontWeight: FontWeight.w700,
      ),
      fontFamily: selected,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخط',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          key: const ValueKey('reader-font-preview'),
          decoration: BoxDecoration(
            color: readerScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: readerScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              'المعاينة: كان الفصل هادئًا، لكن نهايته فتحت بابًا جديدًا.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: previewStyle,
            ),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final scaled = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
            final compact = _layout == _ReaderFontSelectorLayout.sheet;
            final columns = compact && scaled
                ? 1
                : (constraints.maxWidth >= 520 ? 3 : 2);
            final tileWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              key: const ValueKey('reader-font-grid'),
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final font in ReaderFontFamily.values)
                  SizedBox(
                    width: tileWidth,
                    child: _FontOptionTile(
                      font: font,
                      selected: selected == font,
                      layout: _layout,
                      onTap: () => onChanged(font),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FontOptionTile extends StatelessWidget {
  const _FontOptionTile({
    required this.font,
    required this.selected,
    required this.layout,
    required this.onTap,
  });

  final ReaderFontFamily font;
  final bool selected;
  final _ReaderFontSelectorLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = selected ? scheme.primary : scheme.outlineVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: font.label,
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.54)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.32),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          key: ValueKey('reader-font-${font.name}'),
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: layout == _ReaderFontSelectorLayout.sheet ? 72 : 88,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          font.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 17,
                        color: selected ? scheme.primary : scheme.outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    font.preview,
                    maxLines: layout == _ReaderFontSelectorLayout.sheet
                        ? 1
                        : null,
                    overflow: layout == _ReaderFontSelectorLayout.sheet
                        ? TextOverflow.ellipsis
                        : TextOverflow.clip,
                    style: readerFontTextStyle(
                      (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                        height: 1.45,
                        color: scheme.onSurface.withValues(alpha: 0.78),
                      ),
                      fontFamily: font,
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

enum _ReaderFontSelectorLayout { page, sheet }
