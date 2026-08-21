import 'package:flutter/material.dart';

import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';
import '../foundation/galaxy_motion.dart';
import 'galaxy_surface.dart';

class GalaxySettingsGroup extends StatelessWidget {
  const GalaxySettingsGroup({required this.children, this.title, super.key});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final contents = <Widget>[];
    for (var index = 0; index < children.length; index += 1) {
      if (index > 0) {
        contents.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: GalaxyMetrics.space16,
            endIndent: GalaxyMetrics.space16,
            color: tokens.outline.withValues(alpha: 0.45),
          ),
        );
      }
      contents.add(children[index]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title case final value?) ...[
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: GalaxyMetrics.space8,
              bottom: GalaxyMetrics.space8,
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: tokens.contentSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        GalaxySurface(
          variant: GalaxySurfaceVariant.base,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: contents,
          ),
        ),
      ],
    );
  }
}

class GalaxySettingsTile extends StatelessWidget {
  const GalaxySettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final callback = enabled ? onTap : null;
    return _GalaxySettingsRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      onTap: callback,
      trailing:
          trailing ??
          (callback == null
              ? null
              : const Icon(Icons.chevron_left_rounded, size: 22)),
    );
  }
}

class GalaxySettingsSwitchTile extends StatelessWidget {
  const GalaxySettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final callback = enabled ? onChanged : null;
    return _GalaxySettingsRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      onTap: callback == null ? null : () => callback(!value),
      trailing: Switch(value: value, onChanged: callback),
      excludeTrailingSemantics: true,
    );
  }
}

@immutable
class GalaxyAccountSummaryData {
  const GalaxyAccountSummaryData({
    required this.title,
    required this.subtitle,
    this.badge,
    this.avatarUrl,
  });

  final String title;
  final String subtitle;
  final String? badge;
  final String? avatarUrl;
}

class GalaxySettingsAccountSummary extends StatelessWidget {
  const GalaxySettingsAccountSummary({
    required this.summary,
    required this.onTap,
    super.key,
  });

  final GalaxyAccountSummaryData summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final avatarUrl = summary.avatarUrl;
    return GalaxySurface(
      variant: GalaxySurfaceVariant.tonal,
      onTap: onTap,
      semanticLabel: summary.title,
      padding: const EdgeInsets.all(GalaxyMetrics.space16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tokens.brandContainer,
              shape: BoxShape.circle,
              image: avatarUrl == null || avatarUrl.isEmpty
                  ? null
                  : DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    ),
            ),
            alignment: Alignment.center,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Icon(
                    Icons.person_outline_rounded,
                    color: tokens.onBrandContainer,
                    size: 28,
                  )
                : null,
          ),
          const SizedBox(width: GalaxyMetrics.space12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: GalaxyMetrics.space4),
                Text(
                  summary.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.contentSecondary,
                  ),
                ),
                if (summary.badge case final badge?) ...[
                  const SizedBox(height: GalaxyMetrics.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GalaxyMetrics.space8,
                      vertical: GalaxyMetrics.space4,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.warningContainer,
                      borderRadius: BorderRadius.circular(
                        GalaxyMetrics.radiusSmall,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tokens.onWarningContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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

@immutable
class GalaxyThemePreviewData {
  const GalaxyThemePreviewData({
    required this.title,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.brand,
    required this.onBrand,
  });

  final String title;
  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color brand;
  final Color onBrand;
}

class GalaxyCompactThemePreview extends StatelessWidget {
  const GalaxyCompactThemePreview({required this.preview, super.key});

  final GalaxyThemePreviewData preview;

  @override
  Widget build(BuildContext context) {
    final contentColor = preview.canvas.computeLuminance() > 0.45
        ? const Color(0xFF252B33)
        : const Color(0xFFE8EDF4);
    return AnimatedContainer(
      key: const ValueKey('galaxy-theme-compact-preview'),
      duration: GalaxyMotion.resolve(context, GalaxyMotion.emphasis),
      curve: GalaxyMotion.curve,
      padding: const EdgeInsets.all(GalaxyMetrics.space12),
      decoration: BoxDecoration(
        color: preview.canvas,
        borderRadius: BorderRadius.circular(GalaxyMetrics.radiusCard),
        border: Border.all(color: preview.brand.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: GalaxyMetrics.space8),
                Row(
                  children: [
                    _PreviewSwatch(color: preview.surface),
                    const SizedBox(width: GalaxyMetrics.space4),
                    _PreviewSwatch(color: preview.surfaceRaised),
                    const SizedBox(width: GalaxyMetrics.space4),
                    _PreviewSwatch(color: preview.brand),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: GalaxyMetrics.space12),
          Container(
            width: 88,
            height: 76,
            padding: const EdgeInsets.all(GalaxyMetrics.space8),
            decoration: BoxDecoration(
              color: preview.surface,
              borderRadius: BorderRadius.circular(GalaxyMetrics.radiusControl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 8, color: preview.surfaceRaised),
                const Spacer(),
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: preview.brand,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 12,
                    color: preview.onBrand,
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

class _PreviewSwatch extends StatelessWidget {
  const _PreviewSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _GalaxySettingsRow extends StatelessWidget {
  const _GalaxySettingsRow({
    required this.icon,
    required this.title,
    required this.enabled,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.excludeTrailingSemantics = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool excludeTrailingSemantics;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final opacity = enabled ? 1.0 : 0.48;
    return Semantics(
      button: onTap != null,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          overlayColor: WidgetStatePropertyAll(
            tokens.brand.withValues(alpha: 0.08),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GalaxyMetrics.minimumTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GalaxyMetrics.space12,
                vertical: GalaxyMetrics.space12,
              ),
              child: Opacity(
                opacity: opacity,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tokens.brandContainer.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(
                          GalaxyMetrics.radiusControl,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 21, color: tokens.brand),
                    ),
                    const SizedBox(width: GalaxyMetrics.space12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (subtitle case final value?) ...[
                            const SizedBox(height: GalaxyMetrics.space2),
                            Text(
                              value,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: tokens.contentSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing case final widget?) ...[
                      const SizedBox(width: GalaxyMetrics.space8),
                      excludeTrailingSemantics
                          ? ExcludeSemantics(child: widget)
                          : widget,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
