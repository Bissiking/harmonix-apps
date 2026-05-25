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
    final settings = ref.read(settingsRepositoryProvider);
    _urlController = TextEditingController(text: settings.serverUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.read(settingsRepositoryProvider);
    final authToken = ref.watch(authTokenProvider);
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
              await ref
                  .read(settingsRepositoryProvider)
                  .setServerUrl(url);
              ref.invalidate(dioProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL mise à jour — relancez l\'app.')),
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
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Déconnecté.')),
                  );
                }
              },
              child: const Text('Se déconnecter'),
            ),
          const SizedBox(height: 32),
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
              final version = info == null
                  ? '...'
                  : 'v${info.version}+${info.buildNumber}';
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
