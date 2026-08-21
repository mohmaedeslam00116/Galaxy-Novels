import 'package:flutter/material.dart';

import '../../../shared/widgets/app_skeleton.dart';

class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final posterWidth = ((width - 56) / 2.5).clamp(104.0, 144.0);
    return Semantics(
      label: 'جار تحميل الرئيسية...',
      liveRegion: true,
      child: Padding(
        key: const ValueKey('home-loading-skeleton'),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSkeleton(width: 126, height: 24, borderRadius: 6),
            const SizedBox(height: 12),
            const AppSkeleton(height: 172, borderRadius: 14),
            const SizedBox(height: 30),
            const AppSkeleton(width: 148, height: 22, borderRadius: 6),
            const SizedBox(height: 12),
            _PosterSkeletonRow(posterWidth: posterWidth),
            const SizedBox(height: 30),
            const AppSkeleton(width: 166, height: 22, borderRadius: 6),
            const SizedBox(height: 12),
            _PosterSkeletonRow(posterWidth: posterWidth),
          ],
        ),
      ),
    );
  }
}

class _PosterSkeletonRow extends StatelessWidget {
  const _PosterSkeletonRow({required this.posterWidth});

  final double posterWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: posterWidth * 1.5,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: posterWidth,
          child: AppSkeleton(
            width: posterWidth,
            height: posterWidth * 1.5,
            borderRadius: 12,
          ),
        ),
      ),
    );
  }
}
