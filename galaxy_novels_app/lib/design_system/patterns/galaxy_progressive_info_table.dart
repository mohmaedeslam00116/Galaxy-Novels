import 'package:flutter/material.dart';

import '../components/galaxy_surface.dart';
import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';
import '../foundation/galaxy_motion.dart';

@immutable
class GalaxyInfoItem {
  const GalaxyInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Key? key;
}

class GalaxyProgressiveInfoTable extends StatefulWidget {
  const GalaxyProgressiveInfoTable({
    required this.primaryItems,
    this.secondaryItems = const [],
    super.key,
  });

  final List<GalaxyInfoItem> primaryItems;
  final List<GalaxyInfoItem> secondaryItems;

  @override
  State<GalaxyProgressiveInfoTable> createState() =>
      _GalaxyProgressiveInfoTableState();
}

class _GalaxyProgressiveInfoTableState
    extends State<GalaxyProgressiveInfoTable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final secondaryItems = widget.secondaryItems;
    return GalaxySurface(
      key: const ValueKey('galaxy-progressive-info-table'),
      clipBehavior: Clip.antiAlias,
      radius: GalaxyMetrics.radiusCard,
      variant: GalaxySurfaceVariant.tonal,
      child: Column(
        children: [
          ..._rows(widget.primaryItems, tokens),
          if (secondaryItems.isNotEmpty) ...[
            AnimatedSize(
              duration: GalaxyMotion.resolve(context, GalaxyMotion.stateChange),
              curve: GalaxyMotion.curve,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Column(
                      children: [
                        Divider(
                          height: 1,
                          indent: 64,
                          endIndent: GalaxyMetrics.space12,
                          color: tokens.outline.withValues(alpha: 0.48),
                        ),
                        ..._rows(secondaryItems, tokens),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Divider(height: 1, color: tokens.outline.withValues(alpha: 0.48)),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                key: const ValueKey('galaxy-progressive-info-toggle'),
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: GalaxyMotion.resolve(
                    context,
                    GalaxyMotion.stateChange,
                  ),
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                label: Text(_expanded ? 'عرض أقل' : 'عرض كل البيانات'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    GalaxyMetrics.minimumTouchTarget,
                    GalaxyMetrics.minimumTouchTarget,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _rows(List<GalaxyInfoItem> items, GalaxyDesignTokens tokens) {
    return [
      for (var index = 0; index < items.length; index++) ...[
        if (index > 0)
          Divider(
            height: 1,
            indent: 64,
            endIndent: GalaxyMetrics.space12,
            color: tokens.outline.withValues(alpha: 0.48),
          ),
        _GalaxyInfoRow(key: items[index].key, item: items[index]),
      ],
    ];
  }
}

class _GalaxyInfoRow extends StatelessWidget {
  const _GalaxyInfoRow({required this.item, super.key});

  final GalaxyInfoItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GalaxyMetrics.space12,
          vertical: GalaxyMetrics.space8,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.brandContainer.withValues(alpha: 0.64),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: tokens.brand, size: 20),
            ),
            const SizedBox(width: GalaxyMetrics.space12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: tokens.contentSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.contentPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
