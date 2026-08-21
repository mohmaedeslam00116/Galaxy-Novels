import 'package:flutter/material.dart';

import '../../../../design_system/components/galaxy_surface.dart';
import '../novel_details_visual_tokens.dart';

class NovelDetailsSummaryCard extends StatefulWidget {
  const NovelDetailsSummaryCard({required this.summary, super.key});

  final String summary;

  @override
  State<NovelDetailsSummaryCard> createState() =>
      _NovelDetailsSummaryCardState();
}

class _NovelDetailsSummaryCardState extends State<NovelDetailsSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = NovelDetailsVisualTokens.of(context);
    final canExpand = widget.summary.length > 220;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: GalaxySurface(
        key: const ValueKey('novel-details-summary-card'),
        padding: const EdgeInsets.all(18),
        radius: 16,
        variant: GalaxySurfaceVariant.tonal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: tokens.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'الملخص',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              widget.summary,
              maxLines: canExpand && !_expanded ? 4 : null,
              overflow: canExpand && !_expanded
                  ? TextOverflow.ellipsis
                  : TextOverflow.visible,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: tokens.textSecondary,
                height: 1.75,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (canExpand) ...[
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'عرض أقل' : 'عرض المزيد'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
