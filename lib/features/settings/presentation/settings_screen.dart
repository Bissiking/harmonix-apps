import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/navigation/route_names.dart';
import 'package:harmonix_apps/core/session/session_controller.dart';
import 'package:harmonix_apps/core/settings/auth_token_provider.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/update/update_checker.dart';
import 'package:harmonix_apps/shared/widgets/update_download_dialog.dart';
import 'package:harmonix_apps/core/theme/flow_appearance.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';
import 'package:harmonix_apps/features/night/providers/night_provider.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';
import 'package:harmonix_apps/shared/widgets/music_collection.dart';
import 'package:harmonix_apps/features/cast/providers/cast_provider.dart';
import 'package:harmonix_apps/features/cast/providers/google_cast_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;
  UpdateInfo? _updateInfo;
  String? _updateError;
  bool _isCheckingUpdate = false;
  int section = 0;
  late final packageInfo = PackageInfo.fromPlatform();

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: ref.read(settingsRepositoryProvider).serverUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  static const sections = [
    (Icons.palette_outlined, 'Apparence'),
    (Icons.headphones_outlined, 'Écoute'),
    (Icons.dns_outlined, 'Connexion'),
    (Icons.info_outline_rounded, 'À propos'),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsRepositoryProvider);
    final hasToken = ref.watch(authTokenProvider)?.isNotEmpty ?? false;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: CollectionWidth(
              maxWidth: 1180,
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 850;
                final navigation = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < sections.length; index++)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                                leading: Icon(sections[index].$1),
                                title: Text(sections[index].$2),
                                selected: section == index,
                                selectedColor: scheme.onSurface,
                                selectedTileColor: scheme.primaryContainer
                                    .withValues(alpha: .35),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                onTap: () => setState(() => section = index))),
                    ]);
                final content = ListView(
                    key: ValueKey(section),
                    padding: EdgeInsets.fromLTRB(wide ? 32 : 24, 12, 24, 40),
                    children: [
                      Text(sections[section].$2,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                          switch (section) {
                            0 => 'Un espace qui te ressemble.',
                            1 => 'Ta musique, sur cet appareil et ailleurs.',
                            2 => 'Ton serveur et ta session Sonora.',
                            _ => 'Harmonix, toujours à jour.',
                          },
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 28),
                      ..._content(settings, hasToken),
                    ]);
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Paramètres',
                                    style: (MediaQuery.textScalerOf(context)
                                                    .scale(1) >
                                                1.5
                                            ? Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                            : Theme.of(context)
                                                .textTheme
                                                .headlineLarge)
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -1)),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Icon(
                                      hasToken
                                          ? Icons.cloud_done_outlined
                                          : Icons.offline_pin_outlined,
                                      size: 18,
                                      color: scheme.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(
                                          hasToken
                                              ? 'Connecté à Sonora'
                                              : 'Écoute locale',
                                          style: TextStyle(
                                              color: scheme.onSurfaceVariant))),
                                ]),
                              ])),
                      if (!wide)
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                            child: Row(children: [
                              for (var index = 0;
                                  index < sections.length;
                                  index++)
                                Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                        avatar:
                                            Icon(sections[index].$1, size: 18),
                                        label: Text(sections[index].$2),
                                        selected: section == index,
                                        onSelected: (_) =>
                                            setState(() => section = index)))
                            ])),
                      Expanded(
                          child: wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      SizedBox(
                                          width: 220,
                                          child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 24),
                                              child: navigation)),
                                      Expanded(child: content),
                                    ])
                              : content),
                    ]);
              })),
        ));
  }

  List<Widget> _content(SettingsRepository settings, bool hasToken) {
    switch (section) {
      case 0:
        final appearance = ref.watch(appearanceProvider);
        return [
          LayoutBuilder(builder: (context, constraints) {
            final single = MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final width =
                single ? constraints.maxWidth : (constraints.maxWidth - 16) / 2;
            return Wrap(spacing: 16, runSpacing: 20, children: [
              for (final value in FlowAppearance.values)
                SizedBox(
                    width: width,
                    child: _AppearanceChoice(
                        appearance: value,
                        selected: appearance == value,
                        onSelect: () => ref
                            .read(appearanceProvider.notifier)
                            .select(value))),
            ]);
          }),
          const SizedBox(height: 32),
          const Divider(),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Couleurs des pochettes'),
              subtitle: const Text('Une touche de couleur dans le lecteur'),
              value: settings.dynamicColors,
              onChanged: (value) async {
                await settings.setDynamicColors(value);
                if (!mounted) return;
                ref.read(appearanceRevisionProvider.notifier).state++;
                setState(() {});
              }),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Réduire les animations'),
              subtitle: const Text('Des transitions plus discrètes'),
              value: settings.reduceMotion,
              onChanged: (value) async {
                await settings.setReduceMotion(value);
                if (!mounted) return;
                ref.read(appearanceRevisionProvider.notifier).state++;
                setState(() {});
              }),
        ];
      case 1:
        return [
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Utiliser uniquement cet appareil'),
              subtitle:
                  const Text('Catalogue mémorisé, imports et téléchargements.'),
              value: ref.watch(offlineModeProvider),
              onChanged: (value) =>
                  ref.read(offlineModeProvider.notifier).setEnabled(value)),
          const Divider(height: 32),
          _ProfileAction(
              icon: Icons.download_outlined,
              label: 'Téléchargements et stockage',
              onTap: () => context.go('/downloads')),
          _ProfileAction(
              icon: Icons.nightlight_outlined,
              label: 'Harmonix Night et Night Sense',
              onTap: () => context.go('/night')),
          _ProfileAction(
              icon: Icons.graphic_eq_rounded,
              label: 'Rift',
              onTap: () => context.go('/rift')),
          _ProfileAction(
              icon: Icons.library_music_outlined,
              label: 'Bibliothèque',
              onTap: () => context.go('/library')),
        ];
      case 2:
        return [
          if (settings.sessionStorageUnavailable)
            const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.key_off),
                title: Text('Stockage sécurisé indisponible'),
                subtitle: Text(
                    'Déverrouille le coffre système puis redémarre Harmonix pour enregistrer une nouvelle connexion.')),
          TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                  labelText: 'URL du serveur',
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://sonora.mhemery.fr'),
              keyboardType: TextInputType.url),
          const SizedBox(height: 16),
          Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                  onPressed: _saveServerUrl,
                  child: const Text('Enregistrer le serveur'))),
          const SizedBox(height: 32),
          const Divider(),
          const CollectionHeading(title: 'Session'),
          Text(hasToken
              ? 'Ta session Sonora est active sur cet appareil.'
              : 'Connecte-toi pour retrouver ton catalogue Sonora.'),
          const SizedBox(height: 16),
          Align(
              alignment: Alignment.centerLeft,
              child: hasToken
                  ? OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Se déconnecter'))
                  : FilledButton(
                      onPressed: () => context.goNamed(RouteNames.login),
                      child: const Text('Se connecter'))),
        ];
      default:
        return [
          FutureBuilder<PackageInfo>(
              future: packageInfo,
              builder: (context, snapshot) {
                final info = snapshot.data;
                return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.music_note_rounded),
                    title: const Text('Harmonix'),
                    subtitle: Text(info == null
                        ? 'Chargement de la version…'
                        : 'Version ${info.version}'));
              }),
          if (!kIsWeb) ...[
            const SizedBox(height: 24),
            Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                    onPressed: _isCheckingUpdate ? null : _checkUpdate,
                    icon: const Icon(Icons.system_update_alt_rounded),
                    label: Text(_isCheckingUpdate
                        ? 'Vérification…'
                        : 'Vérifier les mises à jour'))),
            if (_updateError != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_updateError!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            if (_updateInfo != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildUpdateStatus(_updateInfo!)),
          ],
        ];
    }
  }

  Future<void> _saveServerUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    await runFlowAction(context, () async {
      await _stopAccountPlayback();
      await ref.read(settingsRepositoryProvider).setServerUrl(url);
      ref.invalidate(dioProvider);
      ref.invalidate(authTokenProvider);
      ref.invalidate(offlineModeProvider);
      ref.invalidate(transfersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serveur Sonora mis à jour.')));
    });
  }

  Future<void> _logout() async {
    await _stopAccountPlayback();
    await ref.read(settingsRepositoryProvider).clearAuthSession();
    await ref.read(settingsRepositoryProvider).setRiftSessionId(null);
    await ref.read(offlineModeProvider.notifier).setEnabled(false);
    ref.invalidate(transfersProvider);
    ref.invalidate(dioProvider);
    ref.invalidate(authTokenProvider);
    ref.read(requireLoginProvider.notifier).state = true;
    if (!mounted) return;
    context.goNamed(RouteNames.login);
  }

  Future<void> _stopAccountPlayback() async {
    if (ref.read(castProvider).isActive) {
      try {
        await ref.read(castProvider.notifier).leave();
      } catch (_) {
        /* The local Rift session is cleared even without network. */
      }
    }
    await ref.read(nightSessionProvider.notifier).finish(pause: true);
    final handler = ref.read(audioHandlerProvider);
    await handler.stop();
    handler.queue.add([]);
    handler.mediaItem.add(null);
    if (ref.read(googleCastProvider).connected) {
      await ref.read(googleCastProvider.notifier).stopCasting();
      await ref.read(googleCastProvider.notifier).disconnect();
    }
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateError = null;
    });
    try {
      final info = await checkForUpdate(
        packageInfo: await PackageInfo.fromPlatform(),
      );
      if (mounted) setState(() => _updateInfo = info);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updateError = error is UpdateCheckException
            ? error.message
            : 'Impossible de vérifier les mises à jour.';
      });
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  Widget _buildUpdateStatus(UpdateInfo info) {
    final updateAvailable = info.updateAvailable;
    final label = updateAvailable
        ? (info.forceUpdate ? 'Mise à jour requise' : 'Mise à jour disponible')
        : 'Harmonix est à jour';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (info.latestVersion != null)
          Text('Dernière version : ${info.latestVersion}'),
        if (info.releaseNotes?.isNotEmpty == true)
          Text(info.releaseNotes!,
              style: Theme.of(context).textTheme.bodySmall),
        if (info.downloadUrl != null && updateAvailable)
          TextButton(
            onPressed: () async {
              if (isDesktopPlatform) {
                final file = await showUpdateDownloadDialog(context, info);
                if (file == null || !mounted) return;
                await launchUrl(
                  Uri.file(file.path),
                  mode: LaunchMode.externalApplication,
                );
              } else {
                final uri = Uri.tryParse(info.downloadUrl!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: const Text('Télécharger'),
          ),
      ],
    );
  }
}

class _AppearanceChoice extends StatelessWidget {
  const _AppearanceChoice(
      {required this.appearance,
      required this.selected,
      required this.onSelect});
  final FlowAppearance appearance;
  final bool selected;
  final VoidCallback onSelect;
  @override
  Widget build(BuildContext context) {
    final light = appearance == FlowAppearance.daylight;
    final background =
        light ? const Color(0xFFF5F5FA) : appearance.palette.darkBackground;
    final foreground =
        light ? const Color(0xFF1C2242) : appearance.palette.text;
    final accent = appearance.palette.accent;
    return Semantics(
        button: true,
        selected: selected,
        label: appearance.label,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onSelect,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                          decoration: BoxDecoration(
                              color: background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                  width: selected ? 2 : 1)),
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(children: [
                                SizedBox(
                                    width: 20,
                                    child: Column(children: [
                                      Icon(Icons.library_music_outlined,
                                          size: 18, color: accent),
                                      const SizedBox(height: 16),
                                      Icon(Icons.search,
                                          size: 18, color: foreground),
                                      const SizedBox(height: 16),
                                      Icon(Icons.bedtime_outlined,
                                          size: 18, color: foreground),
                                    ])),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                      DecoratedBox(
                                          decoration: BoxDecoration(
                                              color:
                                                  accent.withValues(alpha: .25),
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: SizedBox(
                                              height: 36,
                                              child: Icon(Icons.graphic_eq,
                                                  color: accent))),
                                      const SizedBox(height: 12),
                                      LinearProgressIndicator(
                                          value: .7,
                                          minHeight: 4,
                                          color: foreground,
                                          backgroundColor:
                                              foreground.withValues(alpha: .1)),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                          value: .4,
                                          minHeight: 4,
                                          color:
                                              foreground.withValues(alpha: .5),
                                          backgroundColor:
                                              foreground.withValues(alpha: .1)),
                                    ])),
                              ]))),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: Text(
                                appearance.name[0].toUpperCase() +
                                    appearance.name.substring(1),
                                style: Theme.of(context).textTheme.titleSmall)),
                        Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 20,
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)
                      ]),
                    ]))));
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 56,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
