import 'package:flutter/material.dart';

import '../components/galaxy_surface.dart';
import '../foundation/galaxy_design_tokens.dart';

class GalaxyEditorialList extends StatelessWidget {
  const GalaxyEditorialList({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return GalaxySurface(
      key: const ValueKey('galaxy-editorial-list'),
      variant: GalaxySurfaceVariant.base,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: tokens.outline.withValues(alpha: 0.58),
              ),
            children[index],
          ],
        ],
      ),
    );
  }
}

class GalaxyEditorialSliverList extends StatelessWidget {
  const GalaxyEditorialSliverList({
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return SliverPadding(
      padding: padding,
      sliver: SliverList.separated(
        itemCount: itemCount,
        itemBuilder: (context, index) =>
            RepaintBoundary(child: itemBuilder(context, index)),
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 12,
          endIndent: 12,
          color: tokens.outline.withValues(alpha: 0.58),
        ),
      ),
    );
  }
}
