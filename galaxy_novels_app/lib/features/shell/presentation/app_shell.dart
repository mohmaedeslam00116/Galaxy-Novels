import 'package:flutter/material.dart';

import '../../catalog/presentation/catalog_screen.dart';
import '../../downloads/presentation/downloads_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../rankings/presentation/rankings_screen.dart';
import 'app_drawer.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _titles = [
    'الرئيسية',
    'المكتبة',
    'التنزيلات',
    'السجل',
    'الترتيب',
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const CatalogScreen(),
      DownloadsScreen(onOpenLibrary: () => setState(() => _index = 1)),
      const HistoryScreen(),
      const RankingsScreen(),
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_library_outlined),
            selectedIcon: Icon(Icons.local_library),
            label: 'المكتبة',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'التنزيلات',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'السجل',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'الترتيب',
          ),
        ],
      ),
    );
  }
}
