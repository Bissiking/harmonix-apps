import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/features/player/presentation/mini_player_bar.dart';
import 'package:harmonix_apps/shared/layout/responsive_breakpoints.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = <_Destination>[
    _Destination('Accueil', Icons.home_outlined, Icons.home_rounded, '/home'),
    _Destination(
        'Explorer', Icons.search_outlined, Icons.search_rounded, '/catalog'),
    _Destination('Lecteur', Icons.play_circle_outline_rounded,
        Icons.play_circle_fill_rounded, '/player'),
    _Destination('Séances', Icons.graphic_eq_outlined, Icons.graphic_eq_rounded,
        '/sessions'),
    _Destination('Profil', Icons.person_outline_rounded, Icons.person_rounded,
        '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final useRail = ResponsiveBreakpoints.useRailNavigation(context);
    final selected = _indexFromLocation(location);
    final showMiniPlayer = !location.startsWith('/player');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Column(
      children: [
        Expanded(child: child),
        if (showMiniPlayer) const MiniPlayerBar(),
      ],
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.5, -0.85),
            radius: 1.15,
            colors: isDark
                ? const [Color(0xFF121D38), Color(0xFF07101E)]
                : const [Color(0xFFF1EEFF), Color(0xFFFAFAFC)],
          ),
        ),
        child: useRail
            ? Row(
                children: [
                  _DesktopNavigation(
                    selectedIndex: selected,
                    onSelected: (index) => _navigate(context, index),
                  ),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (index) => _navigate(context, index),
              destinations: [
                for (final destination in _destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/catalog') ||
        location.startsWith('/search') ||
        location.startsWith('/library')) {
      return 1;
    }
    if (location.startsWith('/player')) return 2;
    if (location.startsWith('/sessions')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    context.go(_destinations[index].path);
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation(
      {required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final extended = MediaQuery.sizeOf(context).width >= 1080;
    final palette = Theme.of(context).colorScheme;
    return Container(
      width: extended ? 216 : 88,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(extended ? 22 : 16, 22, 16, 20),
              child: Row(
                mainAxisAlignment: extended
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.primary.withValues(alpha: 0.55),
                      ),
                    ),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        palette.primary,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('assets/images/logo_harmonix.png'),
                    ),
                  ),
                  if (extended) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Harmonix',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onSelected,
                extended: extended,
                minWidth: 88,
                minExtendedWidth: 216,
                labelType: extended ? NavigationRailLabelType.none : null,
                groupAlignment: -0.55,
                useIndicator: true,
                destinations: [
                  for (final destination in AppShell._destinations)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: Text(destination.label),
                    ),
                ],
              ),
            ),
            if (extended)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Ta musique, partout.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.path);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}
