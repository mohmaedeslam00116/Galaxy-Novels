import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../design_system/components/galaxy_navigation_chrome.dart';
import '../../../design_system/foundation/galaxy_adaptive.dart';
import 'shell_destination.dart';
import 'stitch_shell_app_bar.dart';

typedef ShellScreenBuilder =
    Widget Function(
      BuildContext context,
      ValueChanged<ShellDestination> selectDestination,
    );

class AdaptiveAppShell extends StatefulWidget {
  AdaptiveAppShell({
    required this.screenBuilders,
    this.drawerBuilder,
    this.initialDestination = ShellDestination.home,
    this.analytics = const NoopAppAnalytics(),
    super.key,
  }) : assert(
         ShellDestination.values.every(screenBuilders.containsKey),
         'A screen builder is required for every shell destination.',
       );

  final Map<ShellDestination, ShellScreenBuilder> screenBuilders;
  final WidgetBuilder? drawerBuilder;
  final ShellDestination initialDestination;
  final AppAnalytics analytics;

  @override
  State<AdaptiveAppShell> createState() => _AdaptiveAppShellState();
}

class _AdaptiveAppShellState extends State<AdaptiveAppShell> {
  late ShellDestination _selected = widget.initialDestination;
  final Map<ShellDestination, Widget> _createdScreens = {};

  @override
  void initState() {
    super.initState();
    unawaited(widget.analytics.logScreenView(_selected.analyticsName));
  }

  void _select(ShellDestination destination) {
    if (_selected == destination) return;
    setState(() => _selected = destination);
    unawaited(widget.analytics.logScreenView(destination.analyticsName));
  }

  void _ensureScreenCreated(ShellDestination destination) {
    _createdScreens.putIfAbsent(
      destination,
      () => KeyedSubtree(
        key: PageStorageKey(destination.name),
        child: widget.screenBuilders[destination]!(context, _select),
      ),
    );
  }

  Widget _body() {
    return IndexedStack(
      index: ShellDestination.values.indexOf(_selected),
      children: [
        for (final destination in ShellDestination.values)
          _createdScreens[destination] ?? const SizedBox.shrink(),
      ],
    );
  }

  void _selectIndex(int index) {
    _select(ShellDestination.values[index]);
  }

  PreferredSizeWidget? _appBar() => _selected == ShellDestination.home
      ? null
      : StitchShellAppBar(destination: _selected);

  Widget _navigationChrome(GalaxyNavigationChromeLayout layout) {
    return GalaxyNavigationChrome(
      layout: layout,
      selectedIndex: ShellDestination.values.indexOf(_selected),
      onDestinationSelected: _selectIndex,
      destinations: [
        for (final destination in ShellDestination.values)
          GalaxyNavigationDestination(
            label: destination.label,
            icon: destination.icon,
            selectedIcon: destination.selectedIcon,
          ),
      ],
    );
  }

  Widget _buildLayout(BuildContext context, BoxConstraints constraints) {
    _ensureScreenCreated(_selected);
    final layoutTier = GalaxyAdaptive.windowClassFor(constraints.maxWidth);
    final body = _body();
    final drawer = widget.drawerBuilder?.call(context);
    final sideNavigation = layoutTier == GalaxyLayoutTier.compact
        ? null
        : _navigationChrome(GalaxyNavigationChromeLayout.rail);

    return Scaffold(
      drawer: drawer,
      appBar: _appBar(),
      body: Row(
        children: [
          if (sideNavigation == null)
            const SizedBox.shrink()
          else
            sideNavigation,
          if (sideNavigation == null)
            const SizedBox.shrink()
          else
            const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: layoutTier == GalaxyLayoutTier.compact
          ? _navigationChrome(GalaxyNavigationChromeLayout.bar)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildLayout);
  }
}
