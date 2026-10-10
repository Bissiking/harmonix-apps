// app_shell.dart
import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonix_apps/features/player/presentation/mini_player_bar.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/shared/layout/responsive_breakpoints.dart';
import 'package:harmonix_apps/shared/widgets/harmonix_mark.dart';
import 'package:harmonix_apps/core/platform/platform_capabilities.dart';

const flowDestinations = <({String label, IconData icon, String path})>[
  (label: 'Accueil', icon: Icons.home_outlined, path: '/home'),
  (label: 'Bibliothèque', icon: Icons.library_music_outlined, path: '/library'),
  (label: 'Recherche', icon: Icons.search, path: '/search'),
  (label: 'Harmonix Night', icon: Icons.nightlight_outlined, path: '/night'),
  (label: 'Rift', icon: Icons.graphic_eq, path: '/rift'),
  (label: 'Téléchargements', icon: Icons.download_outlined, path: '/downloads'),
  (label: 'Explorer', icon: Icons.album_outlined, path: '/catalog'),
  (label: 'Paramètres', icon: Icons.settings_outlined, path: '/settings'),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final tv = ref.watch(isTelevisionProvider).valueOrNull ?? false;
    final rail = tv || ResponsiveBreakpoints.useRailNavigation(context);
    final offline = ref.watch(offlineModeProvider);
    final mobile = [
      flowDestinations[0],
      flowDestinations[1],
      flowDestinations[2],
      flowDestinations[3],
      flowDestinations[7]
    ];
    var selected = mobile.indexWhere((d) => location.startsWith(d.path));
    if (selected < 0) selected = 0;
    final content = Column(children: [
      if (offline)
        Material(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: SafeArea(
                bottom: false,
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(children: [
                      const Icon(Icons.cloud_off, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                          child:
                              Text('Hors connexion · musique de cet appareil')),
                      TextButton(
                          onPressed: () => ref
                              .read(offlineModeProvider.notifier)
                              .setEnabled(false),
                          child: const Text('Reconnecter'))
                    ])))),
      Expanded(child: child),
      if (!location.startsWith('/player')) const MiniPlayerBar(),
    ]);
    return Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.keyK, control: true):
              _SearchIntent(),
          SingleActivator(LogicalKeyboardKey.keyK, meta: true): _SearchIntent(),
        },
        child: Actions(
            actions: {
              _SearchIntent: CallbackAction<_SearchIntent>(onInvoke: (_) {
                context.go('/search');
                return null;
              })
            },
            child: FocusTraversalGroup(
                child: Scaffold(
              drawer: rail
                  ? null
                  : Drawer(
                      child: SafeArea(
                          child: _NavigationList(
                              location: location,
                              extended: true,
                              closeDrawer: true))),
              body: SafeArea(
                  bottom: false,
                  child: rail
                      ? Row(children: [
                          SizedBox(
                              width: tv
                                  ? 244
                                  : MediaQuery.sizeOf(context).width >= 1100
                                      ? 236
                                      : 88,
                              child: Material(
                                  color: Theme.of(context).colorScheme.surface,
                                  child: _NavigationList(
                                      location: location,
                                      extended: tv ||
                                          MediaQuery.sizeOf(context).width >=
                                              1100))),
                          Expanded(child: content),
                        ])
                      : content),
              bottomNavigationBar: rail
                  ? null
                  : NavigationBar(
                      selectedIndex: selected,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.onlyShowSelected,
                      onDestinationSelected: (index) =>
                          context.go(mobile[index].path),
                      destinations: [
                          for (final d in mobile)
                            NavigationDestination(
                                icon: Icon(d.icon),
                                label: d.label == 'Paramètres'
                                    ? 'Profil'
                                    : d.label == 'Harmonix Night'
                                        ? 'Night'
                                        : d.label),
                        ]),
            ))));
  }
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

// Tooltip anchors need separate semantics nodes on Windows (Flutter #182444).
class _NavigationList extends StatelessWidget {
  const _NavigationList(
      {required this.location,
      required this.extended,
      this.closeDrawer = false});
  final String location;
  final bool extended;
  final bool closeDrawer;
  @override
  Widget build(BuildContext context) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          children: [
            Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Row(
                    mainAxisAlignment: extended
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      const HarmonixMark(size: 48),
                      if (extended) ...[
                        const SizedBox(width: 10),
                        Text('Harmonix',
                            style: Theme.of(context).textTheme.titleLarge)
                      ]
                    ])),
            for (final d in flowDestinations)
              Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: extended
                      ? ListTile(
                          leading: Icon(d.icon),
                          title: Text(d.label),
                          selected: location.startsWith(d.path),
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: .12),
                          onTap: () {
                            if (closeDrawer) Navigator.pop(context);
                            context.go(d.path);
                          })
                      : Semantics(
                          container: true,
                          child: FlowIconButton(
                              tooltip: d.label,
                              color: location.startsWith(d.path)
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              onPressed: () => context.go(d.path),
                              icon: Icon(d.icon)))),
            const Divider(),
            Semantics(
                container: true,
                child: FlowIconButton(
                    tooltip: 'Lecteur',
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: () {
                      if (closeDrawer) Navigator.pop(context);
                      context.go('/player');
                    })),
          ]);
}
