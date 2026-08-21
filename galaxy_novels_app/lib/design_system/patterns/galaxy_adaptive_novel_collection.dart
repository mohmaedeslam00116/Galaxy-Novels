import 'package:flutter/material.dart';

import '../foundation/galaxy_metrics.dart';
import 'galaxy_novel_shelf.dart';

/// Adapts a novel collection to its amount of available content.
///
/// This deliberately treats one and two items as editorial compositions rather
/// than leaving large empty areas that resemble an incomplete shelf.
class GalaxyAdaptiveNovelCollection extends StatelessWidget {
  const GalaxyAdaptiveNovelCollection({
    required this.itemCount,
    required this.itemWidth,
    required this.itemExtent,
    required this.singleItemExtent,
    required this.itemBuilder,
    required this.singleItemBuilder,
    this.itemSpacing = GalaxyMetrics.space12,
    this.padding = const EdgeInsets.symmetric(
      horizontal: GalaxyMetrics.space16,
    ),
    super.key,
  });

  final int itemCount;
  final double itemWidth;
  final double itemExtent;
  final double singleItemExtent;
  final IndexedWidgetBuilder itemBuilder;
  final WidgetBuilder singleItemBuilder;
  final double itemSpacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) return const SizedBox.shrink();
    if (itemCount == 1) {
      return Padding(
        padding: padding,
        child: SizedBox(
          key: const ValueKey('galaxy-adaptive-single'),
          height: singleItemExtent,
          width: double.infinity,
          child: RepaintBoundary(child: singleItemBuilder(context)),
        ),
      );
    }
    if (itemCount == 2) {
      return LayoutBuilder(
        builder: (context, constraints) => _buildPair(context, constraints),
      );
    }
    return SizedBox(
      key: const ValueKey('galaxy-adaptive-shelf'),
      height: itemExtent,
      child: GalaxyNovelShelf.builder(
        itemWidth: itemWidth,
        padding: padding,
        itemCount: itemCount,
        itemSpacing: itemSpacing,
        itemBuilder: itemBuilder,
      ),
    );
  }

  Widget _buildPair(BuildContext context, BoxConstraints constraints) {
    final resolvedPadding = padding.resolve(Directionality.of(context));
    final availableWidth = constraints.maxWidth - resolvedPadding.horizontal;
    final fitsSideBySide = itemWidth * 2 + itemSpacing <= availableWidth;
    final pair = fitsSideBySide
        ? SizedBox(
            height: itemExtent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _boundedItem(context, 0)),
                SizedBox(width: itemSpacing),
                Expanded(child: _boundedItem(context, 1)),
              ],
            ),
          )
        : SizedBox(
            height: itemExtent * 2 + itemSpacing,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _boundedItem(context, 0)),
                SizedBox(height: itemSpacing),
                Expanded(child: _boundedItem(context, 1)),
              ],
            ),
          );
    return Padding(
      padding: padding,
      child: KeyedSubtree(
        key: const ValueKey('galaxy-adaptive-pair'),
        child: pair,
      ),
    );
  }

  Widget _boundedItem(BuildContext context, int index) {
    return RepaintBoundary(child: itemBuilder(context, index));
  }
}
