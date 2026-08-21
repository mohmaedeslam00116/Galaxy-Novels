import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_skeleton.dart';

class RankingsLoadingState extends StatelessWidget {
  const RankingsLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'جارٍ تحميل الترتيب...',
      excludeSemantics: true,
      child: ListView(
        key: const ValueKey('rankings-loading-state'),
        padding: const EdgeInsets.all(12),
        children: const [
          AppSkeleton(height: 64),
          SizedBox(height: 12),
          AppSkeleton(height: 236),
          SizedBox(height: 16),
          AppSkeleton(height: 72),
          SizedBox(height: 1),
          AppSkeleton(height: 72),
          SizedBox(height: 1),
          AppSkeleton(height: 72),
        ],
      ),
    );
  }
}
