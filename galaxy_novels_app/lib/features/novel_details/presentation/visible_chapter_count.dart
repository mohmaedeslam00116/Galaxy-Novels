import 'dart:math' as math;

import '../../vip/application/vip_chapters_controller.dart';

int visibleNovelChapterCount({
  required int publicChapterCount,
  required int loadedPublicChapterCount,
  required bool canReadPrivate,
  required VipChaptersState vipState,
}) {
  final publicTotal = math.max(publicChapterCount, loadedPublicChapterCount);
  if (!canReadPrivate || vipState.status != VipChaptersStatus.ready) {
    return publicTotal;
  }

  final privateTotal = math.max(
    vipState.totalAvailable,
    vipState.chapters.length,
  );
  return publicTotal + privateTotal;
}
