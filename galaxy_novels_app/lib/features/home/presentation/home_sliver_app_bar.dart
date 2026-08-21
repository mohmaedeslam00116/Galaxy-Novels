import 'package:flutter/material.dart';

import '../../../shared/layout/app_breakpoints.dart';

class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({super.key});

  static const expandedHeight = 92.0;
  static const collapsedHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact =
        AppBreakpoints.classify(MediaQuery.sizeOf(context).width) ==
        AppWindowClass.compact;
    return SliverAppBar(
      key: const ValueKey('home-sliver-app-bar'),
      pinned: true,
      floating: false,
      snap: false,
      toolbarHeight: collapsedHeight,
      collapsedHeight: collapsedHeight,
      expandedHeight: expandedHeight,
      automaticallyImplyLeading: false,
      leading: compact
          ? Builder(
              builder: (buttonContext) => IconButton(
                key: const ValueKey('home-drawer-button'),
                tooltip: 'فتح القائمة',
                onPressed: () => Scaffold.maybeOf(buttonContext)?.openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
            )
          : null,
      centerTitle: false,
      titleSpacing: compact ? 8 : 20,
      title: Text(
        'مجرة الروايات',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleLarge?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final progress =
              ((constraints.maxHeight - collapsedHeight) /
                      (expandedHeight - collapsedHeight))
                  .clamp(0.0, 1.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.surfaceContainerHigh.withValues(alpha: 0.72),
                      scheme.surface,
                    ],
                  ),
                ),
              ),
              IgnorePointer(
                child: Opacity(
                  opacity: progress,
                  child: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: compact ? 64 : 20,
                        end: 20,
                        bottom: 8,
                      ),
                      child: Text(
                        'اكتشف روايتك التالية',
                        key: const ValueKey('home-brand-subtitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
