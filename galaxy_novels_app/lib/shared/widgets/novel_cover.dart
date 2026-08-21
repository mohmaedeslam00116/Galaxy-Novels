import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../design_system/novel/galaxy_novel_cover.dart';

class NovelCover extends StatelessWidget {
  const NovelCover({
    required this.title,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.backgroundColor,
    super.key,
  });

  const NovelCover.poster({
    required String title,
    required String imageUrl,
    Key? key,
  }) : this(
         title: title,
         imageUrl: imageUrl,
         width: posterWidth,
         height: posterHeight,
         key: key,
       );

  const NovelCover.list({
    required String title,
    required String imageUrl,
    Key? key,
  }) : this(
         title: title,
         imageUrl: imageUrl,
         width: listWidth,
         height: listHeight,
         borderRadius: 6,
         key: key,
       );

  const NovelCover.detail({
    required String title,
    required String imageUrl,
    Key? key,
  }) : this(
         title: title,
         imageUrl: imageUrl,
         width: detailWidth,
         height: detailHeight,
         key: key,
       );

  static const double posterWidth = 112;
  static const double posterAspectRatio = 0.70;
  static const double posterHeight = posterWidth / posterAspectRatio;
  static const double listWidth = 64;
  static const double listHeight = 92;
  static const double detailWidth = 154;
  static const double detailHeight = 230;

  final String title;
  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveImageUrl(context, imageUrl);
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: backgroundColor ?? Colors.transparent,
        child: GalaxyNovelCover(
          artwork: GalaxyNovelArtwork(
            title: title,
            image: resolvedUrl == null ? null : NetworkImage(resolvedUrl),
          ),
          presentation: fit == BoxFit.cover
              ? GalaxyCoverPresentation.fill
              : GalaxyCoverPresentation.fit,
          radius: borderRadius,
        ),
      ),
    );
  }
}

String? _resolveImageUrl(BuildContext context, String url) {
  if (url.isEmpty) {
    return null;
  }

  try {
    return AppDependencies.of(context).config.resolve(url).toString();
  } on Object {
    return null;
  }
}
