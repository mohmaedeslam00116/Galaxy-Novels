import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../account/presentation/account_screen.dart';
import '../../about/presentation/about_screen.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../settings/presentation/settings_screen.dart';

part 'app_drawer_widgets.dart';

enum _DrawerDestination { account, favorites, settings, about }

class _DrawerEntry {
  const _DrawerEntry({
    required this.destination,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final _DrawerDestination destination;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const _readerEntries = [
    _DrawerEntry(
      destination: _DrawerDestination.account,
      label: 'حسابي',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
    _DrawerEntry(
      destination: _DrawerDestination.favorites,
      label: 'المفضلة',
      icon: Icons.bookmark_outline_rounded,
      selectedIcon: Icons.bookmark_rounded,
    ),
  ];

  static const _appEntries = [
    _DrawerEntry(
      destination: _DrawerDestination.settings,
      label: 'الإعدادات',
      icon: Icons.tune_rounded,
      selectedIcon: Icons.tune_rounded,
    ),
  ];

  static const _aboutEntries = [
    _DrawerEntry(
      destination: _DrawerDestination.about,
      label: 'حول التطبيق',
      icon: Icons.info_outline_rounded,
      selectedIcon: Icons.info_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Drawer(
      child: DecoratedBox(
        decoration: BoxDecoration(color: tokens.surface),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            children: [
              const _DrawerHeader(),
              const SizedBox(height: 18),
              _DrawerSection(
                title: 'القارئ',
                entries: _readerEntries,
                onOpen: (destination) => _openDestination(context, destination),
              ),
              const SizedBox(height: 14),
              _DrawerSection(
                title: 'التطبيق',
                entries: _appEntries,
                onOpen: (destination) => _openDestination(context, destination),
              ),
              const SizedBox(height: 14),
              _DrawerSection(
                title: 'مجرة الروايات',
                entries: _aboutEntries,
                onOpen: (destination) => _openDestination(context, destination),
              ),
              const SizedBox(height: 12),
              const _DrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }

  void _openDestination(BuildContext context, _DrawerDestination destination) {
    final navigator = Navigator.of(context);
    navigator.pop();
    final screen = switch (destination) {
      _DrawerDestination.account => const AccountScreen(),
      _DrawerDestination.favorites => const FavoritesScreen(),
      _DrawerDestination.settings => const SettingsScreen(),
      _DrawerDestination.about => const AboutScreen(),
    };
    navigator.push(MaterialPageRoute<void>(builder: (context) => screen));
  }
}
