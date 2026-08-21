import 'package:flutter/material.dart';

import '../../../data/models/home_data.dart';
import '../../../data/models/reading_progress.dart' as local_progress;
import '../../../design_system/foundation/galaxy_motion.dart';
import '../domain/home_customization.dart';
import 'home_card_appearance.dart';
import 'home_density_metrics.dart';
import 'home_novel_cover.dart';

typedef _ContinueReadingDetails = ({
  int chapterPosition,
  String chapterTitle,
  int chaptersTotal,
  int? completionPercent,
  String contentApi,
  String coverUrl,
  String novelTitle,
});

class HomeContinueReadingEntry {
  const HomeContinueReadingEntry._(this._details);

  factory HomeContinueReadingEntry.fromHome(ReadingProgress progress) {
    return HomeContinueReadingEntry._((
      chapterPosition: 0,
      chapterTitle: progress.chapterLabel,
      chaptersTotal: 0,
      completionPercent: progress.progress,
      contentApi: '',
      coverUrl: progress.coverUrl,
      novelTitle: progress.novelTitle,
    ));
  }

  factory HomeContinueReadingEntry.fromLocal(
    local_progress.ReadingProgress progress,
  ) {
    return HomeContinueReadingEntry._((
      chapterPosition: progress.chapterPosition,
      chapterTitle: progress.displayChapterTitle,
      chaptersTotal: progress.chaptersTotal,
      completionPercent: progress.completionPercent,
      contentApi: progress.contentApi,
      coverUrl: progress.coverUrl,
      novelTitle: progress.displayNovelTitle,
    ));
  }

  final _ContinueReadingDetails _details;

  int get chapterPosition => _details.chapterPosition;
  String get chapterTitle => _details.chapterTitle;
  int get chaptersTotal => _details.chaptersTotal;
  int? get completionPercent => _details.completionPercent;
  String get contentApi => _details.contentApi;
  String get coverUrl => _details.coverUrl;
  String get novelTitle => _details.novelTitle;

  String get chapterProgressLabel {
    if (chapterPosition <= 0 || chaptersTotal <= 0) {
      return chapterTitle;
    }
    return 'الفصل $chapterPosition من $chaptersTotal';
  }

  double get completionFraction => completionPercent == null
      ? 0
      : (completionPercent! / 100).clamp(0.0, 1.0);
}

class HomeContinueReadingStrip extends StatefulWidget {
  const HomeContinueReadingStrip({
    required this.entries,
    required this.onOpen,
    this.layout = ContinueReadingLayout.cards,
    this.density = HomeDensity.balanced,
    this.customization,
    super.key,
  });

  final List<HomeContinueReadingEntry> entries;
  final ValueChanged<HomeContinueReadingEntry> onOpen;
  final ContinueReadingLayout layout;
  final HomeDensity density;
  final HomeCustomization? customization;

  @override
  State<HomeContinueReadingStrip> createState() =>
      _HomeContinueReadingStripState();
}

class _HomeContinueReadingStripState extends State<HomeContinueReadingStrip>
    with SingleTickerProviderStateMixin {
  var _currentIndex = 0;
  var _revealedStep = 1;
  var _dragOffset = 0.0;
  var _animationFrom = 0.0;
  var _animationTo = 0.0;
  var _pendingStep = 0;
  late final AnimationController _movementController;

  HomeCustomization get _effective =>
      widget.customization ??
      HomeCustomization.defaults.copyWith(
        density: widget.density,
        continueReadingLayout: widget.layout,
      );

  @override
  void initState() {
    super.initState();
    _movementController = AnimationController(
      vsync: this,
      duration: GalaxyMotion.emphasis,
    )..addStatusListener(_finishDeckAnimation);
  }

  @override
  void didUpdateWidget(covariant HomeContinueReadingStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= widget.entries.length) {
      _currentIndex = widget.entries.length - 1;
    }
    _revealedStep = 1;
    _dragOffset = 0;
    _movementController.reset();
  }

  @override
  void dispose() {
    _movementController
      ..removeStatusListener(_finishDeckAnimation)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effective = _effective;
    final template = effective.continueReadingTemplate;
    final size = effective.cardSizeFor(HomeSectionId.continueReading);
    final textGrowth = (MediaQuery.textScalerOf(context).scale(16) - 16)
        .clamp(0, 24)
        .toDouble();
    final stripHeight =
        _stripHeight(template, size) +
        textGrowth *
            (template == ContinueReadingCardTemplate.coverFocus ? 2 : 3);
    if (template == ContinueReadingCardTemplate.detailed) {
      return _detailedDeck(effective, stripHeight + 28);
    }
    return SizedBox(
      key: const ValueKey('continue-reading-strip'),
      height: stripHeight,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: effective.density.horizontalPadding,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: widget.entries.length,
        separatorBuilder: (_, _) =>
            SizedBox(width: effective.density.itemSpacing),
        itemBuilder: (context, index) {
          final entry = widget.entries[index];
          final onTap = entry.contentApi.isEmpty
              ? null
              : () => widget.onOpen(entry);
          final card = _ContinueReadingCard(
            key: ValueKey('continue-reading-template-${template.name}-$index'),
            entry: entry,
            onTap: onTap,
            customization: effective,
          );
          return KeyedSubtree(
            key: ValueKey(
              template == ContinueReadingCardTemplate.compactStrip
                  ? 'continue-reading-compact-$index'
                  : 'continue-reading-card-$index',
            ),
            child: index == 0
                ? KeyedSubtree(
                    key: const ValueKey('continue-reading-tile'),
                    child: card,
                  )
                : card,
          );
        },
      ),
    );
  }

  Widget _detailedDeck(HomeCustomization customization, double stripHeight) {
    final count = widget.entries.length;
    if (count == 0) {
      return const SizedBox.shrink(key: ValueKey('continue-reading-strip'));
    }
    final canMove = count > 1;
    final visibleDepth = count.clamp(1, 3);
    return SizedBox(
      key: const ValueKey('continue-reading-strip'),
      height: stripHeight,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: customization.density.horizontalPadding,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => AnimatedBuilder(
                  animation: _movementController,
                  builder: (context, child) {
                    final width = constraints.maxWidth;
                    final progress = width <= 0
                        ? 0.0
                        : (_visualOffset.abs() / width).clamp(0.0, 1.0);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var depth = visibleDepth - 1; depth >= 1; depth--)
                          _buildDeckLayer(
                            customization: customization,
                            depth: depth,
                            promotion: progress,
                            entryIndex: _wrappedIndex(
                              _currentIndex + (_revealedStep * depth),
                            ),
                          ),
                        canMove
                            ? _buildDraggableDeckFront(customization, width)
                            : _positionDeckFront(
                                _buildDeckFrontCard(customization),
                              ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (canMove)
            SizedBox(
              height: 52,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const ValueKey('continue-reading-previous'),
                      tooltip: 'الرواية السابقة',
                      onPressed: _movementController.isAnimating
                          ? null
                          : () => _animateDeck(-1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 54,
                      child: Text(
                        key: const ValueKey('continue-reading-deck-counter'),
                        '${_currentIndex + 1} / $count',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      key: const ValueKey('continue-reading-next'),
                      tooltip: 'الرواية التالية',
                      onPressed: _movementController.isAnimating
                          ? null
                          : () => _animateDeck(1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeckLayer({
    required HomeCustomization customization,
    required int depth,
    required int entryIndex,
    required double promotion,
  }) {
    final restingInset = 6.0 * depth;
    final promotedInset = 6.0 * (depth - 1);
    final inset = restingInset + (promotedInset - restingInset) * promotion;
    final bottom = 6.0 * (2 - depth) + 6.0 * promotion;
    final entry = widget.entries[entryIndex];
    return PositionedDirectional(
      key: ValueKey('continue-reading-deck-layer-$depth-$entryIndex'),
      start: inset,
      end: inset,
      top: inset,
      bottom: bottom,
      child: IgnorePointer(
        child: Opacity(
          opacity: depth == 1 ? 0.66 : 0.42,
          child: Transform.scale(
            scale: 1 - depth * 0.012,
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              child: KeyedSubtree(
                key: ValueKey('continue-reading-card-$entryIndex'),
                child: _ContinueReadingCard(
                  key: ValueKey(
                    'continue-reading-template-detailed-$entryIndex',
                  ),
                  entry: entry,
                  onTap: null,
                  customization: customization,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeckFrontCard(HomeCustomization customization) {
    final entry = widget.entries[_currentIndex];
    final onTap = entry.contentApi.isEmpty ? null : () => widget.onOpen(entry);
    return KeyedSubtree(
      key: ValueKey('continue-reading-deck-front-$_currentIndex'),
      child: KeyedSubtree(
        key: ValueKey('continue-reading-card-$_currentIndex'),
        child: KeyedSubtree(
          key: const ValueKey('continue-reading-tile'),
          child: _ContinueReadingCard(
            key: ValueKey('continue-reading-template-detailed-$_currentIndex'),
            entry: entry,
            onTap: onTap,
            customization: customization,
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableDeckFront(
    HomeCustomization customization,
    double width,
  ) {
    final entry = widget.entries[_currentIndex];
    final front = Semantics(
      label: 'رواية ${entry.novelTitle}',
      value: '${_currentIndex + 1} من ${widget.entries.length}',
      increasedValue:
          '${_wrappedIndex(_currentIndex + 1) + 1} من ${widget.entries.length}',
      decreasedValue:
          '${_wrappedIndex(_currentIndex - 1) + 1} من ${widget.entries.length}',
      onIncrease: () => _animateDeck(1),
      onDecrease: () => _animateDeck(-1),
      child: GestureDetector(
        key: ValueKey('continue-reading-deck-gesture-$_currentIndex'),
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: _movementController.isAnimating
            ? null
            : _updateDeckDrag,
        onHorizontalDragEnd: _movementController.isAnimating
            ? null
            : (details) => _endDeckDrag(details, width),
        child: Transform.translate(
          offset: Offset(_visualOffset, 0),
          child: KeyedSubtree(
            key: const ValueKey('continue-reading-deck-draggable'),
            child: _buildDeckFrontCard(customization),
          ),
        ),
      ),
    );
    return _positionDeckFront(front);
  }

  Widget _positionDeckFront(Widget front) {
    return PositionedDirectional(
      start: 0,
      end: 0,
      top: 0,
      bottom: 12,
      child: front,
    );
  }

  double get _visualOffset => _movementController.isAnimating
      ? _animationFrom +
            (_animationTo - _animationFrom) *
                Curves.easeOutCubic.transform(_movementController.value)
      : _dragOffset;

  void _updateDeckDrag(DragUpdateDetails details) {
    if (_movementController.isAnimating) return;
    final delta = details.primaryDelta ?? 0;
    if (delta == 0) return;
    setState(() {
      _dragOffset += delta;
      _revealedStep = _dragOffset < 0 ? 1 : -1;
    });
  }

  int _wrappedIndex(int index) {
    final count = widget.entries.length;
    return ((index % count) + count) % count;
  }

  void _endDeckDrag(DragEndDetails details, double width) {
    if (_movementController.isAnimating) return;
    final velocity = details.primaryVelocity ?? 0;
    final shouldMove =
        _dragOffset.abs() >= width * 0.22 || velocity.abs() > 650;
    if (!shouldMove) {
      if (MediaQuery.disableAnimationsOf(context)) {
        setState(() {
          _dragOffset = 0;
          _revealedStep = 1;
        });
        return;
      }
      _startDeckAnimation(to: 0, pendingStep: 0);
      return;
    }
    final step = _dragOffset == 0
        ? (velocity < 0 ? 1 : -1)
        : (_dragOffset < 0 ? 1 : -1);
    if (MediaQuery.disableAnimationsOf(context)) {
      _moveDeckImmediately(step);
      return;
    }
    _startDeckAnimation(to: step > 0 ? -width : width, pendingStep: step);
  }

  void _animateDeck(int step) {
    if (widget.entries.length < 2 || _movementController.isAnimating) {
      return;
    }
    final width = context.size?.width ?? MediaQuery.sizeOf(context).width;
    _revealedStep = step;
    if (MediaQuery.disableAnimationsOf(context)) {
      _moveDeckImmediately(step);
      return;
    }
    _startDeckAnimation(to: step > 0 ? -width : width, pendingStep: step);
  }

  void _startDeckAnimation({required double to, required int pendingStep}) {
    _animationFrom = _dragOffset;
    _animationTo = to;
    _pendingStep = pendingStep;
    _movementController.forward(from: 0);
  }

  void _finishDeckAnimation(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final step = _pendingStep;
    _movementController.reset();
    if (step == 0) {
      setState(() {
        _dragOffset = 0;
        _revealedStep = 1;
      });
      return;
    }
    _moveDeckImmediately(step);
  }

  void _moveDeckImmediately(int step) {
    setState(() {
      _currentIndex = _wrappedIndex(_currentIndex + step);
      _revealedStep = 1;
      _dragOffset = 0;
      _pendingStep = 0;
    });
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({
    required this.entry,
    required this.onTap,
    required this.customization,
    super.key,
  });

  final HomeContinueReadingEntry entry;
  final VoidCallback? onTap;
  final HomeCustomization customization;

  @override
  Widget build(BuildContext context) {
    final template = customization.continueReadingTemplate;
    final size = customization.cardSizeFor(HomeSectionId.continueReading);
    final showsAction =
        onTap != null &&
        customization.showsQuickAction(HomeSectionId.continueReading);
    final card = homeCardSurface(
      context: context,
      customization: customization,
      radius: customization.coverCorner.radius,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            switch (template) {
              ContinueReadingCardTemplate.detailed => _DetailedContent(
                entry: entry,
                customization: customization,
                reserveActionSpace: showsAction,
              ),
              ContinueReadingCardTemplate.compactStrip => _CompactContent(
                entry: entry,
                customization: customization,
                reserveActionSpace: showsAction,
              ),
              ContinueReadingCardTemplate.coverFocus => _CoverFocusContent(
                entry: entry,
                customization: customization,
                reserveActionSpace: showsAction,
              ),
            },
            if (showsAction)
              PositionedDirectional(
                end: 2,
                bottom: 2,
                child: IconButton(
                  key: ValueKey('continue-reading-action-${entry.novelTitle}'),
                  tooltip: 'متابعة القراءة',
                  onPressed: onTap,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.88),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  iconSize: 18,
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
              ),
          ],
        ),
      ),
    );
    return SizedBox(
      width: template == ContinueReadingCardTemplate.detailed
          ? double.infinity
          : _cardWidth(template, size),
      child: card,
    );
  }
}

class _DetailedContent extends StatelessWidget {
  const _DetailedContent({
    required this.entry,
    required this.customization,
    required this.reserveActionSpace,
  });

  final HomeContinueReadingEntry entry;
  final HomeCustomization customization;
  final bool reserveActionSpace;

  @override
  Widget build(BuildContext context) {
    final scale = customization
        .cardSizeFor(HomeSectionId.continueReading)
        .scale;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 96 * scale,
          child: LayoutBuilder(
            builder: (context, constraints) => HomeNovelCover(
              section: HomeSectionId.continueReading,
              customization: customization,
              title: entry.novelTitle,
              imageUrl: entry.coverUrl,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              14 * scale,
              12 * scale,
              reserveActionSpace ? 46 : 14 * scale,
              12 * scale,
            ),
            child: _ReadingDetails(
              entry: entry,
              customization: customization,
              maxTitleLines: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactContent extends StatelessWidget {
  const _CompactContent({
    required this.entry,
    required this.customization,
    required this.reserveActionSpace,
  });

  final HomeContinueReadingEntry entry;
  final HomeCustomization customization;
  final bool reserveActionSpace;

  @override
  Widget build(BuildContext context) {
    final scale = customization
        .cardSizeFor(HomeSectionId.continueReading)
        .scale;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        8 * scale,
        8 * scale,
        reserveActionSpace ? 44 : 8 * scale,
        8 * scale,
      ),
      child: Row(
        children: [
          HomeNovelCover(
            section: HomeSectionId.continueReading,
            customization: customization,
            title: entry.novelTitle,
            imageUrl: entry.coverUrl,
            width: 46 * scale,
            height: 64 * scale,
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: _ReadingDetails(
              entry: entry,
              customization: customization,
              maxTitleLines: 1,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverFocusContent extends StatelessWidget {
  const _CoverFocusContent({
    required this.entry,
    required this.customization,
    required this.reserveActionSpace,
  });

  final HomeContinueReadingEntry entry;
  final HomeCustomization customization;
  final bool reserveActionSpace;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          HomeNovelCover(
            section: HomeSectionId.continueReading,
            customization: customization,
            title: entry.novelTitle,
            imageUrl: entry.coverUrl,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.scrim.withValues(alpha: 0),
                    scheme.scrim.withValues(alpha: 0.88),
                  ],
                  stops: const [0.42, 1],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 12,
            end: reserveActionSpace ? 48 : 12,
            bottom: 12,
            child: _ReadingDetails(
              entry: entry,
              customization: customization,
              maxTitleLines: 2,
              compact: true,
              onImage: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingDetails extends StatelessWidget {
  const _ReadingDetails({
    required this.entry,
    required this.customization,
    required this.maxTitleLines,
    this.compact = false,
    this.onImage = false,
  });

  final HomeContinueReadingEntry entry;
  final HomeCustomization customization;
  final int maxTitleLines;
  final bool compact;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final section = HomeSectionId.continueReading;
    final imageForeground = homeImageForeground(scheme);
    final foreground = onImage ? imageForeground : scheme.onSurface;
    final secondary = onImage
        ? imageForeground.withValues(alpha: 0.76)
        : scheme.onSurfaceVariant;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.novelTitle,
          maxLines: maxTitleLines,
          overflow: TextOverflow.ellipsis,
          style:
              (compact
                      ? Theme.of(context).textTheme.titleSmall
                      : Theme.of(context).textTheme.titleMedium)
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w900),
        ),
        if (customization.showsField(section, HomeCardField.chapter)) ...[
          const SizedBox(height: 4),
          Text(
            entry.chapterProgressLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: secondary),
          ),
        ],
        if (customization.showsField(section, HomeCardField.progress) &&
            customization.progressStyle != HomeProgressStyle.hidden) ...[
          const SizedBox(height: 7),
          _ReadingProgress(
            entry: entry,
            style: customization.progressStyle,
            onImage: onImage,
          ),
        ],
      ],
    );
  }
}

class _ReadingProgress extends StatelessWidget {
  const _ReadingProgress({
    required this.entry,
    required this.style,
    required this.onImage,
  });

  final HomeContinueReadingEntry entry;
  final HomeProgressStyle style;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percentage = entry.completionPercent ?? 0;
    final foreground = onImage ? scheme.inversePrimary : scheme.primary;
    final background = onImage
        ? scheme.onInverseSurface.withValues(alpha: 0.24)
        : scheme.surfaceContainerHighest;
    return switch (style) {
      HomeProgressStyle.bar => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: entry.completionFraction,
          minHeight: 5,
          color: foreground,
          backgroundColor: background,
        ),
      ),
      HomeProgressStyle.ring => SizedBox.square(
        dimension: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: entry.completionFraction,
              strokeWidth: 4,
              color: foreground,
              backgroundColor: background,
            ),
            Text(
              '$percentage%',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
      HomeProgressStyle.percentage => Text(
        'تمت قراءة $percentage%',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
      HomeProgressStyle.hidden => const SizedBox.shrink(),
    };
  }
}

double _stripHeight(ContinueReadingCardTemplate template, HomeCardSize size) {
  final base = switch (template) {
    ContinueReadingCardTemplate.detailed => 180.0,
    ContinueReadingCardTemplate.compactStrip => 155.0,
    ContinueReadingCardTemplate.coverFocus => 270.0,
  };
  return base * size.scale;
}

double _cardWidth(ContinueReadingCardTemplate template, HomeCardSize size) {
  final base = switch (template) {
    ContinueReadingCardTemplate.detailed => 280.0,
    ContinueReadingCardTemplate.compactStrip => 300.0,
    ContinueReadingCardTemplate.coverFocus => 210.0,
  };
  return base * size.scale;
}
