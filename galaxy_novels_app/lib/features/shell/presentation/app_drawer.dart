import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../app/app_theme.dart';
import '../../../core/analytics/app_screen_names.dart';
import '../../../core/navigation/external_uri_launcher.dart';
import '../../../design_system/gallery/galaxy_design_system_gallery.dart';
import '../../about/application/app_version_info.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../settings/presentation/settings_screen.dart';

part 'app_drawer_widgets.dart';

enum _DrawerDestination { favorites, settings, designSystem, discord }

enum _DrawerIconType { material, discord }

class _DrawerEntry {
  const _DrawerEntry({
    required this.destination,
    required this.label,
    required this.icon,
    this.iconType = _DrawerIconType.material,
  });

  final _DrawerDestination destination;
  final String label;
  final IconData icon;
  final _DrawerIconType iconType;
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    this.uriLauncher = launchExternalUri,
    this.versionLoader = loadPackageVersionInfo,
    super.key,
  });

  final ExternalUriLauncher uriLauncher;
  final AppVersionLoader versionLoader;

  static final _discordUri = Uri.parse('https://discord.gg/fD7U7zbCgM');

  static const _libraryEntries = [
    _DrawerEntry(
      destination: _DrawerDestination.favorites,
      label: 'المفضلة',
      icon: Icons.bookmark_outline_rounded,
    ),
    _DrawerEntry(
      destination: _DrawerDestination.settings,
      label: 'الإعدادات',
      icon: Icons.tune_rounded,
    ),
  ];

  static const _communityEntries = [
    _DrawerEntry(
      destination: _DrawerDestination.discord,
      label: 'مجتمع Discord',
      icon: Icons.forum_outlined,
      iconType: _DrawerIconType.discord,
    ),
  ];

  static const _developerEntries = [
    _DrawerEntry(
      destination: _DrawerDestination.designSystem,
      label: 'مكتبة المكونات',
      icon: Icons.widgets_outlined,
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            children: [
              const _DrawerHeader(),
              const SizedBox(height: 16),
              _DrawerSection(
                id: 'library',
                title: 'المكتبة والتفضيلات',
                entries: _libraryEntries,
                onOpen: (destination) =>
                    unawaited(_openDestination(context, destination)),
              ),
              const SizedBox(height: 16),
              if (!kReleaseMode) ...[
                _DrawerSection(
                  id: 'developer',
                  title: 'للمطورين',
                  entries: _developerEntries,
                  onOpen: (destination) =>
                      unawaited(_openDestination(context, destination)),
                ),
                const SizedBox(height: 16),
              ],
              _DrawerSection(
                id: 'community',
                title: 'المجتمع',
                entries: _communityEntries,
                onOpen: (destination) =>
                    unawaited(_openDestination(context, destination)),
              ),
              const SizedBox(height: 14),
              _DrawerVersionLabel(versionLoader: versionLoader),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDestination(
    BuildContext context,
    _DrawerDestination destination,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop();

    late final Widget screen;
    late final String screenName;
    switch (destination) {
      case _DrawerDestination.favorites:
        screen = const FavoritesScreen();
        screenName = AppScreenNames.favorites;
      case _DrawerDestination.settings:
        screen = const SettingsScreen();
        screenName = AppScreenNames.settings;
      case _DrawerDestination.designSystem:
        screen = const GalaxyDesignSystemGallery();
        screenName = AppScreenNames.componentGallery;
      case _DrawerDestination.discord:
        await _openDiscord(messenger);
        return;
    }
    navigator.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: screenName),
        builder: (context) => screen,
      ),
    );
  }

  Future<void> _openDiscord(ScaffoldMessengerState messenger) async {
    try {
      if (await uriLauncher(_discordUri)) {
        return;
      }
    } on Exception {
      // A failed external launcher follows the same safe feedback path.
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('تعذر فتح رابط Discord الآن.')),
    );
  }
}
