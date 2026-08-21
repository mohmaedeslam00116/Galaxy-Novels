import 'package:flutter/material.dart';

import '../foundation/galaxy_adaptive.dart';
import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';

enum GalaxyNovelDetailsHeaderVariant { standard, centeredPoster }

@immutable
class GalaxyStatItem {
  const GalaxyStatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
    this.tooltip,
    this.enabled = true,
    this.loading = false,
    this.key,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool enabled;
  final bool loading;
  final Key? key;
}

class GalaxyStatsRail extends StatelessWidget {
  const GalaxyStatsRail({required this.items, super.key});

  final List<GalaxyStatItem> items;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const ValueKey('galaxy-stats-rail'),
      decoration: BoxDecoration(
        color: tokens.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(GalaxyMetrics.radiusCard),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.42)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GalaxyMetrics.space12),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0)
                SizedBox(
                  height: 40,
                  child: VerticalDivider(
                    color: tokens.outline.withValues(alpha: 0.45),
                  ),
                ),
              Expanded(
                child: _GalaxyStatCell(
                  item: items[index],
                  tokens: tokens,
                  theme: theme,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GalaxyStatCell extends StatelessWidget {
  const _GalaxyStatCell({
    required this.item,
    required this.tokens,
    required this.theme,
  });

  final GalaxyStatItem item;
  final GalaxyDesignTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = item.enabled && !item.loading ? item.onTap : null;
    final content = Semantics(
      label: '${item.label}: ${item.value}',
      button: item.onTap != null,
      enabled: item.onTap == null ? null : effectiveOnTap != null,
      onTap: effectiveOnTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: effectiveOnTap,
          borderRadius: BorderRadius.circular(GalaxyMetrics.radiusControl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GalaxyMetrics.minimumTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GalaxyMetrics.space4,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.loading)
                    SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        value: 0.65,
                        strokeWidth: 2,
                        color: tokens.brand,
                        semanticsLabel: 'جارٍ التحميل',
                      ),
                    )
                  else
                    Icon(item.icon, size: 18, color: tokens.brand),
                  const SizedBox(height: GalaxyMetrics.space4),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tokens.contentSecondary,
                          ),
                        ),
                      ),
                      if (item.tooltip != null) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.help_outline_rounded,
                          size: 14,
                          color: tokens.contentSecondary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final interactive = item.tooltip == null
        ? content
        : Tooltip(message: item.tooltip!, child: content);
    return KeyedSubtree(
      key: item.key,
      child: Opacity(opacity: item.enabled ? 1 : 0.55, child: interactive),
    );
  }
}

class GalaxyCollapsingDetailsBar extends StatelessWidget {
  const GalaxyCollapsingDetailsBar({
    required this.title,
    this.readLabel,
    this.onRead,
    super.key,
  });

  final String title;
  final String? readLabel;
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (readLabel != null && onRead != null) ...[
          const SizedBox(width: GalaxyMetrics.space8),
          TextButton.icon(
            onPressed: onRead,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(readLabel!),
            style: TextButton.styleFrom(
              foregroundColor: tokens.brand,
              minimumSize: const Size(48, GalaxyMetrics.minimumTouchTarget),
            ),
          ),
        ],
      ],
    );
  }
}

class GalaxyNovelDetailsHeader extends StatelessWidget {
  const GalaxyNovelDetailsHeader({
    required this.title,
    required this.cover,
    required this.content,
    this.subtitle,
    this.badges = const [],
    this.footer,
    this.variant = GalaxyNovelDetailsHeaderVariant.standard,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget cover;
  final Widget content;
  final List<Widget> badges;
  final Widget? footer;
  final GalaxyNovelDetailsHeaderVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tokens.surfaceRaised.withValues(alpha: 0.86), tokens.canvas],
          stops: const [0, 0.94],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = GalaxyAdaptiveMetrics.forWidth(constraints.maxWidth);
          final expanded =
              variant == GalaxyNovelDetailsHeaderVariant.centeredPoster &&
              metrics.tier == GalaxyLayoutTier.expanded;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              metrics.horizontalPadding,
              GalaxyMetrics.space16,
              metrics.horizontalPadding,
              GalaxyMetrics.space24,
            ),
            child: expanded
                ? Row(
                    key: const ValueKey('galaxy-details-expanded-header'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 224),
                        child: cover,
                      ),
                      const SizedBox(width: GalaxyMetrics.space32),
                      Expanded(child: _identity(context, centered: false)),
                    ],
                  )
                : Column(
                    key: const ValueKey('galaxy-details-centered-header'),
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              variant ==
                                  GalaxyNovelDetailsHeaderVariant.centeredPoster
                              ? 224
                              : double.infinity,
                        ),
                        child: cover,
                      ),
                      SizedBox(
                        height:
                            variant ==
                                GalaxyNovelDetailsHeaderVariant.centeredPoster
                            ? GalaxyMetrics.space20
                            : GalaxyMetrics.space16,
                      ),
                      _identity(context, centered: true),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _identity(BuildContext context, {required bool centered}) {
    final theme = Theme.of(context);
    final tokens = GalaxyDesignTokens.of(context);
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: tokens.contentPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle?.trim().isNotEmpty == true) ...[
          const SizedBox(height: GalaxyMetrics.space4),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.labelLarge?.copyWith(
              color: tokens.brand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (badges.isNotEmpty) ...[
          const SizedBox(height: GalaxyMetrics.space12),
          Wrap(
            alignment: centered ? WrapAlignment.center : WrapAlignment.start,
            spacing: GalaxyMetrics.space8,
            runSpacing: GalaxyMetrics.space8,
            children: badges,
          ),
        ],
        const SizedBox(height: GalaxyMetrics.space24),
        content,
        if (footer != null) ...[
          const SizedBox(height: GalaxyMetrics.space16),
          footer!,
        ],
      ],
    );
  }
}
