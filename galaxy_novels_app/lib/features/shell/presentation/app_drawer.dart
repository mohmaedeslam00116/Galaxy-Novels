import 'package:flutter/material.dart';

import '../../account/presentation/account_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
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
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.person_outline,
              title: 'حسابي',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const AccountScreen(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.favorite_border,
              title: 'المفضلة',
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.tune,
              title: 'إعدادات القراءة',
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.workspace_premium_outlined,
              title: 'الاشتراك و VIP',
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.info_outline,
              title: 'حول التطبيق',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}
