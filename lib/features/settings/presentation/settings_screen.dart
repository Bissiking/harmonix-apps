import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/navigation/route_names.dart';
import 'package:harmonix_apps/core/settings/auth_token_provider.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/update/update_checker.dart';
import 'package:harmonix_apps/features/cast/providers/cast_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;
  final TextEditingController _riftSessionIdController = TextEditingController();
  final TextEditingController _riftCodeController = TextEditingController();
  String _selectedRiftRole = 'listen';
  UpdateInfo? _updateInfo;
  String? _updateError;
  bool _isCheckingUpdate = false;

  static const Map<String, String> _roleLabels = {
    'host': 'Hôte',
    'control': 'Contrôle',
    'listen': 'Écoute',
  };

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsRepositoryProvider);
    _urlController = TextEditingController(text: settings.serverUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _riftSessionIdController.dispose();
    _riftCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authToken = ref.watch(authTokenProvider);
    final castState = ref.watch(castProvider);
    final hasToken = authToken?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Serveur',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL du serveur',
              hintText: 'http://192.168.1.x:3000',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final url = _urlController.text.trim();
              if (url.isEmpty) return;
              await ref.read(settingsRepositoryProvider).setServerUrl(url);
              ref.invalidate(dioProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('URL mise à jour — relancez l\'app.')),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
          const SizedBox(height: 24),
          Text(
            'Authentification',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (!hasToken)
            FilledButton(
              onPressed: () => context.goNamed(RouteNames.login),
              child: const Text('Se connecter'),
            )
          else
            TextButton(
              onPressed: () async {
                await ref.read(settingsRepositoryProvider).setAuthToken(null);
                ref.invalidate(dioProvider);
                ref.invalidate(authTokenProvider);
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Déconnecté.')),
                );
              },
              child: const Text('Se déconnecter'),
            ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'RIFT (écoute synchronisée)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedRiftRole,
            decoration: const InputDecoration(
              labelText: 'Rôle',
              border: OutlineInputBorder(),
            ),
            items: _roleLabels.entries
                .map(
                  (entry) =>
                      DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedRiftRole = value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _riftSessionIdController,
            decoration: const InputDecoration(
              labelText: 'ID de session',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _riftCodeController,
            decoration: const InputDecoration(
              labelText: 'Code invité (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: castState.connecting
                    ? null
                    : () => ref
                        .read(castProvider.notifier)
                        .start(role: _selectedRiftRole),
                child: Text(
                  castState.connecting ? 'Connexion...' : 'Créer une session',
                ),
              ),
              FilledButton.tonal(
                onPressed: castState.connecting
                    ? null
                    : () => ref.read(castProvider.notifier).join(
                          sessionId: _riftSessionIdController.text.trim(),
                          code: _riftCodeController.text.trim(),
                          role: _selectedRiftRole,
                        ),
                child: const Text('Rejoindre'),
              ),
              OutlinedButton(
                onPressed: castState.isActive
                    ? () => ref.read(castProvider.notifier).syncPlaybackState()
                    : null,
                child: const Text('Synchroniser maintenant'),
              ),
              OutlinedButton(
                onPressed: castState.isActive
                    ? () => ref.read(castProvider.notifier).setParticipantMode(
                          _selectedRiftRole,
                        )
                    : null,
                child: const Text('Appliquer ce rôle'),
              ),
              OutlinedButton(
                onPressed: castState.isActive
                    ? () => ref.read(castProvider.notifier).leave()
                    : null,
                child: const Text('Quitter session'),
              ),
              OutlinedButton(
                onPressed: castState.isActive
                    ? () => ref.read(castProvider.notifier).end()
                    : null,
                child: const Text('Terminer session'),
              ),
            ],
          ),
          if (castState.sessionId != null) ...[
            const SizedBox(height: 8),
            Text('Session active: ${castState.sessionId}'),
          ],
          if (castState.sessionCode != null) ...[
            const SizedBox(height: 4),
            Text('Code session: ${castState.sessionCode}'),
          ],
          if (castState.role != null) ...[
            const SizedBox(height: 4),
            Text(
              'Rôle courant: ${_roleLabels[castState.role] ?? castState.role}',
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Compat legacy: fallback auto vers /sync/* si /rift/* indisponible.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (castState.error != null) ...[
            const SizedBox(height: 8),
            Text(
              castState.error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Mises à jour',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isCheckingUpdate ? null : _checkUpdate,
            child: Text(_isCheckingUpdate ? 'Vérification...' : 'Vérifier'),
          ),
          if (_updateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _updateError!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          if (_updateInfo != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildUpdateStatus(_updateInfo!),
            ),
          const SizedBox(height: 24),
          Text(
            'À propos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              final version =
                  info == null ? '...' : 'v${info.version}+${info.buildNumber}';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Harmonix Apps'),
                subtitle: Text(version),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateError = null;
    });
    try {
      final info = await checkForUpdate(
        dio: ref.read(dioProvider),
        packageInfo: await PackageInfo.fromPlatform(),
      );
      setState(() {
        _updateInfo = info;
      });
    } catch (_) {
      setState(() {
        _updateError = 'Impossible de vérifier les mises à jour.';
      });
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  Widget _buildUpdateStatus(UpdateInfo info) {
    final updateAvailable = info.updateAvailable;
    final forceUpdate = info.forceUpdate;
    final latest = info.latestVersion;
    final downloadUrl = info.downloadUrl;
    final label = updateAvailable
        ? (forceUpdate ? 'Mise à jour requise' : 'Mise à jour disponible')
        : 'À jour';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        if (latest != null) Text('Dernière: $latest'),
        if (downloadUrl != null && updateAvailable)
          TextButton(
            onPressed: () async {
              final uri = Uri.tryParse(downloadUrl);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Télécharger'),
          ),
      ],
    );
  }
}
