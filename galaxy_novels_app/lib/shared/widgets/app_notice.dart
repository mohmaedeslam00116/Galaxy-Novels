import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

enum AppNoticeKind { info, success, warning, error }

class AppNotice extends StatelessWidget {
  const AppNotice({
    required this.kind,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final AppNoticeKind kind;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final (background, foreground, icon) = switch (kind) {
      AppNoticeKind.info => (
        tokens.brandContainer,
        tokens.onBrandContainer,
        Icons.info_outline_rounded,
      ),
      AppNoticeKind.success => (
        tokens.successContainer,
        tokens.onSuccessContainer,
        Icons.check_circle_outline_rounded,
      ),
      AppNoticeKind.warning => (
        tokens.warningContainer,
        tokens.onWarningContainer,
        Icons.warning_amber_rounded,
      ),
      AppNoticeKind.error => (
        tokens.dangerContainer,
        tokens.onDangerContainer,
        Icons.error_outline_rounded,
      ),
    };

    return Semantics(
      liveRegion: kind == AppNoticeKind.error,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hasAction = actionLabel != null && onAction != null;
              final needsStackedLayout =
                  hasAction &&
                  (constraints.maxWidth < 420 ||
                      MediaQuery.textScalerOf(context).scale(14) >= 21);
              final messageRow = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: foreground),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(message, style: TextStyle(color: foreground)),
                  ),
                ],
              );
              final action = hasAction
                  ? TextButton(
                      style: TextButton.styleFrom(foregroundColor: foreground),
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    )
                  : null;

              if (needsStackedLayout) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    messageRow,
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: action!,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Icon(icon, color: foreground),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(message, style: TextStyle(color: foreground)),
                  ),
                  ?action,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
