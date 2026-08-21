import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../../../data/models/reader_content_data.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../application/reader_pinch_font_scale_controller.dart';
import '../data/chapter_html_parser.dart';
import '../domain/reader_advanced_terminology.dart';
import '../domain/reader_speech_models.dart';
import '../domain/reader_term_replacement.dart';
import '../domain/reader_text_transformer.dart';
import 'reader_chrome_palette.dart';
import 'reader_font_options.dart';
import 'reader_chrome_visibility.dart';
import 'reader_preferences.dart';
import 'reader_reading_column.dart';
import 'reader_stitch_chrome.dart';
import 'reader_term_highlight.dart';

class NativeReaderContent extends StatefulWidget {
  const NativeReaderContent({
    required this.content,
    required this.preferences,
    required this.onOpenChapter,
    this.onOpenNextChapter,
    required this.onOpenComments,
    required this.onReadingActivity,
    required this.onFontScaleCommitted,
    required this.controlsVisible,
    required this.onRetry,
    required this.onControlsVisibilityChanged,
    this.speechState = ReaderSpeechState.idle,
    this.speechFollowEnabled = true,
    this.onSpeechFollowChanged,
    this.onVisibleBlockChanged,
    this.onStartSpeechFromBlock,
    this.termReplacements = const [],
    this.advancedTerminologyState = ReaderAdvancedTerminologyState.defaults,
    this.onTermLongPressed,
    this.onTermRemovalRequested,
    this.htmlParser = parseChapterHtml,
    super.key,
  });

  final ReaderChapterContent content;
  final ReaderPreferences preferences;
  final void Function(String contentApi, String title) onOpenChapter;
  final Future<void> Function(String contentApi, String title)?
  onOpenNextChapter;
  final VoidCallback onOpenComments;
  final ValueChanged<int> onReadingActivity;
  final ValueChanged<double> onFontScaleCommitted;
  final bool controlsVisible;
  final VoidCallback onRetry;
  final ValueChanged<bool> onControlsVisibilityChanged;
  final ReaderSpeechState speechState;
  final bool speechFollowEnabled;
  final ValueChanged<bool>? onSpeechFollowChanged;
  final ValueChanged<int>? onVisibleBlockChanged;
  final ValueChanged<int>? onStartSpeechFromBlock;
  final List<ReaderTermReplacement> termReplacements;
  final ReaderAdvancedTerminologyState advancedTerminologyState;
  final Future<void> Function(String source)? onTermLongPressed;
  final Future<void> Function(String source)? onTermRemovalRequested;
  final ChapterHtmlParser htmlParser;

  @override
  State<NativeReaderContent> createState() => _NativeReaderContentState();
}

class _NativeReaderContentState extends State<NativeReaderContent>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _autoScrollClock;
  late final ReaderPinchFontScaleController _pinchFontScaleController;
  late List<ChapterTextBlock> _blocks;
  final Set<int> _pressedPointerIds = <int>{};
  final Map<int, GlobalKey> _blockKeys = <int, GlobalKey>{};
  ScrollHoldController? _scrollHoldController;
  double? _gestureFontScale;
  Duration? _lastAutoScrollElapsed;
  Timer? _autoScrollResumeTimer;
  bool _continuousChapterRequested = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _blocks = widget.htmlParser(widget.content.contentHtml);
    _scrollController = ScrollController()..addListener(_emitReadingActivity);
    _pinchFontScaleController = ReaderPinchFontScaleController(
      minFontScale: ReaderPreferences.minFontScale,
      maxFontScale: ReaderPreferences.maxFontScale,
    );
    _autoScrollClock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_advanceAutoScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _emitReadingActivity();
        _syncAutoScroll();
      }
    });
  }

  @override
  void didUpdateWidget(covariant NativeReaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content.contentHtml != widget.content.contentHtml ||
        oldWidget.htmlParser != widget.htmlParser) {
      _blocks = widget.htmlParser(widget.content.contentHtml);
      _blockKeys.clear();
    }
    if (oldWidget.content.id != widget.content.id) {
      _cancelPinchZoom();
      _continuousChapterRequested = false;
      _stopAutoScroll();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) {
          return;
        }
        _scrollController.jumpTo(0);
        _emitReadingActivity();
        _syncAutoScroll();
      });
    }
    if (oldWidget.preferences.pinchZoomEnabled &&
        !widget.preferences.pinchZoomEnabled) {
      _cancelPinchZoom();
      _scheduleAutoScrollResumeIfIdle();
    } else if (_gestureFontScale != null &&
        oldWidget.preferences.fontScale != widget.preferences.fontScale) {
      _gestureFontScale = null;
    }
    if (oldWidget.preferences.autoScrollEnabled !=
            widget.preferences.autoScrollEnabled ||
        oldWidget.preferences.autoScrollSpeed !=
            widget.preferences.autoScrollSpeed ||
        oldWidget.controlsVisible != widget.controlsVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncAutoScroll();
      });
    }
    final speechBlockChanged =
        oldWidget.speechState.blockIndex != widget.speechState.blockIndex ||
        oldWidget.speechState.chapter?.chapterId !=
            widget.speechState.chapter?.chapterId;
    if (speechBlockChanged && widget.speechFollowEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _followSpeechBlock());
    }
    if (oldWidget.speechState.status != widget.speechState.status) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncAutoScroll();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _pinchFontScaleController.reset();
    _pressedPointerIds.clear();
    _releaseScrollHold();
    _autoScrollResumeTimer?.cancel();
    _autoScrollResumeTimer = null;
    _autoScrollClock
      ..removeListener(_advanceAutoScroll)
      ..dispose();
    _scrollController
      ..removeListener(_emitReadingActivity)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = widget.content;
    final readerScheme = widget.preferences.colorSchemeFor(context);
    final chromePalette = resolveReaderChromePalette(scheme: theme.colorScheme);
    final mediaQuery = MediaQuery.of(context);
    final textScaler = mediaQuery.textScaler;
    final fontScale = _gestureFontScale ?? widget.preferences.fontScale;
    final headingStyle = _readerTextStyle(
      theme.textTheme.titleLarge,
      fallbackSize: 22,
      fontScale: fontScale,
      fontFamily: widget.preferences.fontFamily,
      height: 1.55,
      color: readerScheme.onSurface,
      fontWeight: FontWeight.w900,
    );
    final paragraphStyle = _readerTextStyle(
      theme.textTheme.titleMedium,
      fallbackSize: 16,
      fontScale: fontScale,
      fontFamily: widget.preferences.fontFamily,
      height: widget.preferences.lineHeight,
      color: readerScheme.onSurface.withValues(alpha: 0.92),
    );
    final titleStyle = _readerTextStyle(
      theme.textTheme.headlineSmall,
      fallbackSize: 24,
      fontScale: fontScale,
      fontFamily: widget.preferences.fontFamily,
      height: 1.45,
      color: readerScheme.onSurface,
      fontWeight: FontWeight.w900,
    );
    final termHighlightColor = readerTermHighlightColor(
      readerScheme.brightness,
    );
    final headerCount = content.effectiveTitle.isEmpty ? 0 : 2;
    final tabletLandscape = isReaderTabletLandscape(mediaQuery);

    final readingSurface = Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: GestureDetector(
        key: const ValueKey('reader-content-tap-area'),
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: _blocks.isEmpty
            ? AppEmptyState(
                title: 'هذا الفصل فارغ الآن',
                message: 'لا يتوفر نص قابل للقراءة في هذا الفصل.',
                actionLabel: 'إعادة المحاولة',
                onAction: widget.onRetry,
              )
            : NotificationListener<UserScrollNotification>(
                onNotification: _handleUserScroll,
                child: ListView.builder(
                  key: const ValueKey('reader-scrollable'),
                  controller: _scrollController,
                  physics: _pinchFontScaleController.isActive
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  padding: EdgeInsets.fromLTRB(
                    0,
                    mediaQuery.padding.top + 18,
                    0,
                    mediaQuery.padding.bottom +
                        mediaQuery.viewInsets.bottom +
                        (tabletLandscape ? 32 : 110),
                  ),
                  itemCount: headerCount + _blocks.length,
                  itemBuilder: (context, index) {
                    final Widget item;
                    if (headerCount > 0 && index == 0) {
                      item = _readerTitle(titleStyle, termHighlightColor);
                    } else if (headerCount > 0 && index == 1) {
                      item = const SizedBox(height: 18);
                    } else {
                      item = _readerTextBlock(
                        index - headerCount,
                        headingStyle,
                        paragraphStyle,
                        termHighlightColor,
                      );
                    }
                    return ReaderReadingColumn(
                      paragraphStyle: paragraphStyle,
                      textWidth: widget.preferences.textWidth,
                      textScaler: textScaler,
                      child: item,
                    );
                  },
                ),
              ),
      ),
    );

    final readerLayout = tabletLandscape
        ? _buildDockedLayout(
            readingSurface: readingSurface,
            mediaQuery: mediaQuery,
            chromePalette: chromePalette,
            content: content,
          )
        : _buildFloatingLayout(
            readingSurface: readingSurface,
            mediaQuery: mediaQuery,
            chromePalette: chromePalette,
            content: content,
          );
    return ColoredBox(
      key: const ValueKey('reader-background'),
      color: readerScheme.surface,
      child: Stack(
        children: [
          Positioned.fill(child: readerLayout),
          if (widget.speechState.isActive && !widget.speechFollowEnabled)
            PositionedDirectional(
              start: 16,
              end: 16,
              bottom: tabletLandscape ? 82 : 112,
              child: Center(
                child: FilledButton.tonalIcon(
                  key: const ValueKey('reader-return-to-speech'),
                  onPressed: () {
                    widget.onSpeechFollowChanged?.call(true);
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _followSpeechBlock(),
                    );
                  },
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('العودة لموضع الصوت'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingLayout({
    required Widget readingSurface,
    required MediaQueryData mediaQuery,
    required ReaderChromePalette chromePalette,
    required ReaderChapterContent content,
  }) {
    return Stack(
      children: [
        Positioned.fill(child: readingSurface),
        PositionedDirectional(
          start: 16,
          end: 16,
          bottom: 16 + mediaQuery.viewInsets.bottom,
          child: SafeArea(
            top: false,
            child: ReaderChromeVisibility(
              visible: widget.controlsVisible,
              hiddenOffset: const Offset(0, 0.18),
              keys: const ReaderChromeVisibilityKeys(
                excludeSemantics: ValueKey('reader-controls-exclude-semantics'),
                ignorePointer: ValueKey('reader-controls-ignore-pointer'),
              ),
              child: ReaderStitchBottomPill(
                key: const ValueKey('reader-floating-controls'),
                palette: chromePalette,
                progress: _chapterProgress(content),
                navigation: _chapterNavigation(content),
                onComments: widget.onOpenComments,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDockedLayout({
    required Widget readingSurface,
    required MediaQueryData mediaQuery,
    required ReaderChromePalette chromePalette,
    required ReaderChapterContent content,
  }) {
    return Column(
      children: [
        Expanded(child: readingSurface),
        ReaderDockedChromeVisibility(
          visible: widget.controlsVisible,
          keys: const ReaderChromeVisibilityKeys(
            excludeSemantics: ValueKey('reader-controls-exclude-semantics'),
            ignorePointer: ValueKey('reader-controls-ignore-pointer'),
          ),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
              child: ReaderStitchBottomDock(
                palette: chromePalette,
                progress: _chapterProgress(content),
                navigation: _chapterNavigation(content),
                onComments: widget.onOpenComments,
              ),
            ),
          ),
        ),
      ],
    );
  }

  ReaderChapterProgress _chapterProgress(ReaderChapterContent content) {
    return (
      label: content.total > 0
          ? 'الفصل ${content.position} من ${content.total}'
          : '',
      value: content.total > 0
          ? (content.position / content.total).clamp(0.0, 1.0)
          : 0,
    );
  }

  ReaderChapterNavigationActions _chapterNavigation(
    ReaderChapterContent content,
  ) {
    final hasPrevious = content.navigation.previousApi.isNotEmpty;
    final hasNext = content.navigation.nextApi.isNotEmpty;
    return (
      onPrevious: hasPrevious
          ? () => widget.onOpenChapter(
              content.navigation.previousApi,
              'الفصل السابق',
            )
          : null,
      onNext: hasNext
          ? () => unawaited(
              _openNextChapter(content.navigation.nextApi, 'الفصل التالي'),
            )
          : null,
    );
  }

  Widget _readerTitle(TextStyle style, Color termHighlightColor) {
    return _ReplaceableReaderText(
      segments: _termSegments(widget.content.effectiveTitle),
      textAlign: TextAlign.center,
      style: style,
      highlightEnabled: widget.preferences.highlightReplacedTerms,
      highlightColor: termHighlightColor,
      onTap: _toggleControls,
      onTermLongPressed: widget.onTermLongPressed,
      onTermRemovalRequested: widget.onTermRemovalRequested,
    );
  }

  Widget _readerTextBlock(
    int index,
    TextStyle headingStyle,
    TextStyle paragraphStyle,
    Color termHighlightColor,
  ) {
    final block = _blocks[index];
    final segments = _termSegments(block.text);
    if (segments.isEmpty ||
        segments.every((segment) => segment.text.trim().isEmpty)) {
      return const SizedBox.shrink();
    }
    final speechHighlighted = _speechHighlightsBlock(index);
    return Container(
      key: _blockKeys.putIfAbsent(index, GlobalKey.new),
      padding: EdgeInsets.only(
        bottom: block.type == ChapterTextBlockType.heading ? 14 : 16,
      ),
      decoration: speechHighlighted
          ? BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: KeyedSubtree(
        key: speechHighlighted
            ? ValueKey('reader-speech-highlight-$index')
            : ValueKey('reader-text-block-$index'),
        child: _ReplaceableReaderText(
          segments: segments,
          textAlign: TextAlign.start,
          style: block.type == ChapterTextBlockType.heading
              ? headingStyle
              : paragraphStyle,
          highlightEnabled: widget.preferences.highlightReplacedTerms,
          highlightColor: termHighlightColor,
          onTap: _toggleControls,
          onTermLongPressed: widget.onTermLongPressed,
          onTermRemovalRequested: widget.onTermRemovalRequested,
          onStartSpeech: widget.onStartSpeechFromBlock == null
              ? null
              : () => widget.onStartSpeechFromBlock!(index),
          speechHighlightStart: speechHighlighted
              ? widget.speechState.characterStart
              : null,
          speechHighlightEnd: speechHighlighted
              ? widget.speechState.characterEnd
              : null,
        ),
      ),
    );
  }

  bool _speechHighlightsBlock(int index) {
    return widget.speechState.chapter?.chapterId == widget.content.id &&
        widget.speechState.blockIndex == index &&
        widget.speechState.isActive;
  }

  List<ReaderTermTextSegment> _termSegments(String text) {
    return transformReaderText(
      text: text,
      novelId: widget.content.novelId,
      personalReplacements: widget.termReplacements,
      advancedState: widget.advancedTerminologyState,
    ).segments;
  }

  void _toggleControls() {
    widget.onControlsVisibilityChanged(!widget.controlsVisible);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pressedPointerIds.add(event.pointer);
    _emitReadingActivity();
    _pauseAutoScrollForInteraction();
    if (!widget.preferences.pinchZoomEnabled) return;

    final started = _pinchFontScaleController.addPointer(
      pointer: event.pointer,
      position: event.localPosition,
      baseFontScale: _gestureFontScale ?? widget.preferences.fontScale,
    );
    if (!started) return;

    _holdScrollPosition();
    setState(() {
      _gestureFontScale ??= widget.preferences.fontScale;
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!widget.preferences.pinchZoomEnabled) return;
    final nextScale = _pinchFontScaleController.updatePointer(
      pointer: event.pointer,
      position: event.localPosition,
    );
    if (nextScale == null || nextScale == _gestureFontScale) return;
    setState(() {
      _gestureFontScale = nextScale;
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pressedPointerIds.remove(event.pointer);
    final wasActive = _pinchFontScaleController.isActive;
    final committedScale = _pinchFontScaleController.removePointer(
      event.pointer,
      commit: true,
    );
    if (wasActive && !_pinchFontScaleController.isActive) {
      _releaseScrollHold();
      if (committedScale != null) {
        if (committedScale == widget.preferences.fontScale) {
          setState(() => _gestureFontScale = null);
        } else {
          setState(() => _gestureFontScale = committedScale);
          widget.onFontScaleCommitted(committedScale);
        }
      }
    }
    _scheduleAutoScrollResumeIfIdle();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pressedPointerIds.remove(event.pointer);
    final wasActive = _pinchFontScaleController.isActive;
    _pinchFontScaleController.removePointer(event.pointer, commit: false);
    if (wasActive && !_pinchFontScaleController.isActive) {
      _releaseScrollHold();
      setState(() => _gestureFontScale = null);
    }
    _scheduleAutoScrollResumeIfIdle();
  }

  void _holdScrollPosition() {
    if (_scrollHoldController != null || !_scrollController.hasClients) return;
    _scrollHoldController = _scrollController.position.hold(() {
      _scrollHoldController = null;
    });
  }

  void _releaseScrollHold() {
    final holdController = _scrollHoldController;
    _scrollHoldController = null;
    holdController?.cancel();
  }

  void _cancelPinchZoom() {
    _pinchFontScaleController.reset();
    _releaseScrollHold();
    _gestureFontScale = null;
  }

  void _emitReadingActivity() {
    if (!_scrollController.hasClients) {
      widget.onReadingActivity(0);
      return;
    }
    final position = _scrollController.position;
    final totalExtent = position.maxScrollExtent + position.viewportDimension;
    final viewedExtent = position.pixels + position.viewportDimension;
    final progress = totalExtent <= 0
        ? 100
        : ((viewedExtent / totalExtent) * 100).round().clamp(0, 100);
    widget.onReadingActivity(progress);
    _emitVisibleBlock();
    if (position.maxScrollExtent > 0 &&
        position.pixels >= position.maxScrollExtent - 12) {
      _finishCurrentChapterScroll();
    }
  }

  void _emitVisibleBlock() {
    final callback = widget.onVisibleBlockChanged;
    if (callback == null) return;
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (final entry in _blockKeys.entries) {
      final renderObject = entry.value.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached) continue;
      final top = renderObject.localToGlobal(Offset.zero).dy;
      final bottom = top + renderObject.size.height;
      if (bottom < 0) continue;
      final distance = top.abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = entry.key;
      }
    }
    callback(bestIndex);
  }

  bool _handleUserScroll(UserScrollNotification notification) {
    if (notification.direction != ScrollDirection.idle &&
        widget.speechState.status == ReaderSpeechStatus.playing &&
        widget.speechFollowEnabled) {
      widget.onSpeechFollowChanged?.call(false);
    }
    return false;
  }

  void _followSpeechBlock() {
    if (_disposed || !mounted || !widget.speechFollowEnabled) return;
    final index = widget.speechState.blockIndex;
    final blockContext = _blockKeys[index]?.currentContext;
    if (blockContext != null) {
      unawaited(
        Scrollable.ensureVisible(
          blockContext,
          alignment: 0.24,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        ),
      );
      return;
    }
    if (!_scrollController.hasClients || _blocks.length <= 1) return;
    final position = _scrollController.position;
    final target =
        position.maxScrollExtent *
        (index.clamp(0, _blocks.length - 1)) /
        (_blocks.length - 1);
    unawaited(
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _syncAutoScroll() {
    if (_disposed || !mounted) return;
    final shouldScroll =
        widget.preferences.autoScrollEnabled &&
        !widget.speechState.suspendsAutoScroll &&
        !_pinchFontScaleController.isActive &&
        _pressedPointerIds.isEmpty &&
        !widget.controlsVisible &&
        _blocks.isNotEmpty &&
        _scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0;
    if (!shouldScroll) {
      _stopAutoScroll();
      return;
    }
    if (!_autoScrollClock.isAnimating) {
      _lastAutoScrollElapsed = null;
      _autoScrollClock.repeat();
    }
  }

  void _advanceAutoScroll() {
    if (_disposed) return;
    if (!_scrollController.hasClients) return;
    final elapsed = _autoScrollClock.lastElapsedDuration;
    final previousElapsed = _lastAutoScrollElapsed;
    _lastAutoScrollElapsed = elapsed;
    if (elapsed == null || previousElapsed == null) return;

    final elapsedSeconds =
        (elapsed - previousElapsed).inMicroseconds /
        Duration.microsecondsPerSecond;
    final position = _scrollController.position;
    final target =
        (position.pixels +
                (widget.preferences.autoScrollSpeed * elapsedSeconds))
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    if (target == position.pixels) {
      _finishCurrentChapterScroll();
      return;
    }
    _scrollController.jumpTo(target);
  }

  void _pauseAutoScrollForInteraction() {
    _autoScrollResumeTimer?.cancel();
    _stopAutoScroll();
  }

  void _scheduleAutoScrollResume() {
    if (_disposed) return;
    _autoScrollResumeTimer?.cancel();
    _autoScrollResumeTimer = Timer(const Duration(milliseconds: 900), () {
      _autoScrollResumeTimer = null;
      _syncAutoScroll();
    });
  }

  void _scheduleAutoScrollResumeIfIdle() {
    if (_pinchFontScaleController.isActive || _pressedPointerIds.isNotEmpty) {
      return;
    }
    _scheduleAutoScrollResume();
  }

  void _stopAutoScroll() {
    _lastAutoScrollElapsed = null;
    if (_disposed) return;
    _autoScrollClock.stop();
  }

  void _finishCurrentChapterScroll() {
    _stopAutoScroll();
    final nextApi = widget.content.navigation.nextApi;
    if (!widget.preferences.continuousReading ||
        _continuousChapterRequested ||
        nextApi.isEmpty) {
      return;
    }
    _continuousChapterRequested = true;
    unawaited(_openNextChapter(nextApi, 'الفصل التالي'));
  }

  Future<void> _openNextChapter(String contentApi, String title) async {
    final callback = widget.onOpenNextChapter;
    if (callback != null) {
      await callback(contentApi, title);
      return;
    }
    widget.onOpenChapter(contentApi, title);
  }
}

class _ReplaceableReaderText extends StatefulWidget {
  const _ReplaceableReaderText({
    required this.segments,
    required this.textAlign,
    required this.style,
    required this.highlightEnabled,
    required this.highlightColor,
    required this.onTap,
    required this.onTermLongPressed,
    required this.onTermRemovalRequested,
    this.onStartSpeech,
    this.speechHighlightStart,
    this.speechHighlightEnd,
  });

  final List<ReaderTermTextSegment> segments;
  final TextAlign textAlign;
  final TextStyle style;
  final bool highlightEnabled;
  final Color highlightColor;
  final VoidCallback onTap;
  final Future<void> Function(String source)? onTermLongPressed;
  final Future<void> Function(String source)? onTermRemovalRequested;
  final VoidCallback? onStartSpeech;
  final int? speechHighlightStart;
  final int? speechHighlightEnd;

  @override
  State<_ReplaceableReaderText> createState() => _ReplaceableReaderTextState();
}

class _ReplaceableReaderTextState extends State<_ReplaceableReaderText> {
  bool _actionPending = false;

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(style: widget.style, children: _textSpans(context)),
      textAlign: widget.textAlign,
      onTap: widget.onTap,
      contextMenuBuilder:
          widget.onTermLongPressed == null &&
              widget.onTermRemovalRequested == null &&
              widget.onStartSpeech == null
          ? null
          : (context, editableTextState) {
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: [
                  if (widget.onTermLongPressed != null)
                    ContextMenuButtonItem(
                      label: 'استبدال',
                      onPressed: () => _runSelectionAction(
                        editableTextState,
                        widget.onTermLongPressed!,
                      ),
                    ),
                  if (widget.onTermRemovalRequested != null)
                    ContextMenuButtonItem(
                      label: 'إخفاء',
                      onPressed: () => _runSelectionAction(
                        editableTextState,
                        widget.onTermRemovalRequested!,
                      ),
                    ),
                  if (widget.onStartSpeech != null)
                    ContextMenuButtonItem(
                      label: 'ابدأ القراءة من هنا',
                      onPressed: () {
                        editableTextState.hideToolbar();
                        widget.onStartSpeech!();
                      },
                    ),
                ],
              );
            },
    );
  }

  List<InlineSpan> _textSpans(BuildContext context) {
    final spans = <InlineSpan>[];
    final rangeStart = widget.speechHighlightStart;
    final rangeEnd = widget.speechHighlightEnd;
    var offset = 0;
    for (final segment in widget.segments) {
      final segmentStart = offset;
      final segmentEnd = offset + segment.text.length;
      final highlightStart = rangeStart?.clamp(segmentStart, segmentEnd);
      final highlightEnd = rangeEnd?.clamp(segmentStart, segmentEnd);
      final replacementStyle = segment.isReplacement && widget.highlightEnabled
          ? TextStyle(backgroundColor: widget.highlightColor)
          : null;
      if (highlightStart == null ||
          highlightEnd == null ||
          highlightEnd <= highlightStart) {
        spans.add(TextSpan(text: segment.text, style: replacementStyle));
      } else {
        _appendTextSpan(
          spans,
          segment.text,
          0,
          highlightStart - segmentStart,
          replacementStyle,
        );
        _appendTextSpan(
          spans,
          segment.text,
          highlightStart - segmentStart,
          highlightEnd - segmentStart,
          TextStyle(
            color: Theme.of(context).colorScheme.onTertiaryContainer,
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            fontWeight: FontWeight.w800,
          ),
        );
        _appendTextSpan(
          spans,
          segment.text,
          highlightEnd - segmentStart,
          segment.text.length,
          replacementStyle,
        );
      }
      offset = segmentEnd;
    }
    return spans;
  }

  void _appendTextSpan(
    List<InlineSpan> spans,
    String text,
    int start,
    int end,
    TextStyle? style,
  ) {
    if (end <= start) return;
    spans.add(TextSpan(text: text.substring(start, end), style: style));
  }

  Future<void> _runSelectionAction(
    EditableTextState editableTextState,
    Future<void> Function(String source) callback,
  ) async {
    if (_actionPending) return;
    final selection = editableTextState.textEditingValue.selection;
    final selectedTerm = selection.textInside(_plainText).trim();
    if (selectedTerm.isEmpty) return;
    editableTextState.hideToolbar();
    _actionPending = true;
    try {
      await callback(selectedTerm);
    } finally {
      _actionPending = false;
    }
  }

  String get _plainText =>
      widget.segments.map((segment) => segment.text).join();
}

TextStyle _readerTextStyle(
  TextStyle? baseStyle, {
  required double fallbackSize,
  required double fontScale,
  required ReaderFontFamily fontFamily,
  required double height,
  required Color color,
  FontWeight? fontWeight,
}) {
  final base = baseStyle ?? TextStyle(fontSize: fallbackSize);
  return readerFontTextStyle(
    base.copyWith(
      color: color,
      fontSize: (base.fontSize ?? fallbackSize) * fontScale,
      fontWeight: fontWeight ?? base.fontWeight,
      height: height,
    ),
    fontFamily: fontFamily,
  );
}
