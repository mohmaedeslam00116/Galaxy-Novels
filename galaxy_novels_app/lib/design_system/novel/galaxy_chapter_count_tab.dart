import 'package:flutter/material.dart';

import '../foundation/galaxy_component_variants.dart';
import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';

class GalaxyChapterCountTab extends StatelessWidget {
  const GalaxyChapterCountTab({
    required this.chapterCount,
    this.size = GalaxyComponentSize.medium,
    super.key,
  });

  final String chapterCount;
  final GalaxyComponentSize size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$chapterCount فصلًا',
      child: ExcludeSemantics(
        child: ClipPath(
          clipper: const _BookmarkTabClipper(),
          child: SizedBox.fromSize(
            size: _tabDimensions(size),
            child: _BookmarkVisual(chapterCount: chapterCount),
          ),
        ),
      ),
    );
  }
}

Size _tabDimensions(GalaxyComponentSize size) => switch (size) {
  GalaxyComponentSize.small => const Size(42, 52),
  GalaxyComponentSize.medium => const Size(48, 58),
  GalaxyComponentSize.large => const Size(54, 64),
};

class _BookmarkVisual extends StatelessWidget {
  const _BookmarkVisual({required this.chapterCount});

  final String chapterCount;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(tokens.surfaceRaised, tokens.brandContainer, 0.72),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(height: 3, color: tokens.brand),
          ),
          _BookmarkLabel(chapterCount: chapterCount, tokens: tokens),
        ],
      ),
    );
  }
}

class _BookmarkLabel extends StatelessWidget {
  const _BookmarkLabel({required this.chapterCount, required this.tokens});

  final String chapterCount;
  final GalaxyDesignTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 6, 5, 10),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 14,
              color: tokens.onBrandContainer,
            ),
            const SizedBox(height: GalaxyMetrics.space2),
            Text(
              chapterCount,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: tokens.onBrandContainer,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: GalaxyMetrics.space2),
            Text(
              'فصل',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tokens.onBrandContainer.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkTabClipper extends CustomClipper<Path> {
  const _BookmarkTabClipper();

  @override
  Path getClip(Size size) {
    final notchDepth = size.height * 0.14;
    final corner = size.width * 0.14;
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - corner)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - corner,
        size.height,
      )
      ..lineTo(size.width / 2, size.height - notchDepth)
      ..lineTo(corner, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - corner)
      ..close();
  }

  @override
  bool shouldReclip(covariant _BookmarkTabClipper oldClipper) => false;
}
