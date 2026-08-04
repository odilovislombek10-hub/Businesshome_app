import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/services/theme_controller.dart';
import 'theme.dart';

/// Persistent chrome around the main sections — the mobile equivalent of the site's header.
///
/// The website is desktop-first: a top bar with six nav links plus dropdowns. On a phone that
/// doesn't fit, so the six links are split — the five most-used become a bottom bar, the rest live
/// in the drawer. Destinations and their URLs are unchanged, so `/birja` is still `/birja`.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = <_Tab>[
    _Tab(path: '/', label: 'Bosh sahifa', icon: Icons.home_outlined, active: Icons.home),
    _Tab(
      path: '/secondary',
      label: 'Business',
      icon: Icons.storefront_outlined,
      active: Icons.storefront,
    ),
    _Tab(
      path: '/reels',
      label: 'Reels',
      icon: Icons.play_circle_outline,
      active: Icons.play_circle,
    ),
    _Tab(path: '/my-home', label: 'Mening uyim', icon: Icons.favorite_outline, active: Icons.favorite),
    _Tab(path: '/cabinet', label: 'Kabinet', icon: Icons.person_outline, active: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const _AppDrawer(),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        // `initialLocation: true` when re-tapping the current tab resets it to its root, which is
        // what tapping the site's logo/nav link does.
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.active),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab({
    required this.path,
    required this.label,
    required this.icon,
    required this.active,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData active;
}

/// Everything the bottom bar has no room for — the remaining header links, plus the theme and
/// account actions that sit in the site's top-right corner.
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  static const _links = <(String, String, IconData)>[
    ('/new-projects', 'Yangi loyihalar', Icons.apartment_outlined),
    ('/rent', 'Ijara', Icons.vpn_key_outlined),
    ('/secondary', 'Ikkilamchi bozor', Icons.sell_outlined),
    ('/designers', 'Dizaynerlar', Icons.design_services_outlined),
    ('/masters', 'Ustalar', Icons.handyman_outlined),
    ('/birja', 'Birja', Icons.gavel_outlined),
    ('/map', 'Xaritada qidirish', Icons.map_outlined),
    ('/news', 'Yangiliklar', Icons.article_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = context.watch<ThemeController>();

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.olive,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.home_work, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('BusinessHome', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            const Divider(),
            for (final (path, label, icon) in _links)
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(path);
                },
              ),
            const Divider(),
            ListTile(
              leading: Icon(themeController.isDark ? Icons.light_mode : Icons.dark_mode),
              title: Text(themeController.isDark ? 'Yorug‘ rejim' : 'Tungi rejim'),
              onTap: themeController.toggle,
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Kirish'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
