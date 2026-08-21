import 'package:flutter/material.dart';

import '../domain/home_customization.dart';
import 'home_card_appearance.dart';
import 'home_density_metrics.dart';

class HomeCustomizationPreview extends StatelessWidget {
  const HomeCustomizationPreview({required this.customization, super.key});

  final HomeCustomization customization;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visibleSections = customization.sectionOrder
        .where(customization.isVisible)
        .toList(growable: false);
    return Container(
      key: const ValueKey('home-customization-preview'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PreviewTopBar(scheme: scheme),
          const SizedBox(height: 10),
          for (var index = 0; index < visibleSections.length; index++) ...[
            _PreviewSection(
              section: visibleSections[index],
              customization: customization,
            ),
            if (index == 0) const _PreviewAdPlaceholder(),
          ],
        ],
      ),
    );
  }
}

class _PreviewTopBar extends StatelessWidget {
  const _PreviewTopBar({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.menu_rounded, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'مجرة الروايات',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.section, required this.customization});

  final HomeSectionId section;
  final HomeCustomization customization;

  @override
  Widget build(BuildContext context) {
    final spacing = 5 * customization.density.scale;
    final content = Padding(
      padding: EdgeInsets.only(bottom: 7 * customization.density.scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _sectionTitle(section),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          _PreviewContent(section: section, customization: customization),
        ],
      ),
    );
    if (customization.containerFor(section) == HomeSectionContainer.open) {
      return content;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: homeSectionPanelDecoration(context, customization),
      child: content,
    );
  }
}

class _PreviewContent extends StatelessWidget {
  const _PreviewContent({required this.section, required this.customization});

  final HomeSectionId section;
  final HomeCustomization customization;

  @override
  Widget build(BuildContext context) {
    final isGrid = switch (section) {
      HomeSectionId.continueReading =>
        customization.continueReadingTemplate ==
            ContinueReadingCardTemplate.coverFocus,
      HomeSectionId.becauseYouRead =>
        customization.recommendedNovelsLayout == RecommendedNovelsLayout.grid,
      HomeSectionId.updatedNovels =>
        customization.updatedNovelsLayout == UpdatedNovelsLayout.grid,
      HomeSectionId.latestUpdates =>
        customization.latestUpdatesLayout == LatestUpdatesLayout.grid,
    };
    if (isGrid) {
      return _PreviewGrid(section: section, customization: customization);
    }
    final isCompact = switch (section) {
      HomeSectionId.continueReading =>
        customization.continueReadingTemplate ==
            ContinueReadingCardTemplate.compactStrip,
      HomeSectionId.becauseYouRead =>
        customization.recommendedNovelsTemplate ==
            RecommendedNovelCardTemplate.horizontal,
      HomeSectionId.updatedNovels =>
        customization.updatedNovelsTemplate ==
            UpdatedNovelCardTemplate.horizontal,
      HomeSectionId.latestUpdates =>
        customization.latestUpdatesTemplate == LatestUpdateCardTemplate.compact,
    };
    return _PreviewRow(
      compact: isCompact,
      section: section,
      customization: customization,
    );
  }
}

class _PreviewGrid extends StatelessWidget {
  const _PreviewGrid({required this.section, required this.customization});

  final HomeSectionId section;
  final HomeCustomization customization;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < 3; index++) ...[
          if (index > 0) const SizedBox(width: 5),
          Expanded(
            child: _PreviewBook(
              tall: true,
              section: section,
              customization: customization,
            ),
          ),
        ],
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.compact,
    required this.section,
    required this.customization,
  });

  final bool compact;
  final HomeSectionId section;
  final HomeCustomization customization;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 30 : 42,
      child: Row(
        children: [
          Expanded(
            child: _PreviewBook(
              tall: !compact,
              section: section,
              customization: customization,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _PreviewBook(
              tall: !compact,
              section: section,
              customization: customization,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewBook extends StatelessWidget {
  const _PreviewBook({
    required this.tall,
    required this.section,
    required this.customization,
  });

  final bool tall;
  final HomeSectionId section;
  final HomeCustomization customization;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: (tall ? 42 : 30) * customization.cardSizeFor(section).scale,
      child: homeCardSurface(
        context: context,
        customization: customization,
        radius: 7,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: 0.42,
            child: _PreviewCover(
              section: section,
              customization: customization,
              scheme: scheme,
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCover extends StatelessWidget {
  const _PreviewCover({
    required this.section,
    required this.customization,
    required this.scheme,
  });

  final HomeSectionId section;
  final HomeCustomization customization;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final presentation = customization.coverPresentationFor(section);
    final radius = (customization.coverCorner.radius / 3)
        .clamp(2, 7)
        .toDouble();
    final cover = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Container(
      key: ValueKey('home-mini-cover-${section.name}-${presentation.name}'),
      margin: const EdgeInsets.all(5),
      decoration: presentation == HomeCoverPresentation.fill
          ? null
          : BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(radius),
              border: presentation == HomeCoverPresentation.tonalFrame
                  ? Border.all(color: scheme.primary.withValues(alpha: 0.32))
                  : null,
            ),
      padding: presentation == HomeCoverPresentation.tonalFrame
          ? const EdgeInsets.all(2)
          : EdgeInsets.zero,
      child: presentation == HomeCoverPresentation.fill
          ? cover
          : Center(
              child: FractionallySizedBox(
                widthFactor: 0.72,
                heightFactor: 0.86,
                child: cover,
              ),
            ),
    );
  }
}

class _PreviewAdPlaceholder extends StatelessWidget {
  const _PreviewAdPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('home-preview-ad-placeholder'),
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(vertical: 3),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        'موضع الإعلان',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

String _sectionTitle(HomeSectionId section) {
  return switch (section) {
    HomeSectionId.continueReading => 'أكمل القراءة',
    HomeSectionId.becauseYouRead => 'لأنك قرأت…',
    HomeSectionId.updatedNovels => 'روايات محدثة',
    HomeSectionId.latestUpdates => 'آخر التحديثات',
  };
}
