import 'package:flutter/material.dart';

import '../../../design_system/galaxy_design_system.dart';
import '../../downloads/application/download_repository.dart';
import '../../downloads/domain/download_models.dart';
import '../application/chapter_download_request.dart';
import '../application/download_planner_controller.dart';
import '../domain/readable_chapter.dart';

@immutable
class DownloadPlannerActions {
  const DownloadPlannerActions({
    this.loadAllChapters,
    this.selectManualChapters,
    this.openOperations,
    this.close,
    this.preloadRewardedAd,
  });

  final Future<DownloadPlannerCatalogResult> Function()? loadAllChapters;
  final Future<List<ReadableChapter>?> Function()? selectManualChapters;
  final VoidCallback? openOperations;
  final VoidCallback? close;
  final Future<void> Function()? preloadRewardedAd;
}

class NovelDownloadPlannerSheet extends StatefulWidget {
  const NovelDownloadPlannerSheet({
    required this.controller,
    required this.novel,
    required this.repository,
    required this.actions,
    super.key,
  });

  final DownloadPlannerController controller;
  final DownloadNovelRequest novel;
  final DownloadRepository repository;
  final DownloadPlannerActions actions;

  @override
  State<NovelDownloadPlannerSheet> createState() =>
      _NovelDownloadPlannerSheetState();
}

class _NovelDownloadPlannerSheetState extends State<NovelDownloadPlannerSheet> {
  late final TextEditingController _rangeStartController;
  late final TextEditingController _rangeEndController;
  var _isSavingWifi = false;
  var _rewardPreloadRequested = false;

  @override
  void initState() {
    super.initState();
    _rangeStartController = TextEditingController(
      text: widget.controller.rangeStart.toString(),
    );
    _rangeEndController = TextEditingController(
      text: widget.controller.rangeEnd.toString(),
    );
    widget.repository.addListener(_syncDashboard);
  }

  @override
  void didUpdateWidget(covariant NovelDownloadPlannerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      oldWidget.repository.removeListener(_syncDashboard);
      widget.repository.addListener(_syncDashboard);
      _syncDashboard();
    }
  }

  @override
  void dispose() {
    widget.repository.removeListener(_syncDashboard);
    _rangeStartController.dispose();
    _rangeEndController.dispose();
    super.dispose();
  }

  void _syncDashboard() {
    widget.controller.updateDashboard(widget.repository.value);
  }

  @override
  Widget build(BuildContext context) {
    return GalaxySurface(
      key: const ValueKey('download-planner-surface'),
      variant: GalaxySurfaceVariant.raised,
      radius: GalaxyMetrics.radiusOverlay,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final submission = widget.controller.submission;
          if (submission != null) {
            return _DownloadPlannerResult(
              result: submission,
              onContinue: widget.actions.close ?? _close,
              onOpenOperations:
                  widget.actions.openOperations ??
                  widget.actions.close ??
                  _close,
            );
          }
          return _buildEditor(context);
        },
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final controller = widget.controller;
    final preview = controller.preview;
    _scheduleRewardPreload(preview);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                GalaxyMetrics.space20,
                GalaxyMetrics.space16,
                GalaxyMetrics.space20,
                GalaxyMetrics.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PlannerHeader(novel: widget.novel),
                  const SizedBox(height: GalaxyMetrics.space20),
                  Text(
                    'اختر الفصول للتنزيل',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: GalaxyMetrics.space12),
                  _buildModes(),
                  const SizedBox(height: GalaxyMetrics.space16),
                  _buildSelectionEditor(),
                  const SizedBox(height: GalaxyMetrics.space16),
                  _PlannerForecast(preview: preview),
                  const SizedBox(height: GalaxyMetrics.space12),
                  _WifiSetting(
                    enabled: controller.dashboard.wifiOnly,
                    saving: _isSavingWifi,
                    onChanged: _setWifiOnly,
                  ),
                  if (!controller.dashboard.wifiOnly &&
                      preview.chapters.length >= 50) ...[
                    const SizedBox(height: GalaxyMetrics.space8),
                    const _MobileDataNotice(),
                  ],
                  if (controller.catalogError case final error?) ...[
                    const SizedBox(height: GalaxyMetrics.space12),
                    _InlineError(message: error, onRetry: _loadAll),
                  ],
                  if (controller.submitError case final error?) ...[
                    const SizedBox(height: GalaxyMetrics.space12),
                    _InlineError(message: error),
                  ],
                ],
              ),
            ),
          ),
          _PlannerFooter(
            preview: preview,
            loading: controller.isSubmitting,
            onPressed: preview.chapters.isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildModes() {
    final selected = widget.controller.mode;
    return Wrap(
      spacing: GalaxyMetrics.space8,
      runSpacing: GalaxyMetrics.space8,
      children: [
        _ModeButton(
          key: const ValueKey('download-planner-next'),
          label: 'الفصول التالية',
          icon: Icons.skip_next_rounded,
          selected: selected == DownloadPlannerSelectionMode.next,
          onPressed: () =>
              widget.controller.selectNext(widget.controller.quickCount),
        ),
        _ModeButton(
          key: const ValueKey('download-planner-range'),
          label: 'نطاق',
          icon: Icons.linear_scale_rounded,
          selected: selected == DownloadPlannerSelectionMode.range,
          onPressed: _updateRange,
        ),
        _ModeButton(
          key: const ValueKey('download-planner-all'),
          label: 'كل المتاح',
          icon: Icons.library_add_check_outlined,
          selected: selected == DownloadPlannerSelectionMode.all,
          onPressed: _loadAll,
        ),
        _ModeButton(
          key: const ValueKey('download-planner-manual'),
          label: 'اختيار متقدم',
          icon: Icons.checklist_rounded,
          selected: selected == DownloadPlannerSelectionMode.manual,
          onPressed: _selectManual,
        ),
      ],
    );
  }

  Widget _buildSelectionEditor() {
    return switch (widget.controller.mode) {
      DownloadPlannerSelectionMode.next => _QuickCountSelector(
        selected: widget.controller.quickCount,
        onSelected: widget.controller.selectNext,
      ),
      DownloadPlannerSelectionMode.range => Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('download-planner-range-start'),
              controller: _rangeStartController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'من الفصل'),
              onChanged: (_) => _updateRange(),
            ),
          ),
          const SizedBox(width: GalaxyMetrics.space12),
          Expanded(
            child: TextField(
              key: const ValueKey('download-planner-range-end'),
              controller: _rangeEndController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'إلى الفصل'),
              onChanged: (_) => _updateRange(),
            ),
          ),
        ],
      ),
      DownloadPlannerSelectionMode.all => GalaxySurface(
        variant: GalaxySurfaceVariant.tonal,
        padding: const EdgeInsets.all(GalaxyMetrics.space12),
        child: Row(
          children: [
            if (widget.controller.isLoadingCatalog)
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.info_outline_rounded),
            const SizedBox(width: GalaxyMetrics.space8),
            const Expanded(
              child: Text('سيتم التحقق من جميع صفحات الفهرس قبل بدء التنزيل.'),
            ),
          ],
        ),
      ),
      DownloadPlannerSelectionMode.manual => GalaxySurface(
        variant: GalaxySurfaceVariant.tonal,
        padding: const EdgeInsets.all(GalaxyMetrics.space12),
        child: Row(
          children: [
            const Expanded(
              child: Text('يمكنك تعديل الفصول المختارة دون بدء التنزيل.'),
            ),
            TextButton(
              onPressed: _selectManual,
              child: const Text('تعديل الاختيار'),
            ),
          ],
        ),
      ),
    };
  }

  void _updateRange() {
    final start = int.tryParse(_rangeStartController.text) ?? 0;
    final end = int.tryParse(_rangeEndController.text) ?? 0;
    widget.controller.selectRange(start: start, end: end);
  }

  Future<void> _loadAll() async {
    final loader = widget.actions.loadAllChapters;
    if (loader == null) {
      widget.controller.selectAll();
      return;
    }
    await widget.controller.loadAllChapters(loader);
  }

  Future<void> _selectManual() async {
    final selector = widget.actions.selectManualChapters;
    if (selector == null) {
      widget.controller.selectManual(const {});
      return;
    }
    final chapters = await selector();
    if (chapters == null) return;
    widget.controller.includeAccessibleChapters(chapters);
    widget.controller.selectManual(chapters.map(chapterDownloadKey).toSet());
  }

  Future<void> _setWifiOnly(bool enabled) async {
    if (_isSavingWifi) return;
    setState(() => _isSavingWifi = true);
    try {
      await widget.repository.setWifiOnly(enabled);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ إعداد Wi-Fi. حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingWifi = false);
    }
  }

  void _scheduleRewardPreload(DownloadPlanPreview preview) {
    final preload = widget.actions.preloadRewardedAd;
    if (_rewardPreloadRequested ||
        preload == null ||
        preview.allowance.adsRemaining <= 0 ||
        (preview.chapters.length <= preview.allowance.remaining &&
            preview.allowance.remaining > preview.allowance.plan.rewardPerAd)) {
      return;
    }
    _rewardPreloadRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) preload();
    });
  }

  Future<void> _submit() async {
    await widget.controller.submit(
      (chapters) => widget.repository.enqueue(
        novel: widget.novel,
        chapters: chapters.map(chapterDownloadRequest).toList(growable: false),
      ),
    );
  }

  void _close() {
    Navigator.of(context).maybePop();
  }
}

class _PlannerHeader extends StatelessWidget {
  const _PlannerHeader({required this.novel});

  final DownloadNovelRequest novel;

  @override
  Widget build(BuildContext context) {
    final coverUri = Uri.tryParse(novel.coverUrl);
    final image = coverUri != null && coverUri.hasScheme
        ? NetworkImage(novel.coverUrl)
        : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 68,
          child: GalaxyNovelCover(
            artwork: GalaxyNovelArtwork(title: novel.title, image: image),
          ),
        ),
        const SizedBox(width: GalaxyMetrics.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                novel.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: GalaxyMetrics.space4),
              Text(
                'خطط دفعتك قبل إضافتها إلى الطابور',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onPressed(),
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _QuickCountSelector extends StatelessWidget {
  const _QuickCountSelector({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('عدد الفصول', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: GalaxyMetrics.space8),
        Wrap(
          spacing: GalaxyMetrics.space8,
          runSpacing: GalaxyMetrics.space8,
          children: [
            for (final count in const [10, 25, 50, 100])
              ChoiceChip(
                key: ValueKey('download-planner-count-$count'),
                label: Text('$count'),
                selected: selected == count,
                onSelected: (_) => onSelected(count),
              ),
          ],
        ),
      ],
    );
  }
}

class _PlannerForecast extends StatelessWidget {
  const _PlannerForecast({required this.preview});

  final DownloadPlanPreview preview;

  @override
  Widget build(BuildContext context) {
    final skipped = preview.skippedDownloaded + preview.skippedQueued;
    return GalaxySurface(
      variant: GalaxySurfaceVariant.base,
      padding: const EdgeInsets.all(GalaxyMetrics.space12),
      child: Column(
        children: [
          _ForecastRow(
            label: 'فصول جديدة',
            value: '${preview.chapters.length}',
            emphasized: true,
          ),
          _ForecastRow(label: 'ينزّل الآن', value: '${preview.availableNow}'),
          _ForecastRow(
            label: 'متاح عبر ${preview.rewardAdsNeeded} إعلان مكافأة',
            value: '${preview.availableThroughRewards}',
          ),
          _ForecastRow(
            label: 'ينتظر تجدد الحصة',
            value: '${preview.deferredUntilReset}',
          ),
          if (skipped > 0)
            _ForecastRow(label: 'تم تجاوزه مسبقًا', value: '$skipped'),
        ],
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  const _ForecastRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GalaxyMetrics.space4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _WifiSetting extends StatelessWidget {
  const _WifiSetting({
    required this.enabled,
    required this.saving,
    required this.onChanged,
  });

  final bool enabled;
  final bool saving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GalaxySurface(
      variant: GalaxySurfaceVariant.tonal,
      padding: const EdgeInsets.symmetric(
        horizontal: GalaxyMetrics.space12,
        vertical: GalaxyMetrics.space4,
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_rounded),
          const SizedBox(width: GalaxyMetrics.space8),
          const Expanded(child: Text('التنزيل عبر Wi-Fi فقط')),
          if (saving)
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              key: const ValueKey('download-planner-wifi-only'),
              value: enabled,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _MobileDataNotice extends StatelessWidget {
  const _MobileDataNotice();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.data_usage_rounded, size: 20),
        SizedBox(width: GalaxyMetrics.space8),
        Expanded(child: Text('هذه دفعة كبيرة وقد تستهلك بيانات الهاتف.')),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return GalaxySurface(
      variant: GalaxySurfaceVariant.base,
      padding: const EdgeInsets.all(GalaxyMetrics.space12),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: tokens.danger),
          const SizedBox(width: GalaxyMetrics.space8),
          Expanded(child: Text(message)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

class _PlannerFooter extends StatelessWidget {
  const _PlannerFooter({
    required this.preview,
    required this.loading,
    required this.onPressed,
  });

  final DownloadPlanPreview preview;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        border: Border(top: BorderSide(color: tokens.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(GalaxyMetrics.space12),
          child: SizedBox(
            width: double.infinity,
            child: GalaxyButton(
              key: const ValueKey('download-planner-submit'),
              label: loading
                  ? 'جارٍ الإضافة…'
                  : 'ابدأ تنزيل ${_arabicChapterCount(preview.chapters.length)}',
              icon: Icons.download_rounded,
              onPressed: loading ? null : onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadPlannerResult extends StatelessWidget {
  const _DownloadPlannerResult({
    required this.result,
    required this.onContinue,
    required this.onOpenOperations,
  });

  final DownloadEnqueueResult result;
  final VoidCallback onContinue;
  final VoidCallback onOpenOperations;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GalaxyMetrics.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.task_alt_rounded, size: 56),
            const SizedBox(height: GalaxyMetrics.space12),
            Text(
              'تمت الإضافة للطابور',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: GalaxyMetrics.space8),
            Text(
              '${_arabicChapterCount(result.acceptedChapterKeys.length)} جديدًا',
              textAlign: TextAlign.center,
            ),
            if (result.skippedChapterKeys.isNotEmpty) ...[
              const SizedBox(height: GalaxyMetrics.space4),
              Text(
                'تم تجاوز ${_arabicChapterCount(result.skippedChapterKeys.length)}',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: GalaxyMetrics.space24),
            GalaxyButton(
              label: 'عرض العمليات',
              icon: Icons.downloading_rounded,
              onPressed: onOpenOperations,
            ),
            const SizedBox(height: GalaxyMetrics.space8),
            GalaxyButton(
              label: 'متابعة التصفح',
              variant: GalaxyActionVariant.secondary,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

String _arabicChapterCount(int count) {
  if (count == 1) return 'فصل واحد';
  if (count == 2) return 'فصلين';
  if (count >= 3 && count <= 10) return '$count فصول';
  return '$count فصلًا';
}
