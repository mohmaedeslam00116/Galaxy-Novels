import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../data/models/novel_details_data.dart';
import '../../../../shared/widgets/novel_cover.dart';
import '../../../../shared/widgets/status_badge.dart';

class NovelDetailsHeader extends StatelessWidget {
  const NovelDetailsHeader({
    required this.details,
    this.chaptersCount,
    super.key,
  });

  final NovelDetails details;
  final int? chaptersCount;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final countryLabel = _countryLabel(details.country);
    final visibleChaptersCount = chaptersCount ?? details.chaptersCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: DecoratedBox(
        key: const ValueKey('novel-details-hero-panel'),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
          boxShadow: [
            BoxShadow(
              color: tokens.primary.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final cover = _CoverShowcase(details: details, compact: !isWide);
              final info = _HeroInfo(
                details: details,
                countryLabel: countryLabel,
                alignCenter: !isWide,
              );

              return Column(
                children: [
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        cover,
                        const SizedBox(width: 18),
                        Expanded(child: info),
                      ],
                    )
                  else ...[
                    cover,
                    const SizedBox(height: 16),
                    info,
                  ],
                  const SizedBox(height: 16),
                  _HeroStatsStrip(
                    details: details,
                    chaptersCount: visibleChaptersCount,
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

class _HeroInfo extends StatelessWidget {
  const _HeroInfo({
    required this.details,
    required this.countryLabel,
    required this.alignCenter,
  });

  final NovelDetails details;
  final String countryLabel;
  final bool alignCenter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final crossAxisAlignment = alignCenter
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = alignCenter ? TextAlign.center : TextAlign.start;
    final wrapAlignment = alignCenter
        ? WrapAlignment.center
        : WrapAlignment.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          details.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.16,
          ),
        ),
        if (details.originalTitle.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            details.originalTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          alignment: wrapAlignment,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (details.statusLabel.isNotEmpty)
              StatusBadge(
                label: details.statusLabel,
                emphasis: StatusBadgeEmphasis.gold,
              ),
            if (countryLabel.isNotEmpty)
              _MetaPill(
                icon: Icons.public_rounded,
                label: countryLabel,
                color: tokens.accent,
              ),
          ],
        ),
        if (details.author.isNotEmpty || details.translator.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: wrapAlignment,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (details.author.isNotEmpty)
                _CreditPill(label: 'المؤلف', value: details.author),
              if (details.translator.isNotEmpty)
                _CreditPill(label: 'المترجم', value: details.translator),
            ],
          ),
        ],
        if (details.genres.isNotEmpty) ...[
          const SizedBox(height: 14),
          _GenreChips(genres: details.genres, alignment: wrapAlignment),
        ],
      ],
    );
  }
}

class _CoverShowcase extends StatelessWidget {
  const _CoverShowcase({required this.details, required this.compact});

  final NovelDetails details;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final width = compact ? 172.0 : 156.0;

    return Semantics(
      label: 'غلاف رواية ${details.title}',
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
          boxShadow: [
            BoxShadow(
              color: tokens.accent.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: NovelCover(
            title: details.title,
            imageUrl: details.bestCover,
            width: width,
            height: width * 1.5,
            borderRadius: 8,
          ),
        ),
      ),
    );
  }
}

class _HeroStatsStrip extends StatelessWidget {
  const _HeroStatsStrip({required this.details, required this.chaptersCount});

  final NovelDetails details;
  final int chaptersCount;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final rating = details.ratingAverage > 0
        ? details.ratingAverage.toStringAsFixed(1)
        : '0.0';

    return DecoratedBox(
      key: const ValueKey('novel-details-stats-strip'),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: _HeroStatItem(
                icon: Icons.menu_book_outlined,
                value: chaptersCount.toString(),
                label: 'فصل',
                color: tokens.accent,
              ),
            ),
            _StatDivider(color: tokens.border),
            Expanded(
              child: _HeroStatItem(
                icon: Icons.visibility_outlined,
                value: _compactNumber(details.views),
                label: 'مشاهدة',
                color: tokens.accent,
              ),
            ),
            _StatDivider(color: tokens.border),
            Expanded(
              child: _HeroStatItem(
                icon: Icons.star_rounded,
                value: rating,
                label: _ratingCountLabel(details.ratingCount),
                color: tokens.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  const _HeroStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: VerticalDivider(width: 1, thickness: 1, color: color),
    );
  }
}

class _CreditPill extends StatelessWidget {
  const _CreditPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Container(
      constraints: const BoxConstraints(minHeight: 34, maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tokens.surfaceSoft.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.genres, required this.alignment});

  final List<NovelGenre> genres;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Wrap(
      alignment: alignment,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final genre in genres.take(8))
          _MetaPill(label: genre.name, color: tokens.accent),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Container(
      constraints: const BoxConstraints(minHeight: 30, maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _compactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

String _ratingCountLabel(int count) {
  if (count == 1) {
    return 'تقييم واحد';
  }
  if (count == 2) {
    return 'تقييمان';
  }
  return '$count تقييمات';
}

String _countryLabel(String value) {
  final normalized = value.trim().toLowerCase();
  return switch (normalized) {
    '' => '',
    'cn' || 'china' => 'الصينية',
    'jp' || 'japan' => 'اليابانية',
    'kr' || 'korea' || 'south korea' => 'الكورية',
    'us' || 'usa' || 'en' || 'english' => 'الإنجليزية',
    _ => value,
  };
}
