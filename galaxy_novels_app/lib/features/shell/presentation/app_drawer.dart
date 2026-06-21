import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../account/presentation/account_screen.dart';

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
            Navigator.pop(context);
            if (index == 0) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AccountScreen(),
                ),
              );
            }
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
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: Text('المفضلة'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.tune),
              selectedIcon: Icon(Icons.tune),
              label: Text('إعدادات القراءة'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.workspace_premium_outlined),
              selectedIcon: Icon(Icons.workspace_premium),
              label: Text('الاشتراك و VIP'),
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
