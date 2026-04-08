import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/player/presentation/mini_player_bar.dart';
import '../theme/color_scheme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          const MiniPlayerBar(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexFromLocation(location),
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
