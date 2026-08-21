import 'package:flutter/material.dart';

import '../foundation/galaxy_metrics.dart';

class GalaxyNovelShelf extends StatelessWidget {
  const GalaxyNovelShelf({
    required this.itemWidth,
    required this.children,
    this.itemSpacing = GalaxyMetrics.space12,
    this.padding = const EdgeInsets.symmetric(
      horizontal: GalaxyMetrics.space16,
    ),
    super.key,
  }) : itemCount = null,
       itemBuilder = null;

  const GalaxyNovelShelf.builder({
    required this.itemWidth,
    required int this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
    this.itemSpacing = GalaxyMetrics.space12,
    this.padding = const EdgeInsets.symmetric(
      horizontal: GalaxyMetrics.space16,
    ),
    super.key,
  }) : children = null;

  final double itemWidth;
  final List<Widget>? children;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final double itemSpacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: padding,
      itemCount: itemCount ?? children!.length,
      itemBuilder: (context, index) => SizedBox(
        width: itemWidth,
        child: RepaintBoundary(
          child: itemBuilder?.call(context, index) ?? children![index],
        ),
      ),
      separatorBuilder: (_, _) => SizedBox(width: itemSpacing),
    );
  }
}
