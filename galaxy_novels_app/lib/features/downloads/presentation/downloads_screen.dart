import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/analytics/app_screen_names.dart';
import '../../../data/repositories/reading_history_repository.dart';
import '../../../design_system/galaxy_design_system.dart';
import '../../ads/application/rewarded_download_ad_repository.dart';
import '../../ads/application/reward_grant_verifier.dart';
import '../application/download_repository.dart';
import '../application/download_analytics.dart';
import '../domain/download_models.dart';
import 'download_artwork.dart';
import 'download_quota_sheet.dart';
import 'downloaded_novel_screen.dart';
import 'downloads_help_sheet.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({
    required this.repository,
    required this.rewardedAds,
    this.readingHistoryRepository,
    this.onOpenLibrary,
    this.rewardVerifier = const LocalRewardGrantVerifier(),
    this.downloadAnalytics = const NoopDownloadAnalytics(),
    super.key,
  });

  final DownloadRepository repository;
  final RewardedDownloadAdRepository rewardedAds;
  final ReadingHistoryRepository? readingHistoryRepository;
  final VoidCallback? onOpenLibrary;
  final RewardGrantVerifier rewardVerifier;
  final DownloadAnalytics downloadAnalytics;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('downloads-screen'),
      appBar: AppBar(title: const Text('التنزيلات')),
      body: DownloadsView(
        repository: repository,
        rewardedAds: rewardedAds,
        readingHistoryRepository: readingHistoryRepository,
        onOpenLibrary: onOpenLibrary,
        rewardVerifier: rewardVerifier,
        downloadAnalytics: downloadAnalytics,
      ),
    );
  }
}

class DownloadsView extends StatefulWidget {
  const DownloadsView({
    required this.repository,
    required this.rewardedAds,
    this.readingHistoryRepository,
    this.onOpenLibrary,
    this.rewardVerifier = const LocalRewardGrantVerifier(),
    this.downloadAnalytics = const NoopDownloadAnalytics(),
    super.key,
  });

  final DownloadRepository repository;
  final RewardedDownloadAdRepository rewardedAds;
  final ReadingHistoryRepository? readingHistoryRepository;
  final VoidCallback? onOpenLibrary;
  final RewardGrantVerifier rewardVerifier;
  final DownloadAnalytics downloadAnalytics;

  @override
  State<DownloadsView> createState() => _DownloadsViewState();
}

class _DownloadsViewState extends State<DownloadsView>
    with AutomaticKeepAliveClientMixin {
  bool _showingAd = false;
  bool _rewardSheetOpen = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      top: false,
      child: ValueListenableBuilder<DownloadsDashboard>(
        valueListenable: widget.repository,
        builder: (context, dashboard, child) {
          if (dashboard.isInitializing) {
            return const _DownloadsSkeleton();
          }
          return _DownloadsDashboardView(
            dashboard: dashboard,
            showingAd: _showingAd,
            onReward: () => _showReward(dashboard),
            onOpenOptions: () => _showOptions(dashboard),
            onOpenQueue: _showQueue,
            onOpenNovel: _openDownloadedNovel,
            onOpenLibrary: widget.onOpenLibrary,
          );
        },
      ),
    );
  }

  void _openDownloadedNovel(DownloadedNovel novel) {
    Navigator.of(context).push(
      galaxyPageRoute<void>(
        context: context,
        settings: const RouteSettings(name: AppScreenNames.downloadedNovel),
        builder: (context) => DownloadedNovelScreen(
          repository: widget.repository,
          novelId: novel.novelId,
          readingHistoryRepository: widget.readingHistoryRepository,
        ),
      ),
    );
  }

  Future<void> _showOptions(DownloadsDashboard dashboard) async {
    var wifiOnly = dashboard.wifiOnly;
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> updateWifi(bool value) async {
            if (saving) return;
            final previous = wifiOnly;
            setSheetState(() {
              wifiOnly = value;
              saving = true;
            });
            try {
              await widget.repository.setWifiOnly(value);
            } catch (_) {
              if (!sheetContext.mounted) return;
              setSheetState(() => wifiOnly = previous);
              _showMessage('تعذر حفظ إعداد Wi‑Fi. أُعيد الخيار السابق.');
            } finally {
              if (sheetContext.mounted) {
                setSheetState(() => saving = false);
              }
            }
          }

          return GalaxyBottomSheet(
            title: 'خيارات التنزيل',
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.62,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GalaxySurface(
                      variant: GalaxySurfaceVariant.base,
                      child: SwitchListTile(
                        key: const ValueKey('downloads-wifi-only'),
                        title: const Text('التنزيل عبر Wi‑Fi فقط'),
                        subtitle: Text(
                          saving ? 'جارٍ الحفظ…' : 'يحمي بيانات الهاتف المحمول',
                        ),
                        value: wifiOnly,
                        onChanged: saving ? null : updateWifi,
                      ),
                    ),
                    const SizedBox(height: GalaxyMetrics.space12),
                    GalaxyButton(
                      key: const ValueKey('downloads-help'),
                      label: 'كيف تعمل التنزيلات؟',
                      icon: Icons.help_outline_rounded,
                      variant: GalaxyActionVariant.secondary,
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) showDownloadsHelpSheet(context);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showQueue() async {
    final groups = _activeGroups(widget.repository.value.groups);
    if (groups.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DownloadQueueSheet(
        repository: widget.repository,
        onPause: _pauseGroup,
        onResume: _resumeGroup,
        onCancel: _confirmCancelGroup,
        onRetry: _retryJob,
      ),
    );
  }

  Future<void> _showReward(DownloadsDashboard dashboard) async {
    if (_rewardSheetOpen) return;
    _rewardSheetOpen = true;
    unawaited(
      widget.downloadAnalytics.record(
        DownloadAnalyticsEvent.reward(
          stage: 'prompt_shown',
          rewardAmount: dashboard.allowance.plan.rewardPerAd,
          adsRemaining: dashboard.allowance.adsRemaining,
          membershipTier: downloadMembershipLabel(dashboard.allowance.plan),
        ),
      ),
    );
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
            onWatch: () => _watchRewardedAd(sheetContext),
          ),
        ),
      );
    } finally {
      _rewardSheetOpen = false;
    }
  }

  Future<void> _watchRewardedAd(BuildContext sheetContext) async {
    final allowance = widget.repository.value.allowance;
    Navigator.of(sheetContext).pop();
    if (!mounted) return;
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
          _showAdOutcome(RewardedDownloadAdStatus.unavailable);
        }
      } else if (mounted) {
        _showAdOutcome(reward.status);
      }
    } on PlatformException {
      if (mounted) _showAdOutcome(RewardedDownloadAdStatus.unavailable);
    } catch (_) {
      if (mounted) {
        _showMessage('تعذر إضافة رصيد التنزيل الآن، حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _showingAd = false);
    }
  }

  void _showAdOutcome(RewardedDownloadAdStatus status) {
    _showMessage(
      status == RewardedDownloadAdStatus.dismissed
          ? 'أكمل مشاهدة الإعلان للحصول على الفصول الإضافية'
          : 'الإعلان غير متاح الآن، حاول بعد قليل',
    );
  }

  Future<void> _pauseGroup(String groupId) => _runGroupAction(
    groupId,
    widget.repository.pauseGroup,
    'تعذر إيقاف التنزيل مؤقتًا.',
  );

  Future<void> _resumeGroup(String groupId) => _runGroupAction(
    groupId,
    widget.repository.resumeGroup,
    'تعذر استئناف التنزيل.',
  );

  Future<void> _confirmCancelGroup(String groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GalaxyDialog(
        title: 'إلغاء مجموعة التنزيل؟',
        content: const Text(
          'ستتوقف الفصول غير المكتملة. الفصول التي اكتمل تنزيلها ستبقى محفوظة.',
        ),
        actions: [
          GalaxyButton(
            label: 'الاحتفاظ',
            variant: GalaxyActionVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          GalaxyButton(
            key: const ValueKey('confirm-cancel-download-group'),
            label: 'إلغاء المجموعة',
            variant: GalaxyActionVariant.danger,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _runGroupAction(
        groupId,
        widget.repository.cancelGroup,
        'تعذر إلغاء التنزيل.',
      );
    }
  }

  Future<void> _retryJob(String jobId) async {
    try {
      await widget.repository.retryJob(jobId);
    } catch (_) {
      if (mounted) _showMessage('تعذرت إعادة محاولة الفصل الآن.');
    }
  }

  Future<void> _runGroupAction(
    String groupId,
    Future<void> Function(String) action,
    String failureMessage,
  ) async {
    try {
      await action(groupId);
    } catch (_) {
      if (mounted) _showMessage(failureMessage);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DownloadsDashboardView extends StatelessWidget {
  const _DownloadsDashboardView({
    required this.dashboard,
    required this.showingAd,
    required this.onReward,
    required this.onOpenOptions,
    required this.onOpenQueue,
    required this.onOpenNovel,
    required this.onOpenLibrary,
  });

  final DownloadsDashboard dashboard;
  final bool showingAd;
  final VoidCallback onReward;
  final VoidCallback onOpenOptions;
  final VoidCallback onOpenQueue;
  final ValueChanged<DownloadedNovel> onOpenNovel;
  final VoidCallback? onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final metrics = GalaxyAdaptiveMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    final activeGroups = _activeGroups(dashboard.groups);
    return CustomScrollView(
      key: const PageStorageKey('downloads-dashboard-scroll'),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            metrics.horizontalPadding,
            GalaxyMetrics.space16,
            metrics.horizontalPadding,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _DownloadAllowanceSummary(
              dashboard: dashboard,
              showingAd: showingAd,
              onReward: onReward,
              onOpenOptions: onOpenOptions,
            ),
          ),
        ),
        if (activeGroups.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              metrics.horizontalPadding,
              GalaxyMetrics.space12,
              metrics.horizontalPadding,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _DownloadQueueSummary(
                groups: activeGroups,
                onTap: onOpenQueue,
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            metrics.horizontalPadding,
            metrics.sectionSpacing,
            metrics.horizontalPadding,
            GalaxyMetrics.space12,
          ),
          sliver: SliverToBoxAdapter(
            child: GalaxySectionHeader(
              title: 'الروايات المحمّلة',
              subtitle: dashboard.novels.isEmpty
                  ? 'اقرأ فصولك المفضلة دون اتصال.'
                  : '${dashboard.novels.length} رواية · ${_formatBytes(dashboard.totalBytes)}',
              icon: Icons.offline_pin_outlined,
            ),
          ),
        ),
        if (dashboard.novels.isEmpty)
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.horizontalPadding,
            ),
            sliver: SliverToBoxAdapter(
              child: GalaxyAsyncState.empty(
                title: 'لا توجد روايات محمّلة',
                message:
                    'ابدأ من قائمة فصول أي رواية واختر الفصول التي تريدها.',
                actionLabel: onOpenLibrary == null ? null : 'فتح المكتبة',
                onAction: onOpenLibrary,
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              metrics.horizontalPadding,
              0,
              metrics.horizontalPadding,
              GalaxyMetrics.space24,
            ),
            sliver: SliverToBoxAdapter(
              child: GalaxyEditorialList(
                children: [
                  for (final novel in dashboard.novels)
                    _DownloadedNovelEditorialRow(
                      novel: novel,
                      onTap: () => onOpenNovel(novel),
                    ),
                ],
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: GalaxyMetrics.space24),
        ),
      ],
    );
  }
}

class _DownloadAllowanceSummary extends StatelessWidget {
  const _DownloadAllowanceSummary({
    required this.dashboard,
    required this.showingAd,
    required this.onReward,
    required this.onOpenOptions,
  });

  final DownloadsDashboard dashboard;
  final bool showingAd;
  final VoidCallback onReward;
  final VoidCallback onOpenOptions;

  @override
  Widget build(BuildContext context) {
    final allowance = dashboard.allowance;
    final tokens = GalaxyDesignTokens.of(context);
    final progress = allowance.plan.baseChapters == 0
        ? 0.0
        : (allowance.remaining / allowance.plan.baseChapters).clamp(0.0, 1.0);
    return GalaxySurface(
      key: const ValueKey('downloads-allowance'),
      variant: GalaxySurfaceVariant.tonal,
      padding: const EdgeInsets.all(GalaxyMetrics.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'متبقي اليوم ${allowance.remaining} فصل',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: GalaxyMetrics.space4),
                    Text(
                      '${allowance.adsRemaining} إعلان متاح · ${_formatBytes(dashboard.totalBytes)} مستخدمة',
                      key: const ValueKey('download-storage-usage'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.contentSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GalaxyMetrics.space8),
              GalaxyIconAction(
                key: const ValueKey('downloads-options'),
                icon: Icons.tune_rounded,
                tooltip: 'خيارات التنزيل',
                onPressed: onOpenOptions,
              ),
            ],
          ),
          const SizedBox(height: GalaxyMetrics.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(GalaxyMetrics.radiusSmall),
            child: LinearProgressIndicator(
              key: const ValueKey('downloads-allowance-progress'),
              value: progress,
              minHeight: 7,
              backgroundColor: tokens.surfaceRaised,
              color: tokens.brand,
            ),
          ),
          if (allowance.remaining == 0 && allowance.canWatchRewardedAd) ...[
            const SizedBox(height: GalaxyMetrics.space12),
            GalaxyButton(
              key: const ValueKey('downloads-reward'),
              label:
                  'شاهد إعلانًا واحصل على ${allowance.plan.rewardPerAd} فصلًا',
              icon: Icons.ondemand_video_rounded,
              onPressed: showingAd ? null : onReward,
            ),
          ],
        ],
      ),
    );
  }
}

class _DownloadQueueSummary extends StatelessWidget {
  const _DownloadQueueSummary({required this.groups, required this.onTap});

  final List<DownloadGroup> groups;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final jobs = groups.expand((group) => group.jobs).toList(growable: false);
    final completed = jobs
        .where((job) => job.status == DownloadJobStatus.completed)
        .length;
    final failed = jobs
        .where((job) => job.status == DownloadJobStatus.failed)
        .length;
    final progress = jobs.isEmpty ? null : completed / jobs.length;
    return GalaxySurface(
      key: const ValueKey('download-queue-section'),
      variant: GalaxySurfaceVariant.base,
      onTap: onTap,
      semanticLabel: 'فتح عمليات التنزيل',
      padding: const EdgeInsets.all(GalaxyMetrics.space12),
      child: Row(
        children: [
          const Icon(Icons.downloading_rounded),
          const SizedBox(width: GalaxyMetrics.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  groups.length == 1
                      ? 'عملية تنزيل واحدة نشطة'
                      : '${groups.length} عمليات تنزيل نشطة',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: GalaxyMetrics.space4),
                Text(
                  jobs.isEmpty
                      ? _groupStatus(groups.first.status)
                      : '$completed من ${jobs.length} مكتمل${failed == 0 ? '' : ' · $failed متعثر'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (progress != null) ...[
                  const SizedBox(height: GalaxyMetrics.space8),
                  LinearProgressIndicator(value: progress, minHeight: 5),
                ],
              ],
            ),
          ),
          const SizedBox(width: GalaxyMetrics.space8),
          const Icon(Icons.chevron_left_rounded),
        ],
      ),
    );
  }
}

class _DownloadQueueSheet extends StatefulWidget {
  const _DownloadQueueSheet({
    required this.repository,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
  });

  final DownloadRepository repository;
  final Future<void> Function(String) onPause;
  final Future<void> Function(String) onResume;
  final Future<void> Function(String) onCancel;
  final Future<void> Function(String) onRetry;

  @override
  State<_DownloadQueueSheet> createState() => _DownloadQueueSheetState();
}

class _DownloadQueueSheetState extends State<_DownloadQueueSheet> {
  final Set<String> _busyGroupIds = {};

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DownloadsDashboard>(
      valueListenable: widget.repository,
      builder: (context, dashboard, child) {
        final groups = _activeGroups(dashboard.groups);
        return GalaxyBottomSheet(
          title: 'عمليات التنزيل',
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.70,
            ),
            child: groups.isEmpty
                ? GalaxyAsyncState.empty(
                    title: 'لا توجد عمليات نشطة',
                    message: 'اكتملت عمليات التنزيل أو تم إلغاؤها.',
                  )
                : ListView.separated(
                    key: const ValueKey('download-queue-sheet-list'),
                    shrinkWrap: true,
                    itemCount: groups.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: GalaxyMetrics.space8),
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return _DownloadGroupPanel(
                        group: group,
                        busy: _busyGroupIds.contains(group.groupId),
                        onPause: (groupId) =>
                            _runGroupAction(groupId, widget.onPause),
                        onResume: (groupId) =>
                            _runGroupAction(groupId, widget.onResume),
                        onCancel: widget.onCancel,
                        onRetry: widget.onRetry,
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Future<void> _runGroupAction(
    String groupId,
    Future<void> Function(String) action,
  ) async {
    if (_busyGroupIds.contains(groupId)) return;
    setState(() => _busyGroupIds.add(groupId));
    try {
      await action(groupId);
    } finally {
      if (mounted) {
        setState(() => _busyGroupIds.remove(groupId));
      }
    }
  }
}

class _DownloadGroupPanel extends StatelessWidget {
  const _DownloadGroupPanel({
    required this.group,
    required this.busy,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
  });

  final DownloadGroup group;
  final bool busy;
  final Future<void> Function(String) onPause;
  final Future<void> Function(String) onResume;
  final Future<void> Function(String) onCancel;
  final Future<void> Function(String) onRetry;

  @override
  Widget build(BuildContext context) {
    final completed = group.jobs
        .where((job) => job.status == DownloadJobStatus.completed)
        .length;
    final failedJobs = group.jobs
        .where((job) => job.status == DownloadJobStatus.failed)
        .toList(growable: false);
    final canPause =
        group.status == DownloadGroupStatus.queued ||
        group.status == DownloadGroupStatus.running;
    final canResume =
        group.status == DownloadGroupStatus.paused ||
        group.status == DownloadGroupStatus.waitingForWifi ||
        group.status == DownloadGroupStatus.waitingForNetwork ||
        group.status == DownloadGroupStatus.storageFull;
    return GalaxySurface(
      key: ValueKey('download-group-${group.groupId}'),
      variant: GalaxySurfaceVariant.base,
      padding: const EdgeInsets.all(GalaxyMetrics.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      group.jobs.isEmpty
                          ? 'مجموعة تنزيل'
                          : '${group.jobs.length} فصل',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(_groupStatus(group.status)),
                  ],
                ),
              ),
              if (busy)
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else
                PopupMenuButton<_DownloadGroupAction>(
                  tooltip: 'إدارة التنزيل',
                  onSelected: (action) {
                    switch (action) {
                      case _DownloadGroupAction.pause:
                        unawaited(onPause(group.groupId));
                      case _DownloadGroupAction.resume:
                        unawaited(onResume(group.groupId));
                      case _DownloadGroupAction.cancel:
                        unawaited(onCancel(group.groupId));
                    }
                  },
                  itemBuilder: (context) => [
                    if (canPause)
                      const PopupMenuItem(
                        value: _DownloadGroupAction.pause,
                        child: Text('إيقاف مؤقت'),
                      ),
                    if (canResume)
                      const PopupMenuItem(
                        value: _DownloadGroupAction.resume,
                        child: Text('استئناف'),
                      ),
                    const PopupMenuItem(
                      value: _DownloadGroupAction.cancel,
                      child: Text('إلغاء'),
                    ),
                  ],
                ),
            ],
          ),
          if (group.jobs.isNotEmpty) ...[
            const SizedBox(height: GalaxyMetrics.space8),
            Text('$completed من ${group.jobs.length} مكتمل'),
            const SizedBox(height: GalaxyMetrics.space4),
            LinearProgressIndicator(
              value: completed / group.jobs.length,
              key: ValueKey('download-group-progress-${group.groupId}'),
            ),
          ],
          for (final job in failedJobs) ...[
            const SizedBox(height: GalaxyMetrics.space8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => unawaited(onRetry(job.jobId)),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  '${_failureLabel(job.lastError)} · إعادة ${job.label}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DownloadedNovelEditorialRow extends StatelessWidget {
  const _DownloadedNovelEditorialRow({
    required this.novel,
    required this.onTap,
  });

  final DownloadedNovel novel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latest = novel.chapters.isEmpty
        ? null
        : novel.chapters.reduce(
            (first, second) =>
                first.downloadedAtUtcMs >= second.downloadedAtUtcMs
                ? first
                : second,
          );
    return GalaxyNovelCard(
      key: ValueKey('downloaded-novel-${novel.novelId}'),
      novel: GalaxyNovelCardData(
        title: novel.title,
        artwork: downloadedNovelArtwork(context, novel),
        metadata:
            '${novel.chapters.length} فصل · ${_formatBytes(novel.totalBytes)}',
        secondaryMetadata: latest == null
            ? null
            : 'الأحدث تنزيلًا: ${latest.label}',
      ),
      style: const GalaxyNovelCardStyle(
        variant: GalaxyNovelCardVariant.horizontal,
        surface: GalaxyCardSurface.flat,
      ),
      onTap: onTap,
    );
  }
}

class _DownloadsSkeleton extends StatelessWidget {
  const _DownloadsSkeleton();

  @override
  Widget build(BuildContext context) {
    final horizontal = GalaxyAdaptive.horizontalPaddingFor(
      MediaQuery.sizeOf(context).width,
    );
    return ListView(
      key: const ValueKey('downloads-loading-skeleton'),
      padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
      children: const [
        GalaxySkeleton(variant: GalaxySkeletonVariant.details),
        SizedBox(height: GalaxyMetrics.space12),
        GalaxySkeleton(),
        SizedBox(height: GalaxyMetrics.space24),
        GalaxySkeleton(),
        SizedBox(height: GalaxyMetrics.space8),
        GalaxySkeleton(),
      ],
    );
  }
}

List<DownloadGroup> _activeGroups(List<DownloadGroup> groups) {
  return groups
      .where(
        (group) =>
            group.status != DownloadGroupStatus.completed &&
            group.status != DownloadGroupStatus.canceled,
      )
      .toList(growable: false);
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _groupStatus(DownloadGroupStatus status) => switch (status) {
  DownloadGroupStatus.waitingForQuota => 'بانتظار تجدد الحصة',
  DownloadGroupStatus.waitingForWifi => 'بانتظار Wi‑Fi',
  DownloadGroupStatus.waitingForNetwork => 'بانتظار الشبكة',
  DownloadGroupStatus.storageFull => 'المساحة غير كافية',
  DownloadGroupStatus.paused => 'متوقف مؤقتًا',
  DownloadGroupStatus.canceled => 'ملغي',
  DownloadGroupStatus.completed => 'مكتمل',
  DownloadGroupStatus.queued => 'في الطابور',
  DownloadGroupStatus.running => 'جارٍ التنزيل',
};

String _failureLabel(DownloadFailure? failure) => switch (failure) {
  DownloadFailure.network => 'مشكلة في الشبكة',
  DownloadFailure.wifiRequired => 'بانتظار Wi‑Fi',
  DownloadFailure.storageFull => 'المساحة غير كافية',
  DownloadFailure.unauthorized => 'انتهت جلسة الحساب',
  DownloadFailure.vipRequired => 'يتطلب اشتراك VIP',
  DownloadFailure.invalidContent => 'بيانات الفصل غير صالحة',
  DownloadFailure.canceled => 'أُلغي التنزيل',
  DownloadFailure.unknown || null => 'فشل التنزيل',
};

enum _DownloadGroupAction { pause, resume, cancel }
