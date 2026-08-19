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
import 'package:harmonix_apps/core/theme/theme_provider.dart';
import 'package:harmonix_apps/core/update/update_checker.dart';
import 'package:harmonix_apps/shared/widgets/update_download_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    final authToken = ref.watch(authTokenProvider);
    final themeMode = ref.watch(themeModeProvider);
    final hasToken = authToken?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Profil')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const _ProfileHeader(),
              const SizedBox(height: 18),
              _ActionPanel(
                children: [
                  _ProfileAction(
                    icon: Icons.favorite_outline_rounded,
                    label: 'Favoris',
                    onTap: () => context.go('/library'),
                  ),
                  _ProfileAction(
                    icon: Icons.graphic_eq_rounded,
                    label: 'Mes séances',
                    onTap: () => context.go('/sessions'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Apparence'),
              const SizedBox(height: 10),
              _SettingsPanel(
                child: _ThemeModeSelector(
                  selected: themeMode,
                  onSelected: (mode) =>
                      ref.read(themeModeProvider.notifier).setMode(mode),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Serveur Sonora'),
              const SizedBox(height: 10),
              _SettingsPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL du serveur',
                        hintText: 'https://sonora.mhemery.fr',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _saveServerUrl,
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
              if (!kIsWeb) ...[
                const SizedBox(height: 24),
                const _SectionTitle('Mises à jour'),
                const SizedBox(height: 10),
                _SettingsPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _isCheckingUpdate ? null : _checkUpdate,
                        icon: const Icon(Icons.system_update_alt_rounded),
                        label: Text(
                          _isCheckingUpdate
                              ? 'Vérification…'
                              : 'Vérifier les mises à jour',
                        ),
                      ),
                      if (_updateError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _updateError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      if (_updateInfo != null) ...[
                        const SizedBox(height: 10),
                        _buildUpdateStatus(_updateInfo!),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const _SectionTitle('Compte'),
              const SizedBox(height: 10),
              _SettingsPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final info = snapshot.data;
                        final version = info == null
                            ? 'Version…'
                            : 'Version ${info.version}+${info.buildNumber}';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.info_outline_rounded),
                          title: const Text('Harmonix'),
                          subtitle: Text(version),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    if (!hasToken)
                      FilledButton(
                        onPressed: () => context.goNamed(RouteNames.login),
                        child: const Text('Se connecter'),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Se déconnecter'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveServerUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    await ref.read(settingsRepositoryProvider).setServerUrl(url);
    ref.invalidate(dioProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Serveur Sonora mis à jour.')),
    );
  }

  Future<void> _logout() async {
    await ref.read(settingsRepositoryProvider).clearAuthSession();
    ref.invalidate(dioProvider);
    ref.invalidate(authTokenProvider);
    ref.read(requireLoginProvider.notifier).state = true;
    if (!mounted) return;
    context.goNamed(RouteNames.login);
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  const Color(0xFF304E78),
                ],
              ),
            ),
            child: const Icon(Icons.person_rounded, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mon espace',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Préférences et bibliothèque Harmonix',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.selected, required this.onSelected});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    const choices = [
      (ThemeMode.light, Icons.light_mode_outlined, 'Clair'),
      (ThemeMode.dark, Icons.dark_mode_outlined, 'Sombre'),
      (ThemeMode.system, Icons.brightness_auto_outlined, 'Auto'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final choice in choices)
          ChoiceChip(
            selected: selected == choice.$1,
            onSelected: (_) => onSelected(choice.$1),
            avatar: Icon(choice.$2, size: 18),
            label: Text(choice.$3),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
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
