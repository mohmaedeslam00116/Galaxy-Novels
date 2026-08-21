import 'package:flutter/widgets.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/analytics/app_screen_names.dart';
import '../../../design_system/foundation/galaxy_route.dart';
import '../../ads/application/standard_ad_visibility_policy.dart';
import 'novel_details_screen.dart';
import 'novel_details_transition.dart';

class NovelDetailsNavigation {
  const NovelDetailsNavigation._();

  static bool _pushStarting = false;

  static Future<void> open(
    BuildContext context, {
    required String manifestPath,
    NovelDetailsTransitionData? transition,
  }) async {
    if (manifestPath.trim().isEmpty || _pushStarting) return;
    _pushStarting = true;
    try {
      final dependencies = AppDependencies.of(context);
      final canShowAd = StandardAdVisibilityPolicy.canShow(
        dependencies.authRepository.value,
      );
      try {
        await dependencies.fullScreenAdRepository.showBrowseInterstitial(
          canShow: canShowAd,
        );
      } on Exception {
        // Advertising must never block access to novel details.
      }
      if (!context.mounted) return;
      Navigator.of(context).push(
        galaxyPageRoute<void>(
          context: context,
          settings: const RouteSettings(name: AppScreenNames.novelDetails),
          builder: (context) => NovelDetailsScreen(
            manifestPath: manifestPath,
            transition: transition,
          ),
        ),
      );
    } finally {
      _pushStarting = false;
    }
  }
}
