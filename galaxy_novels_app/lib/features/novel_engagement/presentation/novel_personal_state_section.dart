import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../application/novel_engagement_controller.dart';

class NovelPersonalStateSection extends StatelessWidget {
  const NovelPersonalStateSection({
    required this.state,
    required this.onRate,
    required this.onSignIn,
    required this.onRetry,
    super.key,
  });

  final NovelEngagementState state;
  final VoidCallback onRate;
  final VoidCallback onSignIn;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface.withValues(alpha: 0.58),
        border: Border.symmetric(horizontal: BorderSide(color: tokens.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _contentFor(state),
        ),
      ),
    );
  }

  Widget _contentFor(NovelEngagementState state) {
    return switch (state.status) {
      NovelEngagementStatus.guest => _GuestRatingAction(onPressed: onSignIn),
      NovelEngagementStatus.loading => const _PersonalStateSkeleton(),
      NovelEngagementStatus.failure => _PersonalStateFailure(
        message: state.errorMessage,
        onRetry: onRetry,
      ),
      NovelEngagementStatus.ready => _ReadyPersonalState(
        state: state,
        onRate: onRate,
      ),
    };
  }
}

class _GuestRatingAction extends StatelessWidget {
  const _GuestRatingAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('novel-personal-state-guest'),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.star_outline_rounded),
        label: const Text('سجّل الدخول للتقييم'),
      ),
    );
  }
}

class _PersonalStateSkeleton extends StatelessWidget {
  const _PersonalStateSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Row(
      key: const ValueKey('novel-personal-state-loading'),
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 12, width: 92, color: tokens.surfaceRaised),
              const SizedBox(height: 9),
              Container(height: 10, width: 138, color: tokens.surfaceRaised),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonalStateFailure extends StatelessWidget {
  const _PersonalStateFailure({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Row(
      key: const ValueKey('novel-personal-state-failure'),
      children: [
        Icon(Icons.cloud_off_outlined, color: tokens.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message ?? 'تعذر تحميل حالتك مع الرواية.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
      ],
    );
  }
}

class _ReadyPersonalState extends StatelessWidget {
  const _ReadyPersonalState({required this.state, required this.onRate});

  final NovelEngagementState state;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final vipActive = state.userState?.vip.active ?? false;

    return LayoutBuilder(
      key: const ValueKey('novel-personal-state-ready'),
      builder: (context, constraints) {
        final rating = Expanded(
          child: _RatingAction(
            rating: state.userState?.myRating ?? 0,
            onPressed: onRate,
          ),
        );
        final vip = vipActive ? const _VipBadge() : null;
        if (constraints.maxWidth < 344 && vip != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [rating]),
              const SizedBox(height: 8),
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: _VipBadge(),
              ),
            ],
          );
        }
        return Row(
          children: [
            rating,
            if (vip != null) ...[const SizedBox(width: 10), vip],
          ],
        );
      },
    );
  }
}

class _RatingAction extends StatelessWidget {
  const _RatingAction({required this.rating, required this.onPressed});

  final int rating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final value = rating > 0 ? '$rating من 5' : 'لم تقيّم بعد';

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        minimumSize: const Size(0, 54),
      ),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: tokens.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تقييمك',
                  maxLines: 1,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VipBadge extends StatelessWidget {
  const _VipBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.gold.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_outlined, color: tokens.gold, size: 18),
          const SizedBox(width: 6),
          Text(
            'عضوية VIP فعالة',
            style: theme.textTheme.labelMedium?.copyWith(
              color: tokens.gold,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
