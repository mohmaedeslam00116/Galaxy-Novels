import 'package:flutter/foundation.dart';

@immutable
class NovelDetailsTransitionData {
  const NovelDetailsTransitionData({
    required this.heroTag,
    required this.title,
    required this.coverUrl,
  });

  final Object heroTag;
  final String title;
  final String coverUrl;
}
