import 'package:flutter/material.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    this.action,
    this.leadingIcon,
    this.padding = const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 8),
    super.key,
  });

  final String title;
  final Widget? action;
  final IconData? leadingIcon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleWidget = ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (leadingIcon != null) Icon(leadingIcon, size: 20),
                Text(title, style: theme.textTheme.titleLarge),
              ],
            ),
          );
          final actionWidget = action == null
              ? null
              : ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  child: Center(child: action!),
                );

          if (constraints.maxWidth < 360 && actionWidget != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleWidget,
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: actionWidget,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleWidget),
              if (actionWidget != null) ...[
                const SizedBox(width: 12),
                actionWidget,
              ],
            ],
          );
        },
      ),
    );
  }
}
