import 'package:flutter/material.dart';

import '../../../design_system/galaxy_design_system.dart';
import '../../ads/application/rewarded_download_ad_repository.dart';
import '../domain/download_models.dart';

class DownloadQuotaSheet extends StatelessWidget {
  const DownloadQuotaSheet({
    required this.dashboard,
    required this.showingAd,
    required this.onWatch,
    required this.adAvailability,
    super.key,
  });

  final DownloadsDashboard dashboard;
  final bool showingAd;
  final VoidCallback onWatch;
  final RewardedDownloadAdAvailability adAvailability;

  @override
  Widget build(BuildContext context) {
    final allowance = dashboard.allowance;
    final usedAds = allowance.plan.maxRewardedAds - allowance.adsRemaining;
    final progress = _quotaProgress(dashboard.groups);
    final canWatchReward = allowance.canWatchRewardedAd;
    return GalaxyBottomSheet(
      title: 'انتهت التنزيلات المجانية لليوم',
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.62,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GalaxySurface(
                variant: GalaxySurfaceVariant.tonal,
                padding: const EdgeInsets.all(GalaxyMetrics.space16),
                child: Column(
                  children: [
                    Text(
                      canWatchReward
                          ? '+${allowance.plan.rewardPerAd} فصلًا'
                          : 'اكتملت إعلانات اليوم',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: GalaxyMetrics.space4),
                    Text(
                      canWatchReward
                          ? 'متبقي ${allowance.adsRemaining} من ${allowance.plan.maxRewardedAds} إعلانات اليوم'
                          : 'الطابور محفوظ وسيتجدد الرصيد عند 12:00 منتصف الليل',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: GalaxyMetrics.space12),
                Text(
                  'اكتمل ${progress.completed} من ${progress.total}، '
                  'تبقى ${progress.remaining}',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: GalaxyMetrics.space16),
              Text(
                canWatchReward
                    ? adAvailability ==
                              RewardedDownloadAdAvailability.unavailable
                          ? 'الإعلان غير متاح الآن، لكن الطابور محفوظ ويمكن إعادة المحاولة دون فقدانه.'
                          : 'بعد اكتمال الإعلان تُضاف الفصول إلى رصيد اليوم ويُستأنف الطابور تلقائيًا.'
                    : 'لا تحتاج إلى إعادة اختيار الفصول؛ سيُستأنف الطابور تلقائيًا بعد تجدد الحصة.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      actions: canWatchReward
          ? [
              GalaxyButton(
                label: switch (adAvailability) {
                  RewardedDownloadAdAvailability.loading =>
                    'جارٍ تجهيز الإعلان…',
                  RewardedDownloadAdAvailability.showing =>
                    'الإعلان معروض الآن…',
                  RewardedDownloadAdAvailability.unavailable =>
                    'إعادة محاولة تجهيز الإعلان',
                  RewardedDownloadAdAvailability.idle ||
                  RewardedDownloadAdAvailability.ready =>
                    'مشاهدة إعلان (${usedAds + 1})',
                },
                icon: Icons.ondemand_video_rounded,
                onPressed:
                    showingAd ||
                        adAvailability ==
                            RewardedDownloadAdAvailability.loading ||
                        adAvailability == RewardedDownloadAdAvailability.showing
                    ? null
                    : onWatch,
              ),
            ]
          : const [],
    );
  }
}

({int completed, int total, int remaining})? _quotaProgress(
  List<DownloadGroup> groups,
) {
  DownloadGroup? candidate;
  for (final group in groups) {
    final hasWaiting = group.jobs.any(
      (job) =>
          job.status != DownloadJobStatus.completed &&
          job.status != DownloadJobStatus.canceled,
    );
    if (!hasWaiting) continue;
    if (candidate == null || group.updatedAtUtcMs > candidate.updatedAtUtcMs) {
      candidate = group;
    }
  }
  if (candidate == null) return null;
  final relevant = candidate.jobs
      .where((job) => job.status != DownloadJobStatus.canceled)
      .toList(growable: false);
  final completed = relevant
      .where((job) => job.status == DownloadJobStatus.completed)
      .length;
  return (
    completed: completed,
    total: relevant.length,
    remaining: relevant.length - completed,
  );
}
