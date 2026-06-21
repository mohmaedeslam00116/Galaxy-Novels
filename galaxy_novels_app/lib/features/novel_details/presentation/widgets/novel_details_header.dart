import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../data/models/novel_details_data.dart';
import '../../../../shared/widgets/novel_cover.dart';
import '../../../../shared/widgets/status_badge.dart';

class NovelDetailsHeader extends StatelessWidget {
  const NovelDetailsHeader({required this.details, super.key});

  final NovelDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final byline = [
      if (details.author.isNotEmpty) 'تأليف: ${details.author}',
      if (details.translator.isNotEmpty) 'ترجمة: ${details.translator}',
    ].join('  •  ');
    final countryLabel = _countryLabel(details.country);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Column(
        children: [
          _CoverShowcase(details: details),
          const SizedBox(height: 18),
          Text(
            details.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.18,
            ),
          ),
          if (details.originalTitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              details.originalTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          if (byline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              byline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
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
          const SizedBox(height: 18),
          _HeroStats(details: details),
          if (details.genres.isNotEmpty) ...[
            const SizedBox(height: 18),
            _GenreChips(genres: details.genres),
          ],
        ],
      ),
    );
  }
}

class _CoverShowcase extends StatelessWidget {
  const _CoverShowcase({required this.details});

  final NovelDetails details;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Semantics(
      label: 'غلاف رواية ${details.title}',
      image: true,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
          boxShadow: [
            BoxShadow(
              color: tokens.primary.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: tokens.accent.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: NovelCover(
          title: details.title,
          imageUrl: details.bestCover,
          width: 176,
          height: 264,
          borderRadius: 8,
        ),
      ),
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.details});

  final NovelDetails details;

  @override
  Widget build(BuildContext context) {
    final rating = details.ratingAverage > 0
        ? details.ratingAverage.toStringAsFixed(1)
        : '0.0';

    return Row(
      children: [
        Expanded(
          child: _HeroStatCard(
            icon: Icons.menu_book_outlined,
            value: details.chaptersCount.toString(),
            label: 'فصل',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeroStatCard(
            icon: Icons.visibility_outlined,
            value: _compactNumber(details.views),
            label: 'مشاهدة',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeroStatCard(
            icon: Icons.star_rounded,
            value: rating,
            label: 'تقييم',
            highlight: true,
          ),
        ),
      ],
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final color = highlight ? tokens.gold : tokens.accent;

    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 7),
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

class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.genres});

  final List<NovelGenre> genres;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Wrap(
      alignment: WrapAlignment.center,
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
