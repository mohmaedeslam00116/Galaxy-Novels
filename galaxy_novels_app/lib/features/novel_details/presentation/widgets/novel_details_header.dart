import 'package:flutter/material.dart';

import '../../../../data/models/novel_details_data.dart';
import '../../../../design_system/components/galaxy_badge.dart';
import '../../../../design_system/patterns/galaxy_novel_details_header.dart';
import '../../../../shared/widgets/novel_cover.dart';
import '../../../novel_engagement/application/novel_engagement_controller.dart';
import '../novel_details_visual_tokens.dart';
import 'novel_details_metadata_table.dart';

class NovelDetailsHeader extends StatelessWidget {
  const NovelDetailsHeader({
    required this.details,
    required this.chaptersCount,
    required this.engagementState,
    required this.onRate,
    required this.onSignIn,
    required this.onRetryEngagement,
    this.heroTag,
    super.key,
  });

  final NovelDetails details;
  final int chaptersCount;
  final NovelEngagementState engagementState;
  final VoidCallback onRate;
  final VoidCallback onSignIn;
  final VoidCallback onRetryEngagement;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final ratingAction = switch (engagementState.status) {
      NovelEngagementStatus.guest => onSignIn,
      NovelEngagementStatus.loading => null,
      NovelEngagementStatus.failure => onRetryEngagement,
      NovelEngagementStatus.ready =>
        engagementState.isSubmitting ? null : onRate,
    };
    final ratingLoading =
        engagementState.status == NovelEngagementStatus.loading ||
        engagementState.isSubmitting;
    final badges = <Widget>[
      if (details.statusLabel.isNotEmpty)
        GalaxyBadge(label: details.statusLabel, tone: GalaxyBadgeTone.success),
      if (engagementState.userState?.vip.active == true) const _VipBadge(),
    ];
    return GalaxyNovelDetailsHeader(
      key: const ValueKey('novel-details-hero'),
      variant: GalaxyNovelDetailsHeaderVariant.centeredPoster,
      title: details.title,
      cover: _CenteredCover(details: details, heroTag: heroTag),
      badges: badges,
      content: Column(
        children: [
          GalaxyStatsRail(
            items: [
              GalaxyStatItem(
                key: const ValueKey('novel-details-rating-action'),
                icon: Icons.star_rounded,
                value: details.ratingAverage > 0
                    ? '★ ${details.ratingAverage.toStringAsFixed(1)}'
                    : '—',
                label: _ratingLabel(engagementState),
                tooltip: 'اضغط لإضافة أو تعديل تقييمك',
                onTap: ratingAction,
                enabled: ratingAction != null,
                loading: ratingLoading,
              ),
              GalaxyStatItem(
                icon: Icons.visibility_outlined,
                value: _compactCount(details.views),
                label: 'المشاهدات',
              ),
              GalaxyStatItem(
                icon: Icons.menu_book_outlined,
                value: '$chaptersCount فصل',
                label: 'الفصول',
              ),
            ],
          ),
          const SizedBox(height: 16),
          NovelDetailsMetadataTable(details: details),
        ],
      ),
      footer: details.genres.isEmpty
          ? null
          : _GenreChips(genres: details.genres),
    );
  }
}

String _ratingLabel(NovelEngagementState state) {
  final personalRating = state.userState?.myRating ?? 0;
  return state.status == NovelEngagementStatus.ready && personalRating > 0
      ? 'تقييمك: $personalRating من 5'
      : 'التقييم';
}

class _CenteredCover extends StatelessWidget {
  const _CenteredCover({required this.details, this.heroTag});

  final NovelDetails details;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final tokens = NovelDetailsVisualTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final coverWidth = constraints.maxWidth.clamp(176.0, 224.0);
        final coverHeight = coverWidth / NovelCover.posterAspectRatio;
        final cover = DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.surfaceHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.primary.withValues(alpha: 0.32)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: NovelCover(
              title: details.title,
              imageUrl: details.bestCover,
              width: coverWidth - 16,
              height: coverHeight - 16,
              borderRadius: 14,
            ),
          ),
        );
        final animatedCover = heroTag == null
            ? cover
            : Hero(tag: heroTag!, transitionOnUserGestures: true, child: cover);
        return Semantics(
          image: true,
          label: 'غلاف رواية ${details.title}',
          child: animatedCover,
        );
      },
    );
  }
}

String _compactCount(int value) {
  if (value >= 1000000) {
    final result = value / 1000000;
    return '${result.toStringAsFixed(result >= 10 ? 0 : 1)}م';
  }
  if (value >= 1000) {
    final result = value / 1000;
    return '${result.toStringAsFixed(result >= 10 ? 0 : 1)}ألف';
  }
  return '$value';
}

class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.genres});

  final List<NovelGenre> genres;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('novel-details-genres'),
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [for (final genre in genres) GalaxyBadge(label: genre.name)],
    );
  }
}

class _VipBadge extends StatelessWidget {
  const _VipBadge();

  @override
  Widget build(BuildContext context) {
    return const GalaxyBadge(
      key: ValueKey('novel-details-vip-badge'),
      label: 'عضوية VIP فعالة',
      tone: GalaxyBadgeTone.warning,
      icon: Icons.workspace_premium_outlined,
    );
  }
}
