import 'package:flutter/foundation.dart';

import '../domain/home_customization.dart';

class HomeNovelOpenRequest {
  const HomeNovelOpenRequest({
    required this.manifestPath,
    required this.heroTag,
    required this.title,
    required this.coverUrl,
  });

  final String manifestPath;
  final Object heroTag;
  final String title;
  final String coverUrl;
}

String homeNovelHeroTag(HomeSectionId section, Object uniqueId) =>
    'home-cover:${section.name}:$uniqueId';

void dispatchHomeNovelOpen({
  required HomeNovelOpenRequest request,
  required ValueChanged<HomeNovelOpenRequest>? enhancedOpen,
  required ValueChanged<String> legacyOpen,
}) {
  if (enhancedOpen != null) {
    enhancedOpen(request);
    return;
  }
  legacyOpen(request.manifestPath);
}
