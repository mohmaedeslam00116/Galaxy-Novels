import 'package:flutter/material.dart';

import '../domain/reader_preferences.dart';
import 'reader_font_options.dart';

class ReaderFontSelector extends StatelessWidget {
  const ReaderFontSelector({
    required this.selected,
    required this.readerScheme,
    required this.onChanged,
    super.key,
  });

  final ReaderFontFamily selected;
  final ColorScheme readerScheme;
  final ValueChanged<ReaderFontFamily> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewStyle = theme.textTheme.bodyLarge?.copyWith(
      color: readerScheme.onSurface,
      fontFamily: selected.fontFamily,
      height: 1.8,
      fontWeight: FontWeight.w700,
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
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ReaderFontFamily.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final font = ReaderFontFamily.values[index];
              return _FontOptionTile(
                font: font,
                selected: selected == font,
                onTap: () => onChanged(font),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FontOptionTile extends StatelessWidget {
  const _FontOptionTile({
    required this.font,
    required this.selected,
    required this.onTap,
  });

  final ReaderFontFamily font;
  final bool selected;
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
          child: SizedBox(
            width: 136,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: font.fontFamily,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.78),
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
