import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    this.emphasis = StatusBadgeEmphasis.primary,
    super.key,
  });

  final String label;
  final StatusBadgeEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final (background, foreground) = switch (_normalizedStatus(label)) {
      _NovelStatus.ongoing => (tokens.brandContainer, tokens.onBrandContainer),
      _NovelStatus.completed => (
        tokens.successContainer,
        tokens.onSuccessContainer,
      ),
      _NovelStatus.stopped => (
        tokens.warningContainer,
        tokens.onWarningContainer,
      ),
      null when emphasis == StatusBadgeEmphasis.gold => (
        tokens.warningContainer,
        tokens.onWarningContainer,
      ),
      null => (tokens.brandContainer, tokens.onBrandContainer),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

enum StatusBadgeEmphasis { primary, gold }

enum _NovelStatus { ongoing, completed, stopped }

_NovelStatus? _normalizedStatus(String label) {
  final normalized = label.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }

  if (_matchesAny(normalized, const ['مستمرة', 'مستمر', 'ongoing'])) {
    return _NovelStatus.ongoing;
  }
  if (_matchesAny(normalized, const [
    'مكتملة',
    'مكتمل',
    'completed',
    'complete',
    'finished',
  ])) {
    return _NovelStatus.completed;
  }
  if (_matchesAny(normalized, const [
    'متوقفة',
    'متوقف',
    'موقوفة',
    'stopped',
    'paused',
    'on hold',
    'on-hold',
  ])) {
    return _NovelStatus.stopped;
  }

  return null;
}

bool _matchesAny(String value, List<String> aliases) {
  return aliases.any(value.contains);
}
