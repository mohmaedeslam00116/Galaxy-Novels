import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ads/application/rewarded_download_ad_repository.dart';
import '../../ads/application/reward_grant_verifier.dart';
import '../application/download_analytics.dart';
import '../application/download_repository.dart';
import '../domain/download_models.dart';
import 'download_quota_sheet.dart';

class DownloadQuotaPromptHost extends StatefulWidget {
  const DownloadQuotaPromptHost({
    required this.repository,
    required this.rewardedAds,
    required this.child,
    this.rewardVerifier = const LocalRewardGrantVerifier(),
    this.downloadAnalytics = const NoopDownloadAnalytics(),
    super.key,
  });

  final DownloadRepository repository;
  final RewardedDownloadAdRepository rewardedAds;
  final Widget child;
  final RewardGrantVerifier rewardVerifier;
  final DownloadAnalytics downloadAnalytics;

  @override
  State<DownloadQuotaPromptHost> createState() =>
      _DownloadQuotaPromptHostState();
}

class _DownloadQuotaPromptHostState extends State<DownloadQuotaPromptHost> {
  int _seenGeneration = 0;
  bool _sheetOpen = false;
  bool _showingAd = false;
  final Map<String, DownloadGroupStatus> _observedGroupStatuses = {};
  final Set<String> _reportedCompletedGroups = {};
  final Set<String> _reportedFailedGroups = {};

  @override
  void initState() {
    super.initState();
    _seedObservedGroups(widget.repository.value.groups);
    widget.repository.addListener(_schedulePromptCheck);
    _schedulePromptCheck();
  }

  @override
  void didUpdateWidget(covariant DownloadQuotaPromptHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository == widget.repository) return;
    oldWidget.repository.removeListener(_schedulePromptCheck);
    widget.repository.addListener(_schedulePromptCheck);
    _observedGroupStatuses.clear();
    _reportedCompletedGroups.clear();
    _reportedFailedGroups.clear();
    _seedObservedGroups(widget.repository.value.groups);
    _seenGeneration = 0;
    _schedulePromptCheck();
  }

  @override
  void dispose() {
    widget.repository.removeListener(_schedulePromptCheck);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _schedulePromptCheck() {
    _observeGroupOutcomes(widget.repository.value);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPromptIfNeeded());
  }

  void _observeGroupOutcomes(DownloadsDashboard dashboard) {
    final membershipTier = downloadMembershipLabel(dashboard.allowance.plan);
    for (final group in dashboard.groups) {
      final previous = _observedGroupStatuses[group.groupId];
      _observedGroupStatuses[group.groupId] = group.status;
      if (previous == group.status) continue;
      if (group.status == DownloadGroupStatus.completed &&
          _reportedCompletedGroups.add(group.groupId)) {
        unawaited(
          widget.downloadAnalytics.record(
            DownloadAnalyticsEvent.groupCompleted(
              chapterCount: group.jobs.length,
              membershipTier: membershipTier,
            ),
          ),
        );
      } else if (group.jobs.any(
            (job) => job.status == DownloadJobStatus.failed,
          ) &&
          _reportedFailedGroups.add(group.groupId)) {
        unawaited(
          widget.downloadAnalytics.record(
            DownloadAnalyticsEvent.groupFailed(
              chapterCount: group.jobs.length,
              membershipTier: membershipTier,
            ),
          ),
        );
      }
    }
  }

  void _seedObservedGroups(List<DownloadGroup> groups) {
    for (final group in groups) {
      _observedGroupStatuses[group.groupId] = group.status;
      if (group.status == DownloadGroupStatus.completed) {
        _reportedCompletedGroups.add(group.groupId);
      }
      if (group.jobs.any((job) => job.status == DownloadJobStatus.failed)) {
        _reportedFailedGroups.add(group.groupId);
      }
    }
  }

  Future<void> _showPromptIfNeeded() async {
    if (!mounted || _sheetOpen) return;
    final dashboard = widget.repository.value;
    if (dashboard.quotaBlockGeneration <= _seenGeneration) return;
    _seenGeneration = dashboard.quotaBlockGeneration;
    if (dashboard.allowance.canWatchRewardedAd) {
      unawaited(widget.rewardedAds.preload());
    }
    unawaited(
      widget.downloadAnalytics.record(
        DownloadAnalyticsEvent.quotaExhausted(
          waitingCount: _waitingDownloadCount(dashboard.groups),
          adsRemaining: dashboard.allowance.adsRemaining,
          membershipTier: downloadMembershipLabel(dashboard.allowance.plan),
        ),
      ),
    );
    _sheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => ValueListenableBuilder(
          valueListenable: widget.rewardedAds,
          builder: (context, availability, _) => DownloadQuotaSheet(
            dashboard: dashboard,
            showingAd: _showingAd,
            adAvailability: availability,
            onWatch: () => _watchAd(sheetContext),
          ),
        ),
      );
    } finally {
      _sheetOpen = false;
    }
  }

  Future<void> _watchAd(BuildContext sheetContext) async {
    final allowance = widget.repository.value.allowance;
    Navigator.of(sheetContext).pop();
    setState(() => _showingAd = true);
    try {
      unawaited(
        widget.downloadAnalytics.record(
          DownloadAnalyticsEvent.reward(
            stage: 'started',
            rewardAmount: allowance.plan.rewardPerAd,
            adsRemaining: allowance.adsRemaining,
            membershipTier: downloadMembershipLabel(allowance.plan),
          ),
        ),
      );
      final reward = await widget.rewardedAds.show();
      if (reward.status == RewardedDownloadAdStatus.earned &&
          reward.rewardEventId != null) {
        unawaited(
          widget.downloadAnalytics.record(
            DownloadAnalyticsEvent.reward(
              stage: 'completed',
              rewardAmount: allowance.plan.rewardPerAd,
              adsRemaining: allowance.adsRemaining,
              membershipTier: downloadMembershipLabel(allowance.plan),
            ),
          ),
        );
        final verified = await widget.rewardVerifier.verify(
          RewardGrantClaim(
            rewardEventId: reward.rewardEventId!,
            rewardType: downloadChaptersRewardType,
          ),
        );
        if (verified) {
          await widget.repository.grantReward(
            rewardEventId: reward.rewardEventId!,
          );
          unawaited(
            widget.downloadAnalytics.record(
              DownloadAnalyticsEvent.reward(
                stage: 'granted',
                rewardAmount: allowance.plan.rewardPerAd,
                adsRemaining: widget.repository.value.allowance.adsRemaining,
                membershipTier: downloadMembershipLabel(allowance.plan),
              ),
            ),
          );
          unawaited(
            widget.downloadAnalytics.record(
              DownloadAnalyticsEvent.reward(
                stage: 'queue_resumed',
                rewardAmount: allowance.plan.rewardPerAd,
                adsRemaining: widget.repository.value.allowance.adsRemaining,
                membershipTier: downloadMembershipLabel(allowance.plan),
              ),
            ),
          );
        } else if (mounted) {
          _showUnavailableMessage(RewardedDownloadAdStatus.unavailable);
        }
      } else if (mounted) {
        _showUnavailableMessage(reward.status);
      }
    } on PlatformException {
      if (mounted) {
        _showUnavailableMessage(RewardedDownloadAdStatus.unavailable);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر إضافة رصيد التنزيل الآن، حاول مرة أخرى.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _showingAd = false);
    }
  }

  void _showUnavailableMessage(RewardedDownloadAdStatus status) {
    final message = status == RewardedDownloadAdStatus.dismissed
        ? 'أكمل مشاهدة الإعلان للحصول على الفصول الإضافية'
        : 'الإعلان غير متاح الآن، حاول بعد قليل';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

int _waitingDownloadCount(List<DownloadGroup> groups) {
  return groups
      .expand((group) => group.jobs)
      .where(
        (job) =>
            job.status != DownloadJobStatus.completed &&
            job.status != DownloadJobStatus.canceled,
      )
      .length;
}
