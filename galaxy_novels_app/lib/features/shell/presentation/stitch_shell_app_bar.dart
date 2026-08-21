import 'package:flutter/material.dart';

import 'shell_destination.dart';

class StitchShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StitchShellAppBar({required this.destination, super.key});

  final ShellDestination destination;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isHome = destination == ShellDestination.home;
    return AppBar(
      key: const ValueKey('shell-app-bar'),
      toolbarHeight: preferredSize.height,
      centerTitle: !isHome,
      titleSpacing: isHome ? 8 : NavigationToolbar.kMiddleSpacing,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      title: Text(
        isHome ? 'مجرة الروايات' : destination.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: isHome ? scheme.primary : scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
