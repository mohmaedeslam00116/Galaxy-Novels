import 'package:flutter/material.dart';

import '../foundation/galaxy_design_tokens.dart';

enum GalaxyNavigationChromeLayout { bar, rail }

@immutable
class GalaxyNavigationDestination {
  const GalaxyNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class GalaxyNavigationChrome extends StatelessWidget {
  const GalaxyNavigationChrome({
    required this.layout,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final GalaxyNavigationChromeLayout layout;
  final List<GalaxyNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return switch (layout) {
      GalaxyNavigationChromeLayout.bar => NavigationBar(
        key: const ValueKey('galaxy-navigation-bar'),
        height: 72,
        backgroundColor: tokens.surface,
        indicatorColor: tokens.brandContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
      GalaxyNavigationChromeLayout.rail => NavigationRail(
        key: const ValueKey('galaxy-navigation-rail'),
        backgroundColor: tokens.surface,
        indicatorColor: tokens.brandContainer,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        labelType: NavigationRailLabelType.all,
        destinations: [
          for (final destination in destinations)
            NavigationRailDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: Text(destination.label),
            ),
        ],
      ),
    };
  }
}
