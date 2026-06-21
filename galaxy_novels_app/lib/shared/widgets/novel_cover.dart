import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';

class NovelCover extends StatelessWidget {
  const NovelCover({
    required this.title,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 8,
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

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveImageUrl(context, imageUrl);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: resolvedUrl == null
            ? _CoverFallback(title: title)
            : Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _CoverFallback(title: title),
              ),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.surfaceRaised),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'غلاف',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: tokens.primary,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
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
