import 'package:flutter/material.dart';

import '../foundation/galaxy_adaptive.dart';
import '../foundation/galaxy_design_tokens.dart';
import '../foundation/galaxy_metrics.dart';

@immutable
class GalaxyCommand {
  const GalaxyCommand({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final Key? key;
}

class GalaxyCommandBar extends StatelessWidget {
  const GalaxyCommandBar({
    required this.actions,
    this.label = 'شريط الأوامر',
    this.leading,
    super.key,
  });

  final List<GalaxyCommand> actions;
  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final showLabels = GalaxyAdaptive.of(context) != GalaxyLayoutTier.compact;
    return Semantics(
      label: label,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.symmetric(
            horizontal: BorderSide(
              color: tokens.outline.withValues(alpha: 0.50),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GalaxyMetrics.space8,
            vertical: GalaxyMetrics.space4,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                Expanded(child: leading!),
                const SizedBox(width: GalaxyMetrics.space8),
              ] else
                const Spacer(),
              for (final command in actions)
                _CommandButton(
                  key: command.key,
                  command: command,
                  showLabel: showLabels,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandButton extends StatelessWidget {
  const _CommandButton({
    required this.command,
    required this.showLabel,
    super.key,
  });

  final GalaxyCommand command;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return Tooltip(
      message: command.label,
      child: Semantics(
        label: command.label,
        button: true,
        selected: command.selected,
        child: showLabel
            ? TextButton.icon(
                onPressed: command.onPressed,
                icon: Icon(command.icon),
                label: Text(command.label),
                style: _buttonStyle(tokens),
              )
            : SizedBox.square(
                dimension: GalaxyMetrics.minimumTouchTarget,
                child: IconButton(
                  onPressed: command.onPressed,
                  icon: Icon(command.icon),
                  style: _buttonStyle(tokens),
                ),
              ),
      ),
    );
  }

  ButtonStyle _buttonStyle(GalaxyDesignTokens tokens) {
    final foreground = command.selected
        ? tokens.brand
        : tokens.contentSecondary;
    return IconButton.styleFrom(
      foregroundColor: foreground,
      minimumSize: const Size(48, GalaxyMetrics.minimumTouchTarget),
      backgroundColor: command.selected
          ? tokens.brandContainer.withValues(alpha: 0.72)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GalaxyMetrics.radiusControl),
      ),
    );
  }
}
