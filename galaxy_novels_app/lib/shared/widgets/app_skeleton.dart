import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    required this.height,
    this.width = double.infinity,
    this.borderRadius = 8,
    this.semanticLabel,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final box = SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );

    return semanticLabel == null
        ? ExcludeSemantics(child: box)
        : Semantics(label: semanticLabel, liveRegion: true, child: box);
  }
}
