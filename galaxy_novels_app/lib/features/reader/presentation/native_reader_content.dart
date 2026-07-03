import 'package:flutter/material.dart';

import '../../../data/models/reader_content_data.dart';
import '../data/chapter_html_parser.dart';
import 'reader_preferences.dart';

class NativeReaderContent extends StatefulWidget {
  const NativeReaderContent({
    required this.content,
    required this.preferences,
    required this.onOpenChapter,
    required this.onOpenSettings,
    required this.onOpenComments,
    required this.onReadingActivity,
    super.key,
  });

  final ReaderChapterContent content;
  final ReaderPreferences preferences;
  final void Function(String contentApi, String title) onOpenChapter;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenComments;
  final ValueChanged<int> onReadingActivity;

  @override
  State<NativeReaderContent> createState() => _NativeReaderContentState();
}

class _NativeReaderContentState extends State<NativeReaderContent> {
  bool _controlsVisible = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_emitReadingActivity);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _emitReadingActivity();
      }
    });
  }

  @override
  void didUpdateWidget(covariant NativeReaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content.id != widget.content.id) {
      _controlsVisible = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) {
          return;
        }
        _scrollController.jumpTo(0);
        _emitReadingActivity();
      });
    }
  }

  @override
  void dispose() {
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
    final blocks = parseChapterHtml(content.contentHtml);
    final hasPrevious = content.navigation.previousApi.isNotEmpty;
    final hasNext = content.navigation.nextApi.isNotEmpty;
    final headingStyle = _readerTextStyle(
      theme.textTheme.titleLarge,
      fallbackSize: 22,
      fontScale: widget.preferences.fontScale,
      height: 1.55,
      color: readerScheme.onSurface,
      fontWeight: FontWeight.w900,
    );
    final paragraphStyle = _readerTextStyle(
      theme.textTheme.titleMedium,
      fallbackSize: 16,
      fontScale: widget.preferences.fontScale,
      height: widget.preferences.lineHeight,
      color: readerScheme.onSurface.withValues(alpha: 0.92),
    );

    return ColoredBox(
      key: const ValueKey('reader-background'),
      color: readerScheme.surface,
      child: Stack(
        children: [
          Listener(
            onPointerDown: (_) => _emitReadingActivity(),
            child: GestureDetector(
              key: const ValueKey('reader-content-tap-area'),
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              child: ListView(
                key: ValueKey(content.id),
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                children: [
                  if (content.effectiveTitle.isNotEmpty) ...[
                    Text(
                      content.effectiveTitle,
                      textAlign: TextAlign.center,
                      style: _readerTextStyle(
                        theme.textTheme.headlineSmall,
                        fallbackSize: 24,
                        fontScale: widget.preferences.fontScale,
                        height: 1.45,
                        color: readerScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  for (final block in blocks)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: block.type == ChapterTextBlockType.heading
                            ? 14
                            : 16,
                      ),
                      child: Text(
                        block.text,
                        textAlign: TextAlign.start,
                        style: block.type == ChapterTextBlockType.heading
                            ? headingStyle
                            : paragraphStyle,
                      ),
                    ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            start: 16,
            end: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: _controlsVisible
                    ? _ReaderFloatingControls(
                        key: const ValueKey('reader-controls-visible'),
                        colorScheme: readerScheme,
                        progressLabel: content.total > 0
                            ? '${content.position} / ${content.total}'
                            : '',
                        progressValue: content.total > 0
                            ? (content.position / content.total).clamp(0.0, 1.0)
                            : 0,
                        hasPrevious: hasPrevious,
                        hasNext: hasNext,
                        onPrevious: () => widget.onOpenChapter(
                          content.navigation.previousApi,
                          'الفصل السابق',
                        ),
                        onNext: () => widget.onOpenChapter(
                          content.navigation.nextApi,
                          'الفصل التالي',
                        ),
                        onSettings: widget.onOpenSettings,
                        onComments: widget.onOpenComments,
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('reader-controls-hidden'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
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
  }
}

class _ReaderFloatingControls extends StatelessWidget {
  const _ReaderFloatingControls({
    required this.colorScheme,
    required this.progressLabel,
    required this.progressValue,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
    required this.onSettings,
    required this.onComments,
    super.key,
  });

  final ColorScheme colorScheme;
  final String progressLabel;
  final double progressValue;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSettings;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progressLabel.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 3,
                        backgroundColor: colorScheme.outlineVariant.withValues(
                          alpha: 0.28,
                        ),
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    progressLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 330;
                final commentsButton = IconButton.filledTonal(
                  key: const ValueKey('reader-comments-button'),
                  tooltip: 'تعليقات الفصل',
                  onPressed: onComments,
                  icon: const Icon(Icons.forum_outlined),
                );
                final settingsButton = IconButton.filledTonal(
                  key: const ValueKey('reader-settings-button'),
                  tooltip: 'إعدادات القراءة',
                  onPressed: onSettings,
                  icon: const Icon(Icons.tune_rounded),
                );

                if (isCompact) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ReaderNavButton(
                              tooltip: 'الفصل التالي',
                              label: 'التالي',
                              icon: Icons.chevron_left_rounded,
                              onPressed: hasNext ? onNext : null,
                              isPrimary: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ReaderNavButton(
                              tooltip: 'الفصل السابق',
                              label: 'السابق',
                              icon: Icons.chevron_right_rounded,
                              onPressed: hasPrevious ? onPrevious : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          commentsButton,
                          const SizedBox(width: 10),
                          settingsButton,
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _ReaderNavButton(
                        tooltip: 'الفصل التالي',
                        label: 'التالي',
                        icon: Icons.chevron_left_rounded,
                        onPressed: hasNext ? onNext : null,
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    commentsButton,
                    const SizedBox(width: 8),
                    settingsButton,
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ReaderNavButton(
                        tooltip: 'الفصل السابق',
                        label: 'السابق',
                        icon: Icons.chevron_right_rounded,
                        onPressed: hasPrevious ? onPrevious : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderNavButton extends StatelessWidget {
  const _ReaderNavButton({
    required this.tooltip,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String tooltip;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final child = isPrimary
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label, overflow: TextOverflow.ellipsis),
          )
        : FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label, overflow: TextOverflow.ellipsis),
          );

    return Tooltip(
      message: tooltip,
      child: SizedBox(height: 46, child: child),
    );
  }
}

TextStyle _readerTextStyle(
  TextStyle? baseStyle, {
  required double fallbackSize,
  required double fontScale,
  required double height,
  required Color color,
  FontWeight? fontWeight,
}) {
  final base = baseStyle ?? TextStyle(fontSize: fallbackSize);
  return base.copyWith(
    color: color,
    fontSize: (base.fontSize ?? fallbackSize) * fontScale,
    fontWeight: fontWeight ?? base.fontWeight,
    height: height,
  );
}
