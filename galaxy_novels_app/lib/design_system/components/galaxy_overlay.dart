import 'package:flutter/material.dart';

import '../foundation/galaxy_metrics.dart';
import 'galaxy_surface.dart';

class GalaxyDialog extends StatelessWidget {
  const GalaxyDialog({
    required this.title,
    required this.content,
    this.actions = const [],
    super.key,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: GalaxySurface(
        variant: GalaxySurfaceVariant.raised,
        radius: GalaxyMetrics.radiusOverlay,
        padding: const EdgeInsets.all(GalaxyMetrics.space20),
        child: _OverlayContent(
          title: title,
          content: content,
          actions: actions,
        ),
      ),
    );
  }
}

class GalaxyBottomSheet extends StatelessWidget {
  const GalaxyBottomSheet({
    required this.title,
    required this.content,
    this.actions = const [],
    super.key,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return GalaxySurface(
      variant: GalaxySurfaceVariant.raised,
      radius: GalaxyMetrics.radiusOverlay,
      padding: const EdgeInsets.fromLTRB(
        GalaxyMetrics.space20,
        GalaxyMetrics.space12,
        GalaxyMetrics.space20,
        GalaxyMetrics.space20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: GalaxyMetrics.space12),
          _OverlayContent(title: title, content: content, actions: actions),
        ],
      ),
    );
  }
}

class _OverlayContent extends StatelessWidget {
  const _OverlayContent({
    required this.title,
    required this.content,
    required this.actions,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: GalaxyMetrics.space12),
        content,
        if (actions.isNotEmpty) ...[
          const SizedBox(height: GalaxyMetrics.space16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: GalaxyMetrics.space8,
            runSpacing: GalaxyMetrics.space8,
            children: actions,
          ),
        ],
      ],
    );
  }
}
