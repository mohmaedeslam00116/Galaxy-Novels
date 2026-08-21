import 'package:flutter/material.dart';

import 'reader_chrome_palette.dart';

typedef ReaderChapterNavigationActions = ({
  VoidCallback? onNext,
  VoidCallback? onPrevious,
});

typedef ReaderChapterProgress = ({String label, double value});

typedef ReaderTopBarActions = ({
  bool autoScrollEnabled,
  bool speechActive,
  VoidCallback? onSpeech,
  VoidCallback onSettings,
  VoidCallback onToggleAutoScroll,
});

class ReaderStitchTopBar extends StatelessWidget {
  const ReaderStitchTopBar({
    required this.title,
    required this.palette,
    required this.actions,
    this.toolbarHeight = 64,
    super.key,
  });

  final String title;
  final ReaderChromePalette palette;
  final ReaderTopBarActions actions;
  final double toolbarHeight;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      key: const ValueKey('reader-app-bar'),
      toolbarHeight: toolbarHeight,
      centerTitle: true,
      backgroundColor: palette.background,
      foregroundColor: palette.foreground,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(color: palette.border.withValues(alpha: 0.5)),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        if (actions.onSpeech != null)
          IconButton(
            key: const ValueKey('reader-speech-button'),
            tooltip: 'القراءة الصوتية',
            onPressed: actions.onSpeech,
            style: IconButton.styleFrom(
              foregroundColor: actions.speechActive
                  ? palette.primary
                  : palette.foreground,
              backgroundColor: actions.speechActive
                  ? palette.primary.withValues(alpha: 0.16)
                  : Colors.transparent,
            ),
            icon: const Icon(Icons.record_voice_over_outlined),
          ),
        Semantics(
          label: actions.autoScrollEnabled
              ? 'إيقاف النزول التلقائي'
              : 'تشغيل النزول التلقائي',
          button: true,
          toggled: actions.autoScrollEnabled,
          onTap: actions.onToggleAutoScroll,
          excludeSemantics: true,
          child: IconButton(
            key: const ValueKey('reader-auto-scroll-toolbar-toggle'),
            tooltip: actions.autoScrollEnabled
                ? 'إيقاف النزول التلقائي'
                : 'تشغيل النزول التلقائي',
            onPressed: actions.onToggleAutoScroll,
            style: IconButton.styleFrom(
              foregroundColor: actions.autoScrollEnabled
                  ? palette.primary
                  : palette.foreground,
              backgroundColor: actions.autoScrollEnabled
                  ? palette.primary.withValues(alpha: 0.16)
                  : Colors.transparent,
            ),
            icon: Icon(
              actions.autoScrollEnabled
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
            ),
          ),
        ),
        Semantics(
          label: 'إعدادات القراءة',
          button: true,
          onTap: actions.onSettings,
          excludeSemantics: true,
          child: IconButton(
            key: const ValueKey('reader-settings-button'),
            tooltip: 'إعدادات القراءة',
            onPressed: actions.onSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ),
      ],
    );
  }
}

class ReaderStitchBottomPill extends StatelessWidget {
  const ReaderStitchBottomPill({
    required this.palette,
    required this.progress,
    required this.navigation,
    required this.onComments,
    super.key,
  });

  final ReaderChromePalette palette;
  final ReaderChapterProgress progress;
  final ReaderChapterNavigationActions navigation;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 768),
        child: Container(
          key: const ValueKey('reader-floating-pill'),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: palette.background.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.border.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (progress.label.isNotEmpty) ...[
                _ReaderProgressRow(progress: progress, palette: palette),
                const SizedBox(height: 8),
              ],
              _ReaderNavigationRow(
                palette: palette,
                navigation: navigation,
                onComments: onComments,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReaderStitchBottomDock extends StatelessWidget {
  const ReaderStitchBottomDock({
    required this.palette,
    required this.progress,
    required this.navigation,
    required this.onComments,
    super.key,
  });

  final ReaderChromePalette palette;
  final ReaderChapterProgress progress;
  final ReaderChapterNavigationActions navigation;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('reader-docked-controls'),
      color: palette.background,
      shape: Border(
        top: BorderSide(color: palette.border.withValues(alpha: 0.72)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _ReaderNavButton.primary(
                palette: palette,
                action: (
                  tooltip: 'الفصل التالي',
                  label: 'التالي',
                  icon: Icons.chevron_left_rounded,
                  onPressed: navigation.onNext,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox.square(
              dimension: 48,
              child: IconButton(
                key: const ValueKey('reader-comments-button'),
                tooltip: 'تعليقات الفصل',
                onPressed: onComments,
                style: IconButton.styleFrom(
                  foregroundColor: palette.foreground,
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
              ),
            ),
            const SizedBox(width: 16),
            if (progress.label.isNotEmpty) ...[
              Expanded(
                flex: 4,
                child: _ReaderProgressRow(progress: progress, palette: palette),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              flex: 3,
              child: _ReaderNavButton.secondary(
                palette: palette,
                action: (
                  tooltip: 'الفصل السابق',
                  label: 'السابق',
                  icon: Icons.chevron_right_rounded,
                  onPressed: navigation.onPrevious,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderProgressRow extends StatelessWidget {
  const _ReaderProgressRow({required this.progress, required this.palette});

  final ReaderChapterProgress progress;
  final ReaderChromePalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              key: const ValueKey('reader-progress-indicator'),
              value: progress.value,
              minHeight: 3,
              backgroundColor: palette.border.withValues(alpha: 0.32),
              color: palette.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            progress.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: palette.foreground.withValues(alpha: 0.76),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReaderNavigationRow extends StatelessWidget {
  const _ReaderNavigationRow({
    required this.palette,
    required this.navigation,
    required this.onComments,
  });

  final ReaderChromePalette palette;
  final ReaderChapterNavigationActions navigation;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReaderNavButton.primary(
            palette: palette,
            action: (
              tooltip: 'الفصل التالي',
              label: 'التالي',
              icon: Icons.chevron_left_rounded,
              onPressed: navigation.onNext,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox.square(
          dimension: 46,
          child: IconButton(
            key: const ValueKey('reader-comments-button'),
            tooltip: 'تعليقات الفصل',
            onPressed: onComments,
            style: IconButton.styleFrom(foregroundColor: palette.foreground),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ReaderNavButton.secondary(
            palette: palette,
            action: (
              tooltip: 'الفصل السابق',
              label: 'السابق',
              icon: Icons.chevron_right_rounded,
              onPressed: navigation.onPrevious,
            ),
          ),
        ),
      ],
    );
  }
}

typedef _ReaderNavAction = ({
  IconData icon,
  String label,
  VoidCallback? onPressed,
  String tooltip,
});

class _ReaderNavButton extends StatelessWidget {
  const _ReaderNavButton.primary({required this.palette, required this.action})
    : _isPrimary = true;

  const _ReaderNavButton.secondary({
    required this.palette,
    required this.action,
  }) : _isPrimary = false;

  final ReaderChromePalette palette;
  final _ReaderNavAction action;
  final bool _isPrimary;

  @override
  Widget build(BuildContext context) {
    final buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(action.icon, size: 20),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            action.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    final navigationButton = _isPrimary
        ? FilledButton(
            onPressed: action.onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              backgroundColor: palette.primary,
              foregroundColor: palette.primaryForeground,
              disabledBackgroundColor: palette.border.withValues(alpha: 0.3),
              disabledForegroundColor: palette.foreground.withValues(
                alpha: 0.42,
              ),
              shape: const StadiumBorder(),
            ),
            child: buttonContent,
          )
        : OutlinedButton(
            onPressed: action.onPressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: palette.foreground,
              disabledForegroundColor: palette.foreground.withValues(
                alpha: 0.42,
              ),
              side: BorderSide(color: palette.border),
              shape: const StadiumBorder(),
            ),
            child: buttonContent,
          );

    return Semantics(
      label: action.tooltip,
      button: true,
      enabled: action.onPressed != null,
      onTap: action.onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: action.tooltip,
        child: SizedBox(height: 46, child: navigationButton),
      ),
    );
  }
}
