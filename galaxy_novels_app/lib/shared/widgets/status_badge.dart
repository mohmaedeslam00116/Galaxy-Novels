import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

const _ongoingStatusColor = Color(0xFF22C55E);
const _completedStatusColor = Color(0xFFEF4444);
const _stoppedStatusColor = Color(0xFFA855F7);

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
    final color =
        _novelStatusColor(label) ??
        (emphasis == StatusBadgeEmphasis.gold ? tokens.gold : tokens.primary);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.42)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

enum StatusBadgeEmphasis { primary, gold }

Color? _novelStatusColor(String label) {
  final normalized = label.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }

  if (_matchesAny(normalized, const ['مستمرة', 'مستمر', 'ongoing'])) {
    return _ongoingStatusColor;
  }
  if (_matchesAny(normalized, const [
    'مكتملة',
    'مكتمل',
    'completed',
    'complete',
    'finished',
  ])) {
    return _completedStatusColor;
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
    return _stoppedStatusColor;
  }

  return null;
}

bool _matchesAny(String value, List<String> aliases) {
  return aliases.any(value.contains);
}
