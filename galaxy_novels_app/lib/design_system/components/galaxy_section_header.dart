import 'package:flutter/material.dart';

import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';

class GalaxySectionHeader extends StatelessWidget {
  const GalaxySectionHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.compact = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GalaxyDesignTokens.of(context);
    final showDetails = !compact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showDetails && icon != null) ...[
              Icon(icon, size: 24, color: tokens.brand),
              const SizedBox(width: GalaxyMetrics.space8),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: tokens.contentPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.22,
                ),
              ),
            ),
            if (showDetails && onAction != null)
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: GalaxyMetrics.minimumTouchTarget,
                  minWidth: GalaxyMetrics.minimumTouchTarget,
                ),
                child: TextButton(
                  key: actionKey,
                  onPressed: onAction,
                  child: Text(actionLabel ?? 'عرض الكل'),
                ),
              ),
          ],
        ),
        if (showDetails && subtitle?.trim().isNotEmpty == true) ...[
          const SizedBox(height: GalaxyMetrics.space2),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.contentSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
