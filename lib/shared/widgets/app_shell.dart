import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/features/player/presentation/mini_player_bar.dart';
import 'package:harmonix_apps/shared/layout/responsive_breakpoints.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final useRail = ResponsiveBreakpoints.useRailNavigation(context);
    final selected = _indexFromLocation(location);
    final content = Column(
      children: [
        Expanded(child: child),
        const MiniPlayerBar(),
      ],
    );

    return Scaffold(
      body: useRail
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selected,
                  onDestinationSelected: (index) => _navigate(context, index),
                  labelType: NavigationRailLabelType.all,
                  minWidth: 72,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.library_music_outlined),
                      selectedIcon: Icon(Icons.library_music),
                      label: Text('Catalogue'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search),
                      label: Text('Recherche'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Paramètres'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: useRail
          ? null
          : BottomNavigationBar(
              currentIndex: selected,
              onTap: (index) => _navigate(context, index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_outlined),
                  activeIcon: Icon(Icons.library_music),
                  label: 'Catalogue',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search),
                  label: 'Recherche',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Paramètres',
                ),
              ],
            ),
    );
  }

  int _indexFromLocation(String loc) {
    if (loc.startsWith('/search')) return 1;
    if (loc.startsWith('/settings')) return 2;
    return 0; // catalog
  }

  void _navigate(BuildContext context, int index) {
    const paths = ['/catalog', '/search', '/settings'];
    context.go(paths[index]);
  }
}
