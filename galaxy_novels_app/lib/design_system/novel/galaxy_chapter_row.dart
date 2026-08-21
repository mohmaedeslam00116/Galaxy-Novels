import 'package:flutter/material.dart';

import '../components/galaxy_badge.dart';
import '../components/galaxy_surface.dart';
import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';

enum GalaxyChapterState {
  available,
  queued,
  downloaded,
  downloading,
  paused,
  failed,
  vipLocked,
}

@immutable
class GalaxyChapterRowData {
  const GalaxyChapterRowData({
    required this.title,
    this.subtitle,
    this.leadingLabel,
    this.state = GalaxyChapterState.available,
    this.isVip = false,
    this.unavailableReason,
    this.progress,
  });

  final String title;
  final String? subtitle;
  final String? leadingLabel;
  final GalaxyChapterState state;
  final bool isVip;
  final String? unavailableReason;
  final double? progress;
}

class GalaxyChapterRow extends StatelessWidget {
  const GalaxyChapterRow({
    required this.chapter,
    this.onTap,
    this.onLongPress,
    this.onAction,
    this.actionKey,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionChanged,
    this.showAction = true,
    this.showNavigationIndicator = false,
    this.emphasized = false,
    super.key,
  });

  final GalaxyChapterRowData chapter;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAction;
  final Key? actionKey;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool>? onSelectionChanged;
  final bool showAction;
  final bool showNavigationIndicator;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final accent = chapter.isVip ? tokens.warning : tokens.brand;
    final selectionTap = onSelectionChanged == null
        ? null
        : () => onSelectionChanged?.call(!selected);
    return Semantics(
      container: true,
      selected: selectionMode ? selected : null,
      child: GalaxySurface(
        variant: chapter.isVip || emphasized || selected
            ? GalaxySurfaceVariant.tonal
            : GalaxySurfaceVariant.base,
        onTap: selectionMode ? selectionTap : onTap,
        onLongPress: onLongPress,
        semanticLabel: selectionMode
            ? '${chapter.title}، ${selected ? 'محدد' : 'غير محدد'}'
            : chapter.title,
        radius: GalaxyMetrics.radiusCard,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 82),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GalaxyMetrics.space12,
              vertical: GalaxyMetrics.space8,
            ),
            child: Row(
              children: [
                if (chapter.leadingLabel case final label?) ...[
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: chapter.isVip
                          ? tokens.warningContainer
                          : tokens.surfaceRaised,
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withValues(alpha: 0.28)),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: GalaxyMetrics.space12),
                ],
                Expanded(child: _ChapterCopy(chapter: chapter)),
                const SizedBox(width: GalaxyMetrics.space8),
                if (selectionMode)
                  Checkbox(
                    value: selected,
                    onChanged: onSelectionChanged == null
                        ? null
                        : (value) =>
                              onSelectionChanged?.call(value ?? !selected),
                  )
                else ...[
                  if (showAction)
                    _ChapterStateAction(
                      key: actionKey,
                      chapter: chapter,
                      onPressed: onAction,
                    ),
                  if (showNavigationIndicator)
                    Icon(
                      chapter.unavailableReason == null
                          ? Icons.chevron_left_rounded
                          : Icons.lock_outline_rounded,
                      size: 24,
                      color: accent,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterCopy extends StatelessWidget {
  const _ChapterCopy({required this.chapter});

  final GalaxyChapterRowData chapter;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                chapter.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: tokens.contentPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (chapter.isVip) ...[
              const SizedBox(width: GalaxyMetrics.space8),
              const GalaxyBadge(
                label: 'VIP',
                tone: GalaxyBadgeTone.warning,
                size: GalaxyComponentSize.small,
              ),
            ],
          ],
        ),
        if (chapter.subtitle?.trim().isNotEmpty == true) ...[
          const SizedBox(height: GalaxyMetrics.space4),
          Text(
            chapter.subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.contentSecondary,
              height: 1.2,
            ),
          ),
        ],
        if (chapter.unavailableReason case final reason?) ...[
          const SizedBox(height: GalaxyMetrics.space4),
          Text(
            reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tokens.contentSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _ChapterStateAction extends StatelessWidget {
  const _ChapterStateAction({
    required this.chapter,
    required this.onPressed,
    super.key,
  });

  final GalaxyChapterRowData chapter;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (chapter.state == GalaxyChapterState.downloading) {
      return Semantics(
        container: true,
        label: 'الفصل قيد التنزيل',
        child: SizedBox.square(
          dimension: GalaxyMetrics.minimumTouchTarget,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CircularProgressIndicator(
              value: chapter.progress,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }
    final tokens = GalaxyDesignTokens.of(context);
    final icon = switch (chapter.state) {
      GalaxyChapterState.available => Icons.download_rounded,
      GalaxyChapterState.queued => Icons.schedule_rounded,
      GalaxyChapterState.downloaded => Icons.download_done_rounded,
      GalaxyChapterState.paused => Icons.pause_circle_outline_rounded,
      GalaxyChapterState.failed => Icons.refresh_rounded,
      GalaxyChapterState.vipLocked => Icons.workspace_premium_outlined,
      GalaxyChapterState.downloading => Icons.autorenew_rounded,
    };
    final tooltip = switch (chapter.state) {
      GalaxyChapterState.available => 'تنزيل الفصل',
      GalaxyChapterState.queued => 'الفصل في طابور التنزيل',
      GalaxyChapterState.downloaded => 'تم تنزيل الفصل',
      GalaxyChapterState.paused => 'تنزيل الفصل متوقف مؤقتًا',
      GalaxyChapterState.failed => 'إعادة محاولة تنزيل الفصل',
      GalaxyChapterState.vipLocked => 'فصل VIP',
      GalaxyChapterState.downloading => 'الفصل قيد التنزيل',
    };
    final color = switch (chapter.state) {
      GalaxyChapterState.available => tokens.brand,
      GalaxyChapterState.queued => tokens.contentSecondary,
      GalaxyChapterState.downloaded => tokens.success,
      GalaxyChapterState.paused => tokens.warning,
      GalaxyChapterState.failed => tokens.danger,
      GalaxyChapterState.vipLocked => tokens.warning,
      GalaxyChapterState.downloading => tokens.brand,
    };
    return SizedBox.square(
      dimension: GalaxyMetrics.minimumTouchTarget,
      child: IconButton(
        tooltip: tooltip,
        onPressed: chapter.state == GalaxyChapterState.downloaded
            ? null
            : onPressed,
        color: color,
        disabledColor: color,
        icon: Icon(icon),
      ),
    );
  }
}
