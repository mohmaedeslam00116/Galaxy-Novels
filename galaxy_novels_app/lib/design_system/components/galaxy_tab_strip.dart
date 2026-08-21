import 'package:flutter/material.dart';

import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';

@immutable
class GalaxyTabSpec {
  const GalaxyTabSpec({required this.label, this.icon});

  final String label;
  final IconData? icon;
}

class GalaxyTabStrip extends StatelessWidget {
  const GalaxyTabStrip({
    required this.controller,
    required this.tabs,
    super.key,
  });

  final TabController controller;
  final List<GalaxyTabSpec> tabs;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return Semantics(
      container: true,
      label: 'أقسام رحلة القارئ',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(
            bottom: BorderSide(color: tokens.outline.withValues(alpha: 0.52)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GalaxyMetrics.space16,
            GalaxyMetrics.space4,
            GalaxyMetrics.space16,
            GalaxyMetrics.space8,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceRaised.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(GalaxyMetrics.radiusControl),
              border: Border.all(color: tokens.outline.withValues(alpha: 0.42)),
            ),
            child: TabBar(
              controller: controller,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(GalaxyMetrics.space4),
              indicator: BoxDecoration(
                color: tokens.brandContainer,
                borderRadius: BorderRadius.circular(GalaxyMetrics.radiusSmall),
              ),
              labelColor: tokens.onBrandContainer,
              unselectedLabelColor: tokens.contentSecondary,
              labelStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              tabs: [
                for (final tab in tabs)
                  Tab(
                    height: GalaxyMetrics.minimumTouchTarget,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (tab.icon case final icon?) ...[
                          Icon(icon, size: 20),
                          const SizedBox(width: GalaxyMetrics.space8),
                        ],
                        Flexible(
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
