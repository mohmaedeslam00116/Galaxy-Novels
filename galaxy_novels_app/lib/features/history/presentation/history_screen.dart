import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/analytics/app_screen_names.dart';
import '../../../core/config/app_config.dart';
import '../../../data/models/reading_progress.dart';
import '../../../data/repositories/reading_history_repository.dart';
import '../../../design_system/galaxy_design_system.dart';
import '../../catalog/presentation/catalog_screen.dart';
import '../../ads/application/inline_native_ad_repository.dart';
import '../../ads/presentation/inline_native_ad_slot.dart';
import '../../reader/presentation/reader_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({this.onOpenLibrary, super.key});

  final VoidCallback? onOpenLibrary;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  ReadingHistoryRepository? _repository;
  Future<List<ReadingProgress>>? _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppDependencies.of(context).readingHistoryRepository;
    if (_repository != repository) {
      _repository?.removeListener(_refresh);
      _repository = repository;
      _repository?.addListener(_refresh);
      _future = repository.load();
    }
  }

  @override
  void dispose() {
    _repository?.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<ReadingProgress>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _HistoryStateViewport(
            child: GalaxyAsyncState.loading(label: 'جارٍ تحميل سجل القراءة'),
          );
        }
        if (snapshot.hasError) {
          return _HistoryStateViewport(
            child: GalaxyAsyncState.error(
              title: 'تعذر تحميل سجل القراءة',
              message: 'تحقق من الاتصال ثم حاول مجددًا.',
              onRetry: _refresh,
            ),
          );
        }

        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return _HistoryStateViewport(
            child: GalaxyAsyncState.empty(
              title: 'لا يوجد سجل قراءة بعد',
              message: 'ابدأ القراءة من المكتبة لتجد آخر فصولك هنا.',
              actionLabel: 'فتح المكتبة',
              onAction: widget.onOpenLibrary ?? _openLibrary,
            ),
          );
        }
        return _HistoryContent(items: items, onOpenReader: _openReader);
      },
    );
  }

  void _refresh() {
    final repository = _repository;
    if (repository == null || !mounted) return;
    setState(() {
      _future = repository.load();
    });
  }

  void _openReader(ReadingProgress progress) {
    Navigator.of(context).push(
      galaxyPageRoute<void>(
        context: context,
        settings: const RouteSettings(name: AppScreenNames.reader),
        builder: (context) => ReaderScreen(
          contentApi: progress.contentApi,
          chapterTitle: progress.displayChapterTitle,
          novelTitle: progress.displayNovelTitle,
          coverUrl: progress.coverUrl,
        ),
      ),
    );
  }

  void _openLibrary() {
    Navigator.of(context).push(
      galaxyPageRoute<void>(
        context: context,
        settings: const RouteSettings(name: AppScreenNames.library),
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('المكتبة')),
          body: const CatalogScreen(),
        ),
      ),
    );
  }
}

class _HistoryStateViewport extends StatelessWidget {
  const _HistoryStateViewport({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final horizontal = GalaxyAdaptive.horizontalPaddingFor(
      MediaQuery.sizeOf(context).width,
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const PageStorageKey('history-state-scroll'),
        padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.items, required this.onOpenReader});

  final List<ReadingProgress> items;
  final ValueChanged<ReadingProgress> onOpenReader;

  @override
  Widget build(BuildContext context) {
    final metrics = GalaxyAdaptiveMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    final previous = items.skip(1).toList(growable: false);

    return CustomScrollView(
      key: const PageStorageKey('reader-history-scroll'),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            metrics.horizontalPadding,
            GalaxyMetrics.space20,
            metrics.horizontalPadding,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: GalaxySectionHeader(
              title: 'متابعة القراءة',
              subtitle: 'عد مباشرة إلى آخر فصل وصلت إليه.',
              icon: Icons.auto_stories_rounded,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            metrics.horizontalPadding,
            GalaxyMetrics.space12,
            metrics.horizontalPadding,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _ContinueReadingHero(
              progress: items.first,
              onTap: () => onOpenReader(items.first),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: InlineNativeAdSlot(
            placement: InlineNativeAdPlacement.readerJourney,
          ),
        ),
        if (previous.isNotEmpty) ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              metrics.horizontalPadding,
              metrics.sectionSpacing,
              metrics.horizontalPadding,
              GalaxyMetrics.space12,
            ),
            sliver: SliverToBoxAdapter(
              child: GalaxySectionHeader(
                title: 'قراءات سابقة',
                subtitle: '${previous.length} موضع قراءة محفوظ',
                icon: Icons.history_rounded,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.horizontalPadding,
            ),
            sliver: SliverToBoxAdapter(
              child: GalaxyEditorialList(
                children: [
                  for (final progress in previous)
                    _HistoryEditorialRow(
                      progress: progress,
                      onTap: () => onOpenReader(progress),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(
          child: SizedBox(height: GalaxyMetrics.space24),
        ),
      ],
    );
  }
}

class _ContinueReadingHero extends StatelessWidget {
  const _ContinueReadingHero({required this.progress, required this.onTap});

  final ReadingProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GalaxyDesignTokens.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Semantics(
      container: true,
      button: true,
      label:
          'متابعة قراءة ${progress.displayNovelTitle}، ${progress.displayChapterTitle}',
      child: ExcludeSemantics(
        child: GalaxySurface(
          key: const ValueKey('history-latest-reading'),
          variant: GalaxySurfaceVariant.tonal,
          onTap: onTap,
          padding: const EdgeInsets.all(GalaxyMetrics.space12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360 || textScale >= 1.8;
              final cover = SizedBox(
                width: compact ? 68 : 88,
                child: GalaxyNovelCover(
                  artwork: GalaxyNovelArtwork(
                    title: progress.displayNovelTitle,
                    image: _historyCover(context, progress.coverUrl),
                  ),
                  presentation: GalaxyCoverPresentation.tonalFrame,
                  radius: GalaxyMetrics.radiusControl,
                ),
              );
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: GalaxyMetrics.space8,
                    runSpacing: GalaxyMetrics.space8,
                    children: [
                      const GalaxyBadge(
                        label: 'الأحدث',
                        icon: Icons.schedule_rounded,
                        tone: GalaxyBadgeTone.brand,
                        size: GalaxyComponentSize.small,
                      ),
                      if (_isVipProgress(progress))
                        const GalaxyBadge(
                          label: 'VIP',
                          icon: Icons.workspace_premium_rounded,
                          tone: GalaxyBadgeTone.warning,
                          size: GalaxyComponentSize.small,
                        ),
                    ],
                  ),
                  const SizedBox(height: GalaxyMetrics.space8),
                  Text(
                    progress.displayNovelTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: tokens.contentPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: GalaxyMetrics.space4),
                  Text(
                    progress.displayChapterTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.contentSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: GalaxyMetrics.space8),
                  Text(
                    'آخر قراءة: ${_dateLabel(progress.updatedAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.contentSecondary,
                    ),
                  ),
                ],
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (compact) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        cover,
                        const SizedBox(width: GalaxyMetrics.space12),
                        Expanded(child: details),
                      ],
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        cover,
                        const SizedBox(width: GalaxyMetrics.space16),
                        Expanded(child: details),
                      ],
                    ),
                  const SizedBox(height: GalaxyMetrics.space12),
                  _ReadingProgressIndicator(progress: progress),
                  const SizedBox(height: GalaxyMetrics.space12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GalaxyButton(
                      label: 'تابع القراءة',
                      icon: Icons.menu_book_rounded,
                      onPressed: onTap,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HistoryEditorialRow extends StatelessWidget {
  const _HistoryEditorialRow({required this.progress, required this.onTap});

  final ReadingProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return Semantics(
      button: true,
      label:
          'فتح قراءة ${progress.displayNovelTitle}، ${progress.displayChapterTitle}',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(GalaxyMetrics.space8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 58,
                  child: GalaxyNovelCover(
                    artwork: GalaxyNovelArtwork(
                      title: progress.displayNovelTitle,
                      image: _historyCover(context, progress.coverUrl),
                    ),
                    radius: GalaxyMetrics.radiusSmall,
                  ),
                ),
                const SizedBox(width: GalaxyMetrics.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        progress.displayNovelTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: GalaxyMetrics.space4),
                      Text(
                        progress.displayChapterTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.contentSecondary,
                        ),
                      ),
                      const SizedBox(height: GalaxyMetrics.space8),
                      _ReadingProgressIndicator(progress: progress),
                    ],
                  ),
                ),
                const SizedBox(width: GalaxyMetrics.space8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _dateLabel(progress.updatedAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tokens.contentSecondary,
                      ),
                    ),
                    if (_isVipProgress(progress)) ...[
                      const SizedBox(height: GalaxyMetrics.space8),
                      const GalaxyBadge(
                        label: 'VIP',
                        tone: GalaxyBadgeTone.warning,
                        size: GalaxyComponentSize.small,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingProgressIndicator extends StatelessWidget {
  const _ReadingProgressIndicator({required this.progress});

  final ReadingProgress progress;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final percent = progress.completionPercent;
    final label = percent == null ? 'موضع محفوظ' : '$percent%';
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: tokens.brand,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: GalaxyMetrics.space8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GalaxyMetrics.radiusSmall),
            child: LinearProgressIndicator(
              value: progress.completionFraction ?? 0,
              minHeight: 6,
              backgroundColor: tokens.surfaceRaised,
              color: tokens.brand,
            ),
          ),
        ),
      ],
    );
  }
}

ImageProvider<Object>? _historyCover(BuildContext context, String coverUrl) {
  if (coverUrl.trim().isEmpty) return null;
  try {
    return NetworkImage(
      AppDependencies.of(context).config.resolve(coverUrl).toString(),
    );
  } on AppConfigException {
    return null;
  } on FormatException {
    return null;
  }
}

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

bool _isVipProgress(ReadingProgress progress) {
  final api = progress.contentApi.toLowerCase();
  return api.contains('/vip/') || api.contains('vip/chapters');
}
