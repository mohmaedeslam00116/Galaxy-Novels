import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/repositories/downloads_repository.dart';
import '../../../shared/widgets/novel_cover.dart';
import '../../ads/application/rewarded_ad_repository.dart';
import '../../rewards/application/reader_rewards_repository.dart';
import '../application/download_manager.dart';
import '../domain/downloaded_novel_group.dart';
import 'downloaded_novel_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({this.onOpenLibrary, super.key});

  final VoidCallback? onOpenLibrary;

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  DownloadsRepository? _repository;
  ReaderRewardsRepository? _rewardsRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final dependencies = AppDependencies.of(context);
    final repository = dependencies.downloadsRepository;

    if (_repository != repository) {
      _repository = repository;
      unawaited(repository.load());
    }

    final rewardsRepository = dependencies.readerRewardsRepository;
    if (_rewardsRepository != rewardsRepository) {
      _rewardsRepository = rewardsRepository;
      unawaited(rewardsRepository.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final repository = _repository ?? dependencies.downloadsRepository;
    final downloadManager = dependencies.downloadManager;

    return SafeArea(
      top: false,
      child: ValueListenableBuilder<DownloadManagerState>(
        valueListenable: downloadManager.state,
        builder: (context, jobState, _) {
          return ValueListenableBuilder<DownloadsState>(
            valueListenable: repository.state,
            builder: (context, downloadsState, _) {
              final groups = groupDownloadedChapters(downloadsState.chapters);
              final totalBytes = groups.fold(
                0,
                (total, group) => total + group.totalBytes,
              );

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        sliver: SliverList.list(
                          children: [
                            const _DownloadsHeroHeader(),
                            const SizedBox(height: 12),
                            _DownloadsCountBanner(
                              state: downloadsState,
                              totalBytes: totalBytes,
                            ),
                            const SizedBox(height: 10),
                            _DownloadPointsBanner(
                              rewardsRepository:
                                  dependencies.readerRewardsRepository,
                              rewardedAdRepository:
                                  dependencies.rewardedAdRepository,
                            ),
                            if (_showJobBanner(jobState)) ...[
                              const SizedBox(height: 10),
                              _DownloadJobBanner(
                                state: jobState,
                                onTap: downloadManager.showOverlay,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (groups.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _DownloadsEmptyState(
                            onOpenLibrary: widget.onOpenLibrary,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList.builder(
                            itemCount: groups.length,
                            itemBuilder: (context, index) {
                              final group = groups[index];
                              return Column(
                                children: [
                                  _DownloadedNovelRow(
                                    group: group,
                                    onTap: () => _openNovel(group.novelId),
                                  ),
                                  if (index < groups.length - 1)
                                    const Divider(height: 1),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openNovel(int novelId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DownloadedNovelScreen(novelId: novelId),
      ),
    );
  }
}

bool _showJobBanner(DownloadManagerState state) {
  return state.progress != null &&
      (state.isActive || state.status == DownloadJobStatus.failed);
}

class _DownloadsHeroHeader extends StatelessWidget {
  const _DownloadsHeroHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 2),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.download_for_offline_rounded,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مركز التنزيلات',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تابع الرصيد والتحميلات والقراءة دون اتصال من مكان واحد.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

class _DownloadPointsBanner extends StatefulWidget {
  const _DownloadPointsBanner({
    required this.rewardsRepository,
    required this.rewardedAdRepository,
  });

  final ReaderRewardsRepository rewardsRepository;
  final RewardedAdRepository rewardedAdRepository;

  @override
  State<_DownloadPointsBanner> createState() => _DownloadPointsBannerState();
}

class _DownloadPointsBannerState extends State<_DownloadPointsBanner> {
  bool _isShowingAd = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ValueListenableBuilder<ReaderRewardsState>(
      valueListenable: widget.rewardsRepository.state,
      builder: (context, rewardsState, _) {
        final watched = rewardsState.clampedRewardedAdsWatchedToday;
        final max = ReaderRewardsState.maxRewardedAdsPerDay;
        final canWatch = rewardsState.canWatchRewardedAd && !_isShowingAd;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded, color: colors.tertiary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'نقاط التنزيل',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${rewardsState.points} نقطة',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.tertiary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'كل فيديو يمنحك 25 نقطة. كل فصل يكلف نقطة واحدة. '
                  'إذا فشل تنزيل فصل، ترجع نقطته تلقائيا.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: rewardsState.rewardedAdsProgress,
                    backgroundColor: colors.surface,
                    color: colors.tertiary,
                  ),
                ),
                const SizedBox(height: 9),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 330;
                    final limitText = Text(
                      'شاهدت $watched / $max اليوم. المتبقي '
                      '${rewardsState.remainingRewardedAdsToday} فيديو. '
                      'قريبا سنضيف طرقا جديدة لزيادة نقاطك.',
                      maxLines: isCompact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    );
                    final action = FilledButton.tonalIcon(
                      key: const ValueKey('download-rewarded-ad-button'),
                      onPressed: canWatch ? _watchRewardedAd : null,
                      icon: _isShowingAd
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_circle_outline_rounded),
                      label: Text(
                        _isShowingAd
                            ? 'جاري فتح الإعلان'
                            : rewardsState.canWatchRewardedAd
                            ? (isCompact ? 'فيديو +25' : 'شاهد فيديو +25')
                            : (isCompact ? 'تم الحد' : 'تم الحد اليومي'),
                      ),
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          limitText,
                          const SizedBox(height: 10),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: action,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: limitText),
                        const SizedBox(width: 10),
                        action,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _watchRewardedAd() async {
    if (_isShowingAd) {
      return;
    }
    setState(() => _isShowingAd = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final outcome = await widget.rewardedAdRepository.showRewardedAd();
      if (!mounted) {
        return;
      }
      if (outcome == RewardedAdOutcome.earnedReward) {
        widget.rewardsRepository.grantRewardedAdPoints();
        messenger.showSnackBar(
          const SnackBar(content: Text('تمت إضافة 25 نقطة إلى رصيدك')),
        );
        return;
      }

      final message = switch (outcome) {
        RewardedAdOutcome.unavailable => 'الإعلان غير متاح الآن، حاول لاحقا.',
        RewardedAdOutcome.dismissed => 'أكمل مشاهدة الإعلان للحصول على النقاط.',
        RewardedAdOutcome.failed => 'تعذر تشغيل الإعلان الآن.',
        RewardedAdOutcome.earnedReward => 'تمت إضافة 25 نقطة إلى رصيدك',
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on RewardedAdDailyLimitException {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('وصلت إلى حد المشاهدات اليومي.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isShowingAd = false);
      }
    }
  }
}

class _DownloadsCountBanner extends StatelessWidget {
  const _DownloadsCountBanner({required this.state, required this.totalBytes});

  final DownloadsState state;
  final int totalBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.offline_pin_rounded, color: colors.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${state.downloadedCount} / ${state.maxChapters} فصل محمل',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatDownloadSize(totalBytes),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.secondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadJobBanner extends StatelessWidget {
  const _DownloadJobBanner({required this.state, required this.onTap});

  final DownloadManagerState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final progress = state.progress!;
    final isPaused = state.status == DownloadJobStatus.paused;
    final isFailed = state.status == DownloadJobStatus.failed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              isFailed
                  ? Icons.error_outline_rounded
                  : isPaused
                  ? Icons.pause_circle_outline_rounded
                  : Icons.downloading_rounded,
              color: isFailed ? colors.error : colors.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isFailed
                    ? 'تعذر إكمال التنزيل'
                    : isPaused
                    ? 'التنزيل متوقف مؤقتا'
                    : 'جاري تحميل ${progress.completed + progress.failed} من ${progress.total}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isFailed ? colors.error : colors.onSecondaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DownloadedNovelRow extends StatelessWidget {
  const _DownloadedNovelRow({required this.group, required this.onTap});

  final DownloadedNovelGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            NovelCover.list(
              title: group.novelTitle,
              imageUrl: group.novelCover,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.novelTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${group.downloadedCount} فصل  •  ${formatDownloadSize(group.totalBytes)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'الأحدث: ${group.latestChapter.chapterLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_left_rounded, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _DownloadsEmptyState extends StatelessWidget {
  const _DownloadsEmptyState({required this.onOpenLibrary});

  final VoidCallback? onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 48, 8, 0),
      child: Column(
        children: [
          Icon(
            Icons.download_for_offline_outlined,
            color: colors.secondary,
            size: 44,
          ),
          const SizedBox(height: 16),
          Text(
            'الفصول التي تحملها ستظهر هنا للقراءة بدون إنترنت',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onOpenLibrary,
            child: const Text('فتح المكتبة'),
          ),
        ],
      ),
    );
  }
}
