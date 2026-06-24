import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../account/presentation/account_screen.dart';
import '../../about/presentation/about_screen.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../reader/presentation/reader_settings_screen.dart';

enum _DrawerDestination { account, favorites, readerSettings, about }

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Drawer(
      child: SafeArea(
        child: NavigationDrawer(
          selectedIndex: null,
          onDestinationSelected: (index) {
            final navigator = Navigator.of(context);
            navigator.pop();
            final destination = _DrawerDestination.values[index];
            final screen = switch (destination) {
              _DrawerDestination.account => const AccountScreen(),
              _DrawerDestination.favorites => const FavoritesScreen(),
              _DrawerDestination.readerSettings => const ReaderSettingsScreen(),
              _DrawerDestination.about => const AboutScreen(),
            };
            navigator.push(
              MaterialPageRoute<void>(builder: (context) => screen),
            );
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مجرة الروايات',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'حسابك وإعدادات القراءة',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: Text('حسابي'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.bookmark_outline_rounded),
              selectedIcon: Icon(Icons.bookmark_rounded),
              label: Text('المفضلة'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.tune),
              selectedIcon: Icon(Icons.tune),
              label: Text('إعدادات القراءة'),
            ),
            const Divider(height: 24),
            const NavigationDrawerDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info),
              label: Text('حول التطبيق'),
            ),
          ],
        ),
      ),
    );
  }
}
