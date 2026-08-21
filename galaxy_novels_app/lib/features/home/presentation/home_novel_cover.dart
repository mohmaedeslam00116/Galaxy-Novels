import 'package:flutter/material.dart';

import '../../../shared/widgets/novel_cover.dart';
import '../domain/home_customization.dart';
import 'home_card_appearance.dart';

class HomeNovelCover extends StatelessWidget {
  const HomeNovelCover({
    required this.section,
    required this.customization,
    required this.title,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.heroTag,
    super.key,
  });

  final HomeSectionId section;
  final HomeCustomization customization;
  final String title;
  final String imageUrl;
  final double width;
  final double height;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final presentation = customization.coverPresentationFor(section);
    final scheme = Theme.of(context).colorScheme;
    final radius = customization.coverCorner.radius;

    final cover = SizedBox(
      key: ValueKey('home-cover-${section.name}-${presentation.name}'),
      width: width,
      height: height,
      child: switch (presentation) {
        HomeCoverPresentation.fill => NovelCover(
          title: title,
          imageUrl: imageUrl,
          width: width,
          height: height,
          borderRadius: radius,
        ),
        HomeCoverPresentation.fit => NovelCover(
          title: title,
          imageUrl: imageUrl,
          width: width,
          height: height,
          borderRadius: radius,
          fit: BoxFit.contain,
          backgroundColor: scheme.surfaceContainerHighest,
        ),
        HomeCoverPresentation.tonalFrame => DecoratedBox(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.10),
              scheme.surfaceContainerLow,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: LayoutBuilder(
              builder: (context, constraints) => NovelCover(
                title: title,
                imageUrl: imageUrl,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                borderRadius: (radius - 5).clamp(0, double.infinity),
                fit: BoxFit.contain,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
      },
    );
    if (heroTag == null || MediaQuery.disableAnimationsOf(context)) {
      return cover;
    }
    return Hero(tag: heroTag!, transitionOnUserGestures: true, child: cover);
  }
}
