import 'package:flutter/material.dart';

import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';
import 'galaxy_surface.dart';

enum GalaxyAsyncStateKind { loading, empty, error, disabled }

class GalaxyAsyncState extends StatelessWidget {
  const GalaxyAsyncState.loading({required String label, Key? key})
    : this._(kind: GalaxyAsyncStateKind.loading, title: label, key: key);

  const GalaxyAsyncState.empty({
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Key? key,
  }) : this._(
         kind: GalaxyAsyncStateKind.empty,
         title: title,
         message: message,
         actionLabel: actionLabel,
         onAction: onAction,
         key: key,
       );

  const GalaxyAsyncState.error({
    required String title,
    required String message,
    VoidCallback? onRetry,
    Key? key,
  }) : this._(
         kind: GalaxyAsyncStateKind.error,
         title: title,
         message: message,
         onRetry: onRetry,
         key: key,
       );

  const GalaxyAsyncState.disabled({
    required String title,
    required String message,
    Key? key,
  }) : this._(
         kind: GalaxyAsyncStateKind.disabled,
         title: title,
         message: message,
         key: key,
       );

  const GalaxyAsyncState._({
    required this.kind,
    required this.title,
    this.message,
    this.onRetry,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final GalaxyAsyncStateKind kind;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final icon = switch (kind) {
      GalaxyAsyncStateKind.loading => Icons.autorenew_rounded,
      GalaxyAsyncStateKind.empty => Icons.auto_stories_outlined,
      GalaxyAsyncStateKind.error => Icons.cloud_off_outlined,
      GalaxyAsyncStateKind.disabled => Icons.lock_outline_rounded,
    };
    return GalaxySurface(
      variant: GalaxySurfaceVariant.tonal,
      padding: const EdgeInsets.all(GalaxyMetrics.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kind == GalaxyAsyncStateKind.loading)
            Semantics(
              label: title,
              child: SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: tokens.brand,
                ),
              ),
            )
          else
            Icon(icon, size: 28, color: tokens.brand),
          const SizedBox(height: GalaxyMetrics.space8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: tokens.contentPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (message case final message?) ...[
            const SizedBox(height: GalaxyMetrics.space4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.contentSecondary),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: GalaxyMetrics.space12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ] else if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: GalaxyMetrics.space12),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
