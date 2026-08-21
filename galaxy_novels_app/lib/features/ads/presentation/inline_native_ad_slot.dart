import 'package:flutter/widgets.dart';

import '../../../app/app_dependencies.dart';
import '../application/inline_native_ad_repository.dart';
import 'standard_ad_gate.dart';

class InlineNativeAdSlot extends StatelessWidget {
  const InlineNativeAdSlot({required this.placement, super.key});

  final InlineNativeAdPlacement placement;

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    return StandardAdGate(
      authRepository: dependencies.authRepository,
      builder: (context) {
        final ad = dependencies.inlineNativeAdRepository.buildNativeAd(
          context,
          placement: placement,
        );
        if (ad == null) return const SizedBox.shrink();
        return KeyedSubtree(
          key: ValueKey('inline-native-ad-slot-${placement.name}'),
          child: ad,
        );
      },
    );
  }
}
