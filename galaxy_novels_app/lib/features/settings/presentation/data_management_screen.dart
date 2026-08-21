import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/app_cache_maintenance.dart';
import '../../../design_system/galaxy_design_system.dart';
import '../../downloads/application/download_repository.dart';
import '../../downloads/domain/download_models.dart';
import '../../home/application/home_recommendation_exclusion_repository.dart';
import 'settings_formatters.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({
    required this.cacheMaintenance,
    required this.downloadRepository,
    this.exclusionRepository,
    this.onOpenDownloads,
    super.key,
  });

  final AppCacheMaintenance cacheMaintenance;
  final DownloadRepository downloadRepository;
  final HomeRecommendationExclusionRepository? exclusionRepository;
  final VoidCallback? onOpenDownloads;

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  int? _cacheBytes;
  int? _hiddenCount;
  bool _cacheError = false;
  bool _recommendationsError = false;
  bool _clearingCache = false;
  bool _clearingRecommendations = false;

  @override
  void initState() {
    super.initState();
    widget.exclusionRepository?.addListener(_reloadRecommendations);
    unawaited(_reloadAll());
  }

  @override
  void didUpdateWidget(covariant DataManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exclusionRepository != widget.exclusionRepository) {
      oldWidget.exclusionRepository?.removeListener(_reloadRecommendations);
      widget.exclusionRepository?.addListener(_reloadRecommendations);
      unawaited(_reloadRecommendations());
    }
  }

  @override
  void dispose() {
    widget.exclusionRepository?.removeListener(_reloadRecommendations);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = GalaxyAdaptiveMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    return Scaffold(
      key: const ValueKey('data-management-screen'),
      appBar: AppBar(title: const Text('إدارة البيانات')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            metrics.horizontalPadding,
            GalaxyMetrics.space16,
            metrics.horizontalPadding,
            GalaxyMetrics.space32,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GalaxySettingsGroup(
                      title: 'الملفات المؤقتة',
                      children: [
                        GalaxySettingsTile(
                          key: const ValueKey('data-cache-row'),
                          icon: Icons.cleaning_services_outlined,
                          title: 'Cache المحتوى العام',
                          subtitle: _cacheSubtitle,
                          trailing: _clearingCache
                              ? const SizedBox.square(
                                  dimension: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                          onTap: _cacheAction,
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.sectionSpacing),
                    ValueListenableBuilder<DownloadsDashboard>(
                      valueListenable: widget.downloadRepository,
                      builder: (context, dashboard, child) {
                        return GalaxySettingsGroup(
                          title: 'التنزيلات',
                          children: [
                            GalaxySettingsTile(
                              key: const ValueKey('data-downloads-row'),
                              icon: Icons.download_done_rounded,
                              title: 'إدارة التنزيلات',
                              subtitle:
                                  '${dashboard.novels.length} رواية • ${formatStorageSize(dashboard.totalBytes)}',
                              onTap: widget.onOpenDownloads,
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: metrics.sectionSpacing),
                    GalaxySettingsGroup(
                      title: 'التوصيات الشخصية',
                      children: [
                        GalaxySettingsTile(
                          key: const ValueKey(
                            'data-hidden-recommendations-row',
                          ),
                          icon: Icons.visibility_off_outlined,
                          title: 'الروايات المخفية',
                          subtitle: _recommendationsSubtitle,
                          trailing: _clearingRecommendations
                              ? const SizedBox.square(
                                  dimension: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                          enabled:
                              !_clearingRecommendations &&
                              widget.exclusionRepository != null,
                          onTap:
                              (_hiddenCount ?? 0) > 0 &&
                                  !_clearingRecommendations
                              ? _confirmRestoreRecommendations
                              : _recommendationsError
                              ? _reloadRecommendations
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: GalaxyMetrics.space16),
                    Text(
                      'مسح الملفات المؤقتة لا يحذف الفصول المحمّلة أو الحساب أو سجل القراءة أو تخصيصاتك.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: GalaxyDesignTokens.of(context).contentSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _cacheSubtitle {
    if (_cacheError) return 'تعذر حساب المساحة — اضغط للمحاولة';
    final bytes = _cacheBytes;
    if (bytes == null) return 'جارٍ حساب المساحة…';
    if (bytes == 0) return 'لا توجد ملفات مؤقتة حاليًا';
    return '${formatStorageSize(bytes)} • اضغط للمسح';
  }

  String get _recommendationsSubtitle {
    if (_recommendationsError) {
      return 'تعذر قراءة القائمة — اضغط للمحاولة';
    }
    final count = _hiddenCount;
    if (count == null) return 'جارٍ قراءة القائمة…';
    if (count == 0) return 'لا توجد روايات مخفية لهذا الحساب';
    return '$count رواية • اضغط لإعادتها إلى التوصيات';
  }

  VoidCallback? get _cacheAction {
    if (_clearingCache || _cacheBytes == null && !_cacheError) return null;
    if (_cacheError) return () => unawaited(_reloadCache());
    if ((_cacheBytes ?? 0) == 0) return null;
    return () => unawaited(_confirmClearCache());
  }

  Future<void> _reloadAll() async {
    await Future.wait([_reloadCache(), _reloadRecommendations()]);
  }

  Future<void> _reloadCache() async {
    try {
      final bytes = await widget.cacheMaintenance.cacheSizeBytes();
      if (mounted) {
        setState(() {
          _cacheBytes = bytes;
          _cacheError = false;
        });
      }
    } on Exception {
      if (mounted) setState(() => _cacheError = true);
    }
  }

  Future<void> _reloadRecommendations() async {
    final repository = widget.exclusionRepository;
    if (repository == null) {
      if (mounted) setState(() => _hiddenCount = 0);
      return;
    }
    try {
      final ids = await repository.load();
      if (mounted && identical(repository, widget.exclusionRepository)) {
        setState(() {
          _hiddenCount = ids.length;
          _recommendationsError = false;
        });
      }
    } on Exception {
      if (mounted) setState(() => _recommendationsError = true);
    }
  }

  Future<void> _confirmClearCache() async {
    if (_cacheError) {
      await _reloadCache();
      return;
    }
    final confirmed = await _confirm(
      title: 'مسح الملفات المؤقتة؟',
      message:
          'سيُحذف Cache المحتوى العام فقط، ولن تتأثر الفصول المحمّلة أو إعداداتك.',
      actionLabel: 'مسح',
    );
    if (!confirmed || !mounted) return;
    setState(() => _clearingCache = true);
    try {
      await widget.cacheMaintenance.clearTemporaryCache();
      if (mounted) {
        setState(() {
          _cacheBytes = 0;
          _cacheError = false;
        });
        _message('تم مسح الملفات المؤقتة.');
      }
    } on Exception {
      if (mounted) _message('تعذر مسح الملفات المؤقتة الآن.');
    } finally {
      if (mounted) setState(() => _clearingCache = false);
    }
  }

  Future<void> _confirmRestoreRecommendations() async {
    final repository = widget.exclusionRepository;
    if (repository == null) return;
    final confirmed = await _confirm(
      title: 'إعادة الروايات المخفية؟',
      message:
          'ستعود الروايات المخفية إلى التوصيات لهذا الحساب أو نطاق الزائر الحالي فقط.',
      actionLabel: 'إعادة',
    );
    if (!confirmed || !mounted) return;
    setState(() => _clearingRecommendations = true);
    try {
      await repository.clear();
      if (mounted) {
        setState(() {
          _hiddenCount = 0;
          _recommendationsError = false;
        });
        _message('أُعيدت الروايات المخفية إلى التوصيات.');
      }
    } on Exception {
      if (mounted) _message('تعذر إعادة الروايات المخفية الآن.');
    } finally {
      if (mounted) setState(() => _clearingRecommendations = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(actionLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
